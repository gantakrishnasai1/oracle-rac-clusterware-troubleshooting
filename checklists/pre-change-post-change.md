
# Oracle RAC Pre-Change and Post-Change Checklist

## 1. Overview

This checklist provides a standard procedure for
performing planned maintenance activities in Oracle
RAC and Grid Infrastructure environments.

It helps DBAs validate the environment before and
after infrastructure or database changes.

Applicable activities include:

- Grid Infrastructure maintenance.
- Oracle Database patching.
- ASM disk group modifications.
- RAC node maintenance.
- Database parameter changes.
- CPU and memory scaling.
- Storage scaling.
- Network changes.
- Operating system maintenance.
- Planned database restarts.

This document is a general operational checklist.
Always follow the approved implementation plan and
the Oracle-supported procedure for the specific activity.

## 2. Change Information

Complete the following information before starting.

| Parameter | Details |
|---|---|
| Change ID | |
| Change description | |
| Environment | Production / Pre-production / Test |
| Database name | |
| Database version | |
| Grid Infrastructure version | |
| RAC node count | |
| Planned start time | |
| Planned end time | |
| Change owner | |
| DBA contact | |
| Application contact | |
| Infrastructure contact | |
| Approval status | |

## 3. Pre-Change Checklist

### 3.1 Change Planning

- [ ] Change request approved.
- [ ] Maintenance window confirmed.
- [ ] Implementation plan reviewed.
- [ ] Impact assessment completed.
- [ ] Application team informed.
- [ ] Infrastructure team informed.
- [ ] Dependencies identified.
- [ ] Required personnel available.
- [ ] Rollback plan documented.
- [ ] Communication bridge established where required.

### 3.2 Database Health Validation

- [ ] Database status verified.
- [ ] All RAC instances verified.
- [ ] Database services verified.
- [ ] No unexpected instance failures.
- [ ] No critical alert log errors.
- [ ] No unresolved critical database alerts.
- [ ] Tablespace utilization reviewed.
- [ ] FRA utilization reviewed.
- [ ] Archive log generation reviewed.
- [ ] Database backup status verified.
- [ ] Data Guard status checked where applicable.

Useful commands:

```sql
SELECT
    inst_id,
    instance_name,
    host_name,
    status,
    database_status
FROM
    gv$instance
ORDER BY
    inst_id;
```

Check database open mode:

```sql
SELECT
    inst_id,
    name,
    open_mode,
    database_role
FROM
    gv$database
CROSS JOIN
    gv$instance
ORDER BY
    inst_id;
```

### 3.3 Clusterware Health Validation

- [ ] Clusterware services checked on all nodes.
- [ ] Cluster-wide status verified.
- [ ] RAC node membership verified.
- [ ] Cluster resources checked.
- [ ] Voting disk configuration verified.
- [ ] OCR integrity verified.
- [ ] OCR backup information reviewed.
- [ ] Clusterware alert logs reviewed.

Commands:

```bash
crsctl check crs
```

```bash
crsctl check cluster -all
```

```bash
crsctl stat res -t
```

```bash
olsnodes -n -s
```

```bash
ocrcheck
```

```bash
ocrconfig -showbackup
```

```bash
crsctl query css votedisk
```

### 3.4 ASM Health Validation

- [ ] ASM instances verified.
- [ ] Required disk groups mounted.
- [ ] Disk group redundancy reviewed.
- [ ] ASM disk status reviewed.
- [ ] Disk group usable capacity checked.
- [ ] No unexpected offline disks.
- [ ] No unresolved rebalance operations.
- [ ] ASM alert logs reviewed.

Commands:

```bash
asmcmd lsdg
```

```bash
asmcmd lsdsk -p
```

Check active ASM operations:

```sql
SELECT
    inst_id,
    group_number,
    operation,
    state,
    power,
    actual,
    sofar,
    est_work,
    est_minutes
FROM
    gv$asm_operation;
```

### 3.5 Operating System and Infrastructure Checks

