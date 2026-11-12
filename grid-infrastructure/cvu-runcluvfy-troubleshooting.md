
# Oracle Grid Infrastructure CVU and runcluvfy Troubleshooting

## 1. Overview

Oracle Cluster Verification Utility (CVU) is used to validate
the configuration and readiness of servers before installing
Oracle Grid Infrastructure and Oracle RAC.

CVU checks various prerequisites, including:

- Node reachability.
- Hostname resolution.
- Network configuration.
- SSH user equivalence.
- Operating system requirements.
- Shared storage accessibility.
- Kernel parameters.
- Required packages.
- User and group configuration.
- Installation prerequisites.

CVU failures should be investigated and resolved before
proceeding with Grid Infrastructure installation.

This guide provides common CVU commands, troubleshooting
methods and validation procedures for Oracle RAC environments.

## 2. Scope

This document covers:

- CVU overview and execution.
- Grid Infrastructure installation pre-checks.
- Node connectivity validation.
- SSH user equivalence.
- Network and hostname validation.
- Operating system prerequisite failures.
- Shared storage validation.
- Common CVU errors.
- Post-correction validation.

## 3. Prerequisites

Before running CVU, collect:

| Parameter | Example |
|---|---|
| Oracle Grid Infrastructure version | 19c |
| Node 1 | node1 |
| Node 2 | node2 |
| Grid Infrastructure owner | grid |
| Grid Infrastructure Oracle Home | /u01/app/19.0.0/grid |
| Installation media | Grid Infrastructure software |

Use actual hostnames and paths from your environment.

Confirm the Grid Infrastructure installation media
is accessible and the required permissions are available.

## 4. Basic CVU Commands

Navigate to the Grid Infrastructure installation media.

Example:

```bash
cd /stage/grid
```

Check CVU help:

```bash
./runcluvfy.sh -help
```

Check the Grid Infrastructure installation prerequisites:

```bash
./runcluvfy.sh stage -pre crsinst \
-n node1,node2 -verbose
```

Use the release-specific CVU syntax provided by
the installation media.

## 5. Node Connectivity Validation

Check node connectivity:

```bash
./runcluvfy.sh comp nodecon \
-n node1,node2 -verbose
```

This validation helps identify issues related to:

- Node reachability.
- Network interface configuration.
- Hostname resolution.
- Node-to-node communication.

If the check fails, perform the following OS-level checks.

### 5.1 Hostname validation

Execute on both nodes:

```bash
hostname
hostname -s
hostname -f
```

Check hostname resolution:

```bash
getent hosts node1
getent hosts node2
```

Check DNS:

```bash
nslookup node1
nslookup node2
```

Verify that each node resolves the other node
to the expected IP address.

### 5.2 /etc/hosts validation

Review:

```bash
cat /etc/hosts
```

Example:

```text
192.0.2.11 node1.example.com node1
192.0.2.12 node2.example.com node2

198.51.100.11 node1-priv.example.com node1-priv
198.51.100.12 node2-priv.example.com node2-priv
```

Ensure:

- Entries are consistent across nodes.
- Public and private addresses are correct.
- There are no duplicate or conflicting mappings.
- SCAN and VIP resolution follows the supported
  configuration for the Oracle release.

The IP addresses above are documentation examples.

### 5.3 Network connectivity

From node1:

```bash
ping -c 4 node2
ping -c 4 198.51.100.12
```

From node2:

```bash
ping -c 4 node1
ping -c 4 198.51.100.11
```

Check routing:

```bash
ip route show
ip addr show
```

Note: ICMP may be blocked by network policy.
A failed ping alone does not establish that all
Oracle cluster communication is unavailable.

## 6. SSH User Equivalence Validation

Grid Infrastructure installation requires the
appropriate SSH connectivity between nodes.

From node1:

```bash
ssh node2 hostname
```

From node2:

```bash
ssh node1 hostname
```

Check SSH version:

```bash
ssh -V
```

Check the SSH service:

```bash
systemctl status sshd
```

Check SSH permissions:

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Recommended permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Perform detailed SSH troubleshooting:

```bash
ssh -vvv node2 hostname
```

Check SSH server logs using the appropriate
operating system logging mechanism.

Do not weaken SSH security or enable deprecated
algorithms globally without security approval.

## 7. Common CVU Errors and Troubleshooting

### 7.1 PRVG-11097 - Node Reachability Failure

Possible symptoms:

- CVU reports that nodes cannot be reached.
- Node reachability validation fails.
- Pre-installation validation cannot continue.

Possible causes:

- Incorrect hostname resolution.
- Missing or inconsistent /etc/hosts entries.
- Incorrect network routing.
- Firewall restrictions.
- Network interface failure.
- SSH or node communication problems.

Troubleshooting:

1. Check hostname resolution on all nodes.
2. Compare /etc/hosts entries.
3. Validate public and private IP addresses.
4. Check network interfaces.
5. Verify routing.
6. Test connectivity in both directions.
7. Validate SSH connectivity.
8. Review CVU detailed output.
9. Re-run node connectivity validation.

### 7.2 PRVF-4083 - Node Connectivity or Reachability Issue

Investigate the exact message and affected validation
component in the CVU output.

