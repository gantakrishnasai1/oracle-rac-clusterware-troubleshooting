
# Oracle Database SQL Performance Investigation and Troubleshooting

## 1. Overview

SQL performance investigation is an important responsibility
of an Oracle Database Administrator.

Poorly performing SQL statements can affect:

- Application response time.
- Database CPU utilization.
- Logical and physical I/O.
- Database throughput.
- Concurrent sessions.
- RAC inter-instance communication.
- Overall database availability.

This guide describes a systematic approach to investigating
SQL performance issues in Oracle Database environments.

## 2. Scope

This document covers:

- Identifying expensive SQL statements.
- SQL execution statistics.
- SQL execution plan analysis.
- Index and table access investigation.
- Bind variable issues.
- Hard parsing and soft parsing.
- SQL plan regression.
- RAC SQL performance investigation.
- Historical SQL analysis.
- Post-tuning validation.

## 3. Prerequisites

Before starting an investigation, collect:

| Parameter | Description |
|---|---|
| Database version | Oracle release and RU |
| Database name | Database under investigation |
| SQL ID | SQL statement identifier |
| Schema | Application schema |
| Execution period | Time when issue occurred |
| Execution frequency | Number of executions |
| Application impact | Response time or timeout |
| Recent changes | SQL, application or database changes |

Understand whether the issue affects:

- One SQL statement.
- Multiple SQL statements.
- One application module.
- One database instance.
- All RAC instances.
- A specific time period.

## 4. Identify Expensive SQL Statements

### 4.1 Top SQL by elapsed time

```sql
SELECT
    sql_id,
    plan_hash_value,
    executions,
    ROUND(elapsed_time / 1000000, 2)
        AS elapsed_seconds,
    ROUND(
        elapsed_time / NULLIF(executions, 0) / 1000000,
        4
    ) AS avg_elapsed_seconds,
    ROUND(cpu_time / 1000000, 2)
        AS cpu_seconds,
    buffer_gets,
    disk_reads
FROM
    v$sql
WHERE
    executions > 0
ORDER BY
    elapsed_time DESC
FETCH FIRST 20 ROWS ONLY;
```

This query identifies SQL statements with high
cumulative elapsed time in the shared SQL area.

Important:

- V$SQL statistics are cumulative since cursor load.
- Multiple child cursors may exist.
- Statistics can reset after cursor aging or instance restart.
- Consider executions when evaluating total elapsed time.

### 4.2 Top SQL by CPU time

```sql
SELECT
    sql_id,
    plan_hash_value,
    executions,
    ROUND(cpu_time / 1000000, 2)
        AS cpu_seconds,
    ROUND(
        cpu_time / NULLIF(executions, 0) / 1000000,
        4
    ) AS avg_cpu_seconds,
    buffer_gets
FROM
    v$sql
WHERE
    executions > 0
ORDER BY
    cpu_time DESC
FETCH FIRST 20 ROWS ONLY;
```

High CPU consumption may indicate:

- Expensive SQL execution.
- High logical reads.
- Inefficient joins.
- Excessive execution frequency.
- CPU-intensive application processing.

### 4.3 Top SQL by buffer gets

```sql
SELECT
    sql_id,
    plan_hash_value,
    executions,
    buffer_gets,
    ROUND(
        buffer_gets / NULLIF(executions, 0)
    ) AS buffer_gets_per_exec,
    ROUND(elapsed_time / 1000000, 2)
        AS elapsed_seconds
FROM
    v$sql
WHERE
    executions > 0
ORDER BY
    buffer_gets DESC
FETCH FIRST 20 ROWS ONLY;
```

High buffer gets may indicate excessive logical I/O.

Investigate execution plans and the number of rows
processed by the SQL statement.

## 5. Retrieve SQL Text

Use SQL ID to retrieve the SQL text:

```sql
SELECT
    sql_id,
    sql_text
FROM
    v$sql
WHERE
    sql_id = '<SQL_ID>';
```

For statements with multiple child cursors,
review the available cursor information.

SQL text can contain sensitive information,
including literals and application data.

Sanitize SQL text before sharing it publicly.

## 6. SQL Execution Statistics

Review:

- Executions.
- Elapsed time.
- CPU time.
- Buffer gets.
- Disk reads.
- Rows processed.
- Parse calls.
- Fetches.
- Child cursor count.

A statement with a high total elapsed time
may simply execute frequently.

Compare both cumulative and per-execution metrics.

Example:

```sql
SELECT
    sql_id,
    plan_hash_value,
    executions,
    ROUND(
        elapsed_time / NULLIF(executions, 0) / 1000000,
        4
    ) AS avg_elapsed_seconds,
    ROUND(
        cpu_time / NULLIF(executions, 0) / 1000000,
        4
    ) AS avg_cpu_seconds,
    ROUND(
        buffer_gets / NULLIF(executions, 0)
    ) AS avg_buffer_gets
FROM
    v$sql
WHERE
    sql_id = '<SQL_ID>'
    AND executions > 0;
```

