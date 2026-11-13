
# Oracle Data Guard Administration and Troubleshooting Guide

## 1. Overview

Oracle Data Guard provides high availability, data protection, and disaster recovery for Oracle databases.

It maintains one or more standby databases using redo transport and redo apply services.

Common Data Guard configurations include:

- Physical standby
- Logical standby
- Snapshot standby
- Far Sync
- Active Data Guard, where licensed

This guide focuses primarily on physical standby configurations in Oracle Database 19c.

## 2. Understand Data Guard Architecture

A typical Data Guard configuration includes:

| Component | Description |
|---|---|
| Primary database | Production database generating redo |
| Physical standby | Database receiving and applying redo |
| Redo transport | Transfers redo from primary to standby |
| Redo apply | Applies received redo to standby data files |
| Data Guard Broker | Manages and monitors Data Guard configuration |
| Standby Redo Logs | Support real-time redo transport and apply |

Basic data flow:

1. Primary database generates redo.
2. Redo transport sends redo to the standby.
3. Standby receives redo into standby redo logs or archived logs.
4. Managed Recovery Process applies redo.
5. Standby database maintains synchronization with primary.

## 3. Check Data Guard Configuration

Connect to the primary database:

```sql
SELECT name,
       db_unique_name,
       database_role,
       open_mode,
       protection_mode,
       protection_level
FROM v$database;
```

Check database role on all instances:

```sql
SELECT inst_id,
       name,
       db_unique_name,
       database_role,
       open_mode
FROM gv$database
ORDER BY inst_id;
```

Check database instances:

```sql
SELECT inst_id,
       instance_name,
       host_name,
       status
FROM gv$instance
ORDER BY inst_id;
```

Confirm which database is primary and which is standby before performing any administrative operation.

## 4. Check Data Guard Initialization Parameters

Review important Data Guard parameters:

```sql
SHOW PARAMETER db_name;
SHOW PARAMETER db_unique_name;
SHOW PARAMETER log_archive_config;
SHOW PARAMETER log_archive_dest;
SHOW PARAMETER log_archive_dest_state;
SHOW PARAMETER fal_server;
SHOW PARAMETER standby_file_management;
SHOW PARAMETER dg_broker_start;
```

Important parameters include:

| Parameter | Purpose |
|---|---|
| DB_NAME | Database name shared by primary and physical standby |
| DB_UNIQUE_NAME | Unique identifier for each database |
| LOG_ARCHIVE_CONFIG | Defines Data Guard configuration |
| LOG_ARCHIVE_DEST_n | Configures redo destinations |
| LOG_ARCHIVE_DEST_STATE_n | Enables or disables archive destinations |
| FAL_SERVER | Identifies the fetch archive log server |
| STANDBY_FILE_MANAGEMENT | Controls standby file management |
| DG_BROKER_START | Enables Data Guard Broker |

Review actual parameter values and validate them against the existing configuration.

## 5. Check Redo Transport Status

On the primary database:

```sql
SELECT dest_id,
       status,
       target,
       destination,
       error,
       db_unique_name
FROM v$archive_dest
WHERE target = 'STANDBY'
ORDER BY dest_id;
```

Check destination details:

```sql
SELECT dest_id,
       status,
       type,
       database_mode,
       recovery_mode,
       synchronization_status,
       error
FROM v$archive_dest_status
WHERE dest_id > 0
ORDER BY dest_id;
```

Investigate:

- Destination status
- Transport errors
- TNS connectivity
- Authentication problems
- Standby availability
- Archive destination configuration

A destination showing an error requires investigation of the complete error message.

## 6. Check Redo Transport and Apply Lag

On the standby database:

```sql
SELECT name,
       value,
       unit,
       time_computed,
       datum_time
FROM v$dataguard_stats
WHERE name IN (
    'transport lag',
    'apply lag',
    'apply finish time'
);
```

Interpretation:

| Metric | Meaning |
|---|---|
| Transport lag | Delay in receiving redo from primary |
| Apply lag | Delay in applying redo on standby |
| Apply finish time | Estimated time to apply received redo |

Lag values must be interpreted with the `DATUM_TIME` and `TIME_COMPUTED` columns.

A stale datum time may indicate that the standby is not receiving fresh information from the primary.

## 7. Check Redo Apply Process Status

On the standby database:

