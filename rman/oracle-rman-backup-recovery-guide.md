
# Oracle RMAN Backup and Recovery Guide

## 1. Overview

Oracle Recovery Manager (RMAN) is Oracle's recommended utility for database backup, restore, and recovery operations.

RMAN supports:

- Full database backups
- Incremental backups
- Archived redo log backups
- Control file backups
- SPFILE backups
- Tablespace and data file backups
- Database restore and recovery
- Point-in-time recovery (PITR)
- Block media recovery

This guide provides practical RMAN administration and troubleshooting procedures.

**Important:** Always validate backup and recovery procedures against the database architecture, Oracle release, backup destination, and recovery objectives.

---

## 2. Check RMAN Configuration

Connect to RMAN:

```bash
rman target /
```

Display RMAN configuration:

```rman
SHOW ALL;
```

Review important configuration parameters:

- Retention policy
- Backup optimization
- Default device type
- Control file autobackup
- Channel configuration
- Compression settings
- Archived log deletion policy

Example configuration:

```rman
CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;
```

Enable control file autobackup:

```rman
CONFIGURE CONTROLFILE AUTOBACKUP ON;
```

**Note:** These are example settings. Confirm the organization's backup and recovery requirements before changing existing RMAN configuration.

---

## 3. Check Database Backup Information

Connect to the database:

```sql
SELECT name,
       open_mode,
       database_role,
       log_mode
FROM v$database;
```

Check database incarnation:

```rman
LIST INCARNATION OF DATABASE;
```

Check available backups:

```rman
LIST BACKUP SUMMARY;
```

Display database backup information:

```rman
LIST BACKUP OF DATABASE;
```

Display archived log backups:

```rman
LIST BACKUP OF ARCHIVELOG ALL;
```

Display control file backups:

```rman
LIST BACKUP OF CONTROLFILE;
```

---

## 4. Perform Full Database Backup

Example full database backup:

```rman
BACKUP DATABASE;
```

Full database backup including archived redo logs:

```rman
BACKUP DATABASE PLUS ARCHIVELOG;
```

Example backup with a descriptive tag:

```rman
BACKUP DATABASE PLUS ARCHIVELOG
TAG 'FULL_DATABASE_BACKUP';
```

Check backup completion:

```rman
LIST BACKUP SUMMARY;
```

Review the RMAN output and backup destination to confirm that the operation completed successfully.

**Important:** A successful backup command does not independently prove that the backup is recoverable.

---

## 5. Perform Incremental Backup

Level 0 incremental backup:

```rman
BACKUP INCREMENTAL LEVEL 0 DATABASE;
```

Level 1 incremental backup:

```rman
BACKUP INCREMENTAL LEVEL 1 DATABASE;
```

Cumulative level 1 backup:

```rman
BACKUP INCREMENTAL LEVEL 1 CUMULATIVE DATABASE;
```

Differential level 1 backup:

```rman
BACKUP INCREMENTAL LEVEL 1 DATABASE;
```

Level 1 backups are dependent on an appropriate parent backup chain.

Validate the backup strategy and incremental backup relationship before relying on it for recovery.

---

## 6. Perform Archived Redo Log Backup

Back up all archived redo logs:

```rman
BACKUP ARCHIVELOG ALL;
```

Back up archived logs and delete input files after successful backup:

```rman
BACKUP ARCHIVELOG ALL DELETE INPUT;
```

**Important:** Do not use `DELETE INPUT` without confirming backup completion, retention requirements, Data Guard requirements, and archive log deletion policies.

Check archive log backup information:

```sql
SELECT thread#,
       sequence#,
       first_time,
       next_time,
       archived,
       deleted,
       status
FROM v$archived_log
ORDER BY thread#, sequence#;
```

---

## 7. Validate RMAN Backups

Validate the database:

```rman
VALIDATE DATABASE;
```

Validate backup sets:

```rman
RESTORE DATABASE VALIDATE;
```

Validate a specific backup:

```rman
VALIDATE BACKUPSET <BACKUPSET_KEY>;
```

Check backup information:

```rman
LIST BACKUP SUMMARY;
```

Review RMAN validation output for:

- Missing backup pieces
- Corrupted backup blocks
- Missing data files
- Unavailable archived logs
- Backup accessibility issues

Validation is useful, but a controlled restore and recovery test is the stronger proof of recoverability.

---

## 8. Check RMAN Backup Status

Check recent RMAN backup jobs:

```sql
SELECT session_key,
       input_type,
       status,
       start_time,
       end_time,
       output_bytes_display
FROM v$rman_backup_job_details
ORDER BY start_time DESC;
```

Check RMAN backup details:

```sql
SELECT session_key,
       session_recid,
       session_stamp,
       operation,
       object_type,
       status,
       start_time,
       end_time
FROM v$rman_status
ORDER BY start_time DESC;
```

Check backup pieces:

```sql
SELECT recid,
       stamp,
       set_stamp,
       set_count,
       device_type,
       bytes / 1024 / 1024 AS size_mb,
       status,
       handle
FROM v$backup_piece
ORDER BY completion_time DESC;
```

For RAC environments, review the backup job output and channels across the participating instances.

---

## 9. Restore and Recover Database

Database restore and recovery must follow a planned recovery procedure.

Before beginning:

- Confirm the failure scenario.
- Identify the required recovery point.
- Verify backup availability.
- Verify archived redo log availability.
- Confirm control file and SPFILE availability.
- Understand the impact on Data Guard.
- Prepare the recovery environment.

Example RMAN commands for a complete database restore:

```rman
STARTUP MOUNT;

RESTORE DATABASE;

RECOVER DATABASE;
```

After successful recovery:

```rman
ALTER DATABASE OPEN;
```

**Important:** These are illustrative commands for an appropriate complete recovery scenario. The required startup, restore, recovery, and database-open sequence depends on the failure scenario and database state.

Do not execute them blindly against a production database.

---

## 10. Restore and Recover a Single Data File

Identify the data file:

```sql
SELECT file_id,
       file_name,
       tablespace_name,
       status
FROM dba_data_files
ORDER BY file_id;
```

Example RMAN recovery:

```rman
RESTORE DATAFILE <DATAFILE_NUMBER>;

RECOVER DATAFILE <DATAFILE_NUMBER>;
```

Depending on the database state and recovery scenario, the affected data file or tablespace may need to be taken offline and brought online after successful recovery.

Always follow the applicable Oracle recovery procedure.

---

## 11. Restore Control File

Control file recovery is required when the current control file is lost or damaged.

If a control file autobackup is available, an example procedure is:

```rman
STARTUP NOMOUNT;

RESTORE CONTROLFILE FROM AUTOBACKUP;

ALTER DATABASE MOUNT;
```

After restoring the control file:

1. Validate database identity and incarnation.
2. Review RMAN repository information.
3. Catalog backup pieces if required.
4. Restore database files.
5. Recover the database.
6. Open the database using the appropriate recovery procedure.

Example:

```rman
RESTORE DATABASE;

RECOVER DATABASE;
```

**Important:** The correct recovery sequence depends on whether the control file is current, whether the recovery catalog is available, and whether the database is undergoing complete or incomplete recovery.

---

## 12. Point-in-Time Recovery (PITR)

Point-in-time recovery restores the database to an earlier time.

Before PITR:

- Identify the required recovery timestamp.
- Confirm available backups.
- Confirm archived redo log availability.
- Understand the data loss implications.
- Confirm whether the entire database or a specific tablespace requires recovery.

Example database PITR:

```rman
STARTUP MOUNT;

RUN {
    SET UNTIL TIME
        "TO_DATE('2026-11-13 10:00:00',
                 'YYYY-MM-DD HH24:MI:SS')";

    RESTORE DATABASE;

    RECOVER DATABASE;
}
```

For an incomplete database recovery, opening the database generally requires:

```rman
ALTER DATABASE OPEN RESETLOGS;
```

After opening with RESETLOGS:

- Verify the database state.
- Validate application data.
- Take a new database backup.
- Review the database incarnation.
- Revalidate Data Guard configuration if applicable.

**Important:** PITR can result in data loss after the selected recovery point. Obtain approval before performing it.

---

## 13. Check RMAN Recovery Catalog

If using a recovery catalog, connect using the appropriate catalog credentials:

```bash
rman target / catalog <CATALOG_USER>@<CATALOG_SERVICE>
```

Check database registration:

```rman
LIST DB_UNIQUE_NAME OF DATABASE;
```

Check backup information:

```rman
LIST BACKUP SUMMARY;
```

Check database incarnation:

```rman
LIST INCARNATION;
```

The recovery catalog and control file repository may contain different amounts of historical backup information.

---

## 14. Common RMAN Errors

| Error | General investigation |
|---|---|
| RMAN-03002 | Review the complete command failure and preceding errors |
| RMAN-06054 | Investigate an unknown archived log required for recovery |
| RMAN-06025 | Check whether the required archived log backup is available |
| RMAN-06023 | Investigate whether a suitable backup of the required data file is available |
| RMAN-06010 | Review the associated data file lookup error |
| RMAN-20201 | Check recovery catalog database registration and metadata |
| RMAN-20202 | Verify the database incarnation and catalog metadata |
| ORA-19505 | Investigate backup file location and accessibility |
| ORA-27037 | Check operating-system file access and storage availability |

