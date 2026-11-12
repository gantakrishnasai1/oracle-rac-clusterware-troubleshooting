
# Oracle ASM Disk Group Troubleshooting Guide

## 1. Overview

Oracle Automatic Storage Management (ASM) provides storage management for Oracle Database files.

This guide covers common ASM disk group health and capacity checks, disk status validation, and troubleshooting approaches for Oracle RAC environments.

## 2. Check ASM Instance Status

Connect to the ASM instance:

```bash
export ORACLE_SID=+ASM1
sqlplus / as sysasm
```

For RAC environments, validate ASM instances across all nodes:

```bash
srvctl status asm
```

Check ASM instance status:

```sql
SELECT inst_id,
       instance_name,
       status,
       version
FROM gv$instance
ORDER BY inst_id;
```

## 3. Check Disk Group Status and Capacity

Check disk group configuration:

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

For RAC environments, use:

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

### Important capacity columns

| Column | Description |
|---|---|
| TOTAL_MB | Total disk group capacity |
| FREE_MB | Free capacity before redundancy considerations |
| REQUIRED_MIRROR_FREE_MB | Space reserved to restore redundancy after a disk failure |
| USABLE_FILE_MB | Estimated space available for files after redundancy considerations |

**Important:** `USABLE_FILE_MB` is generally more useful than `FREE_MB` when evaluating capacity in normal or high redundancy disk groups.

Monitor disk group capacity regularly and investigate unexpected changes in free space.

## 4. Check ASM Disk Status

Check ASM disk information:

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

For RAC environments:

```sql
SELECT inst_id,
       group_number,
       disk_number,
       name,
       path,
       header_status,
       mode_status,
       state
FROM gv$asm_disk
ORDER BY inst_id, group_number, disk_number;
```

### Important disk status values

| Column | Value | Meaning |
|---|---|---|
| HEADER_STATUS | MEMBER | Disk belongs to an ASM disk group |
| HEADER_STATUS | CANDIDATE | Disk is available for ASM use |
| HEADER_STATUS | FORMER | Disk was previously part of a disk group |
| MODE_STATUS | ONLINE | Disk is online |
| MODE_STATUS | OFFLINE | Disk is offline |
| STATE | NORMAL | Disk is operating normally |
| STATE | ADDING | Disk is being added |
| STATE | DROPPING | Disk is being removed |
| STATE | HUNG | Disk operation is hung |

Interpret status values in the context of the disk group operation and Oracle release.

## 5. Check ASM Disk Group Attributes

```sql
SELECT name,
       value
FROM v$asm_attribute
WHERE name IN (
    'compatible.asm',
    'compatible.rdbms',
    'au_size',
    'disk_repair_time'
)
ORDER BY name;
```

Check redundancy and compatibility attributes before planning storage changes or database upgrades.

## 6. Check ASM Rebalance Operations

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

For RAC environments:

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

### Important columns

| Column | Description |
|---|---|
| OPERATION | ASM operation, such as REBAL |
| PASS | Current rebalance phase |
| STATE | Operation state |
| POWER | Requested rebalance power |
| ACTUAL | Actual rebalance power |
| SOFAR | Work completed |
| EST_WORK | Estimated total work |
| EST_MINUTES | Estimated remaining time |
| ERROR_CODE | Error associated with the operation, if any |

Check rebalance progress periodically. Avoid changing rebalance power without understanding the workload and storage impact.

## 7. Check ASM Disk Group Usage Using ASMCMD

Connect to the ASM environment:

```bash
export ORACLE_SID=+ASM1
asmcmd
```

List disk groups:

```bash
lsdg
```

List ASM disks:

```bash
lsdsk
```

Show detailed disk information:

```bash
lsdsk -p
```

List files in a disk group:

```bash
ls +DATA/
```

Check ASM disk group usage:

```bash
du +DATA/
```

Use the appropriate disk group name for your environment.

## 8. Common ASM Troubleshooting Scenarios

### Scenario 1: Disk group is not mounted

Check disk group status:

```sql
SELECT name, state
FROM v$asm_diskgroup;
```

Check ASM alert logs and disk discovery configuration.

Review:

- ASM instance status
- Disk discovery string
- Underlying storage visibility
- Disk header status
- Clusterware resource status
- ASM alert log errors

Do not force-mount a disk group without understanding why it is dismounted and validating the recovery implications.

### Scenario 2: ASM disk is offline

Check disk status:

```sql
SELECT name,
       path,
       header_status,
       mode_status,
       state
FROM v$asm_disk
ORDER BY name;
```

Investigate:

- Storage availability
- Multipath status
- Disk permissions and ownership
- ASM alert log messages
- Storage and operating-system errors
- Disk repair timer and redundancy status

Do not drop or replace an ASM disk until the storage issue and disk group redundancy are understood.

### Scenario 3: Disk group space is running low

Check capacity:

```sql
SELECT name,
       total_mb,
       free_mb,
       usable_file_mb
FROM v$asm_diskgroup
ORDER BY name;
```

Investigate:

- Database file growth
- Archive log accumulation
- Backup retention
- Temporary files
- Unused or obsolete files
- ASM rebalance activity

Plan capacity expansion based on usable capacity, redundancy, and expected growth.

### Scenario 4: ASM rebalance is taking longer than expected

Check active operations:

```sql
SELECT group_number,
       operation,
       state,
       power,
       actual,
       sofar,
       est_work,
       est_minutes
FROM v$asm_operation;
```

Investigate:

- Storage I/O latency
- Disk performance
- Concurrent database workload
- Rebalance power
- ASM alert log messages
- Storage-side performance issues

Increasing rebalance power can increase storage I/O utilization and affect database workloads. Change it only after assessing the impact.

## 9. ASM Alert Log Checks

Use ADRCI to identify the ASM alert log:

```bash
adrci
```

Inside ADRCI:

```text
show homes
set home <ASM ADR HOME>
show alert -tail 100
```

Review errors related to:

- Disk discovery
- Disk offline or missing
- Disk group mount failures
- Rebalance errors
- I/O failures
- ASM instance startup

Sanitize diagnostic output before sharing it externally.

## 10. Pre-change Validation Checklist

Before performing ASM disk group changes:

- [ ] Confirm ASM instance health on all RAC nodes.
- [ ] Confirm disk group state.
- [ ] Verify usable capacity.
- [ ] Check disk status and redundancy.
- [ ] Review active rebalance operations.
- [ ] Confirm storage visibility across nodes.
- [ ] Review ASM alert logs.
- [ ] Validate backup and recovery readiness.
- [ ] Obtain approved change authorization.
- [ ] Prepare a change-specific rollback or recovery plan.

## 11. Important Safety Notes

- Never remove ASM disks directly from the operating system while they are still managed by ASM.
- Do not manually modify ASM disk headers.
- Do not drop disks without checking redundancy and rebalance implications.
- Validate disk group capacity before and after storage operations.
- Use Oracle-supported procedures for disk replacement and disk group recovery.
- Follow Oracle Support guidance for critical production storage failures.

## 12. References

- Oracle Database Administrator's Guide
- Oracle Automatic Storage Management Administrator's Guide
- Oracle Database Reference
- Oracle Clusterware Administration and Deployment Guide

Always validate commands against the installed Oracle Database and Grid Infrastructure release.