- [ ] Host availability verified.
- [ ] CPU utilization reviewed.
- [ ] Memory utilization reviewed.
- [ ] Swap utilization reviewed.
- [ ] Filesystem utilization checked.
- [ ] /tmp capacity checked.
- [ ] Network interfaces verified.
- [ ] Public network connectivity verified.
- [ ] Private interconnect verified.
- [ ] Multipath status checked where applicable.
- [ ] No critical OS errors.
- [ ] Infrastructure health confirmed.

Useful commands:

```bash
hostname -f
uptime
free -h
df -h
df -i
ip addr show
ip route show
```

### 3.6 Performance Baseline

- [ ] AWR baseline collected where licensed.
- [ ] DB Time recorded.
- [ ] DB CPU recorded.
- [ ] Top wait events recorded.
- [ ] SQL performance baseline collected.
- [ ] RAC Global Cache statistics reviewed.
- [ ] Host CPU baseline recorded.
- [ ] I/O performance baseline recorded.
- [ ] Application response time baseline recorded.

Important:

Use comparable workload periods when collecting
performance baselines.

AWR and related Diagnostics Pack features are subject
to Oracle licensing requirements.

### 3.7 Backup and Recovery Readiness

- [ ] Recent RMAN backup verified.
- [ ] Backup completion checked.
- [ ] Backup availability confirmed.
- [ ] Recovery requirements reviewed.
- [ ] Archive log availability verified.
- [ ] Control file backup availability verified.
- [ ] SPFILE backup availability verified.
- [ ] OCR backup information reviewed.
- [ ] Recovery procedure documented.
- [ ] Rollback strategy approved.

A successful backup status does not automatically
prove that recovery is possible.

Verify backup integrity and recovery readiness
using the approved procedure.

## 4. Change Execution Checklist

### 4.1 Before Execution

- [ ] Maintenance window started.
- [ ] Application activity handled as planned.
- [ ] Required approvals reconfirmed.
- [ ] Change owner confirmed.
- [ ] Pre-change outputs saved.
- [ ] Current configuration recorded.
- [ ] Rollback criteria confirmed.

### 4.2 During Execution

- [ ] Follow approved implementation plan.
- [ ] Record execution timestamps.
- [ ] Record commands executed.
- [ ] Monitor database availability.
- [ ] Monitor Clusterware resources.
- [ ] Monitor ASM operations.
- [ ] Monitor infrastructure health.
- [ ] Record any unexpected warnings.
- [ ] Escalate deviations from the plan.
- [ ] Stop execution if rollback criteria are met.

### 4.3 Change-Specific Validation

For Grid Infrastructure patching:

- [ ] Validate patch inventory.
- [ ] Validate patch applicability.
- [ ] Follow the approved patching procedure.
- [ ] Monitor patch execution.
- [ ] Validate Grid Infrastructure after patching.
- [ ] Verify node and resource status.
- [ ] Verify database and ASM availability.

For ASM changes:

- [ ] Validate disk group configuration.
- [ ] Confirm approved storage changes.
- [ ] Monitor rebalance operations.
- [ ] Verify disk group state.
- [ ] Verify usable capacity.
- [ ] Confirm database accessibility.

For database changes:

- [ ] Verify parameter modifications.
- [ ] Verify database open mode.
- [ ] Verify RAC instance availability.
- [ ] Verify service availability.
- [ ] Validate application connectivity.
- [ ] Check alert logs.

For infrastructure scaling:

- [ ] Verify requested CPU or storage configuration.
- [ ] Confirm infrastructure operation completed.
- [ ] Validate database and ASM status.
- [ ] Compare resource allocation with baseline.
- [ ] Check for performance changes.

## 5. Post-Change Checklist

### 5.1 Database Validation

- [ ] All expected instances available.
- [ ] Database open mode correct.
- [ ] Database role correct.
- [ ] Services available.
- [ ] Application connectivity verified.
- [ ] No unexpected database errors.
- [ ] Alert logs reviewed.
- [ ] Tablespace utilization checked.
- [ ] FRA utilization checked.
- [ ] Archive log generation reviewed.

Commands:

```sql
SELECT inst_id,
       name,
       open_mode,
       database_role
FROM gv$database
ORDER BY inst_id;
```