Always review the complete RMAN error stack, including the underlying ORA errors.

---

## 15. Troubleshoot RMAN-20201 and RMAN-06010

Example errors:

```text
RMAN-20201: datafile not found in the recovery catalog
RMAN-06010: error while looking up datafile
```

Possible investigation areas:

- Data file number
- Database registration
- Database incarnation
- Recovery catalog metadata
- Control file records
- Backup metadata
- Database identity

Check data file information:

```sql
SELECT file#,
       name,
       status
FROM v$datafile
ORDER BY file#;
```

Check registered database information:

```rman
LIST DB_UNIQUE_NAME OF DATABASE;
```

If the recovery catalog is used, confirm that the correct database is connected and registered.

Do not blindly use `UNREGISTER`, `RESET DATABASE`, or catalog resynchronization commands to resolve a metadata issue.

Follow the appropriate recovery catalog procedure.

---

## 16. Check RMAN Channels and Backup Performance

Review configured channels:

```rman
SHOW ALL;
```

Example manual channel allocation:

```rman
RUN {
    ALLOCATE CHANNEL ch1 DEVICE TYPE DISK;

    BACKUP DATABASE;

    RELEASE CHANNEL ch1;
}
```

For production environments, review:

- Number of channels
- Backup destination throughput
- CPU utilization
- Storage latency
- Compression overhead
- Concurrent database workload
- Backup window requirements

Use a channel configuration appropriate for the backup architecture.

---

## 17. RMAN and Oracle RAC Considerations

For RAC databases:

- Validate shared backup destination accessibility.
- Confirm archived redo logs from every redo thread are backed up.
- Check channel allocation and instance placement.
- Review backup logs from the executing node.
- Validate recovery files and archive destinations.
- Consider cluster and database availability requirements.

Check redo thread information:

```sql
SELECT thread#,
       status,
       enabled
FROM v$thread
ORDER BY thread#;
```

Check archived log sequence information:

```sql
SELECT thread#,
       sequence#,
       first_time,
       next_time,
       archived,
       deleted
FROM v$archived_log
ORDER BY thread#, sequence#;
```

A successful backup of one RAC instance does not automatically prove that all required redo threads and recovery files are protected.

---

## 18. Pre-backup Checklist

- [ ] Confirm database status.
- [ ] Check RMAN configuration.
- [ ] Verify backup destination availability.
- [ ] Confirm sufficient storage capacity.
- [ ] Validate archived log availability.
- [ ] Check recovery catalog connectivity, if applicable.
- [ ] Review existing backup jobs.
- [ ] Confirm retention policy.
- [ ] Validate backup completion.
- [ ] Review RMAN logs.

## 19. Pre-recovery Checklist

- [ ] Identify the failure scenario.
- [ ] Confirm database identity and DBID.
- [ ] Identify the required recovery point.
- [ ] Verify backup availability.
- [ ] Verify archived redo log availability.
- [ ] Confirm control file and SPFILE availability.
- [ ] Review database incarnation.
- [ ] Assess Data Guard dependencies.
- [ ] Obtain recovery approval.
- [ ] Prepare the recovery procedure.
- [ ] Document expected data loss, if any.

## 20. Post-recovery Checklist

- [ ] Confirm database open mode.
- [ ] Validate database role.
- [ ] Verify data file status.
- [ ] Check database alert logs.
- [ ] Validate application connectivity.
- [ ] Verify important database objects and data.
- [ ] Review database invalid objects.
- [ ] Confirm backup and archive log operations.
- [ ] Take a fresh backup when required.
- [ ] Validate Data Guard configuration.
- [ ] Document recovery details and outcome.

---

## 21. Important Safety Notes

- Never assume a successful backup guarantees recoverability.
- Perform periodic restore and recovery tests.
- Do not delete archived logs without checking recovery and Data Guard requirements.
- Do not perform PITR without understanding data loss implications.
- Do not use RESETLOGS without confirming the recovery scenario requires it.
- Protect RMAN backup pieces and recovery catalog credentials.
- Maintain documented recovery procedures.
- Follow Oracle Support guidance for critical recovery failures.

## 22. References

- Oracle Database Backup and Recovery User's Guide
- Oracle Database Backup and Recovery Reference
- Oracle Database Administrator's Guide
- Oracle Recovery Manager documentation
- Oracle Support documentation and relevant MOS notes

**Disclaimer:** This guide is a general Oracle Database 19c RMAN reference. Validate all commands against the actual database state, recovery scenario, and installed Oracle Database Release Update before production execution.
