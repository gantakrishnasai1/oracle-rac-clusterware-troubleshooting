
# Oracle RAC AWR Report Analysis and Performance Troubleshooting

## 1. Overview

Automatic Workload Repository (AWR) collects database
performance statistics over time.

AWR reports help Oracle DBAs investigate:

- Database workload.
- DB Time and DB CPU.
- Host CPU utilization.
- Foreground wait events.
- SQL performance.
- I/O performance.
- RAC global cache activity.
- Instance-level workload distribution.
- Performance changes after infrastructure modifications.

In Oracle RAC, performance analysis must consider both
database-wide and individual-instance statistics.

This guide describes a structured approach to analyzing
AWR reports in Oracle RAC environments.

## 2. Scope

This document covers:

- AWR report generation.
- Snapshot selection.
- RAC instance comparison.
- DB Time and DB CPU.
- Host CPU utilization.
- Top wait events.
- Global Cache and interconnect analysis.
- SQL statistics.
- Execution plan investigation.
- Before-and-after performance comparison.

## 3. Important Licensing Consideration

AWR, ADDM and related Diagnostics Pack functionality
are subject to Oracle licensing requirements.

Before generating or accessing AWR reports, verify that
the appropriate Oracle Diagnostics Pack entitlement
exists for the environment.

Do not assume that access to an AWR report automatically
means that the environment is licensed to use it.

Refer to the Oracle licensing documentation and
the applicable contract.

## 4. Prerequisites

Before analyzing an AWR report, collect:

| Parameter | Description |
|---|---|
| Database name | Database under investigation |
| Database version | Oracle release and RU |
| Database architecture | RAC or standalone |
| Number of instances | RAC instance count |
| Snapshot start | Beginning snapshot |
| Snapshot end | Ending snapshot |
| Analysis period | Workload duration |
| Infrastructure changes | Any changes during the period |
| Application activity | Batch, online or maintenance workload |

Record any recent changes such as:

- CPU scaling.
- Storage scaling.
- Database patching.
- SQL deployments.
- Application releases.
- Parameter modifications.
- Network changes.
- Backup or maintenance activities.

These changes may influence AWR statistics.

## 5. Generate AWR Reports

### 5.1 Generate an AWR report using SQL*Plus

Connect as a user with the required privileges.

Run:

```sql
@$ORACLE_HOME/rdbms/admin/awrrpt.sql
```

Select:

1. Report format.
2. Snapshot start ID.
3. Snapshot end ID.
4. Report output filename.

### 5.2 Generate a RAC AWR report

For RAC-wide analysis, use the RAC AWR report script:

```sql
@$ORACLE_HOME/rdbms/admin/awrgrpt.sql
```

This produces a global report covering the RAC database.

For individual instance analysis:

```sql
@$ORACLE_HOME/rdbms/admin/awrrpt.sql
```

Generate reports for each relevant instance.

Use the scripts supplied with the installed Oracle
Database release.

### 5.3 Identify available snapshots

When Diagnostics Pack usage is licensed, inspect snapshots:

```sql
SELECT
    snap_id,
    instance_number,
    begin_interval_time,
    end_interval_time
FROM
    dba_hist_snapshot
ORDER BY
    snap_id,
    instance_number;
```

For RAC, compare the snapshots across all instances
and ensure that the selected periods are aligned.

## 6. AWR Report Analysis Methodology

Use the following sequence when investigating
database performance.

1. Confirm report period and workload.
2. Review database instance information.
3. Analyze DB Time and DB CPU.
4. Review host CPU utilization.
5. Identify top foreground wait events.
6. Investigate RAC global cache activity.
7. Review I/O performance.
8. Identify SQL statements contributing to DB Time.
9. Compare execution plans.
10. Compare results against the baseline period.

Avoid drawing conclusions from a single metric.

## 7. Database Workload Analysis

### 7.1 DB Time

DB Time represents the total time spent by foreground
sessions executing database calls, including CPU time
and non-idle wait time.

DB Time is cumulative across foreground sessions.

It is not the same as elapsed wall-clock time.

### 7.2 DB CPU

