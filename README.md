# Oracle RAC & Clusterware Troubleshooting

A practical knowledge base for Oracle Database Administrators working
with Oracle RAC, Grid Infrastructure, Clusterware, and database
performance troubleshooting.

This repository documents diagnostic approaches, useful commands,
checklists, and lessons learned from Oracle RAC administration. The goal
is to make troubleshooting workflows easier to follow, repeat, and
validate.

## Repository Scope

### 1. Oracle RAC and Grid Infrastructure

-   Clusterware and CRS troubleshooting
-   Cluster resource status and management
-   Node reachability and name-resolution checks
-   Inter-node connectivity and SSH validation
-   Grid Infrastructure installation pre-checks
-   Common `runcluvfy` validation failures

### 2. RAC Performance Analysis

-   Oracle AWR and ADDM report review
-   Instance workload distribution
-   Database CPU and wait-event analysis
-   RAC global cache and interconnect investigation
-   SQL performance and execution-plan review
-   Logical I/O and physical I/O investigation

### 3. Database Administration Diagnostics

-   Practical SQL and command-line checks
-   Health-check and validation procedures
-   Evidence collection for incident investigation
-   Pre-change and post-change validation checklists

## Suggested Repository Structure

``` text
oracle-rac-clusterware-troubleshooting/
├── README.md
├── clusterware/
│   ├── cluster-resource-troubleshooting.md
│   ├── node-reachability-checks.md
│   └── runcluvfy-precheck-troubleshooting.md
├── rac-performance/
│   ├── oracle-rac-awr-analysis.md
│   ├── rac-wait-event-analysis.md
│   └── sql-performance-investigation.md
├── grid-infrastructure/
│   └── installation-prerequisites.md
└── scripts/
    └── README.md
```

Add files to these folders as the corresponding guides and scripts are
published. Do not create placeholder files that imply content exists
when it does not.

## How to Use This Repository

1.  Find the guide related to the issue you are investigating.
2.  Confirm that the commands and checks apply to your Oracle Database
    and Grid Infrastructure versions.
3.  Run diagnostic commands with the appropriate privileges.
4.  Capture the output and compare it with the expected behavior
    described in the guide.
5.  Validate configuration changes in a non-production environment
    whenever possible.
6.  Document the result and any environment-specific differences.

## Important Notes

-   Commands and examples are provided for learning and troubleshooting;
    validate them before running in production.
-   Some commands require `root`, `grid`, or `oracle` privileges. Use
    the least privilege required.
-   AWR and ADDM access may be subject to Oracle licensing and privilege
    requirements. Confirm the applicable entitlements for your
    environment.
-   Do not publish customer AWR reports, SQL text, SQL IDs, database or
    schema names, hostnames, IP addresses, credentials, wallet contents,
    or other confidential information.
-   Sanitize terminal output and screenshots before committing them to a
    public repository.
-   Always review the impact and rollback plan before making production
    changes.

## Contributions

Suggestions, corrections, and additional troubleshooting notes are
welcome. When contributing:

-   Include the Oracle Database / Grid Infrastructure version where
    relevant.
-   Explain the issue, diagnostic steps, and observed result.
-   Remove customer-specific and confidential information.
-   Clearly distinguish confirmed behavior from assumptions or
    environment-specific observations.

## Disclaimer

This repository is an independent technical knowledge-sharing project.
It is not an official Oracle publication and is not affiliated with or
endorsed by Oracle.

------------------------------------------------------------------------

**Maintainer:** Krishna Sai\
**Focus:** Oracle Database \| RAC \| Grid Infrastructure \| Clusterware
\| AWR \| Performance Troubleshooting