## 7. SQL Execution Plan Analysis

Execution plans describe how Oracle executes SQL.

Review:

- Access paths.
- Join methods.
- Join order.
- Estimated rows.
- Actual rows.
- Predicate information.
- Partition pruning.
- Index usage.
- Cost estimates.

### 7.1 Current execution plan

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

### 7.2 Actual execution statistics

To collect actual row-source statistics,
execute the statement with the GATHER_PLAN_STATISTICS hint:

```sql
SELECT /*+ GATHER_PLAN_STATISTICS */
       *
FROM your_table
WHERE your_column = :value;
```

Retrieve the execution plan:

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

- E-Rows: Estimated rows.
- A-Rows: Actual rows.
- Starts: Number of operation starts.
- Buffers: Logical buffer usage.
- Reads: Physical read activity.
- A-Time: Actual execution time.

Actual statistics may not be available for every cursor.

### 7.3 Historical execution plan

If the execution plan is available in AWR:

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

Historical AWR access is subject to the
applicable Oracle Diagnostics Pack licensing.

## 8. Index and Table Access Investigation

Review whether SQL statements use appropriate
access paths.

Common access paths include:

- TABLE ACCESS FULL.
- INDEX RANGE SCAN.
- INDEX UNIQUE SCAN.
- INDEX SKIP SCAN.
- TABLE ACCESS BY INDEX ROWID.
- PARTITION RANGE operations.

A full table scan is not automatically a problem.

It can be appropriate for queries that access
a large percentage of table rows.

### 8.1 Review indexes

```sql
SELECT
    owner,
    index_name,
    table_name,
    index_type,
    uniqueness,
    status,
    visibility
FROM
    dba_indexes
WHERE
    owner = UPPER('<SCHEMA_NAME>')
ORDER BY
    table_name,
    index_name;
```

### 8.2 Review index columns

```sql
SELECT
    index_owner,
    index_name,
    table_name,
    column_name,
    column_position
FROM
    dba_ind_columns
WHERE
    table_owner = UPPER('<SCHEMA_NAME>')
ORDER BY
    table_name,
    index_name,
    column_position;
```

### 8.3 Review table statistics

```sql
SELECT
    owner,
    table_name,
    num_rows,
    blocks,
    last_analyzed,
    stale_stats
FROM
    dba_tab_statistics
WHERE
    owner = UPPER('<SCHEMA_NAME>')
ORDER BY
    table_name;
```

Investigate:

- Stale statistics.
- Incorrect cardinality estimates.
- Missing or unsuitable indexes.
- Data skew.
- Partition pruning.
- Table growth.

Do not create an index solely because a SQL
statement performs a full table scan.

Evaluate DML overhead, storage and other
workload requirements before recommending
index creation.

## 9. Bind Variable and Parsing Investigation

Bind variables help reduce unnecessary hard parsing
and improve cursor sharing.

Review parsing activity in the AWR report
and investigate SQL statements with excessive
parse activity.

Current SQL cursor information:

```sql
SELECT
    sql_id,
    child_number,
    executions,
    parse_calls,
    loads,
    invalidations,
    version_count
FROM
    v$sqlarea
WHERE
    sql_id = '<SQL_ID>';
```

Investigate:

- Literal SQL versus bind variables.
- Excessive hard parsing.
- Child cursor proliferation.
- Bind variable peeking.
- Adaptive cursor sharing.
- Incompatible optimizer environments.

Do not force bind variables into every statement
without understanding the application's requirements.

Bind peeking and adaptive cursor sharing
can influence execution plan selection.

## 10. SQL Plan Regression Investigation

A SQL statement may experience performance
degradation after:

- Database patching.
- Statistics gathering.
- Application deployment.
- Index modifications.
- Parameter changes.
- Data volume changes.

Compare:

- SQL ID.
- Plan hash value.
- Execution count.
- Average elapsed time.
- CPU time.
- Buffer gets.
- Physical reads.

Historical SQL plan information can be investigated
using DBA_HIST_SQLSTAT and DBA_HIST_SQL_PLAN,
subject to the relevant licensing requirements.

Example:

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
    sql_id = '<SQL_ID>'
    AND snap_id BETWEEN :begin_snap AND :end_snap
GROUP BY
    sql_id,
    plan_hash_value
ORDER BY
    elapsed_seconds DESC;
```

A different plan hash value does not automatically
mean that a regression occurred.

Validate performance using equivalent workload
and execution statistics.

## 11. RAC-Specific SQL Investigation

In RAC environments, SQL performance can differ
between instances.

Review:

- SQL execution distribution.
- Instance-level CPU usage.
- Global Cache waits.
- Block contention.
- Service placement.
- Execution plan consistency.

### 11.1 Current SQL execution by instance

```sql
SELECT
    inst_id,
    sql_id,
    plan_hash_value,
    SUM(executions) AS executions,
    ROUND(
        SUM(elapsed_time) / 1000000,
        2
    ) AS elapsed_seconds,
    SUM(buffer_gets) AS buffer_gets
