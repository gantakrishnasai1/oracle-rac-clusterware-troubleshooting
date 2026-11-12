# Oracle SQL Performance Investigation

## 1. Select candidates

Use AWR SQL statistics to identify statements with material elapsed time, CPU, buffer gets, physical reads, or execution frequency. Consider total workload contribution and per-execution behavior.

## 2. Retrieve plans

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

If available in the shared pool:

```sql
SELECT *
FROM TABLE(
  DBMS_XPLAN.DISPLAY_CURSOR(
    '<SQL_ID>',
    NULL,
    'ALLSTATS LAST +PEEKED_BINDS'
  )
);
```

Use bind display options carefully: bind values may contain sensitive information. Do not paste raw output into public repositories.

## 3. Plan review

Inspect:
- Access paths and index usage.
- Join order and join methods.
- Predicate placement and filter selectivity.
- Estimated versus actual rows.
- Sort, aggregation, and row-limiting operations.
- Partition pruning where applicable.
- Plan hash changes.

## 4. Index assessment

Before recommending an index:
1. Inspect existing indexes and constraints.
2. Review column selectivity and data distribution.
3. Check predicate and join usage.
4. Consider DML overhead and storage.
5. Test with representative data and workload.
6. Validate execution plan and application behavior.

## 5. Change validation

Capture baseline metrics, define success criteria, test in non-production, and prepare rollback. Do not force a plan or create an index solely from one AWR statistic.
