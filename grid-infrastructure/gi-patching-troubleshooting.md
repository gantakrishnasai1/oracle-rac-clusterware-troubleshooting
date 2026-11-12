
# Oracle Grid Infrastructure Patching Troubleshooting Guide

## 1. Overview

Oracle Grid Infrastructure patching is an important maintenance activity for Oracle RAC environments.

Grid Infrastructure patches may include:

- Release Updates (RU)
- Release Update Revisions (RUR), where applicable
- Monthly or quarterly security-related updates
- One-off patches
- Merge patches
- Grid Infrastructure and Database home updates

Patching must follow the README and installation instructions supplied with the specific patch.

This guide covers the general troubleshooting workflow for Oracle Grid Infrastructure 19c patching.

## 2. Understand the Patching Tools

| Tool | Purpose |
|---|---|
| OPatch | Applies and rolls back Oracle interim patches |
| OPatchAuto | Automates supported system patching workflows |
| CVU | Validates cluster prerequisites |
| CRSCTL | Checks and manages Clusterware |
| SRVCTL | Manages Oracle resources |
| OPatch lsinventory | Displays installed patch inventory |

**Important:** The correct patching method depends on the patch README, Oracle release, platform, and target home. Do not assume every GI patch can be applied using the same command.

## 3. Identify Current Grid Infrastructure Version

Check the Grid Infrastructure version:

```bash
crsctl query crs activeversion
crsctl query crs softwareversion
```

Check the Clusterware version:

```bash
crsctl query crs releaseversion
```

Check the OPatch version:

```bash
$ORACLE_HOME/OPatch/opatch version
```

Check installed patches:

```bash
$ORACLE_HOME/OPatch/opatch lsinventory
```

For detailed inventory:

```bash
$ORACLE_HOME/OPatch/opatch lsinventory -detail
```

Run the commands against the correct Grid Infrastructure home.

## 4. Pre-Patching Validation

Before starting patching, collect the current cluster health information.

### 4.1 Check Clusterware

```bash
crsctl check cluster -all
```

```bash
crsctl stat res -t
```

```bash
olsnodes -n -s
```

### 4.2 Check OCR and Voting Disks

```bash
ocrcheck
```

```bash
ocrconfig -showbackup
```

```bash
crsctl query css votedisk
```

### 4.3 Check ASM

```bash
srvctl status asm
```

```bash
asmcmd lsdg
```

```bash
asmcmd lsdsk -p
```

### 4.4 Check Database Instances

```bash
srvctl status database -db <DB_UNIQUE_NAME>
```

Check database status:

```sql
SELECT inst_id,
       instance_name,
       host_name,
       status,
       database_status
FROM gv$instance
ORDER BY inst_id;
```

### 4.5 Check Filesystem Capacity

```bash
df -h
```

```bash
df -i
```

Verify sufficient free space in:

- Grid Infrastructure home
- Database home
- Inventory location
- Temporary filesystem
- Patch staging filesystem

### 4.6 Check Existing Patches

```bash
$ORACLE_HOME/OPatch/opatch lsinventory
```

Review existing one-off patches and conflicts before applying the new patch.

## 5. Review Patch README and Requirements

Before patching:

1. Download the correct patch for the Oracle release and platform.
2. Verify the patch number and target release.
3. Read the complete patch README.
4. Review OPatch and OPatchAuto version requirements.
5. Check required interim patches.
6. Review conflict and prerequisite instructions.
7. Confirm rolling or non-rolling patching support.
8. Review downtime and application impact.
9. Prepare a rollback or recovery plan.

Do not use generic commands without checking the patch README.

## 6. Validate OPatch Version

Check the current OPatch version:

```bash
$ORACLE_HOME/OPatch/opatch version
```

If an OPatch update is required, follow the Oracle-provided OPatch update instructions.

After updating, verify:

```bash
$ORACLE_HOME/OPatch/opatch version
```

Check the version in every relevant Oracle home.

## 7. Check Patch Conflicts

For supported patch types, use OPatch conflict checking.

