
# Oracle RAC Node Reachability Troubleshooting

## 1. Overview

Node-to-node connectivity is a critical prerequisite for Oracle
Grid Infrastructure and Oracle RAC environments.

All cluster nodes must have proper hostname resolution,
network connectivity and passwordless SSH access where
required by the installation procedure.

Network configuration issues can cause:

- Grid Infrastructure installation failures.
- CVU validation failures.
- Node communication problems.
- RAC node eviction.
- Private interconnect communication failures.
- Cluster synchronization issues.

This document provides a systematic approach to validating
node reachability in Oracle RAC environments.

## 2. Scope

The checks in this document cover:

- Public network connectivity.
- Private interconnect connectivity.
- Hostname and DNS resolution.
- /etc/hosts validation.
- SSH connectivity.
- Network interface status.
- Routing configuration.
- MTU consistency.
- Cluster Verification Utility (CVU) validation.

## 3. Prerequisites

Before performing the checks, collect the following information:

| Parameter | Node 1 | Node 2 |
|---|---|---|
| Hostname | node1 | node2 |
| Public IP | 192.0.2.11 | 192.0.2.12 |
| Private IP | 198.51.100.11 | 198.51.100.12 |
| Public interface | ens192 | ens192 |
| Private interface | ens224 | ens224 |

Note: All IP addresses above are documentation examples.
Replace them with the actual environment values.

## 4. Hostname Validation

Execute on each node:

```bash
hostname
hostname -s
hostname -f
uname -n
```

Verify:

- Short hostname is correct.
- Fully qualified domain name is correct.
- Hostname matches the intended cluster configuration.
- Both nodes resolve each other's names correctly.

## 5. DNS Resolution

Check DNS resolution from each node.

```bash
getent hosts node1
getent hosts node2
```

Check forward lookup:

```bash
nslookup node1.example.com
nslookup node2.example.com
```

Check reverse lookup:

```bash
nslookup 192.0.2.11
nslookup 192.0.2.12
```

Expected result:

- Correct IP address returned.
- Correct hostname returned for reverse lookup.
- No unexpected DNS records.
- Consistent resolution from all cluster nodes.

If DNS resolution fails, verify:

```bash
cat /etc/resolv.conf
```

Also verify the configured DNS servers and search domains.

## 6. /etc/hosts Validation

Review the hosts file on all nodes:

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

Important:

- Use the actual public and private addresses.
- Avoid duplicate hostname mappings.
- Ensure mappings are consistent on every node.
- Do not map public hostnames to private IP addresses.
- Follow the Oracle Grid Infrastructure release-specific
  requirements for SCAN and VIP name resolution.

Do not manually create incorrect VIP or SCAN mappings.

## 7. Public Network Connectivity

From node1:

```bash
ping -c 4 node2
ping -c 4 192.0.2.12
```

From node2:

```bash
ping -c 4 node1
ping -c 4 192.0.2.11
```

Verify the route:

```bash
ip route get 192.0.2.12
ip route get 192.0.2.11
```

Check interface configuration:

```bash
ip addr show
```

Expected result:

- Correct public IP configured.
- Interface is UP.
- Routing is correct.
- No unexpected packet loss.

Note: Ping failure alone does not prove that RAC connectivity
is unavailable. ICMP may be blocked by network policy.

## 8. Private Interconnect Connectivity

The private interconnect is used for RAC cluster communication.

From node1:

```bash
ping -c 4 198.51.100.12
```

From node2:

```bash
ping -c 4 198.51.100.11
```

Check private interface:

```bash
ip addr show
ip route show
```

Check the route to the remote private address:

```bash
ip route get 198.51.100.12
```

Verify:

- Private addresses are assigned correctly.
- Both nodes use the intended private network.
- Routing is consistent.
- No unexpected firewall or network filtering exists.
- Network interfaces are operational.

Important:

A successful ping does not prove that all required
RAC interconnect communication is working.

Validate the actual interconnect using supported Oracle
diagnostic tools and network monitoring.

## 9. Network Interface and MTU Validation

List network interfaces:

```bash
ip link show
```

Check interface details:

```bash
ip -d link show
```

Check MTU:

```bash
ip link show ens224
```

Example output:

```text
mtu 9000
```

If jumbo frames are configured, validate MTU consistency
across the complete network path, including switches and
other network devices.

Test a jumbo frame where supported:

```bash
ping -M do -s 8972 -c 4 198.51.100.12
```

For an IPv4 network, a 8972-byte ICMP payload plus
28 bytes of IP and ICMP headers requires an MTU of 9000.

For standard MTU 1500, test:

```bash
ping -M do -s 1472 -c 4 198.51.100.12
```

Do not change MTU during production troubleshooting
without an approved change plan.

## 10. SSH Passwordless Connectivity

Verify SSH connectivity between cluster nodes using the
appropriate installation account.

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

Check SSH service status:

```bash
systemctl status sshd
```

