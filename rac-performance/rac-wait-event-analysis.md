# Oracle RAC Wait Event Analysis

## 1. Start with foreground impact

In AWR, review Top Timed Foreground Events and wait-class contribution to DB time. Focus on total time and workload impact, not just the event name.

## 2. Cluster-related waits

Review global cache and enqueue statistics, cluster wait events, interconnect statistics, and instance workload. Correlate with application latency and workload changes.

A low cluster wait contribution during one interval makes RAC coordination a lower-priority hypothesis for that interval, but does not rule out intermittent issues.

## 3. Redo and control-file waits

For redo-related events, examine wait count, total time, average latency, log switch frequency, and storage telemetry. For control-file waits, review the same dimensions and correlate with backup, checkpoint, and metadata activity.

## 4. Analysis workflow

1. Identify top waits by total foreground time.
2. Determine whether the wait is foreground-relevant or background activity.
3. Review count, total time, average, and distribution.
4. Compare across AWR intervals.
5. Correlate with OS, storage, network, and application metrics.
6. State what the evidence proves and what remains a hypothesis.

## 5. Avoid premature changes

Do not change CSS misscount, interconnect settings, redo configuration, or storage settings based only on an event average. Require a reproducible symptom, supporting evidence, and an approved change plan.
