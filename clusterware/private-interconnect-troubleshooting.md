
# Oracle RAC Private Interconnect Troubleshooting Guide

## 1. Overview

The Oracle RAC private interconnect is used for communication between database instances running on different cluster nodes.

It supports Cache Fusion, Global Cache Services (GCS), Global Enqueue Services (GES), and other cluster communication activities.

Private interconnect problems can cause:

- Global Cache waits
- Increased database response time
- Cluster communication failures
- CSS heartbeat issues
- Node eviction
- RAC instance instability

This guide provides practical checks for investigating private interconnect issues in Oracle RAC environments.

---

## 2. Identify the Private Interconnect Configuration

Connect to the database:

```sql
SELECT inst_id,
       name,
       ip_address,
       is_public,
       source
FROM gv$cluster_interconnects
ORDER BY inst_id, name;
```

Check the network interfaces on each RAC node:

```bash
ip addr
```

Check routing:

```bash
ip route
```

Check interface details:

```bash
ip link show
```

Verify that the expected private network interfaces are configured and available on all nodes.

---

## 3. Validate RAC Interconnect Configuration

Check the interconnect information:

```sql
SELECT inst_id,
       name,
       ip_address,
       is_public,
       source
FROM gv$cluster_interconnects
ORDER BY inst_id;
```

Check the RAC interconnect-related initialization parameters:

```sql
SHOW PARAMETER cluster_interconnects;
SHOW PARAMETER cluster_interconnects;
```

Review the configured private interface and compare it with the actual network configuration.

**Note:** Do not change the `CLUSTER_INTERCONNECTS` parameter without understanding the existing configuration and Oracle-supported requirements.

---

## 4. Check Network Connectivity Between Nodes

From each RAC node, test connectivity to the private IP addresses of the other nodes.

```bash
ping <PEER_PRIVATE_IP>
```

Check the network path:

```bash
ip route get <PEER_PRIVATE_IP>
```

Check packet loss and latency:

```bash
ping -c 20 <PEER_PRIVATE_IP>
```

Validate connectivity in both directions.

Successful ping responses alone do not prove that the RAC interconnect is healthy. Also investigate packet drops, latency, interface errors, and switch-level issues.

---

## 5. Validate MTU Configuration

Check the MTU configured on each private interface:

```bash
ip link show
```

Example output:

```text
eth1: mtu 9000
```

For an MTU of 9000, test jumbo-frame connectivity:

```bash
ping -M do -s 8972 -c 5 <PEER_PRIVATE_IP>
```

For an MTU of 1500, test:

```bash
ping -M do -s 1472 -c 5 <PEER_PRIVATE_IP>
```

The payload sizes above account for the IPv4 and ICMP headers.

Validate MTU consistency across:

- RAC node network interfaces
- VLAN configuration
- Switch ports
- Network bonding configuration
- Intermediate network devices

Do not change MTU in production without validating the complete network path and obtaining change approval.

---

## 6. Check Network Interface Errors and Packet Drops

Run the following command:

```bash
ip -s link
```

Review:

- RX errors
- TX errors
- Dropped packets
- Interface state
- Packet counters

Check interface statistics:

```bash
ethtool <INTERFACE_NAME>
```

Check driver statistics where supported:

```bash
ethtool -S <INTERFACE_NAME>
```

Investigate:

- Network interface resets
- CRC errors
- Packet drops
- Link flaps
- Driver errors
- Speed or duplex mismatch

Correlate interface errors with the database and Clusterware incident timestamps.

---

## 7. Check Bonding Configuration

If network bonding is configured, check:

```bash
cat /proc/net/bonding/bond0
```

Review:

- Bonding mode
- Active slave
- Slave interface status
- Link failure count
- MII status
- Link monitoring configuration

Check interface status:

```bash
ip link show
```

Investigate bonding failures and switch-side configuration mismatches.

Do not change bonding configuration without coordinating with the network team.

---

## 8. Investigate RAC Global Cache Wait Events

Private interconnect problems may contribute to increased Global Cache wait events.

Check current system wait statistics:

```sql
SELECT inst_id,
       event,
       total_waits,
       time_waited_micro
FROM gv$system_event
WHERE event LIKE 'gc%'
ORDER BY time_waited_micro DESC;
```

Review important Global Cache events, including:

- gc cr block 2-way
- gc cr block 3-way
- gc current block 2-way
- gc current block 3-way
- gc buffer busy acquire
- gc buffer busy release

Event names and availability can vary by Oracle release.

Do not assume that every Global Cache wait indicates an interconnect problem. High wait times can also result from workload patterns, block contention, CPU scheduling, and storage activity.

---

## 9. Identify SQL Workloads Associated with Global Cache Waits