Review SSH configuration:

```bash
grep -E 'PubkeyAuthentication|PasswordAuthentication|PermitRootLogin' \
/etc/ssh/sshd_config
```

Check authorized keys and permissions:

```bash
ls -ld ~/.ssh
ls -l ~/.ssh/authorized_keys
```

Recommended permissions:

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

Important:

Do not enable root passwordless SSH or weaken SSH security
without reviewing the applicable Oracle installation
requirements and organizational security policy.

For detailed SSH troubleshooting, use:

```bash
ssh -vvv node2 hostname
```

## 11. Firewall and Network Policy

Check the local firewall:

```bash
systemctl status firewalld
```

Check firewall rules:

```bash
firewall-cmd --list-all
```

For environments using nftables:

```bash
nft list ruleset
```

Do not disable the firewall as a troubleshooting shortcut.

Verify required Oracle Grid Infrastructure and RAC ports
against the documentation for the installed release and
the organization's network security policy.

## 12. Cluster Verification Utility (CVU)

Run the Grid Infrastructure pre-installation validation
from the Grid Infrastructure installation media.

Example:

```bash
./runcluvfy.sh stage -pre crsinst \
-n node1,node2 -verbose
```

For a more targeted network validation, use the
appropriate CVU command and options supported by your
Grid Infrastructure release.

Example:

```bash
./runcluvfy.sh comp nodecon \
-n node1,node2 -verbose
```

Review the CVU output for:

- Node reachability.
- Hostname resolution.
- Network interface configuration.
- SSH connectivity.
- User equivalence.
- Network configuration consistency.

Always check the exact CVU syntax supported by the
installed Grid Infrastructure release.

## 13. Common Troubleshooting Scenarios

### Scenario 1: PRVG-11097 / Node Reachability Failure

Possible causes:

- Hostname resolution failure.
- Incorrect /etc/hosts entries.
- Firewall restrictions.
- Incorrect routing.
- Network interface down.
- Missing connectivity between nodes.

Troubleshooting:

1. Verify hostname resolution.
2. Validate public and private IP addresses.
3. Check routing on both nodes.
4. Check firewall and network policies.
5. Validate SSH connectivity.
6. Re-run CVU validation.

### Scenario 2: Passwordless SSH Failure

Possible causes:

- Incorrect authorized_keys.
- Incorrect file permissions.
- Public key authentication disabled.
- SSH configuration differences.
- Incompatible or restricted SSH algorithms.
- Account-level security restrictions.

Troubleshooting:

1. Check SSH service.
2. Validate key permissions.
3. Run ssh -vvv.
4. Review SSH server logs.
5. Compare SSH client/server configuration.

Do not globally enable deprecated SSH algorithms
without a security review.

### Scenario 3: Private Interconnect Communication Failure

Possible causes:

- Incorrect private IP mapping.
- Interface failure.
- MTU mismatch.
- Network route issue.
- VLAN or switch configuration issue.
- Packet loss.

Troubleshooting:

1. Check private interface status.
2. Validate node-to-node private connectivity.
3. Check MTU consistency.
4. Verify routes and network paths.
5. Review operating system and Oracle diagnostics.

### Scenario 4: Name Resolution Inconsistency

Possible causes:

- Different /etc/hosts files.
- Incorrect DNS records.
- Duplicate hostname entries.
- Incorrect DNS search domains.
- Stale resolver configuration.

Troubleshooting:

1. Compare /etc/hosts across nodes.
2. Check forward and reverse resolution.
3. Verify DNS server configuration.
4. Check SCAN and VIP name resolution separately.

## 14. Final Validation Checklist

| Check | Expected Result |
|---|---|
| Hostname | Correct on all nodes |
| FQDN | Correct and consistent |
| DNS forward lookup | Successful |
| DNS reverse lookup | Correct |
| /etc/hosts | Consistent |
| Public connectivity | Validated |
| Private connectivity | Validated |
| Network interface | UP |
| Routing | Correct |
| MTU | Consistent end-to-end |
| SSH connectivity | Successful |
| Firewall policy | Required traffic permitted |
| CVU validation | No unresolved failures |

## 15. Best Practices

- Validate both directions of node communication.
- Keep hostname and IP mappings consistent.
- Maintain separate public and private network paths
  according to the supported RAC architecture.
- Validate MTU end-to-end before deploying jumbo frames.
- Use CVU before installation and after network changes.
- Avoid making unapproved firewall or network changes.
- Preserve diagnostic outputs for future comparison.
- Follow the Oracle documentation for the specific
  Grid Infrastructure release.

## 16. References

- Oracle Grid Infrastructure Installation Guide:
  https://docs.oracle.com/en/database/oracle/oracle-database/
- Oracle Cluster Verification Utility documentation:
  https://docs.oracle.com/en/database/oracle/oracle-database/

Note: Refer to the documentation for your exact Oracle
release and operating system.