```sql
SELECT process,
       status,
       thread#,
       sequence#,
       block#,
       blocks
FROM v$managed_standby
ORDER BY process;
```

Check recovery processes:

```sql
SELECT process,
       status,
       thread#,
       sequence#,
       block#
FROM v$managed_standby
WHERE process LIKE 'MRP%';
```

**Note:** `V$MANAGED_STANDBY` is deprecated in newer Oracle releases. For Oracle 19c, it remains useful for legacy monitoring. Where supported, use `V$DATAGUARD_PROCESS` for current process monitoring.

Example:

```sql
SELECT name,
       role,
       action,
       thread#,
       sequence#
FROM v$dataguard_process
ORDER BY name;
```

## 8. Check Archive Log Gaps

On the standby database:

```sql
SELECT thread#,
       low_sequence#,
       high_sequence#
FROM v$archive_gap;
```

If rows are returned, investigate the missing archive log sequence range.

Check received archive logs:

```sql
SELECT thread#,
       sequence#,
       first_time,
       next_time,
       applied,
       registrar
FROM v$archived_log
ORDER BY thread#, sequence#;
```

For RAC databases, check each redo thread separately.

An empty `V$ARCHIVE_GAP` result does not independently prove that the standby is fully synchronized. Also verify transport, apply status, and lag.

## 9. Check Standby Redo Logs

Check standby redo log configuration:

```sql
SELECT group#,
       thread#,
       sequence#,
       bytes / 1024 / 1024 AS size_mb,
       status
FROM v$standby_log
ORDER BY thread#, group#;
```

Check online redo logs:

```sql
SELECT group#,
       thread#,
       bytes / 1024 / 1024 AS size_mb,
       status
FROM v$log
ORDER BY thread#, group#;
```

For RAC Data Guard configurations, validate standby redo logs for every primary redo thread.

A common planning guideline is to configure at least one more standby redo log group per thread than the number of online redo log groups for that thread, with compatible sizing.

Always validate the actual configuration against Oracle Data Guard documentation.

## 10. Check Data Guard Broker

Check whether Broker is enabled:

```sql
SHOW PARAMETER dg_broker_start;
```

Connect to DGMGRL:

```bash
dgmgrl /
```

Display configuration:

```text
SHOW CONFIGURATION;
```

Display database details:

```text
SHOW DATABASE VERBOSE '<DB_UNIQUE_NAME>';
```

Check configuration status:

```text
SHOW CONFIGURATION VERBOSE;
```

Validate the configuration:

```text
VALIDATE DATABASE VERBOSE '<DB_UNIQUE_NAME>';
```

For a physical standby, additional validation may be available through:

```text
VALIDATE DATABASE '<DB_UNIQUE_NAME>' SPFILE;
```

Use the commands supported by the installed Broker release.

## 11. Common Data Guard Troubleshooting Scenarios

### Scenario 1: Transport lag is increasing

Possible causes:

- Network connectivity problems
- Primary redo generation increase
- Standby destination errors
- Standby database unavailable
- Transport process issues

Investigation:

1. Check `V$ARCHIVE_DEST_STATUS` on primary.
2. Review the destination error.
3. Validate primary-to-standby network connectivity.
4. Check standby alert logs.
5. Review redo generation and transport throughput.

### Scenario 2: Apply lag is increasing

Possible causes:

- Standby I/O bottlenecks
- Insufficient recovery throughput
- High redo generation
- Resource contention
- Recovery process errors

Investigation:

1. Check `V$DATAGUARD_STATS`.
2. Check managed recovery processes.
3. Review standby alert logs.
4. Check storage performance.
5. Compare redo generation with apply throughput.

Do not restart managed recovery without first investigating the underlying issue.

### Scenario 3: Archive log gap detected

Investigate:

- Missing sequence numbers
- Redo thread identification
- Archive log availability
- FAL configuration
- Network connectivity
- Archive destination errors

Check the primary and standby archive log inventories.

Use Oracle-supported procedures to transfer and register missing archived logs when automatic gap resolution cannot recover them.

### Scenario 4: ORA-16766 – Redo Apply is stopped

Investigate:

- Standby alert log
- Recovery process errors
- Missing archived logs
- Data file issues
- Recovery configuration
- Broker status

Resolve the underlying issue before restarting recovery.

### Scenario 5: ORA-12514 or ORA-12154

Investigate:

- TNS alias configuration
- Listener registration
- Service name
- DNS or hostname resolution
- Network connectivity
- Connect descriptor