Possible areas to investigate:

- Node communication.
- Hostname resolution.
- Network configuration.
- SSH connectivity.
- Interface availability.

Troubleshooting:

1. Identify the affected node and network.
2. Validate DNS and /etc/hosts.
3. Check interface configuration.
4. Validate node-to-node communication.
5. Review CVU logs.
6. Re-run the affected prerequisite check.

The error number alone is not sufficient to determine
the root cause. Follow the complete CVU error message.

### 7.3 PRKN-1034 - Node Communication Failure

Investigate the full error text and the operation
that generated the failure.

Possible investigation areas:

- Node reachability.
- Hostname resolution.
- Network path.
- SSH connectivity.
- Operating system restrictions.

Troubleshooting:

1. Check the affected hostname.
2. Validate forward and reverse resolution.
3. Check network connectivity.
4. Validate SSH access.
5. Review operating system logs.
6. Review CVU diagnostic output.

Do not assume every PRKN-1034 occurrence has
the same underlying cause.

## 8. Operating System Prerequisite Checks

Review operating system information:

```bash
cat /etc/os-release
uname -a
uname -r
```

Check memory:

```bash
free -h
```

Check swap:

```bash
swapon --show
```

Check filesystem space:

```bash
df -h
```

Check temporary directory:

```bash
df -h /tmp
```

Check required package availability:

```bash
rpm -qa | sort
```

Check kernel parameters:

```bash
sysctl -a
```

Compare the actual configuration with the
requirements for the specific Oracle Grid Infrastructure
release and operating system.

Do not apply generic kernel parameter values without
checking the Oracle installation documentation.

## 9. Shared Storage Validation

For RAC configurations using shared storage,
validate that the required storage is accessible
from all cluster nodes.

Check device availability:

```bash
lsblk
```

Check multipath configuration where applicable:

```bash
multipath -ll
```

Check ASM disks:

```bash
asmcmd lsdsk -p
```

The ASM command requires the appropriate ASM
environment and permissions.

Review:

- Device visibility across nodes.
- Multipath consistency.
- Storage permissions.
- ASM disk discovery.
- Device ownership and group.
- Underlying storage connectivity.

Do not modify disk labels, partitions or ASM disk
headers as a troubleshooting shortcut.

## 10. Temporary Directory Validation

Grid Infrastructure installation requires adequate
temporary filesystem capacity.

Check:

```bash
df -h /tmp
```

Check inode utilization:

```bash
df -i /tmp
```

If /tmp does not have sufficient capacity:

1. Identify the current filesystem and mount.
2. Review the installation requirements.
3. Check available filesystem capacity.
4. Obtain the necessary change approval.
5. Increase capacity using the approved procedure.
6. Re-run CVU validation.

Do not delete files from /tmp without identifying
their ownership and usage.

## 11. CVU Log and Diagnostic Investigation

When a CVU check fails, preserve the complete output.

Review the CVU log files generated by the execution.

Common installation and CVU diagnostic locations
depend on the installation media and execution context.

Check the Grid Infrastructure installation
diagnostic logs and CVU output for:

- Exact failing component.
- Affected node.
- Reported error code.
- Failed command.
- Underlying operating system error.
- Suggested corrective action.

Use the complete error message rather than
relying only on the PRVG or PRVF error number.

## 12. Re-run CVU After Corrections

After resolving the identified issues, repeat
the affected validation.

Node connectivity:

```bash
./runcluvfy.sh comp nodecon \
-n node1,node2 -verbose
```

Grid Infrastructure installation prerequisites:

```bash
./runcluvfy.sh stage -pre crsinst \
-n node1,node2 -verbose
```

Review all remaining failures and warnings.

Do not proceed with installation while critical
prerequisites remain unresolved.

## 13. CVU Validation Checklist

| Validation | Expected Result |
|---|---|
| Hostname validation | Correct on all nodes |
| DNS resolution | Successful |
| /etc/hosts | Consistent |
| Public connectivity | Validated |
| Private connectivity | Validated |
| SSH user equivalence | Successful |
| Network interfaces | Correctly configured |
| Routing | Correct |
| MTU | Consistent where jumbo frames are used |
| Operating system | Supported |
| Required packages | Available |
| Memory and swap | Meet release requirements |
| /tmp space | Sufficient |
| Shared storage | Accessible |
| ASM disk discovery | Validated where applicable |
| CVU node connectivity | Successful |
| CVU installation pre-check | No unresolved critical failures |

## 14. Best Practices

- Run CVU before Grid Infrastructure installation.
- Use the CVU utility provided with the target
  Grid Infrastructure release.
- Validate connectivity from every cluster node.
- Resolve hostname and DNS inconsistencies first.
- Validate SSH using the intended installation owner.
- Verify shared storage on all nodes.
- Preserve CVU output for change records.
- Re-run validation after network or OS changes.
- Do not ignore critical CVU failures.
- Use Oracle-supported procedures for corrections.

## 15. References

Oracle Grid Infrastructure documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Oracle Cluster Verification Utility documentation:

https://docs.oracle.com/en/database/oracle/oracle-database/

Refer to the documentation corresponding to
the exact Grid Infrastructure release and platform.
