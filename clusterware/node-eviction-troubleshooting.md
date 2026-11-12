# Oracle RAC Node Eviction Troubleshooting Guide

## 1. Overview

Oracle RAC node eviction occurs when Oracle Clusterware removes a node from cluster membership to protect cluster integrity.

Common causes or contributing factors include:

- Private interconnect failures
- CSS heartbeat communication issues
- Voting disk or storage access problems
- Operating-system hangs
- CPU or memory resource exhaustion
- Network latency or packet loss
- Storage I/O latency
- Clusterware-related failures

**Important:** Not every node reboot is a node eviction. Confirm the event using Clusterware diagnostics.

---

## 2. Initial Cluster Health Checks

Run the following commands using the appropriate Grid Infrastructure account.

### Check Clusterware status

```bash
crsctl check cluster -all
```

### Check CRS resources

```bash
crsctl stat res -t
```

### Check cluster nodes

```bash
olsnodes -n -s
```

### Check voting disks

```bash
crsctl query css votedisk
```

### Check OCR health

```bash
ocrcheck
```

### Check ASM status

```bash
srvctl status asm
```

---

## 3. Identify the Evicted Node and Incident Time

Collect:

- Affected node name
- Surviving cluster nodes
- Eviction timestamp
- Database instance status
- Clusterware restart status
- Application impact
- Recent infrastructure changes

Check uptime:

```bash
uptime
```

Check reboot history:

```bash
last reboot
```

Review operating-system logs:

```bash
journalctl --since "YYYY-MM-DD HH:MM:SS" \
           --until "YYYY-MM-DD HH:MM:SS"
```

Use the actual incident timestamps.

---

## 4. Investigate Cluster Synchronization Services (CSS)

Check CSS status:

```bash
crsctl check css
```

Review Clusterware resources:

```bash
crsctl stat res -t
```

Review the Grid Infrastructure alert log and CSSD trace files.

Using ADRCI:

```bash
adrci
```

Inside ADRCI:

```text
show homes
set home <GI_ADR_HOME>
show alert -tail 200
```

Investigate messages related to:

- CSS heartbeat failures
- Cluster membership changes
- Node eviction
- Voting disk access
- Network communication errors
- Cluster reconfiguration

Correlate messages across all RAC nodes.

---

## 5. Investigate Private Interconnect

Check network interfaces:

```bash
ip addr
```

Check routing:

```bash
ip route
```

Check interface errors:

```bash
ip -s link
```

Test peer-node connectivity:

```bash
ping <PEER_PRIVATE_IP>
```

Check MTU:

```bash
ip link show
```

Investigate:

- Packet loss
- Interface resets
- Switch port errors
- VLAN issues
- Network bonding failures
- MTU mismatch
- Network latency
- Interconnect saturation

**Note:** Successful ping tests do not guarantee that the RAC private interconnect is healthy.

---

## 6. Investigate Voting Disks and Storage

Check voting disks:

```bash
crsctl query css votedisk
```

Check ASM disk groups:

```bash
asmcmd lsdg
```

Check ASM disks:

```bash
asmcmd lsdsk -p
```

Check multipath status, where applicable:

```bash
multipath -ll
```

Investigate:

- Storage path failures
- Disk I/O errors
- ASM disk offline events
- Voting disk access failures
- Storage latency
- Disk group dismount events

Do not modify voting disks or ASM disk configurations during initial diagnosis.

---

## 7. Investigate Operating-System Issues

Check CPU and memory:

```bash
top
free -h
```

Check system activity:

```bash
vmstat 5 5
```

Check disk performance:

```bash
iostat -xz 5 5
```

Check filesystem usage:

```bash
df -h
df -i
```

Review kernel messages:

```bash
dmesg -T | tail -200
```

Review kernel journal:

```bash
journalctl -k --since "YYYY-MM-DD HH:MM:SS"
```

Look for:

- Out-of-memory events
- Kernel panics
- Hung processes
- CPU starvation
- Memory pressure
- I/O timeouts
- Network driver errors

---