```sql
SELECT
    inst_id,
    name,
    open_mode,
    database_role
FROM
    gv$database
CROSS JOIN
    gv$instance
ORDER BY
    inst_id;
```

### 5.2 Clusterware Validation

- [ ] Clusterware running on all nodes.
- [ ] All expected nodes participating.
- [ ] Cluster resources online.
- [ ] Voting disks accessible.
- [ ] OCR integrity verified.
- [ ] No unexpected resource failures.
- [ ] Clusterware logs reviewed.

Commands:

```bash
crsctl check cluster -all
crsctl stat res -t
olsnodes -n -s
ocrcheck
crsctl query css votedisk
```

### 5.3 ASM Validation

- [ ] ASM instances available.
- [ ] Required disk groups mounted.
- [ ] Expected disk status confirmed.
- [ ] Usable capacity verified.
- [ ] Redundancy verified.
- [ ] Rebalance operations completed or understood.
- [ ] No unexpected ASM errors.

Commands:

```bash
asmcmd lsdg
asmcmd lsdsk -p
```

### 5.4 Performance Validation

- [ ] DB Time compared with baseline.
- [ ] DB CPU compared with baseline.
- [ ] Wait events reviewed.
- [ ] RAC Global Cache waits reviewed.
- [ ] SQL performance compared.
- [ ] I/O latency compared.
- [ ] Host CPU utilization compared.
- [ ] Application response time confirmed.
- [ ] No unexpected performance regression.

Use equivalent workload periods for before-and-after
performance comparisons.

### 5.5 Application and Business Validation

- [ ] Application connectivity confirmed.
- [ ] Application services functioning.
- [ ] Business transactions validated.
- [ ] Batch processing verified where applicable.
- [ ] Application team confirmation received.
- [ ] Monitoring alerts reviewed.
- [ ] Business owner sign-off received.

## 6. Rollback Readiness and Decision Criteria

Rollback must be based on the approved change-specific
rollback plan.

Examples of conditions that may require escalation
or rollback assessment:

- Database unavailable beyond the approved threshold.
- Unexpected RAC node eviction.
- Critical Clusterware resource failure.
- ASM disk group unavailable.
- Unexpected data accessibility issues.
- Significant application impact.
- Unacceptable performance degradation.
- Patch or infrastructure operation failure.

Before rollback:

1. Stop further changes.
2. Inform the change owner.
3. Preserve logs and diagnostic outputs.
4. Confirm the failure scenario.
5. Follow the approved rollback procedure.
6. Validate database and application recovery.

Important:

Not every Oracle change can be safely reversed by
simply restoring a configuration file or restarting
the database.

Some operations require a specific Oracle-supported
rollback or recovery procedure.

## 7. Final Change Summary

Complete the following after the maintenance activity.

| Parameter | Result |
|---|---|
| Change ID | |
| Start time | |
| End time | |
| Actual duration | |
| Implementation status | Successful / Failed / Rolled back |
| Database status | |
| Clusterware status | |
| ASM status | |
| Application status | |
| Performance status | |
| Issues encountered | |
| Rollback required | Yes / No |
| DBA sign-off | |
| Application sign-off | |
| Change owner sign-off | |

## 8. Evidence and Documentation

Attach or preserve:

- Pre-change database status.
- Post-change database status.
- Clusterware resource output.
- OCR validation output.
- Voting disk output.
- ASM disk group output.
- RMAN backup evidence.
- Performance baseline.
- Post-change performance results.
- Relevant alert logs.
- Execution logs.
- Approval and sign-off records.

Do not attach credentials, customer information,
internal network details or sensitive production
data to public repositories.

## 9. Best Practices

- Never start production changes without approval.
- Capture a baseline before modifying the environment.
- Validate backups and recovery readiness.
- Follow Oracle-supported procedures.
- Monitor all RAC nodes during maintenance.
- Record commands and timestamps.
- Define rollback criteria before execution.
- Validate the application after database changes.
- Preserve change evidence.
- Obtain the required sign-offs.

## 10. References

Oracle Grid Infrastructure documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database Backup and Recovery documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database Performance Tuning documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Refer to the documentation for the installed
Oracle Database and Grid Infrastructure release.
