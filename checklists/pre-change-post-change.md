# Oracle RAC Pre-change and Post-change Checklist

## Before change

- [ ] Confirm scope, business reason, and affected services.
- [ ] Confirm Oracle Database and Grid Infrastructure versions.
- [ ] Record current cluster and resource status.
- [ ] Capture relevant AWR/ADDM or monitoring baseline where appropriate.
- [ ] Confirm backup and recovery readiness.
- [ ] Review dependencies, maintenance window, and stakeholder approval.
- [ ] Document implementation steps and expected outcome.
- [ ] Define validation checks and rollback criteria.
- [ ] Confirm responsible engineer and escalation contacts.

## During change

- [ ] Record start time and each action.
- [ ] Validate command target and privileges before execution.
- [ ] Stop if observed behavior differs from the approved plan.
- [ ] Capture errors and diagnostic evidence.
- [ ] Avoid unrelated changes during the maintenance window.

## After change

- [ ] Run `crsctl check cluster -all`.
- [ ] Run `crsctl stat res -t`.
- [ ] Confirm expected nodes and services are available.
- [ ] Validate database and application connectivity.
- [ ] Check alert logs for new errors.
- [ ] Compare key performance metrics with baseline.
- [ ] Obtain application/business confirmation.
- [ ] Record completion time, outcome, and follow-up actions.

## Rollback

- [ ] Trigger rollback only when predefined criteria are met.
- [ ] Follow the approved, topology-specific rollback procedure.
- [ ] Revalidate cluster, database, and application health.
- [ ] Record rollback evidence and incident references.
