
# Oracle Exadata and Exadata Cloud Service Health Check Guide

## 1. Overview

Oracle Exadata is an engineered system designed to run Oracle Database workloads with optimized database, storage, and networking components.

Exadata Cloud Service (ExaCS) provides Exadata infrastructure through Oracle Cloud Infrastructure (OCI).

This guide covers practical health checks and troubleshooting for:

- Exadata database servers
- Exadata storage cells
- Grid Infrastructure and ASM
- Database instances
- Storage capacity
- Cell services
- Smart Scan and offload
- I/O performance
- OCI Exadata infrastructure

The commands and checks must be validated against the deployed Exadata model, software image, Oracle Database release, and OCI service configuration.

## 2. Exadata Architecture Overview

Major Exadata components include:

| Component | Purpose |
|---|---|
| Database servers | Run Oracle Database instances |
| Storage cells | Provide Exadata storage services |
| ASM | Manages database storage |
| Cell services | Provide storage access and Exadata offload functionality |
| InfiniBand or RoCE network | Provides high-performance connectivity, depending on generation |
| Grid Infrastructure | Manages RAC and cluster resources |
| OCI infrastructure | Manages Exadata Cloud Service resources |

An Exadata health assessment should cover database, Grid Infrastructure, ASM, storage cells, networking, and OCI infrastructure.

## 3. Check Database Server Health

Connect to each database server and check the operating-system status.

### Check hostname

```bash
hostname
hostname -f
```

### Check operating-system version

```bash
cat /etc/os-release
uname -r
```

### Check CPU

```bash
lscpu
```

Check current CPU utilization:

```bash
top
```

### Check memory

```bash
free -h
```

### Check filesystem usage

```bash
df -h
df -i
```

### Check uptime

```bash
uptime
```

Investigate:

- CPU saturation
- Memory pressure
- Swap activity
- Filesystem capacity
- Unexpected reboots
- Kernel errors
- Network interface errors

## 4. Check Grid Infrastructure and RAC Health

Check Clusterware across all nodes:

```bash
crsctl check cluster -all
```

Check cluster resources:

```bash
crsctl stat res -t
```

Check cluster nodes:

```bash
olsnodes -n -s
```

Check OCR:

```bash
ocrcheck
```

Check voting disks:

```bash
crsctl query css votedisk
```

Check ASM instances:

```bash
srvctl status asm
```

Check database instances:

```bash
srvctl status database -db <DB_UNIQUE_NAME>
```

Review Grid Infrastructure alert logs for:

- CRS resource failures
- CSS communication issues
- Node eviction
- ASM failures
- Network errors
- Unexpected resource restarts

## 5. Check ASM Disk Group Health

Connect to the ASM instance:

```bash
sqlplus / as sysasm
```

Check disk group capacity:

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

Check ASM disk status:

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

Check ASM operations:

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

Investigate:

- Disk group dismounts
- Disk offline events
- Capacity pressure
- Rebalance errors
- ASM disk discovery failures
- Unexpected disk state changes

## 6. Check Exadata Storage Cell Health

Connect to a storage cell using the authorized cell administration account.

Check cell status:

```bash
cellcli -e LIST CELL DETAIL
```

Check physical disks:

```bash
cellcli -e LIST PHYSICALDISK ATTRIBUTES name,status,errMedia,errOther
```

Check grid disks:

```bash
cellcli -e LIST GRIDDISK ATTRIBUTES name,status,asmModeStatus,asmDeactivationOutcome
```

Check cell disks:

```bash
cellcli -e LIST CELLDISK ATTRIBUTES name,status
```

Check cell services:

```bash
cellcli -e LIST CELLSRV DETAIL
cellcli -e LIST MS DETAIL
cellcli -e LIST RS DETAIL
```

Review:

- Physical disk status
- Cell disk status
- Grid disk status
- Cell services
- Media errors
- Other disk errors
- Storage cell alerts

**Important:** CellCLI attributes and command availability may differ across Exadata software releases. Validate syntax on the installed release.

## 7. Check Exadata Storage Alerts

Review storage cell alerts:

```bash
cellcli -e LIST ALERTHISTORY
```

Check recent alerts and investigate:

- Disk failures
- Cell service failures
- Flash cache issues
- Storage connectivity
- Hardware faults
- Temperature or power events

Correlate cell alerts with database and ASM alert logs.

For critical hardware alerts, follow the applicable Oracle Support and Exadata maintenance procedures.

## 8. Check Exadata Flash Cache

Check flash cache configuration:

```bash
cellcli -e LIST FLASHCACHE DETAIL
```

Review:

- Flash cache status
- Capacity
- Write-back or write-through configuration, where applicable
- Cache errors
- Flash cache replacement or failure events

Flash cache configuration and behavior depend on Exadata generation and software release.

Do not change flash cache settings without understanding the storage architecture and Oracle guidance.

## 9. Check Exadata Smart Scan and Offload

Exadata Smart Scan can offload eligible SQL processing to storage cells.

Check relevant database statistics:

```sql
SELECT name,
       value
FROM v$sysstat
WHERE LOWER(name) LIKE '%cell%'
ORDER BY name;
```

Review relevant statistics such as:

- cell physical IO interconnect bytes
- cell physical IO bytes eligible for predicate offload
- cell physical IO bytes saved by storage index
- cell physical IO interconnect bytes returned by smart scan

Statistics available and their names may vary by release.

Review SQL execution plans:

```sql
SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        '<SQL_ID>',
        NULL,
        'ALLSTATS LAST'
    )
);
```

Investigate:

- Whether the SQL is eligible for offload
- Execution plan operations
- Predicate pushdown
- Storage index usage
- Interconnect traffic
- Actual rows processed

Do not assume that every full table scan should use Smart Scan. Eligibility depends on SQL operations, execution conditions, and Exadata configuration.

## 10. Check Database I/O Performance

Review database wait events:

```sql
SELECT inst_id,
       event,
       wait_class,
       total_waits,
       time_waited_micro
FROM gv$system_event
WHERE wait_class IN ('User I/O', 'System I/O')
ORDER BY time_waited_micro DESC;
```

Check file I/O statistics:

```sql
SELECT inst_id,
       filetype_name,
       small_read_megabytes,
       large_read_megabytes,
       small_write_megabytes,
       large_write_megabytes
FROM gv$iostat_file
ORDER BY inst_id, filetype_name;
```

Review:

- Read latency
- Write latency
- I/O throughput
- Database wait events
- Storage cell performance
- SQL execution workload

Use AWR reports for detailed before-and-after performance comparisons where the required Oracle Diagnostics Pack license is available.

## 11. Check Exadata Database and Storage Connectivity

Validate database server network interfaces:

```bash
ip addr
```

Check interface statistics:

```bash
ip -s link
```

Check routing:

```bash
ip route
```

Check connectivity to the appropriate infrastructure endpoints using approved diagnostic procedures.

Investigate:

- Network interface errors
- Packet drops
- Link failures
- Network latency
- Storage connectivity
- Interconnect failures

Exadata network architecture varies by generation. Use the correct network troubleshooting procedures for the deployed system.

## 12. Exadata Cloud Service (ExaCS) Health Checks

For OCI Exadata Cloud Service, monitor both database-level and OCI infrastructure-level health.

Review the following:

- Exadata infrastructure status
- VM cluster status
- Database server status
- Storage server status
- Database home status
- Database status
- Maintenance activities
- Backup status
- CPU allocation
- Storage capacity
- Monitoring alarms

Use the OCI Console to review infrastructure and resource health.

Where OCI CLI is configured, validate the available commands and permissions.

Example command structure for listing Exadata infrastructure resources:

```bash
oci db exadata-infrastructure list \
  --compartment-id <COMPARTMENT_OCID>
```

Example command structure for listing VM clusters:

```bash
oci db vm-cluster list \
  --compartment-id <COMPARTMENT_OCID>
```

The exact CLI command and available fields depend on the OCI CLI version and resource type.

Never publish OCIDs, tenancy information, private endpoints, or credentials in a public repository.

## 13. ExaCS CPU and Storage Monitoring

Monitor database CPU allocation and infrastructure capacity.

