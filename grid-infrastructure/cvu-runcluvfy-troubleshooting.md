# CVU and runcluvfy Troubleshooting

## Purpose

Cluster Verification Utility (CVU) validates prerequisites and cluster configuration. Always use the CVU associated with the intended Oracle Grid Infrastructure release.

## Example pre-check

```bash
./runcluvfy.sh stage -pre crsinst -n <node1>,<node2> -verbose
```

## Common failure categories

### Node reachability / name resolution

- Confirm short hostname and FQDN on every node.
- Validate DNS and `/etc/hosts` consistency.
- Check private/public interface mappings.
- Verify routing and required network paths.

### SSH equivalence

- Test SSH from each node to the other using the correct installation owner.
- Check home directory and `.ssh` permissions.
- Review `authorized_keys`, SSH daemon policy, and authentication logs.
- Confirm the selected key and user are correct.

### Temporary filesystem

```bash
df -h /tmp
df -i /tmp
```

Check both free space and inode availability. Size requirements depend on the release and installation workflow; use the installation guide rather than a generic fixed value.

### User limits and packages

Check the exact limits and packages required by the Oracle installation documentation for the target release and OS. Do not apply unrelated parameter values from another platform.

## Remediation discipline

1. Save the full CVU output.
2. Identify the exact failed check and node.
3. Confirm the relevant Oracle documentation requirement.
4. Apply one approved change at a time.
5. Re-run the failed check.
6. Record before/after evidence.

`-fixup` may generate or apply supported corrections in some scenarios, but review its proposed changes and use it only under an approved procedure.
