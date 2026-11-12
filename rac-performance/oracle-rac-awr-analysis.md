# Oracle RAC AWR Performance Analysis

## 1. Review objectives

Use AWR to identify workload characteristics and prioritize investigation. Establish whether the report interval represents normal, peak, or abnormal workload.

Review:
- Load Profile.
- Time Model Statistics.
- Foreground Wait Events.
- SQL ordered by elapsed time, CPU, buffer gets, and reads.
- Instance Activity and RAC-related sections.
- Operating-system statistics.

## 2. DB time and CPU

A high DB CPU share means foreground database time is predominantly CPU time. It does not prove host CPU saturation. Compare with OS CPU utilization, CPU count, load/run queue, and application response times.

## 3. I/O and wait events

Evaluate total wait time, wait count, average latency, and outliers. Correlate database waits with storage telemetry and application response time. Do not diagnose storage from one average alone.

## 4. RAC workload distribution

Compare instance DB time, DB CPU, active sessions, services, and connection pools. Uneven activity may be intentional due to service placement or workload routing. Confirm expected service configuration before making changes.

## 5. SQL tuning candidates

Prioritize SQL using overall impact, including elapsed time, CPU, buffer gets, physical reads, executions, and rows processed. For each candidate:
1. Retrieve historical execution plans.
2. Review predicates, access paths, join order, and join methods.
3. Compare estimated and actual cardinality where available.
4. Review existing indexes and data distribution.
5. Compare plan hash values across the interval.
6. Validate changes in non-production.

High logical reads do not automatically mean an index is required.

## 6. Historical plan template

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

## 7. Current cursor statistics template

```sql
SELECT inst_id,
       sql_id,
       plan_hash_value,
       executions,
       ROUND(elapsed_time / 1000000, 2) AS elapsed_sec,
       ROUND(cpu_time / 1000000, 2) AS cpu_sec,
       buffer_gets,
       disk_reads,
       rows_processed
FROM gv$sql
WHERE sql_id = '<SQL_ID>'
ORDER BY inst_id, plan_hash_value;
```

`GV$SQL` represents current shared-pool cursor statistics and may not match the historical AWR interval.

## 8. AWR review checklist

- [ ] Confirm DB version, instance count, and snapshot interval.
- [ ] Confirm workload representativeness.
- [ ] Review DB time and DB CPU.
- [ ] Review top foreground wait events.
- [ ] Compare OS CPU and database CPU.
- [ ] Review instance workload and service placement.
- [ ] Identify high-impact SQL.
- [ ] Retrieve and compare historical plans.
- [ ] Correlate I/O waits with storage telemetry.
- [ ] Document evidence, hypothesis, validation, and action.

## 9. Licensing and privacy

AWR/ADDM access and use may have Oracle licensing and privilege implications. Confirm entitlements. Never publish raw AWR reports, SQL text, SQL IDs, object names, hostnames, addresses, or customer metrics without authorization.