DB CPU represents the CPU time consumed by database
foreground processes.

Compare DB CPU with DB Time to understand the
relative contribution of CPU and waits.

A higher DB CPU contribution may indicate a
CPU-intensive workload.

A high DB Time with relatively low DB CPU may
indicate that sessions spend more time waiting.

### 7.3 AWR workload statistics

Review:

- DB Time.
- DB CPU.
- Executions.
- User calls.
- Logical reads.
- Physical reads.
- Physical writes.
- Transactions.
- Parses.
- Redo generated.

Consider workload volume when comparing two periods.

For example, a higher DB Time may simply result from
a higher number of transactions.

## 8. RAC Instance Comparison

In Oracle RAC, analyze every instance.

Review the instance information and workload
distribution in the RAC AWR report.

Check:

- DB Time per instance.
- DB CPU per instance.
- Logical reads per instance.
- Physical reads per instance.
- SQL execution distribution.
- Top wait events per instance.
- Global Cache activity.

### 8.1 Instance-level DB Time

Example SQL:

```sql
WITH metric_delta AS (
    SELECT
        dbid,
        instance_number,
        startup_time,
        snap_id,
        stat_name,
        value,
        LAG(value) OVER (
            PARTITION BY
                dbid,
                instance_number,
                startup_time,
                stat_name
            ORDER BY snap_id
        ) AS previous_value
    FROM dba_hist_sys_time_model
    WHERE stat_name IN (
        'DB time',
        'DB CPU'
    )
)
SELECT
    instance_number,
    stat_name,
    SUM(value - previous_value) AS total_delta
FROM metric_delta
WHERE previous_value IS NOT NULL
  AND value >= previous_value
GROUP BY
    instance_number,
    stat_name
ORDER BY
    instance_number,
    stat_name;
```

This query aggregates the sampled time-model values
for the selected snapshots.

### 8.2 Instance-level DB CPU

```sql
SELECT
    instance_number,
    SUM(value) / 1000000 AS db_cpu_seconds
FROM
    dba_hist_sys_time_model
WHERE
    snap_id BETWEEN :begin_snap AND :end_snap
    AND stat_name = 'DB CPU'
GROUP BY
    instance_number
ORDER BY
    instance_number;
```

Compare the results across instances.

Note:

- These are cumulative statistics.
- Use matching snapshot intervals.
- Check for instance restarts or counter resets.
- Do not interpret an uneven workload distribution
  as a problem without considering service placement,
  connection pools and application routing.

## 9. Host CPU Analysis

Review the Operating System Statistics section
of the AWR report.

Important metrics include:

- CPU count.
- CPU utilization.
- Idle CPU.
- Load average.
- Run queue.
- Host CPU usage.

Investigate whether CPU pressure is occurring
at the operating system level.

A database showing high DB CPU does not necessarily
mean that the host is CPU saturated.

Compare database CPU consumption with actual
host CPU availability.

## 10. Top Foreground Wait Events

Review the Top Foreground Events section.

Common event categories include:

| Wait event | Investigation area |
|---|---|
| db file sequential read | Single-block I/O |
| db file scattered read | Multiblock reads |
| log file sync | Commit latency |
| log file parallel write | Redo write performance |
| direct path read | Direct path I/O |
| enq: TX - row lock contention | Transaction locking |
| gc current request | RAC global cache |
| gc cr request | RAC consistent read |
| gc buffer busy acquire | Global cache buffer contention |
| gc buffer busy release | Global cache buffer contention |

A wait event should be investigated using:

- Total wait time.
- Number of waits.
- Average wait time.
- Number of affected sessions.
- SQL statements associated with the wait.
- Time distribution during the report period.

Do not tune an event simply because it appears
at the top of the wait-event list.

## 11. RAC Global Cache Analysis

RAC global cache waits represent coordination
between instances for database block access.

Review:

- Global Cache Service statistics.
- Global Cache transfer activity.
- Interconnect traffic.
- Cache fusion waits.
- Block transfer latency.
- Frequent block access across instances.

Common events include:

- gc current request.
- gc cr request.
- gc buffer busy acquire.
- gc buffer busy release.

