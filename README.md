
# Oracle RAC Administration & Troubleshooting Knowledge Base

A practical knowledge base for Oracle Database Administrators covering Oracle Real Application Clusters (RAC), Grid Infrastructure, Clusterware, performance troubleshooting, health checks, and automation.

This repository contains DBA-focused troubleshooting guides, operational checklists, and shell scripts designed to help diagnose issues, perform routine health checks, and support Oracle RAC environments.

## Contents

- [Clusterware Troubleshooting](#clusterware-troubleshooting)
- [Grid Infrastructure](#grid-infrastructure)
- [RAC Performance](#rac-performance)
- [Automation Scripts](#automation-scripts)
- [Operational Checklists](#operational-checklists)
- [Getting Started](#getting-started)
- [Compatibility and Safety](#compatibility-and-safety)
- [Contributing](#contributing)

## Clusterware Troubleshooting

Guides for investigating Oracle Clusterware and RAC connectivity issues.

| Guide | Description |
|---|---|
| [Node Reachability Checks](clusterware/node-reachability-checks.md) | Troubleshoot hostname resolution, node connectivity, SSH, network interfaces, and routing. |
| [OCR and Voting Disk Checks](clusterware/ocr-voting-disk-checks.md) | Check OCR health, OCR backups, voting disks, and related Clusterware issues. |

## Grid Infrastructure

Guides for Grid Infrastructure verification and troubleshooting.

| Guide | Description |
|---|---|
| [CVU and runcluvfy Troubleshooting](grid-infrastructure/cvu-runcluvfy-troubleshooting.md) | Investigate Cluster Verification Utility failures and installation prerequisite issues. |

## RAC Performance

Practical approaches to analyzing Oracle RAC performance and database wait events.

| Guide | Description |
|---|---|
| [Oracle RAC AWR Analysis](rac-performance/oracle-rac-awr-analysis.md) | Analyze AWR reports, DB Time, CPU, I/O, RAC waits, and SQL performance. |
| [RAC Wait Event Analysis](rac-performance/rac-wait-event-analysis.md) | Investigate Global Cache waits, Cache Fusion, and RAC interconnect-related waits. |
| [SQL Performance Investigation](rac-performance/sql-performance-investigation.md) | Investigate SQL execution statistics, execution plans, and performance regressions. |

## Automation Scripts

Shell scripts for routine Oracle RAC administration and monitoring.

| Script | Description |
|---|---|
| [Node Reboot Alert](scripts/node_reboot_alert.sh) | Detect a recent Linux node reboot and send an email notification. |
| [RAC Health Snapshot](scripts/rac_health_snapshot.sh) | Collect a basic RAC, Clusterware, ASM, and operating-system health snapshot. |

Review each script before execution and adjust environment-specific settings.

## Operational Checklists

| Checklist | Description |
|---|---|
| [Pre-change and Post-change Checklist](checklists/pre-change-post-change.md) | A structured checklist for planning, validating, and documenting database infrastructure changes. |

## Getting Started

1. Browse the relevant troubleshooting guide or checklist.
2. Review the prerequisites and commands before executing them.
3. Replace example values with details from your own environment.
4. Validate commands against your Oracle Database and Grid Infrastructure versions.
5. Capture diagnostic output before and after changes.
6. Document findings and follow your organization's change-management process.

## Compatibility and Safety

- The documentation primarily focuses on Oracle Database RAC and Grid Infrastructure administration.
- Command availability and syntax may vary by Oracle Database release, Grid Infrastructure version, and operating system.
- Linux shell scripts may require GNU utilities and appropriate operating-system permissions.
- Some diagnostic features, including AWR, ADDM, ASH, and SQL Monitor, may require Oracle Diagnostics Pack or Tuning Pack licensing. Verify your organization's licensing before use.
- Review scripts and commands before running them in production.
- Avoid executing destructive commands without an approved change plan and recovery strategy.
- Never publish production credentials, private IP details, customer information, or sensitive diagnostic output.

## Contributing

Contributions, corrections, and practical troubleshooting scenarios are welcome.

When contributing:

1. Use clear and descriptive file names.
2. Include the Oracle Database and Grid Infrastructure versions where relevant.
3. Provide reproducible steps and sanitized command output.
4. Explain the root cause and resolution where known.
5. Remove credentials, customer details, and other sensitive information.
6. Verify commands before submitting changes.

For issues or suggestions, open a GitHub Issue in this repository.

## Disclaimer

This repository is intended for educational and operational reference purposes. The examples are provided as-is and should be validated in a non-production environment before being used in production.

Always follow Oracle documentation, applicable support guidance, organizational policies, and approved change procedures.

## License

See the [LICENSE](LICENSE) file for licensing information.

---

**Maintained as a practical Oracle DBA knowledge base.**