## 8. Review Clusterware Diagnostic Logs

Important components include:

| Component | Purpose |
|---|---|
| CSSD | Cluster membership and synchronization |
| CRSD | Cluster resource management |
| OHASD | Oracle High Availability Services |
| EVMD | Cluster event management |

Use ADRCI to locate relevant diagnostic homes.

```bash
adrci
```

```text
show homes
```

Review the appropriate Grid Infrastructure diagnostic files.

Correlate timestamps from:

1. Evicted node
2. Surviving nodes
3. ASM instances
4. Database instances
5. Operating-system logs
6. Network infrastructure
7. Storage infrastructure

The earliest relevant failure may help identify the root cause.

---

## 9. Common Troubleshooting Scenarios

### Scenario 1: Private interconnect failure

Possible indicators:

- CSS communication errors
- Packet loss
- Network interface failures
- Switch or VLAN issues

Recommended investigation:

- Check private network interfaces.
- Review interface error counters.
- Verify routing and MTU.
- Review switch logs.
- Compare timestamps with CSS messages.

### Scenario 2: Voting disk or storage failure

Possible indicators:

- Voting disk access errors
- ASM I/O errors
- Storage path failures
- High storage latency

Recommended investigation:

- Review voting disk status.
- Check ASM disk status.
- Investigate storage connectivity.
- Review multipath logs.
- Correlate storage errors with eviction time.

### Scenario 3: Operating-system hang

Possible indicators:

- Kernel errors
- Hung tasks
- OOM events
- Unexpected reboot

Recommended investigation:

- Review system journal.
- Check kernel logs.
- Analyze historical CPU and memory metrics.
- Investigate OS or driver issues.

### Scenario 4: Clusterware communication failure

Possible indicators:

- CSS communication errors
- Membership reconfiguration
- CRS resource transitions

Recommended investigation:

- Collect CSSD and CRS logs.
- Compare events across nodes.
- Check network and storage health.
- Review recent GI changes.

---

## 10. Diagnostic Collection Checklist

| Area | Required information |
|---|---|
| Cluster | Cluster name and node names |
| Database | Database version and RAC configuration |
| Grid Infrastructure | GI version and patch level |
| Incident | Eviction timestamp |
| Clusterware | CRS and CSS logs |
| Voting disks | Voting disk configuration |
| ASM | Disk group and disk status |
| Network | Private interconnect errors |
| OS | Kernel and system logs |
| Application | Business impact |

Sanitize sensitive diagnostic information before sharing.

---

## 11. Pre-change Checklist

- [ ] Identify the affected node.
- [ ] Confirm the eviction timestamp.
- [ ] Collect CSSD and Clusterware logs.
- [ ] Check private interconnect health.
- [ ] Validate voting disk accessibility.
- [ ] Check ASM and storage status.
- [ ] Review operating-system logs.
- [ ] Investigate recent changes.
- [ ] Prepare an approved remediation plan.

## 12. Post-change Checklist

- [ ] Confirm all RAC nodes are online.
- [ ] Validate Clusterware resource status.
- [ ] Validate ASM instance status.
- [ ] Validate database instance status.
- [ ] Confirm private interconnect connectivity.
- [ ] Review alert logs.
- [ ] Monitor cluster stability.
- [ ] Confirm application availability.
- [ ] Document root cause and corrective actions.

---

## 13. Safety Notes

- Do not repeatedly restart Clusterware without collecting diagnostics.
- Do not modify voting disks without an approved recovery procedure.
- Do not delete diagnostic files before collecting evidence.
- Do not assume network failure is the root cause without validating other components.
- Avoid simultaneous infrastructure changes during troubleshooting.
- Follow Oracle Support guidance for critical production incidents.

---

## 14. References

- Oracle Clusterware Administration and Deployment Guide
- Oracle Grid Infrastructure Installation and Upgrade Guide
- Oracle Database Reference
- Oracle Support documentation and relevant MOS notes

**Disclaimer:** Validate all commands against the installed Oracle Grid Infrastructure release before using them in production.