Possible investigation areas:

- Application workload distribution.
- Hot blocks.
- Concurrent updates.
- Service placement.
- Interconnect performance.
- Block access patterns.

A global cache wait is not automatically evidence
of an interconnect problem.

First determine whether the delay is caused by
network transfer, remote instance processing,
block contention or another component.

## 12. I/O Performance Analysis

Review the AWR I/O statistics.

Important areas:

- Physical read requests.
- Physical write requests.
- Read latency.
- Write latency.
- I/O throughput.
- Tablespace and datafile activity.
- Direct path I/O.

Common events:

- db file sequential read.
- db file scattered read.
- direct path read.
- direct path write.
- log file parallel write.

Compare database I/O statistics with the
underlying storage metrics.

Do not conclude that storage is slow based only
on a high physical read count.

Workload volume, read size and access pattern
must also be considered.

## 13. SQL Performance Analysis

Identify SQL statements contributing to:

- DB Time.
- DB CPU.
- Buffer Gets.
- Physical Reads.
- Executions.
- Elapsed Time.

Review the SQL ordered by elapsed time and
CPU time in the AWR report.

When investigating SQL:

1. Identify the SQL ID.
2. Check execution frequency.
3. Review average elapsed time.
4. Check buffer gets per execution.
5. Review physical reads.
6. Compare execution plans.
7. Investigate bind variables.
8. Validate the proposed change.

### 13.1 SQL statistics from AWR

When licensed and available:

```sql
SELECT
    sql_id,
    plan_hash_value,
    SUM(executions_delta) AS executions,
    ROUND(
        SUM(elapsed_time_delta) / 1000000,
        2
    ) AS elapsed_seconds,
    ROUND(
        SUM(cpu_time_delta) / 1000000,
        2
    ) AS cpu_seconds,
    SUM(buffer_gets_delta) AS buffer_gets,
    SUM(disk_reads_delta) AS disk_reads
FROM
    dba_hist_sqlstat
WHERE
    snap_id BETWEEN :begin_snap AND :end_snap
GROUP BY
    sql_id,
    plan_hash_value
ORDER BY
    elapsed_seconds DESC;
```

Important:

- SQL statistics are generally recorded as deltas
  between snapshots.
- Multiple plan hash values may exist for one SQL ID.
- Some SQL statements may not be captured.
- A SQL statement may execute across multiple instances.
- Avoid summing overlapping or duplicated snapshot
  intervals.
- Consider instance_number and database-level
  scope when investigating RAC.

## 14. Execution Plan Investigation

### 14.1 Retrieve historical execution plan

Use DBMS_XPLAN to display an available historical plan:

```sql
SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_AWR(
        '<SQL_ID>',
        NULL,
        NULL,
        'ALL'
    )
);
```

Replace <SQL_ID> with the actual SQL ID.

The plan must be available in the AWR repository.

### 14.2 Retrieve current execution plan

```sql
SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        '<SQL_ID>',
        NULL,
        'ALL'
    )
);
```

For actual row-source statistics, use a cursor
whose execution statistics were collected.

For example, the statement can be executed with
the GATHER_PLAN_STATISTICS hint:

```sql
SELECT /*+ GATHER_PLAN_STATISTICS */
       *
FROM   your_table
WHERE  your_column = :value;
```

Then retrieve the plan:

```sql
SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        NULL,
        NULL,
        'ALLSTATS LAST'
    )
);
```

Review:

- Estimated rows.
- Actual rows.
- Access paths.
- Join methods.
- Join order.
- Predicate information.
- Buffer usage.
- Plan hash value.

Do not assume that a different plan hash value
automatically indicates a performance regression.

## 15. Before-and-After AWR Comparison

Before comparing two AWR reports, ensure:

- Comparable workload.
- Similar business activity.
- Equivalent report duration.
- Similar execution volume.
- Consistent instance count.
- No unrelated maintenance activity.
- No major application changes.

Recommended comparison metrics:

| Metric | Before | After | Interpretation |
|---|---|---|---|
| DB Time | Record | Record | Workload time |
| DB CPU | Record | Record | CPU consumption |
| Executions | Record | Record | Workload volume |
| Buffer Gets | Record | Record | Logical I/O |
| Physical Reads | Record | Record | Physical I/O |
| Average SQL elapsed | Record | Record | SQL response |
| Top Wait Events | Record | Record | Bottlenecks |
| RAC GC waits | Record | Record | Cache fusion |
| Host CPU | Record | Record | Host utilization |
| I/O latency | Record | Record | Storage behavior |

### 15.1 Calculate percentage change

Use:

Percentage Change =
((After - Before) / Before) * 100

Example:

Before DB Time = 1,000 seconds

After DB Time = 800 seconds

Percentage change = -20%

This indicates a 20% reduction in DB Time,
provided the two periods are comparable.

If the baseline value is zero, percentage
change is undefined.

### 15.2 Normalize workload metrics

When execution volumes differ, compare:

- DB Time per execution.
- CPU time per execution.
- Buffer Gets per execution.
- Physical Reads per execution.
- Average response time.

Normalized metrics can provide better insight
than raw totals.

## 16. Common AWR Investigation Scenarios

### Scenario 1: High DB CPU

Possible causes:

- CPU-intensive SQL.
- Excessive logical reads.
- Inefficient execution plans.
- High execution frequency.
- Application workload increase.

Investigation:

1. Review DB CPU.
2. Identify top SQL by CPU.
3. Review buffer gets per execution.
4. Compare execution plans.
5. Check host CPU utilization.
6. Review workload changes.

### Scenario 2: High DB Time but Low DB CPU

Possible causes:

- I/O waits.
- Concurrency waits.
- Application transaction contention.
- RAC global cache waits.
- Commit latency.

Investigation:

1. Review top foreground events.
2. Identify the affected SQL.
3. Check wait time distribution.
4. Compare I/O statistics.
5. Investigate RAC-related waits.

### Scenario 3: High RAC Global Cache Waits

Possible causes:

- Hot blocks.
- Cross-instance block access.
- Application workload distribution.
- Interconnect latency.
- Contention.

Investigation:

1. Review global cache statistics.
2. Identify affected instances.
3. Investigate hot objects and SQL.
4. Review interconnect performance.
5. Validate service placement.

### Scenario 4: Performance Degradation After Infrastructure Change

Possible causes:

- CPU scaling.
- Storage scaling.
- Changed I/O characteristics.
- Workload changes.
- Execution plan changes.
- Resource allocation changes.

Investigation:

1. Compare before-and-after AWR reports.
2. Verify equivalent workload periods.
3. Compare host CPU statistics.
4. Review I/O latency.
5. Compare RAC wait events.
6. Review SQL execution plans.
7. Check infrastructure monitoring data.

Do not attribute a performance change to an
infrastructure modification without supporting evidence.

## 17. Final AWR Analysis Checklist

| Check | Expected Result |
|---|---|
| Snapshot period | Correct |
| Workload comparability | Verified |
| DB Time | Reviewed |
| DB CPU | Reviewed |
| Host CPU | Reviewed |
| Top foreground events | Reviewed |
| RAC GC waits | Reviewed |
| I/O performance | Reviewed |
| SQL statistics | Reviewed |
| Execution plans | Compared |
| Instance distribution | Reviewed |
| Before/after comparison | Completed |
| Recommendations | Evidence-based |

## 18. Best Practices

- Always understand the workload before interpreting AWR.
- Compare equivalent business periods.
- Analyze each RAC instance.
- Review DB Time alongside DB CPU.
- Investigate wait events using SQL and session context.
- Check global cache activity in RAC environments.
- Normalize SQL metrics by execution volume.
- Validate execution plans before recommending changes.
- Preserve baseline reports.
- Avoid making changes based on one metric.
- Verify Oracle Diagnostics Pack licensing.

## 19. References

Oracle Database Performance Tuning Guide:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database PL/SQL Packages and Types Reference:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database Licensing Information:

https://docs.oracle.com/en/database/oracle/oracle-database/

Refer to the documentation for the installed
Oracle Database release.