Example:

```bash
$ORACLE_HOME/OPatch/opatch prereq \
  CheckConflictAgainstOHWithDetail \
  -phBaseDir <PATCH_DIRECTORY>
```

Check applicable prerequisites:

```bash
$ORACLE_HOME/OPatch/opatch prereq -help
```

For GI system patching, use the conflict and prerequisite checks documented in the specific patch README and OPatchAuto instructions.

Do not assume that a successful conflict check proves the entire patching process is safe.

## 8. Grid Infrastructure Patching Workflow

The patching workflow depends on the patch type and release.

A general workflow is:

1. Confirm cluster health.
2. Review patch README.
3. Validate OPatch version.
4. Validate patch prerequisites.
5. Check patch conflicts.
6. Stage and verify patch files.
7. Execute the documented patching procedure.
8. Monitor Clusterware and database resources.
9. Verify patch inventory.
10. Perform post-patching validation.

### OPatchAuto

For patch types explicitly documented to use OPatchAuto, the general command structure may look like:

```bash
$ORACLE_HOME/OPatch/opatchauto apply <PATCH_DIRECTORY>
```

The exact command, execution location, privileges, and required arguments must come from the patch README.

Do not run this example blindly on a production cluster.

### Manual OPatch

Some patches or individual Oracle homes may require manual OPatch commands.

Follow the exact sequence and requirements in the patch README.

Do not substitute manual OPatch for an OPatchAuto procedure unless Oracle documents that method for the specific patch.

## 9. Monitor Patching Progress

Monitor Clusterware resources:

```bash
crsctl stat res -t
```

Check cluster status:

```bash
crsctl check cluster -all
```

Check database status:

```bash
srvctl status database -db <DB_UNIQUE_NAME>
```

Check ASM status:

```bash
srvctl status asm
```

Monitor patching logs and the relevant OPatch or OPatchAuto log files.

Typical log locations include:

- Oracle Inventory logs
- OPatch logs under the Oracle home
- OPatchAuto logs under the Oracle base configuration area
- Grid Infrastructure diagnostic logs

Use the log paths reported by the patching tool rather than assuming a fixed location.

## 10. Post-Patching Validation

### 10.1 Verify Grid Infrastructure Version

```bash
crsctl query crs activeversion
```

```bash
crsctl query crs softwareversion
```

### 10.2 Verify Patch Inventory

```bash
$ORACLE_HOME/OPatch/opatch lsinventory
```

For detailed inventory:

```bash
$ORACLE_HOME/OPatch/opatch lsinventory -detail
```

Compare the inventory with the patch README and expected patch list.

### 10.3 Verify Clusterware

```bash
crsctl check cluster -all
```

```bash
crsctl stat res -t
```

### 10.4 Verify ASM

```bash
srvctl status asm
```

```bash
asmcmd lsdg
```

### 10.5 Verify Database Instances

```bash
srvctl status database -db <DB_UNIQUE_NAME>
```

Run the appropriate database SQL validation:

```sql
SELECT inst_id,
       instance_name,
       host_name,
       status,
       database_status
FROM gv$instance
ORDER BY inst_id;
```

### 10.6 Verify SQL Patch Registry

For database homes that received database patches, check the SQL patch registry:

```sql
SELECT patch_id,
       patch_type,
       action,
       status,
       action_time,
       description
FROM dba_registry_sqlpatch
ORDER BY action_time DESC;
```

**Important:** This query checks database SQL patch application status. It does not replace verification of the Grid Infrastructure or binary patch inventory.

Run the required datapatch procedure only as documented for the specific database patch and patching workflow.

## 11. Common Patching Issues

| Issue | Investigation |
|---|---|
| OPatch version incompatible | Verify the required OPatch version in the patch README |
| Patch conflict | Review conflict output and Oracle patch guidance |
| Insufficient filesystem space | Validate Grid home, inventory, and temporary filesystem capacity |
| CVU prerequisite failure | Review the complete CVU output |
| OPatchAuto failure | Review OPatchAuto logs and the exact failing phase |
| CRS resource failure | Check Clusterware logs and resource dependencies |
| Database instance unavailable | Review database alert logs and SRVCTL status |
| SQL patch registry failure | Review datapatch logs and `DBA_REGISTRY_SQLPATCH` |
| Inventory mismatch | Re-run inventory checks and investigate the patch logs |

