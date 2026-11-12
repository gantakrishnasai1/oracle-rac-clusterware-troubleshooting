
# Oracle RAC Wait Event Analysis and Troubleshooting

## 1. Overview

Oracle RAC uses Cache Fusion technology to coordinate
database block access between multiple instances.

When a session requests a database block that is currently
available in another instance's buffer cache, Oracle RAC
coordinates the block transfer through the Global Cache
Service (GCS) and Global Enqueue Service (GES).

RAC-related wait events can help identify:

- Global Cache block transfer delays.
- Inter-instance block contention.
- Hot block access.
- Private interconnect issues.
- Concurrent transaction activity.
- Application workload distribution.
- I/O-related performance issues.

This guide describes how to investigate RAC wait events
and identify their possible causes.

## 2. Scope

This document covers:

- Oracle RAC wait-event fundamentals.
- Foreground wait-event analysis.
- Global Cache and Cache Fusion.
- RAC interconnect investigation.
- Common Global Cache wait events.
- Instance-level comparison.
- Block contention.
- SQL and object-level investigation.
- Troubleshooting procedures.

## 3. Prerequisites

Before starting the investigation, collect:

| Parameter | Description |
|---|---|
| Database version | Oracle release and RU |
| RAC configuration | Number of instances |
| Database name | Database under investigation |
| Instance names | All RAC instances |
| Analysis period | Start and end time |
| Workload type | OLTP, batch or reporting |
| Recent changes | Infrastructure or application changes |

For historical AWR-based analysis, verify the required
Diagnostics Pack licensing.

For real-time investigation, use appropriate dynamic
performance views and privileges.

## 4. Understanding Oracle RAC Wait Events

Wait events indicate that a database process is waiting
for a particular resource or operation.

In RAC environments, wait events can be broadly grouped
into:

- Global Cache waits.
- Concurrency waits.
- I/O waits.
- Commit waits.
- Application waits.
- Network-related waits.

Not every RAC wait event indicates a problem.

Evaluate:

- Total wait time.
- Number of waits.
- Average wait time.
- Number of affected sessions.
- SQL statements involved.
- Objects and blocks involved.
- Business workload during the period.

Avoid interpreting wait-event counts without considering
their contribution to DB Time.

## 5. Important RAC Global Cache Wait Events

Common Global Cache wait events include:

| Wait event | Investigation area |
|---|---|
| gc current request | Current block request |
| gc cr request | Consistent read block request |
| gc current block 2-way | Current block transfer |
| gc current block 3-way | Current block transfer involving additional coordination |
| gc cr block 2-way | Consistent read block transfer |
| gc cr block 3-way | Consistent read block transfer involving additional coordination |
| gc buffer busy acquire | Buffer contention while acquiring a block |
| gc buffer busy release | Buffer contention while releasing a block |

The exact event names and availability depend on
the Oracle Database release.

Always check the complete event name and wait
parameters before determining the root cause.

## 6. Check Current RAC Wait Events

### 6.1 Instance-level system wait events

Execute:

```sql
SELECT
    inst_id,
    event,
    wait_class,
    total_waits,
    time_waited_micro / 1000000 AS time_waited_seconds,
    CASE
        WHEN total_waits > 0 THEN
            ROUND(
                time_waited_micro / total_waits / 1000,
                3
            )
    END AS avg_wait_ms
FROM
    gv$system_event
WHERE
    wait_class <> 'Idle'
ORDER BY
    time_waited_micro DESC;
```

This query displays cumulative system wait statistics
for each RAC instance.

Important:

- These values are cumulative since instance startup.
- Consider instance uptime and recent restarts.
- Use interval-based deltas for meaningful comparisons.
- Do not compare cumulative values from different
  uptime periods without normalization.

### 6.2 RAC Global Cache waits

```sql
SELECT
    inst_id,
    event,
    total_waits,
    ROUND(time_waited_micro / 1000000, 2)
        AS wait_seconds,
    ROUND(
        time_waited_micro /
        NULLIF(total_waits, 0) / 1000,
        3
    ) AS avg_wait_ms
FROM
    gv$system_event
WHERE
    event LIKE 'gc%'
ORDER BY
    time_waited_micro DESC;
```

Review the events contributing the most wait time.

A high number of Global Cache waits does not
automatically mean the interconnect is slow.

Investigate block contention, workload distribution
and interconnect performance together.

## 7. Historical Wait Event Analysis

When Diagnostics Pack licensing permits AWR access,
historical system event statistics can be reviewed
using DBA_HIST_SYSTEM_EVENT.

The following query calculates approximate event
deltas between consecutive snapshots.

