# Oracle RAC & Clusterware Troubleshooting Knowledge Base

A practical knowledge base for Oracle Database Administrators working with Oracle RAC, Grid Infrastructure, ASM, Data Guard, RMAN, and Exadata environments.

This repository contains installation guides, troubleshooting procedures, performance analysis queries, health checks, operational scripts, and maintenance checklists.

## Repository Contents

### 1. Clusterware Troubleshooting

| Document | Description |
|---|---|
| [Node Reachability Checks](clusterware/node-reachability-checks.md) | Troubleshooting node connectivity and name resolution |
| [OCR and Voting Disk Checks](clusterware/ocr-voting-disk-checks.md) | OCR integrity, backup, and voting disk validation |
| [Node Eviction Troubleshooting](clusterware/node-eviction-troubleshooting.md) | Investigating RAC node evictions and cluster reconfiguration |
| [Private Interconnect Troubleshooting](clusterware/private-interconnect-troubleshooting.md) | Diagnosing RAC interconnect and network issues |

### 2. Grid Infrastructure

| Document | Description |
|---|---|
| [CVU and runcluvfy Troubleshooting](grid-infrastructure/cvu-runcluvfy-troubleshooting.md) | Resolving Cluster Verification Utility failures |
| [Grid Infrastructure Patching](grid-infrastructure/gi-patching-troubleshooting.md) | GI patching checks and troubleshooting procedures |

### 3. Oracle RAC Installation

| Document | Description |
|---|---|
| [Oracle RAC 19c Installation Guide](installation/rac-19c-installation-guide.md) | RAC 19c installation prerequisites and configuration guidance |

### 4. ASM Troubleshooting

| Document | Description |
|---|---|
| [ASM Disk Group Troubleshooting](asm/asm-diskgroup-troubleshooting.md) | Disk group health, capacity, and disk failure investigation |
| [ASM Rebalance Analysis](asm/asm-rebalance-analysis.md) | Monitoring and analyzing ASM rebalance operations |

### 5. RAC Performance Analysis

| Document | Description |
|---|---|
| [Oracle RAC AWR Analysis](rac-performance/oracle-rac-awr-analysis.md) | AWR analysis and instance-level performance investigation |
| [RAC Wait Event Analysis](rac-performance/rac-wait-event-analysis.md) | Historical and real-time wait-event analysis |
| [SQL Performance Investigation](rac-performance/sql-performance-investigation.md) | SQL execution plans and performance troubleshooting |

### 6. Oracle Data Guard

| Document | Description |
|---|---|
| [Oracle Data Guard Troubleshooting](dataguard/oracle-dataguard-troubleshooting.md) | Data Guard configuration, synchronization, and troubleshooting |

### 7. RMAN Backup and Recovery

| Document | Description |
|---|---|
| [Oracle RMAN Backup and Recovery Guide](rman/oracle-rman-backup-recovery-guide.md) | Backup validation, restore, recovery, and RMAN troubleshooting |

### 8. Oracle Exadata and ExaCS

| Document | Description |
|---|---|
| [Oracle Exadata and ExaCS Health Checks](exadata/oracle-exadata-exacs-health-checks.md) | Exadata storage, cell, database, and infrastructure health checks |

### 9. Automation Scripts

| Script | Description |
|---|---|
| [Node Reboot Alert](scripts/node_reboot_alert.sh) | Detects node reboots and sends email notifications |
| [RAC Health Snapshot](scripts/rac_health_snapshot.sh) | Captures RAC environment health information |

### 10. Operational Checklists

| Checklist | Description |
|---|---|
| [Pre-Change and Post-Change Checklist](checklists/pre-change-post-change.md) | Standard operational validation before and after maintenance |

---

## Repository Structure

```text
oracle-rac-clusterware-troubleshooting/
│
├── README.md
├── LICENSE
│
├── clusterware/
│   ├── node-reachability-checks.md
│   ├── ocr-voting-disk-checks.md
│   ├── node-eviction-troubleshooting.md
│   └── private-interconnect-troubleshooting.md
│
├── grid-infrastructure/
│   ├── cvu-runcluvfy-troubleshooting.md
│   └── gi-patching-troubleshooting.md
│
├── installation/
│   └── rac-19c-installation-guide.md
│
├── asm/
│   ├── asm-diskgroup-troubleshooting.md
│   └── asm-rebalance-analysis.md
│
├── rac-performance/
│   ├── oracle-rac-awr-analysis.md
│   ├── rac-wait-event-analysis.md
│   └── sql-performance-investigation.md
│
├── dataguard/
│   └── oracle-dataguard-troubleshooting.md
│
├── rman/
│   └── oracle-rman-backup-recovery-guide.md
│
├── exadata/
│   └── oracle-exadata-exacs-health-checks.md
│
├── scripts/
│   ├── node_reboot_alert.sh
│   └── rac_health_snapshot.sh
│
└── checklists/
    └── pre-change-post-change.md
```

---

## Technologies Covered

- Oracle Database 19c
- Oracle Real Application Clusters (RAC)
- Oracle Grid Infrastructure
- Automatic Storage Management (ASM)
- Oracle Clusterware
- Oracle Data Guard
- Oracle RMAN
- Oracle Exadata
- Oracle Exadata Cloud Service (ExaCS)
- Linux administration and shell scripting

## Purpose

The objective of this repository is to maintain practical Oracle DBA documentation that can help with:

- Day-to-day Oracle RAC administration.
- Troubleshooting production database issues.
- Grid Infrastructure installation and patching.
- ASM storage management.
- Database performance analysis.
- Backup and recovery operations.
- Exadata and ExaCS health monitoring.
- Pre-change and post-change validation.

## Disclaimer

These documents are intended for technical reference and educational purposes.

Always validate commands in a non-production environment before executing them in production. Follow the applicable Oracle documentation, support recommendations, licensing requirements, and approved change procedures.

## Contributions

Suggestions, corrections, and improvements are welcome.

If you find an issue or have additional Oracle RAC troubleshooting scenarios, feel free to contribute.

---

**Maintained by:** Oracle Database Administration Community
