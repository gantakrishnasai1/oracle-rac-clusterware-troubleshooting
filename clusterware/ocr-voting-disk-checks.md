
# Oracle RAC OCR and Voting Disk Troubleshooting

## 1. Overview

Oracle Clusterware uses Oracle Cluster Registry (OCR) and
voting files to maintain cluster configuration and node
membership information.

OCR stores configuration information for resources managed
by Oracle Clusterware.

Voting files are used by Cluster Synchronization Services
(CSS) to maintain cluster membership and help prevent
split-brain conditions.

Issues with OCR or voting files can affect:

- Clusterware startup.
- Cluster resource availability.
- Node membership.
- RAC database availability.
- Cluster synchronization.
- Cluster reconfiguration.

This document describes health checks, backup validation,
diagnostic commands and troubleshooting procedures.

## 2. Scope

This guide covers:

- OCR health validation.
- OCR configuration and location.
- OCR backup verification.
- Voting disk configuration.
- Voting disk accessibility.
- ASM-based OCR and voting file considerations.
- Common OCR and voting disk errors.
- Safe troubleshooting and recovery considerations.

## 3. Prerequisites

Before executing the checks, identify:

| Parameter | Description |
|---|---|
| Oracle Grid Infrastructure version | Example: 19c |
| Cluster name | Configured RAC cluster name |
| Number of nodes | Total cluster nodes |
| OCR location | ASM disk group or supported storage |
| Voting file location | ASM disk group or supported storage |
| ASM redundancy | External, Normal or High |
| Grid owner | Usually grid |
| Privileged account | Root, where required |

Use the correct Grid Infrastructure environment.

Example:

```bash
export ORACLE_HOME=/u01/app/19.0.0/grid
export PATH=$ORACLE_HOME/bin:$PATH
```

Use the actual Grid Infrastructure Oracle Home.

## 4. Clusterware Status Validation

Before investigating OCR and voting files,
check the overall Clusterware status.

```bash
crsctl check crs
```

Check cluster-wide status:

```bash
crsctl check cluster -all
```

Check cluster resources:

```bash
crsctl stat res -t
```

Check node membership:

```bash
olsnodes -n -s
```

Review the output for:

- Clusterware services online.
- CSS services running.
- Expected nodes participating in the cluster.
- No unexpected resource failures.

## 5. OCR Health Validation

### 5.1 Check OCR integrity

Execute:

```bash
ocrcheck
```

Review the output for:

- OCR integrity check successful.
- OCR location information.
- OCR storage accessibility.
- No reported corruption.

Example of an illustrative successful result:

```text
Status of Oracle Cluster Registry is as follows:

Version                  : 4
Total space (kbytes)     : ...
Used space (kbytes)      : ...
Available space (kbytes): ...

PROT-602: Oracle Cluster Registry is not corrupted
```

Exact output can vary by Oracle release.

### 5.2 Detailed OCR configuration

Execute:

```bash
ocrcheck -config -details
```

Review the OCR configuration and storage details.

### 5.3 Identify OCR locations

Execute:

```bash
ocrcheck -config
```

For additional configuration information:

```bash
ocrconfig -showbackup
```

Verify that the configured OCR locations are accessible
and correspond to the expected storage configuration.

## 6. OCR Backup Validation

Oracle Clusterware maintains automatic OCR backups.

Check available OCR backups:

```bash
ocrconfig -showbackup
```

Review:

- Backup timestamps.
- Backup locations.
- Availability of recent backup files.
- Backup retention and operational requirements.

### 6.1 Create a manual OCR backup

Where permitted by the operational procedure,
a manual OCR backup can be initiated.

Execute as root:

```bash
ocrconfig -manualbackup
```

Verify the backup information:

```bash
ocrconfig -showbackup
```

Important:

A successful backup command does not replace the need
to verify the backup file and the recovery procedure.

### 6.2 Export OCR configuration

For an additional logical export:

```bash
ocrconfig -export /path/to/ocr_export.ocr
```

Use an approved secure directory with sufficient
space and appropriate permissions.

This export is supplementary and does not replace
the normal OCR backup and recovery process.

## 7. Voting Disk Health Validation

### 7.1 Check voting disk configuration

Execute:

```bash
crsctl query css votedisk
```

Review:

- Voting file count.
- Voting file locations.
- Voting file accessibility.
- Expected storage configuration.

Example illustrative output:

```text
##  STATE    File Universal Id                File Name
1. ONLINE   <voting-file-id>                 [DATA]
2. ONLINE   <voting-file-id>                 [DATA]
3. ONLINE   <voting-file-id>                 [DATA]

Located 3 voting disk(s).
```

Actual output depends on the storage configuration.

### 7.2 Check voting disk accessibility

Review the voting disk status from the cluster nodes.

```bash
crsctl query css votedisk
```

Execute the command from the relevant nodes and
compare the reported configuration.

Investigate any unexpected differences or unavailable
voting files.

### 7.3 Check ASM disk group status

If OCR and voting files are stored in ASM:

```bash
asmcmd lsdg
```

Check ASM disks:

```bash
asmcmd lsdsk -p
```

Review:

- Disk group state.
- Usable free space.
- Disk group redundancy.
- Disk accessibility.
- Offline or missing disks.
- Rebalance activity.

For additional ASM diagnostics, refer to the
ASM troubleshooting guide.

## 8. OCR and Voting Disk Storage Considerations

OCR and voting files can be stored in supported
ASM configurations or other supported storage
configurations depending on the Grid Infrastructure
release and architecture.

For ASM-based configurations, verify:

- ASM disk group is mounted.
- Required disks are online.
- Disk group redundancy is appropriate.
- No unexpected disk failures exist.
- Sufficient usable capacity is available.

Do not assume that three voting files always need
to be manually created.

The number and placement of voting files are managed
according to the configured storage architecture.

For ASM-managed voting files, Oracle Clusterware
manages their placement and redundancy.

Do not manually copy, move or delete voting files.

## 9. Common Troubleshooting Scenarios

### Scenario 1: OCR Integrity Check Failure

Symptoms:

- ocrcheck reports an integrity problem.
- OCR configuration cannot be accessed.
- Clusterware resources fail to start.

Possible causes:

- Storage unavailable.
- ASM disk group unavailable.
- OCR file corruption.
- Storage or I/O errors.
- Incorrect permissions or configuration.

Troubleshooting:

1. Check Clusterware status.
2. Execute ocrcheck.
3. Verify OCR locations.
4. Check ASM disk group status if applicable.
5. Review Grid Infrastructure alert logs.
6. Preserve diagnostic logs.
7. Follow the Oracle-supported recovery procedure.

Do not attempt an OCR restore until the storage
condition and backup validity are established.

### Scenario 2: Voting Disk Unavailable

Symptoms:

- Voting disk query reports unavailable files.
- CSSD communication issues.
- Node membership problems.
- Cluster reconfiguration or node eviction.

Possible causes:

- Storage path failure.
- ASM disk group unavailable.
- Disk failure.
- Storage connectivity problems.
- Underlying multipath or I/O issues.

Troubleshooting:

1. Execute crsctl query css votedisk.
2. Check ASM disk group status.
3. Verify storage accessibility.
4. Review operating system and storage logs.
5. Review CSSD and Clusterware diagnostics.
6. Engage storage and Oracle support if required.

Do not manually recreate voting files as an initial
troubleshooting action.

### Scenario 3: OCR Backup Not Available

Symptoms:

- ocrconfig -showbackup does not show expected backups.
- Backup directory unavailable.
- OCR backup files are missing.

Possible causes:

- Backup retention or cleanup.
- Storage location unavailable.
- Backup operation failure.
- Incorrect backup expectations.

Troubleshooting:

1. Check ocrconfig -showbackup.
2. Verify backup directory accessibility.
3. Check file ownership and permissions.
4. Review Clusterware logs.
5. Follow the organization's backup retention process.

### Scenario 4: ASM Disk Group Unavailable

Symptoms:

- OCR or voting files inaccessible.
- ASM disk group is dismounted.
- Clusterware resources fail.

Troubleshooting:

1. Check ASM instance status.
2. Check disk group mount status.
3. Validate disk accessibility.
4. Review ASM alert logs.
5. Investigate underlying storage errors.
6. Follow the approved ASM recovery procedure.

## 10. Important Diagnostic Locations

Use ADRCI to identify diagnostic homes:

```bash
adrci
```

Inside ADRCI:

```text
show homes
```

Select the appropriate diagnostic home:

```text
set homepath <diagnostic_home>
```

Display alert log:

```text
show alert -tail 100
```

Relevant diagnostic components may include:

- Clusterware.
- CSSD.
- CRSD.
- OHASD.
- ASM.

Typical diagnostic directory structure:

```text
$ORACLE_BASE/diag/crs/<hostname>/crs/trace/
```

Actual locations depend on the installation.

## 11. OCR and Voting Disk Recovery Considerations

OCR and voting disk recovery are sensitive Clusterware
administration activities.

Before any recovery operation:

1. Identify the affected nodes.
2. Determine whether the issue is OCR, voting disk,
   ASM or underlying storage related.
3. Check current Clusterware status.
4. Verify available OCR backups.
5. Preserve relevant diagnostic logs.
6. Confirm the supported recovery procedure for
   the installed Grid Infrastructure release.
7. Obtain the required change approval.

Important safety rules:

- Never delete OCR files manually.
- Never manually modify voting file contents.
- Never restore an old OCR backup without
  understanding the configuration changes since
  that backup.
- Never perform voting file replacement based
  solely on an unavailable voting disk message.
- Do not stop or restart all cluster nodes
  simultaneously without an approved procedure.

Use Oracle-supported ocrconfig and Clusterware
recovery procedures only when the failure scenario
has been identified.

For production corruption or cluster-wide failures,
engage Oracle Support when necessary.

## 12. Final Validation Checklist

| Check | Expected Result |
|---|---|
| crsctl check crs | Clusterware services healthy |
| crsctl check cluster -all | Expected nodes available |
| crsctl stat res -t | Expected resources online |
| olsnodes -n -s | Expected node membership |
| ocrcheck | OCR integrity successful |
| ocrcheck -config -details | Expected OCR configuration |
| ocrconfig -showbackup | Backup information available |
| crsctl query css votedisk | Expected voting files online |
| asmcmd lsdg | Required disk groups mounted |
| asmcmd lsdsk -p | Expected disks accessible |
| ADRCI | No unresolved critical errors |

## 13. Best Practices

- Validate OCR integrity periodically.
- Monitor OCR backup availability.
- Protect OCR backup files.
- Monitor ASM disk group capacity.
- Review voting disk availability.
- Preserve Clusterware diagnostic logs.
- Perform recovery operations only through
  supported Oracle procedures.
- Include OCR and voting disk checks in
  pre-change and post-change validation.

## 14. References

Oracle Grid Infrastructure documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Clusterware administration and management
documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Refer to the documentation for the exact
Grid Infrastructure release and platform.