Review active sessions:

```sql
SELECT inst_id,
       sid,
       serial#,
       username,
       event,
       wait_class,
       sql_id,
       blocking_session
FROM gv$session
WHERE wait_class = 'Cluster'
ORDER BY inst_id, sid;
```

Review SQL statistics:

```sql
SELECT inst_id,
       sql_id,
       executions,
       buffer_gets,
       disk_reads,
       elapsed_time,
       cpu_time
FROM gv$sql
WHERE sql_id IS NOT NULL
ORDER BY elapsed_time DESC;
```

Investigate:

- SQL statements accessing heavily contended blocks
- Concurrent updates to the same objects
- Hot index blocks
- Application workload distribution
- Service placement across RAC instances

Correlate SQL-level findings with the Global Cache wait events.

---

## 10. Check RAC Interconnect Traffic

Where supported, use operating-system monitoring tools to inspect network traffic.

Check interface statistics:

```bash
ip -s link
```

Monitor interface traffic:

```bash
sar -n DEV 5 5
```

Monitor TCP statistics where relevant:

```bash
sar -n TCP,ETCP 5 5
```

For Exadata environments, investigate the relevant database server and storage cell network metrics using supported Exadata monitoring tools.

Consider:

- Network throughput
- Packet drops
- Interface utilization
- Network latency
- Switch congestion
- Network driver performance

---

## 11. Review Clusterware Logs

If interconnect problems are associated with node eviction or cluster communication errors, inspect Grid Infrastructure diagnostics.

Open ADRCI:

```bash
adrci
```

List diagnostic homes:

```text
show homes
```

Select the appropriate Grid Infrastructure diagnostic home:

```text
set home <GI_ADR_HOME>
```

Review recent alert messages:

```text
show alert -tail 200
```

Investigate:

- CSS heartbeat communication errors
- Node membership changes
- Network communication failures
- Cluster reconfiguration
- Node eviction messages

Correlate the timestamps with operating-system and network logs.

---

## 12. Common Troubleshooting Scenarios

### Scenario 1: Packet loss on private interconnect

Investigate:

- Interface error counters
- Network driver errors
- Switch port statistics
- VLAN configuration
- Bonding configuration
- Network congestion

### Scenario 2: MTU mismatch

Investigate:

- Interface MTU on every RAC node
- Switch port MTU
- VLAN MTU
- Intermediate network devices
- Jumbo-frame connectivity

Ensure that the entire network path supports the configured MTU.

### Scenario 3: High Global Cache waits

Investigate:

- SQL workload
- Block contention
- Hot objects
- RAC instance workload distribution
- CPU utilization
- Interconnect latency and throughput

Do not attribute all Global Cache waits to network problems.

### Scenario 4: Node eviction related to network failure

Investigate:

- CSSD logs
- Clusterware alert logs
- Network interface failures
- Packet drops
- Switch logs
- Interconnect connectivity

Identify the earliest failure event before implementing a corrective action.

---

## 13. Pre-change Checklist

- [ ] Identify the private interconnect interfaces.
- [ ] Verify private IP configuration on all nodes.
- [ ] Check network routes.
- [ ] Validate MTU consistency.
- [ ] Check interface errors and packet drops.
- [ ] Review bonding configuration.
- [ ] Check Global Cache wait events.
- [ ] Review CSSD and Clusterware logs.
- [ ] Capture network performance baseline.
- [ ] Obtain change approval before network modifications.

## 14. Post-change Checklist

- [ ] Confirm private interfaces are operational.
- [ ] Validate node-to-node connectivity.
- [ ] Confirm MTU consistency.
- [ ] Verify packet drops and interface errors.
- [ ] Validate RAC interconnect configuration.
- [ ] Review Global Cache wait events.
- [ ] Check Clusterware health.
- [ ] Confirm database instance availability.
- [ ] Monitor application performance.
- [ ] Document the changes and results.

---

## 15. Important Safety Notes

- Do not change the RAC private interconnect configuration without understanding the existing network architecture.
- Do not modify MTU or bonding settings without coordinating with the network team.
- Do not assume high Global Cache waits always indicate network failure.
- Avoid changing `CLUSTER_INTERCONNECTS` without validating Oracle-supported configuration requirements.
- Collect diagnostics before restarting network interfaces or Clusterware.
- Follow Oracle Support guidance for production RAC communication failures.

---

## 16. References

- Oracle Database Reference
- Oracle Database Performance Tuning Guide
- Oracle Clusterware Administration and Deployment Guide
- Oracle Grid Infrastructure documentation
- Oracle Exadata documentation, where applicable

**Disclaimer:** Validate commands and configuration changes against the installed Oracle Database, Grid Infrastructure, and operating-system versions before production use.
