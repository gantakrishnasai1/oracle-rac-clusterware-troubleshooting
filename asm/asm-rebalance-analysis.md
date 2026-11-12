
# Oracle ASM Rebalance Analysis and Troubleshooting

## 1. Overview

Oracle Automatic Storage Management (ASM) automatically redistributes data when disks are added, dropped, resized, or when disk group operations require rebalancing.

ASM rebalance operations can generate significant storage I/O. Monitoring their progress and understanding their impact is important, particularly in production Oracle RAC and Exadata environments.

This guide covers:

- Monitoring active ASM rebalance operations
- Understanding rebalance progress and status
- Monitoring rebalance power
- Investigating slow rebalance operations
- Assessing database workload impact
- Validating completion

## 2. Check Active ASM Rebalance Operations

Connect to the ASM instance:

```bash
export ORACLE_SID=+ASM1
sqlplus / as sysasm
```

Check active ASM operations:

```sql
SELECT group_number,
       operation,
       pass,
       state,
       power,
       actual,
       sofar,
       est_work,
       est_rate,
       est_minutes,
       error_code
FROM v$asm_operation;
```

For Oracle RAC environments, use:

```sql
SELECT inst_id,
       group_number,
       operation,
       pass,
       state,
       power,
       actual,
       sofar,
       est_work,
       est_rate,
       est_minutes,
       error_code
FROM gv$asm_operation
ORDER BY inst_id, group_number;
```

## 3. Understand ASM Rebalance Columns

| Column | Description |
|---|---|
| GROUP_NUMBER | ASM disk group identifier |
| OPERATION | ASM operation being performed |
| PASS | Current rebalance phase |
| STATE | Current operation state |
| POWER | Requested rebalance power |
| ACTUAL | Actual rebalance power |
| SOFAR | Work completed in the current pass |
| EST_WORK | Estimated total work in the current pass |
| EST_RATE | Estimated work rate |
| EST_MINUTES | Estimated remaining time |
| ERROR_CODE | Error code, if reported |

**Important:** `SOFAR` and `EST_WORK` describe the current pass. Rebalance operations may contain multiple passes, so these values should not be interpreted as a simple percentage of the entire operation.

The estimated completion time can change as workload and storage performance change.

## 4. Check ASM Disk Group Capacity

Before and during rebalance operations, monitor disk group capacity:

```sql
SELECT name,
       state,
       type,
       total_mb,
       free_mb,
       required_mirror_free_mb,
       usable_file_mb
FROM v$asm_diskgroup
ORDER BY name;
```

For RAC:

```sql
SELECT inst_id,
       name,
       state,
       type,
       total_mb,
       free_mb,
       usable_file_mb
FROM gv$asm_diskgroup
ORDER BY inst_id, name;
```

Pay particular attention to:

- FREE_MB
- REQUIRED_MIRROR_FREE_MB
- USABLE_FILE_MB
- Disk group redundancy
- Available capacity for the planned operation

Do not assume that FREE_MB represents the capacity available for new files. Redundancy requirements must be considered.

## 5. Understand ASM Rebalance Phases

ASM rebalance operations can involve multiple passes.

Common pass names include:

| Pass | Description |
|---|---|
| COMPACT | Compacts allocated space where applicable |
| REBALANCE | Redistributes ASM extents |
| RESYNC | Synchronizes extent changes where applicable |

The actual passes and their behavior depend on the operation and ASM release.

Monitor the PASS column to understand which phase is currently running.

## 6. Understand ASM Rebalance Power

ASM rebalance power controls the resources allocated to rebalance operations.

Check the current ASM power limit:

```sql
SHOW PARAMETER asm_power_limit;
```

You can also query:

```sql
SELECT name,
       value
FROM v$parameter
WHERE name = 'asm_power_limit';
```

Higher rebalance power can increase the speed of redistribution, but it may also increase storage I/O and affect database workloads.

Lower power may reduce the impact on database activity but can extend the rebalance duration.

### Example: Change rebalance power

Review the current operation and workload before changing power.

Example syntax:

```sql
ALTER DISKGROUP DATA REBALANCE POWER 8;
```

Replace `DATA` with the actual disk group name.

**Important:**

- Choose power based on workload and storage capacity.
- Do not blindly increase power in production.
- Validate the supported power range for your ASM release.
- Consider other concurrent ASM operations.
- Monitor database latency after changing power.

The `POWER` clause applies to the specified rebalance operation. The `ASM_POWER_LIMIT` initialization parameter provides the default power limit when a power level is not specified.

## 7. Investigate Slow ASM Rebalance Operations

If rebalance operations are taking longer than expected, investigate the following areas.

### 7.1 Check ASM operation progress

```sql
SELECT group_number,
       operation,
       pass,
       state,
       power,
       actual,
       sofar,
       est_work,
       est_rate,
       est_minutes
FROM v$asm_operation;
```

Capture the output periodically and compare progress.

### 7.2 Check ASM disk status

```sql
SELECT group_number,
       disk_number,
       name,
       path,
       header_status,
       mode_status,
       state,
       total_mb,
       free_mb
FROM v$asm_disk
ORDER BY group_number, disk_number;
```

