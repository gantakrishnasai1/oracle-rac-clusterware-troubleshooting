# OCR and Voting Disk Checks

## Read-only diagnostics

Run with appropriate Grid Infrastructure privileges:

```bash
ocrcheck
ocrconfig -showbackup
crsctl query css votedisk
```

Capture command output and timestamp as part of the incident record.

## Interpretation guidance

- `ocrcheck` reports the Oracle Cluster Registry integrity status.
- `ocrconfig -showbackup` lists available OCR backups known to the configuration.
- `crsctl query css votedisk` reports voting disk configuration and status.

A successful command does not replace review of Clusterware alert logs or storage health.

## Safety

Do not manually delete, move, overwrite, or recreate OCR or voting disk files. Do not execute restore or replacement commands without confirming the cluster topology, storage layout, backup validity, Oracle release procedure, and approved recovery plan.
