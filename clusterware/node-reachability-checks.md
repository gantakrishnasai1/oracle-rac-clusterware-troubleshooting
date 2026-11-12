# RAC Node Reachability Checklist

Use this checklist when Cluster Verification Utility reports node reachability or name-resolution failures.

## 1. Verify identity on every node

```bash
hostname
hostname -s
hostname -f
uname -n
```

Expected: each node reports its intended short hostname and fully qualified hostname consistently.

## 2. Verify forward name resolution

```bash
getent hosts <node1_short_name>
getent hosts <node1_fqdn>
getent hosts <node2_short_name>
getent hosts <node2_fqdn>
```

Repeat from every node. Confirm the returned address is the intended public or private address for the check being performed.

## 3. Inspect host configuration

```bash
cat /etc/hosts
cat /etc/resolv.conf
```

Check for:
- Missing peer-node entries.
- Typographical errors.
- Duplicate or conflicting mappings.
- Incorrect interface-to-name mappings.
- Inconsistent DNS search domains.

Do not blindly copy an `/etc/hosts` file between servers; verify each address and interface mapping.

## 4. Test network path

```bash
ip addr
ip route
ping -c 3 <peer_private_address>
```

Where permitted, validate the required ports and firewall rules against the Oracle installation documentation and local security policy. ICMP success alone does not prove all required Clusterware communication paths are working.

## 5. Validate SSH

As the installation owner, test the exact node-to-node direction required by the installation procedure:

```bash
ssh <peer_node> hostname
```

If SSH fails, check DNS, routing, account access, authorized keys, permissions, SSH daemon policy, and client/server logs. Do not weaken SSH security globally as a workaround.

## 6. Re-run CVU

Use the `runcluvfy.sh` shipped with the intended Grid Infrastructure installation media or home. Example syntax; adapt node names and options to the release:

```bash
./runcluvfy.sh stage -pre crsinst -n <node1>,<node2> -verbose
```

Review the complete CVU output and fix the reported root cause. Do not assume `-fixup` can safely resolve every failure.

## Evidence template

| Check | Node 1 | Node 2 |
|---|---|---|
| Short hostname | | |
| FQDN | | |
| Peer short-name resolution | | |
| Peer FQDN resolution | | |
| Private address reachability | | |
| SSH to peer | | |
| CVU result | | |