```sql
WITH event_history AS
(
    SELECT
        snap_id,
        instance_number,
        event_name,
        wait_class,
        total_waits,
        time_waited_micro,
        LAG(total_waits) OVER
        (
            PARTITION BY
                instance_number,
                event_name
            ORDER BY snap_id
        ) AS previous_waits,
        LAG(time_waited_micro) OVER
        (
            PARTITION BY
                instance_number,
                event_name
            ORDER BY snap_id
        ) AS previous_time
    FROM
        dba_hist_system_event
    WHERE
        snap_id BETWEEN :begin_snap - 1
                    AND :end_snap
)
SELECT
    instance_number,
    event_name,
    wait_class,
    SUM(total_waits - previous_waits)
        AS waits_delta,
    ROUND(
        SUM(time_waited_micro - previous_time) / 1000000,
        2
    ) AS wait_seconds
FROM
    event_history
WHERE
    snap_id BETWEEN :begin_snap AND :end_snap
    AND previous_waits IS NOT NULL
    AND previous_time IS NOT NULL
    AND total_waits >= previous_waits
    AND time_waited_micro >= previous_time
GROUP BY
    instance_number,
    event_name,
    wait_class
ORDER BY
    wait_seconds DESC;
```

Important:

- Use matching DBID and snapshot periods when
  extending this query for multi-database environments.
- The query assumes consecutive snapshots for each
  instance and event.
- Excluded negative deltas may indicate instance
  restarts or counter resets.
- Review snapshot interval boundaries.
- Historical data availability depends on AWR retention.

## 8. RAC Global Cache and Cache Fusion

Cache Fusion enables database blocks to be transferred
between RAC instances using the private interconnect.

A typical block access operation may involve:

1. A session requests a database block.
2. Oracle checks whether the block is available locally.
3. If required, GCS coordinates with the remote instance.
4. The requested block is transferred.
5. The requesting session continues execution.

Investigate:

- Block transfer latency.
- Frequent cross-instance access.
- Hot database blocks.
- Concurrent modifications.
- Global Cache wait events.
- Network and interconnect health.

High Cache Fusion activity can be normal in RAC.
The important factor is whether it contributes
significantly to response time.

## 9. RAC Interconnect Analysis

The private interconnect carries RAC cluster
communication and Cache Fusion traffic.

Investigate the following:

- Interconnect latency.
- Packet drops.
- Network errors.
- Interface utilization.
- MTU consistency.
- Network routing.
- Interface health.

### 9.1 Check network interfaces

```bash
ip addr show
```

### 9.2 Check interface statistics

```bash
ip -s link show
```

Review:

- RX errors.
- TX errors.
- Dropped packets.
- Interface state.

### 9.3 Check routing

```bash
ip route show
```

### 9.4 Validate private network connectivity

```bash
ping -c 4 <REMOTE_PRIVATE_IP>
```

For jumbo-frame environments, validate the MTU
across the complete network path.

Example for an IPv4 MTU of 9000:

```bash
ping -M do -s 8972 -c 4 <REMOTE_PRIVATE_IP>
```

A successful ping alone does not prove that all
RAC interconnect communication is healthy.

Use Oracle-supported diagnostics and network
monitoring for deeper investigation.

## 10. Identify SQL Statements Associated with RAC Waits

When Diagnostics Pack licensing permits access
to historical SQL and ASH data, investigate SQL
statements associated with Global Cache waits.

Example:

```sql
SELECT
    instance_number,
    sql_id,
    event,
    COUNT(*) AS sample_count
FROM
    dba_hist_active_sess_history
WHERE
    snap_id BETWEEN :begin_snap AND :end_snap
    AND event LIKE 'gc%'
    AND sql_id IS NOT NULL
GROUP BY
    instance_number,
    sql_id,
    event
ORDER BY
    sample_count DESC;
```

This query identifies sampled active sessions
associated with Global Cache waits.

Important:

- ASH is sampled data, not a complete record of every wait.
- Sample counts are not exact wait counts.
- A SQL statement appearing frequently does not
  automatically establish root cause.
- Correlate SQL activity with AWR statistics and
  execution plans.

## 11. Investigate Hot Objects and Block Contention

High Global Cache activity may be associated with
frequently accessed or modified database blocks.

Possible causes include:

- Hot index leaf blocks.
- Frequently updated rows.
- Right-growing indexes.
- Concurrent updates to the same data.
- Application-level contention.
- Inefficient workload distribution.

### 11.1 Inspect current object-related ASH samples

When the appropriate licensing is available:

```sql
SELECT
    instance_number,
    sql_id,
    current_obj#,
    event,
    COUNT(*) AS sample_count
FROM
    dba_hist_active_sess_history
WHERE
    snap_id BETWEEN :begin_snap AND :end_snap
    AND event LIKE 'gc%'
    AND current_obj# IS NOT NULL
GROUP BY
    instance_number,
    sql_id,
    current_obj#,
    event
ORDER BY
    sample_count DESC;
```