Validate connectivity using the appropriate Oracle Net tools.

## 12. Start and Stop Managed Recovery

For a physical standby database, managed recovery can be controlled using SQL.

Example command to start real-time apply:

```sql
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE
USING CURRENT LOGFILE DISCONNECT FROM SESSION;
```

Example command to stop managed recovery:

```sql
ALTER DATABASE RECOVER MANAGED STANDBY DATABASE CANCEL;
```

**Important:**

- Confirm the database role before executing.
- Use the appropriate administrative account.
- Understand the effect of stopping recovery.
- Follow Broker-managed procedures when the configuration is controlled by Data Guard Broker.
- Validate the exact recovery syntax and configuration for your Oracle 19c RU.

Do not execute recovery commands on the primary database.

## 13. Switchover Validation

A switchover is a planned role reversal between primary and standby databases.

Before a switchover:

- Confirm primary and standby health.
- Check transport lag.
- Check apply lag.
- Confirm no archive gaps.
- Validate standby redo logs.
- Confirm application readiness.
- Validate Data Guard Broker configuration.
- Prepare the application connectivity change.

With Data Guard Broker:

```text
DGMGRL> VALIDATE DATABASE VERBOSE '<STANDBY_DB_UNIQUE_NAME>';
DGMGRL> SWITCHOVER TO '<STANDBY_DB_UNIQUE_NAME>';
```

After switchover:

```text
DGMGRL> SHOW CONFIGURATION;
```

Validate the new roles:

```sql
SELECT name,
       db_unique_name,
       database_role,
       open_mode
FROM v$database;
```

Validate database services and application connectivity.

## 14. Failover Validation

Failover is used when the primary database is unavailable and cannot be recovered within the required recovery objective.

Before failover:

- Confirm primary database unavailability.
- Determine the latest recoverable redo.
- Assess possible data loss.
- Confirm standby database health.
- Review business approval and disaster recovery procedures.
- Validate application recovery requirements.

With Data Guard Broker, a failover may be initiated using:

```text
DGMGRL> FAILOVER TO '<STANDBY_DB_UNIQUE_NAME>';
```

For a forced failover, use only the procedure documented for the actual failure scenario and recovery objective.

After failover:

- Verify the new primary role.
- Validate database open mode.
- Confirm database services.
- Validate application connectivity.
- Review Data Guard Broker configuration.
- Plan reinstatement or recreation of the former primary.

**Important:** Failover may result in data loss depending on protection mode, transport state, and recovery position. Never execute it as a routine troubleshooting action.

## 15. Pre-change Checklist

- [ ] Confirm primary and standby database roles.
- [ ] Validate Data Guard Broker status.
- [ ] Check transport lag.
- [ ] Check apply lag.
- [ ] Validate archive log gap status.
- [ ] Check redo transport destinations.
- [ ] Validate standby redo logs.
- [ ] Review database alert logs.
- [ ] Confirm backup and recovery readiness.
- [ ] Confirm application dependencies.
- [ ] Obtain change approval.
- [ ] Prepare a recovery and rollback plan.

## 16. Post-change Checklist

- [ ] Verify primary and standby roles.
- [ ] Validate redo transport.
- [ ] Validate redo apply.
- [ ] Check transport and apply lag.
- [ ] Confirm no unresolved archive gaps.
- [ ] Validate Data Guard Broker configuration.
- [ ] Confirm database services.
- [ ] Validate application connectivity.
- [ ] Review alert logs.
- [ ] Document the activity and outcome.

## 17. Important Safety Notes

- Never perform a failover without understanding potential data loss.
- Do not modify archive destinations blindly.
- Do not delete archived logs without validating recovery requirements.
- Do not stop managed recovery without understanding the impact.
- Validate every RAC redo thread.
- Follow Broker procedures when Broker manages the configuration.
- Keep primary and standby backup strategies documented.
- Follow Oracle Support guidance for critical Data Guard failures.

## 18. References

- Oracle Data Guard Concepts and Administration
- Oracle Database Reference
- Oracle Database Administrator's Guide
- Oracle Data Guard Broker documentation
- Oracle Support documentation and relevant MOS notes

**Disclaimer:** This guide is a general Oracle Database 19c physical standby reference. Validate all commands and procedures against the installed Oracle Database Release Update and the actual Data Guard configuration before production execution.