Review:

- Allocated ECPU or OCPU
- Minimum and maximum CPU settings, where applicable
- Current database workload
- Storage allocation
- ASM usable capacity
- Capacity growth
- Scaling configuration

For dynamic scaling configurations, verify the supported limits and configuration using the applicable Oracle documentation.

Before scaling:

1. Capture the current configuration.
2. Review database workload.
3. Check capacity requirements.
4. Review resource dependencies.
5. Obtain change approval.
6. Follow the supported scaling procedure.
7. Perform post-change validation.

Do not assume CPU scaling and storage scaling have the same operational impact.

## 14. Common Exadata Troubleshooting Scenarios

### Scenario 1: ASM disk group space is low

Investigate:

- ASM usable capacity
- Disk group redundancy
- Database growth
- Archive log accumulation
- Storage cell capacity
- Planned storage expansion

### Scenario 2: Physical disk failure

Investigate:

- Physical disk status
- Cell alert history
- Cell disk status
- Grid disk status
- ASM redundancy
- Storage cell diagnostics

Do not manually remove or replace disks without following Oracle Exadata maintenance procedures.

### Scenario 3: High database I/O latency

Investigate:

- Database wait events
- AWR reports
- SQL workload
- ASM rebalance activity
- Storage cell alerts
- Cell services
- Storage performance metrics

### Scenario 4: Cell service unavailable

Investigate:

- CELLSRV status
- MS status
- RS status
- Storage cell alert history
- Hardware and network health

Follow Oracle Support guidance before restarting critical storage services.

### Scenario 5: ExaCS infrastructure scaling

Before scaling:

- Check database workload.
- Capture current CPU and storage allocation.
- Review ASM usable capacity.
- Validate supported scaling limits.
- Review maintenance requirements.
- Obtain approval.

After scaling:

- Verify infrastructure status.
- Check Clusterware.
- Check ASM.
- Check database instances.
- Compare performance with the baseline.

## 15. Pre-change Health Check Checklist

- [ ] Confirm database server health.
- [ ] Check operating-system status.
- [ ] Validate Clusterware.
- [ ] Validate OCR and voting disks.
- [ ] Check ASM disk groups.
- [ ] Check ASM disk status.
- [ ] Validate storage cell health.
- [ ] Review cell alert history.
- [ ] Check physical disk errors.
- [ ] Review database I/O performance.
- [ ] Check CPU and memory utilization.
- [ ] Validate ExaCS infrastructure status.
- [ ] Capture performance baseline.
- [ ] Confirm backup and recovery readiness.
- [ ] Obtain change approval.

## 16. Post-change Health Check Checklist

- [ ] Verify all database servers are healthy.
- [ ] Verify all storage cells are healthy.
- [ ] Validate Clusterware resources.
- [ ] Validate ASM disk groups.
- [ ] Check physical and grid disk status.
- [ ] Review storage cell alerts.
- [ ] Validate database instances.
- [ ] Check database services.
- [ ] Review I/O wait events.
- [ ] Compare performance against baseline.
- [ ] Confirm application connectivity.
- [ ] Document the activity and outcome.

## 17. Important Safety Notes

- Never modify Exadata storage configuration without following Oracle-supported procedures.
- Do not manually remove physical disks or grid disks.
- Do not restart storage cell services without understanding the impact.
- Validate ASM redundancy before storage operations.
- Do not assume cell health alone guarantees database health.
- Check both database and infrastructure-level monitoring.
- Sanitize infrastructure details before publishing diagnostic output.
- Follow Oracle Support guidance for critical Exadata failures.

## 18. References

- Oracle Exadata Database Machine documentation
- Oracle Exadata System Software documentation
- Oracle Exadata Cloud Service documentation
- Oracle Database Administrator's Guide
- Oracle Automatic Storage Management Administrator's Guide
- Oracle Cloud Infrastructure documentation
- Oracle Support documentation and relevant MOS notes

**Disclaimer:** This guide is a general health-check reference. Validate all commands, attributes, and procedures against the deployed Exadata generation, software image, Oracle Database release, and OCI service configuration.