FROM
    gv$sql
WHERE
    sql_id = '<SQL_ID>'
GROUP BY
    inst_id,
    sql_id,
    plan_hash_value
ORDER BY
    inst_id;
```

### 11.2 Check SQL child cursors

```sql
SELECT
    inst_id,
    sql_id,
    child_number,
    plan_hash_value,
    executions,
    loads,
    invalidations
FROM
    gv$sql
WHERE
    sql_id = '<SQL_ID>'
ORDER BY
    inst_id,
    child_number;
```

Investigate whether different instances use
different execution plans.

Do not assume different plans are necessarily
incorrect. Different data distributions,
bind values or optimizer environments may
justify different plans.

## 12. SQL Monitoring

For long-running SQL statements, SQL Monitor
can provide execution-level monitoring information.

Where the required licensing and privileges
are available, review:

```sql
SELECT
    inst_id,
    sql_id,
    status,
    sql_exec_id,
    sql_exec_start,
    elapsed_time,
    cpu_time,
    buffer_gets,
    disk_reads
FROM
    gv$sql_monitor
WHERE
    sql_id = '<SQL_ID>'
ORDER BY
    sql_exec_start DESC;
```

SQL Monitor and related Tuning Pack functionality
are subject to Oracle licensing requirements.

Verify entitlement before using these features.

## 13. Common SQL Performance Problems

### Scenario 1: High CPU Consumption

Possible causes:

- Inefficient execution plan.
- Excessive logical reads.
- Expensive joins.
- High SQL execution frequency.
- Application workload increase.

Investigation:

1. Identify SQL by CPU time.
2. Review execution statistics.
3. Check buffer gets per execution.
4. Compare execution plans.
5. Investigate workload changes.

### Scenario 2: High Physical Reads

Possible causes:

- Large table scans.
- Inefficient access paths.
- High data volume.
- Poor partition pruning.
- Buffer cache pressure.

Investigation:

1. Identify SQL with high disk reads.
2. Review the execution plan.
3. Check table and index statistics.
4. Investigate storage latency.
5. Evaluate whether the access path is appropriate.

### Scenario 3: SQL Performance Regression

Possible causes:

- Plan changes.
- Statistics changes.
- Data growth.
- Bind variable behavior.
- Application changes.

Investigation:

1. Compare historical execution plans.
2. Review plan hash values.
3. Compare average execution time.
4. Compare buffer gets and physical reads.
5. Investigate the change that introduced the regression.

### Scenario 4: SQL Performance Difference Between RAC Instances

Possible causes:

- Different execution plans.
- Different workload.
- Instance-level resource contention.
- Service placement.
- Global Cache activity.

Investigation:

1. Compare SQL statistics across instances.
2. Check plan hash values.
3. Review instance-level wait events.
4. Check service distribution.
5. Investigate application workload.

## 14. Post-Tuning Validation

After implementing a SQL tuning change,
compare the performance before and after.

Validate:

- Average elapsed time.
- CPU time.
- Buffer gets.
- Physical reads.
- Execution count.
- Execution plan.
- Application response time.
- RAC Global Cache activity, where relevant.

Also verify that the change has not negatively
affected other SQL statements or DML operations.

Preserve the baseline statistics and document
the approved change.

## 15. SQL Performance Investigation Checklist

| Check | Expected Result |
|---|---|
| SQL ID | Identified |
| SQL text | Reviewed and sanitized |
| Execution frequency | Reviewed |
| Elapsed time | Reviewed |
| CPU time | Reviewed |
| Buffer gets | Reviewed |
| Physical reads | Reviewed |
| Execution plan | Reviewed |
| Actual row statistics | Collected where appropriate |
| Index usage | Evaluated |
| Table statistics | Reviewed |
| Bind variables | Investigated |
| RAC instance comparison | Completed where applicable |
| Before/after validation | Completed |

## 16. Best Practices

- Identify the SQL statement before making changes.
- Review per-execution and cumulative statistics.
- Examine actual execution plans when available.
- Do not create indexes without workload analysis.
- Investigate bind variable behavior.
- Compare historical and current plans.
- Evaluate SQL performance across all RAC instances.
- Validate tuning changes with representative workloads.
- Preserve rollback options.
- Follow Oracle licensing requirements for AWR,
  SQL Monitor and tuning-related features.

## 17. References

Oracle Database SQL Tuning Guide:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database PL/SQL Packages and Types Reference:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Database Performance Tuning Guide:

https://docs.oracle.com/en/database/oracle/oracle-database/

Refer to the documentation for the installed
Oracle Database release.