## 12. Troubleshooting OPatchAuto Failures

When OPatchAuto fails:

1. Record the complete command and exit status.
2. Identify the node and Oracle home involved.
3. Identify the failed patching phase.
4. Review the OPatchAuto log.
5. Review the corresponding OPatch log.
6. Check Clusterware resource status.
7. Check filesystem and inventory availability.
8. Review the patch README for recovery instructions.

Do not immediately rerun the patch command without understanding the failure state.

Avoid manually deleting patch-related files or modifying inventory contents.

## 13. Rolling and Non-Rolling Patching

Patching may be rolling or non-rolling depending on the patch and supported configuration.

### Rolling patching

A supported rolling procedure applies the patch to cluster nodes in a controlled sequence while maintaining service availability within the supported limitations.

### Non-rolling patching

A non-rolling procedure may require a broader outage or coordinated downtime.

Before selecting the method, verify:

- Patch rolling support
- GI and database release
- RAC configuration
- Application availability requirements
- Service placement
- Patch README instructions

Do not assume every Release Update supports rolling patching in every configuration.

## 14. Rollback and Recovery Planning

Before patching, document:

- Existing GI and database versions
- Existing patch inventory
- Patch application sequence
- Node-by-node activity plan
- Database and application dependencies
- Backup and recovery readiness
- Approved rollback criteria
- Oracle Support escalation details

**Important:** Patch rollback is not always equivalent to restoring the previous environment.

Some failures require a documented recovery procedure, restore, or Oracle Support intervention.

Use only the rollback instructions provided for the specific patch and installation type.

## 15. Pre-Patching Checklist

- [ ] Confirm current GI version and patch inventory.
- [ ] Confirm database version and patch inventory.
- [ ] Review the complete patch README.
- [ ] Validate OPatch version.
- [ ] Check patch prerequisites.
- [ ] Check patch conflicts.
- [ ] Validate cluster health.
- [ ] Validate OCR and voting disks.
- [ ] Validate ASM and disk group health.
- [ ] Check database and application availability.
- [ ] Verify filesystem capacity.
- [ ] Confirm backup and recovery readiness.
- [ ] Obtain change approval.
- [ ] Prepare a patch-specific rollback plan.

## 16. Post-Patching Checklist

- [ ] Confirm expected patch inventory on all relevant homes.
- [ ] Validate active and software GI versions.
- [ ] Confirm all cluster nodes are healthy.
- [ ] Validate Clusterware resources.
- [ ] Validate ASM disk groups.
- [ ] Validate database instances.
- [ ] Check SQL patch registry where applicable.
- [ ] Review GI and database alert logs.
- [ ] Validate listener and database services.
- [ ] Perform application connectivity testing.
- [ ] Compare database performance with the baseline.
- [ ] Document patching completion and issues.

## 17. Important Safety Notes

- Always follow the patch-specific Oracle README.
- Never assume the same command applies to every GI patch.
- Do not ignore prerequisite or conflict failures.
- Do not modify Oracle inventory manually.
- Do not remove patch files while patching is in progress.
- Do not perform rollback without understanding the patch state.
- Collect diagnostic logs before troubleshooting a failed patch.
- Follow Oracle Support guidance for critical production failures.

## 18. References

- Oracle Grid Infrastructure Installation and Upgrade Guide
- Oracle OPatch User's Guide
- Oracle Database Release Update documentation
- Oracle Clusterware Administration and Deployment Guide
- Oracle Support documentation and patch-specific README files

**Disclaimer:** This guide is a general troubleshooting reference. Always follow the exact patch README, platform certification, and Oracle Support instructions for the installed Oracle Grid Infrastructure release.