Investigate disks that are offline, missing, or in unexpected states.

### 7.3 Check database wait events

For RAC environments:

```sql
SELECT inst_id,
       event,
       total_waits,
       time_waited_micro
FROM gv$system_event
WHERE wait_class = 'User I/O'
ORDER BY time_waited_micro DESC;
```

Review relevant I/O waits and compare them with the workload baseline.

### 7.4 Check ASM alert logs

Use ADRCI:

```bash
adrci
```

Then:

```text
show homes
set home <ASM ADR HOME>
show alert -tail 100
```

Look for:

- Disk I/O errors
- Disk offline messages
- Rebalance errors
- Disk group space issues
- Storage-related errors

### 7.5 Check operating-system storage performance

Where operating-system access is available, review storage performance using appropriate tools:

```bash
iostat -xz 5 5
```

On Oracle Linux, ensure the required sysstat package is installed.

For Exadata, investigate relevant storage-server and cell metrics using supported Exadata monitoring tools.

Do not rely on a single OS metric to determine the cause of slow ASM rebalance operations.

## 8. ASM Rebalance After Adding or Dropping Disks

Adding or dropping ASM disks can trigger data redistribution.

Before the operation:

- Confirm disk group health.
- Validate available capacity.
- Check disk visibility across RAC nodes.
- Confirm redundancy.
- Review storage configuration.
- Capture the current disk group status.
- Review active ASM operations.

After the operation:

- Verify disk status.
- Monitor rebalance completion.
- Check disk group capacity.
- Review ASM alert logs.
- Confirm the disk group is healthy.
- Validate database workload performance.

Use Oracle-supported procedures for adding, dropping, or replacing disks.

Do not remove storage devices directly from the operating system while ASM is managing them.

## 9. Validate Rebalance Completion

Check whether any operation remains active:

```sql
SELECT group_number,
       operation,
       pass,
       state,
       power,
       actual,
       sofar,
       est_work,
       est_minutes,
       error_code
FROM v$asm_operation;
```

An empty result means no operations are currently reported by this view. It does not independently prove that the storage change was successful.

Perform additional checks:

```sql
SELECT name,
       state,
       type,
       total_mb,
       free_mb,
       usable_file_mb
FROM v$asm_diskgroup
ORDER BY name;
```

Validate disk states:

```sql
SELECT name,
       path,
       header_status,
       mode_status,
       state
FROM v$asm_disk
ORDER BY name;
```

Review ASM alert logs and confirm that the intended storage configuration has been achieved.

## 10. Common Troubleshooting Scenarios

### Scenario 1: Rebalance is taking longer than expected

Investigate:

- Current rebalance pass
- Rebalance power
- Storage I/O latency
- Concurrent database workload
- Disk performance
- ASM alert log messages

Avoid increasing rebalance power without assessing the impact.

### Scenario 2: Rebalance operation reports an error

Check:

- ERROR_CODE in V$ASM_OPERATION
- ASM alert logs
- Disk availability
- Disk group state
- Storage connectivity

Collect diagnostics and follow Oracle Support guidance where necessary.

### Scenario 3: Database performance degrades during rebalance

Compare database performance before and during the operation.

Investigate:

- User I/O wait events
- Storage latency
- Database workload
- ASM rebalance power
- Exadata cell performance, where applicable

If necessary, assess reducing rebalance power through an approved change.

### Scenario 4: Disk group capacity is insufficient

Review usable capacity and redundancy requirements before proceeding.

Do not assume that adding a disk or dropping another disk will always resolve the capacity issue. Validate the expected capacity and failure-group implications first.

## 11. Pre-change and Post-change Checklist

### Before rebalance

- [ ] Confirm ASM instance health.
- [ ] Confirm disk group state.
- [ ] Validate redundancy and usable capacity.
- [ ] Check all ASM disk states.
- [ ] Review existing rebalance operations.
- [ ] Capture database performance baseline.
- [ ] Review storage performance.
- [ ] Obtain approved change authorization.
- [ ] Prepare a change-specific recovery plan.

### After rebalance

- [ ] Confirm no unexpected active ASM operations remain.
- [ ] Validate disk group state.
- [ ] Validate ASM disk status.
- [ ] Verify usable capacity.
- [ ] Review ASM alert logs.
- [ ] Compare database performance with baseline.
- [ ] Confirm application availability.
- [ ] Document completion and observations.

## 12. Important Safety Notes

- Do not terminate ASM rebalance operations without understanding the consequences.
- Do not modify ASM disk headers manually.
- Do not change rebalance power blindly.
- Validate redundancy before disk removal or replacement.
- Do not assume an empty V$ASM_OPERATION result confirms every aspect of a storage change.
- Follow Oracle documentation and Oracle Support guidance for production storage operations.

## 13. References

- Oracle Automatic Storage Management Administrator's Guide
- Oracle Database Reference
- Oracle Database Administrator's Guide
- Oracle Exadata documentation, where applicable

Always validate commands and procedures against the installed Oracle Database and Grid Infrastructure release.