The CURRENT_OBJ# value can be investigated
against the relevant database object metadata.

Example:

```sql
SELECT
    owner,
    object_name,
    subobject_name,
    object_type
FROM
    dba_objects
WHERE
    object_id = :object_id;
```

Important:

- Object identifiers may not always resolve to
  the expected object.
- Consider container and partition information.
- Review the actual SQL and block access pattern.
- Validate the findings before proposing index changes.

## 12. RAC Instance Workload Distribution

Uneven workload distribution may contribute
to inter-instance block transfers.

Review:

- Service placement.
- Application connection pools.
- Preferred and available instances.
- Session distribution.
- SQL execution distribution.

Current session distribution:

```sql
SELECT
    inst_id,
    COUNT(*) AS session_count
FROM
    gv$session
WHERE
    type = 'USER'
GROUP BY
    inst_id
ORDER BY
    inst_id;
```

Review service distribution:

```sql
SELECT
    inst_id,
    service_name,
    COUNT(*) AS session_count
FROM
    gv$session
WHERE
    type = 'USER'
GROUP BY
    inst_id,
    service_name
ORDER BY
    inst_id,
    service_name;
```

Uneven session distribution is not necessarily
a problem. Consider workload intensity and
application architecture.

## 13. Common RAC Wait Event Troubleshooting Scenarios

### Scenario 1: High gc current request Waits

Possible investigation areas:

- Frequent current block transfers.
- Concurrent modifications.
- Cross-instance access.
- Hot blocks.
- Application workload distribution.

Troubleshooting:

1. Identify the affected SQL statements.
2. Review ASH samples.
3. Investigate frequently accessed objects.
4. Check instance workload distribution.
5. Review block transfer patterns.
6. Validate interconnect health.

### Scenario 2: High gc cr request Waits

Possible investigation areas:

- Consistent read block requests.
- Remote instance block access.
- High read workload.
- Cache Fusion transfer latency.

Troubleshooting:

1. Identify affected SQL statements.
2. Review consistent read activity.
3. Check Global Cache statistics.
4. Compare instance-level workload.
5. Validate network health.

### Scenario 3: High gc buffer busy Waits

Possible investigation areas:

- Buffer contention.
- Concurrent access to database blocks.
- Hot index or table blocks.
- Application transaction patterns.

Troubleshooting:

1. Identify affected SQL statements.
2. Review ASH object and block information.
3. Check concurrent DML activity.
4. Investigate hot objects.
5. Review application transaction design.

### Scenario 4: High RAC Interconnect Latency

Possible investigation areas:

- Packet drops.
- Network congestion.
- MTU mismatch.
- Interface errors.
- Incorrect routing.
- Infrastructure-level network issues.

Troubleshooting:

1. Review RAC wait-event statistics.
2. Check network interface counters.
3. Validate MTU consistency.
4. Review network switch and infrastructure metrics.
5. Correlate network latency with database waits.

Do not conclude that the interconnect is the root
cause solely because Global Cache waits are high.

## 14. Before-and-After RAC Wait Comparison

When comparing performance before and after
an infrastructure or configuration change,
review the following metrics:

| Metric | Before | After |
|---|---|---|
| DB Time | Record | Record |
| DB CPU | Record | Record |
| Global Cache wait time | Record | Record |
| gc current request | Record | Record |
| gc cr request | Record | Record |
| Average wait time | Record | Record |
| Interconnect latency | Record | Record |
| Network packet drops | Record | Record |
| SQL execution time | Record | Record |
| Instance workload | Record | Record |

Compare equivalent workloads and time periods.

Normalize metrics where execution volumes differ.

## 15. Final RAC Wait Event Checklist

| Check | Expected Result |
|---|---|
| DB Time | Reviewed |
| DB CPU | Reviewed |
| Foreground waits | Reviewed |
| Global Cache waits | Reviewed |
| Interconnect latency | Validated |
| Network interface errors | Investigated |
| MTU | Consistent |
| SQL statements | Identified |
| Hot objects | Investigated |
| Instance distribution | Reviewed |
| AWR comparison | Completed |

## 16. Best Practices

- Analyze wait time rather than event count alone.
- Review every RAC instance.
- Correlate Global Cache waits with SQL activity.
- Investigate hot blocks before changing indexes.
- Validate the private interconnect independently.
- Compare equivalent workload periods.
- Normalize wait metrics where necessary.
- Avoid tuning based on one wait event.
- Preserve AWR and diagnostic evidence.
- Verify Oracle Diagnostics Pack licensing.

## 17. References

Oracle Database Performance Tuning Guide:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Real Application Clusters Administration
and Deployment Guide:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database Reference:

https://docs.oracle.com/en/database/oracle/oracle-database/

Refer to the documentation for the installed
Oracle Database release.
