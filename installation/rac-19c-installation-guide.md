
# Oracle RAC 19c Installation Guide – Linux

## 1. Overview

Oracle Real Application Clusters (RAC) allows multiple database instances running on different servers to access a shared database.

This guide describes a structured installation workflow for a two-node Oracle RAC 19c environment using Oracle Grid Infrastructure and Oracle Database software.

The major installation phases are:

1. Server and operating-system preparation
2. Network configuration
3. Shared storage configuration
4. Grid Infrastructure prerequisites
5. Grid Infrastructure installation
6. ASM configuration
7. Oracle Database software installation
8. RAC database creation
9. Post-installation validation

**Note:** This is a general installation reference. Exact package requirements, kernel parameters, storage configuration, and installation procedures depend on the Oracle Database 19c Release Update, operating-system release, and certified platform.

---

## 2. Example Environment

The following is an illustrative two-node configuration.

| Component | Node 1 | Node 2 |
|---|---|---|
| Hostname | racnode1 | racnode2 |
| Public IP | 192.0.2.101 | 192.0.2.102 |
| Private IP | 198.51.100.101 | 198.51.100.102 |
| Virtual IP | 192.0.2.111 | 192.0.2.112 |
| SCAN | rac-scan.example.com | Shared SCAN name |
| Grid user | grid | grid |
| Oracle user | oracle | oracle |

Example software versions:

- Oracle Grid Infrastructure 19c
- Oracle Database 19c
- Linux operating system certified for the selected 19c RU

The IP addresses and hostnames are documentation examples. Replace them with the actual values in your environment.

---

## 3. Server Prerequisites

Validate the following on both nodes:

- CPU and memory meet Oracle requirements.
- Operating-system release is certified.
- Required packages are installed.
- Kernel parameters are configured.
- User and group configuration is consistent.
- Shared storage is accessible.
- Public and private network interfaces are configured.
- Time synchronization is operational.
- DNS or `/etc/hosts` resolution is consistent.

Check operating-system version:

```bash
cat /etc/os-release
```

Check kernel version:

```bash
uname -r
```

Check CPU information:

```bash
lscpu
```

Check memory:

```bash
free -h
```

Check filesystem capacity:

```bash
df -h
```

Check inode usage:

```bash
df -i
```

---

## 4. Hostname and Network Configuration

Verify hostname:

```bash
hostname
hostname -f
```

Review hostname resolution:

```bash
getent hosts racnode1
getent hosts racnode2
getent hosts racnode1-vip
getent hosts racnode2-vip
getent hosts rac-scan.example.com
```

Check network interfaces:

```bash
ip addr
```

Check routing:

```bash
ip route
```

Validate public and private connectivity between both nodes.

Example `/etc/hosts` entries, only when using a hosts-file-based configuration:

```text
192.0.2.101       racnode1.example.com racnode1
192.0.2.102       racnode2.example.com racnode2
192.0.2.111       racnode1-vip.example.com racnode1-vip
192.0.2.112       racnode2-vip.example.com racnode2-vip
198.51.100.101    racnode1-priv.example.com racnode1-priv
198.51.100.102    racnode2-priv.example.com racnode2-priv
```

SCAN name resolution should be configured using the appropriate DNS architecture. A SCAN hostname normally resolves to three IP addresses for a standard production RAC deployment.

Do not configure SCAN as a substitute for the required public and VIP resolution.

---

## 5. User and Group Configuration

Create the required Oracle groups according to the selected installation design.

Common groups include:

- oinstall
- dba
- oper
- asmadmin
- asmdba
- asmoper

Example group creation:

```bash
groupadd oinstall
groupadd dba
groupadd oper
groupadd asmadmin
groupadd asmdba
groupadd asmoper
```

Create the Grid user:

```bash
useradd -g oinstall \
        -G asmadmin,asmdba,asmoper,dba \
        grid
```

Create the Oracle user:

```bash
useradd -g oinstall \
        -G dba,oper,asmdba \
        oracle
```

Set passwords using your organization's password policy:

```bash
passwd grid
passwd oracle
```

**Important:** Confirm group membership and user separation against the selected Oracle installation design. Do not blindly recreate users or groups on an existing server.

---

## 6. Directory Structure

Example directory structure:

```bash
mkdir -p /u01/app/19.0.0/grid
mkdir -p /u01/app/grid
mkdir -p /u01/app/oracle
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
```

Set ownership:

```bash
chown -R grid:oinstall /u01/app/19.0.0
chown -R grid:oinstall /u01/app/grid
chown -R oracle:oinstall /u01/app/oracle
```

Set directory ownership and permissions according to the Oracle installation plan.

**Important:** Do not apply recursive permissions such as `chmod -R 775` to the entire `/u01/app` directory. This may change permissions on Oracle software, Grid Infrastructure files, and other directories unexpectedly.

Validate the required ownership and permissions before running the installers.

---

## 7. Operating-System Prerequisites

Use the Oracle Linux or platform-specific installation documentation for the exact package and kernel requirements.

For Oracle Linux, the Oracle Database preinstallation RPM may help configure supported prerequisites.

Example package installation:

```bash
dnf install oracle-database-preinstall-19c
```

**Important:** Confirm that this package and version are applicable to the exact operating-system release and Oracle 19c installation. It does not replace every Grid Infrastructure prerequisite.

Check installed packages:

```bash
rpm -qa | sort
```

Check kernel parameters:

```bash
sysctl -a
```

Review the relevant settings against Oracle documentation.

Do not blindly apply generic `sysctl.conf` values from another Linux release.

---

## 8. SSH Passwordless Connectivity

Configure SSH equivalence between the Grid users on both nodes.

As the Grid user:

```bash
su - grid
```

Generate an SSH key if one does not already exist:

```bash
ssh-keygen -t rsa
```

Configure authorized keys on both nodes using your organization's approved procedure.

Test connectivity:

```bash
ssh racnode1 date
ssh racnode2 date
```

Test SSH in both directions.

Repeat the validation for the Oracle user if required by the installation workflow.

Check:

- Hostname resolution
- SSH connectivity
- User permissions
- Authorized keys
- SSH directory permissions
- OpenSSH compatibility

Do not weaken SSH security settings without validating Oracle certification and organizational security requirements.

---

## 9. Shared Storage and ASM Prerequisites

RAC requires shared storage accessible to the participating nodes.

Validate storage presentation:

```bash
lsblk
```

Check persistent device paths:

```bash
ls -l /dev/disk/by-id/
```

Check multipath configuration, where applicable:

```bash
multipath -ll
```

Confirm that:

- All intended ASM devices are visible on both nodes.
- Device identities are consistent.
- Multipath configuration is correct.
- Permissions and ownership are consistent.
- Storage redundancy is understood.
- Devices are not accidentally reused from another disk group.

Use Oracle ASM Filter Driver or ASMLib only when appropriate for the selected platform and architecture.

Do not format or partition shared devices without an approved storage design.

---

## 10. Grid Infrastructure Pre-installation Validation

Locate the Grid Infrastructure installation media and extract it into the planned Grid home.

Example:

```bash
mkdir -p /u01/app/19.0.0/grid
```

Run CVU prerequisite checks using the installation media's `runcluvfy.sh`:

```bash
./runcluvfy.sh stage -pre crsinst \
  -n racnode1,racnode2 \
  -verbose
```

Review all reported failures and warnings.

Check node connectivity:

```bash
./runcluvfy.sh comp nodecon \
  -n racnode1,racnode2 \
  -verbose
```

Check installation prerequisites:

```bash
./runcluvfy.sh stage -pre crsinst \
  -n racnode1,racnode2 \
  -verbose
```

Resolve prerequisite failures before continuing.

**Note:** CVU options and checks can vary by release and platform. Review the `runcluvfy.sh -help` output for the exact installation media.

---

## 11. Grid Infrastructure Installation

Start the Grid Infrastructure installer as the Grid user.

```bash
cd /u01/app/19.0.0/grid
./gridSetup.sh
```

Follow the installer workflow.

Typical configuration activities include:

1. Select Configure Oracle Grid Infrastructure for a New Cluster.
2. Configure cluster name and SCAN.
3. Add all RAC nodes.
4. Configure public and private network interfaces.
5. Select the appropriate ASM storage configuration.
6. Configure ASM disk groups.
7. Configure Grid Infrastructure management settings.
8. Review prerequisite checks.
9. Execute root scripts when prompted.

Run the required root scripts on the specified nodes in the order instructed by the installer.

Do not run root scripts manually before the installer requests them.

---

## 12. Validate Grid Infrastructure Installation

Check CRS:

```bash
crsctl check cluster -all
```

Check cluster resources:

```bash
crsctl stat res -t
```

Check node membership:

```bash
olsnodes -n -s
```

Check voting disks:

```bash
crsctl query css votedisk
```

Check OCR:

```bash
ocrcheck
```

Check ASM:

```bash
srvctl status asm
```

Check ASM disk groups:

```bash
asmcmd lsdg
```

Verify that the cluster is stable before installing the database software.

---

## 13. Oracle Database Software Installation

Prepare the Oracle Database home.

Example:

```bash
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
chown -R oracle:oinstall /u01/app/oracle/product
```

Extract the Oracle Database 19c installation image into the database home according to Oracle's image-based installation procedure.

Run the installer:

```bash
cd /u01/app/oracle/product/19.0.0/dbhome_1
./runInstaller
```

Select the RAC installation option and configure the appropriate cluster nodes.

Review all prerequisite checks.

Execute root scripts when prompted by the installer.

Apply the approved Oracle Database 19c Release Update using the applicable Oracle patching procedure.

---

## 14. Create the RAC Database

Use Database Configuration Assistant (DBCA):

```bash
dbca
```

Select the RAC database creation workflow.

Configure:

- Database name
- Database unique name
- Database type
- Node selection
- Instance configuration
- Storage location
- ASM disk group
- Database character set
- Memory configuration
- Listener and services
- Backup and recovery settings

Review all settings before creating the database.

For automated deployments, use the DBCA response file and validate its options against the installed DBCA version.

---

## 15. Post-installation RAC Validation

### Check database instances

```sql
SELECT inst_id,
       instance_name,
       host_name,
       status,
       database_status
FROM gv$instance
ORDER BY inst_id;
```

### Check database status

```sql
SELECT inst_id,
       name,
       open_mode,
       database_role
FROM gv$database
ORDER BY inst_id;
```

### Check database services

```bash
srvctl status service -db <DB_UNIQUE_NAME>
```

### Check database configuration

```bash
srvctl config database -db <DB_UNIQUE_NAME>
```

### Check listeners

```bash
srvctl status listener
```

### Check cluster resources

```bash
crsctl stat res -t
```

### Check ASM

```bash
asmcmd lsdg
```

Validate that the database instances and services are available on the intended nodes.

---

## 16. Installation Validation Checklist

### Server and OS

- [ ] OS version and kernel are certified.
- [ ] CPU and memory requirements are satisfied.
- [ ] Required packages are installed.
- [ ] Kernel parameters are validated.
- [ ] Time synchronization is configured.
- [ ] Filesystem capacity is sufficient.

### Network

- [ ] Public IP connectivity is working.
- [ ] Private interconnect connectivity is working.
- [ ] VIP resolution is correct.
- [ ] SCAN resolution is correct.
- [ ] MTU configuration is consistent.
- [ ] SSH connectivity is working.

### Storage

- [ ] Shared disks are visible on all nodes.
- [ ] Multipath configuration is validated.
- [ ] ASM devices are configured correctly.
- [ ] Disk permissions are consistent.
- [ ] Redundancy requirements are understood.

### Grid Infrastructure

- [ ] CVU prerequisite checks are successful.
- [ ] Grid Infrastructure installation is completed.
- [ ] CRS is healthy on all nodes.
- [ ] OCR is healthy.
- [ ] Voting disks are accessible.
- [ ] ASM disk groups are mounted.

### Database

- [ ] Oracle Database software is installed.
- [ ] Required Release Update is applied.
- [ ] RAC database creation is completed.
- [ ] All database instances are online.
- [ ] Database services are configured.
- [ ] Application connectivity is validated.

---

## 17. Common Installation Issues

| Issue | Investigation |
|---|---|
| PRVG-11097 | Review node connectivity and CVU diagnostics |
| PRVF-4083 | Validate node name resolution and network reachability |
| PRKN-1034 | Review the complete CVU error and underlying node communication failure |
| SSH equivalence failure | Check keys, permissions, host resolution, and SSH configuration |
| ASM disk discovery failure | Review disk discovery paths, device permissions, and storage visibility |
| Grid installation prerequisite failure | Review CVU output and OS certification requirements |
| SCAN resolution failure | Validate DNS configuration and SCAN records |
| VIP configuration failure | Review public network and VIP address availability |

Always investigate the complete error output rather than relying only on the error code.

---

## 18. Important Safety Notes

- Verify Oracle certification before installation.
- Use the correct Oracle 19c Release Update and installation media.
- Do not modify shared storage without approval.
- Do not format existing ASM devices.
- Do not ignore CVU prerequisite failures.
- Validate SSH configuration without compromising security.
- Maintain installation logs and configuration records.
- Follow Oracle documentation for the exact platform and release.

---

## 19. References

- Oracle Grid Infrastructure Installation and Upgrade Guide
- Oracle Database Installation Guide for Linux
- Oracle Real Application Clusters Administration and Deployment Guide
- Oracle Database Administrator's Guide
- Oracle Clusterware Administration and Deployment Guide
- Oracle Support documentation and relevant MOS notes

**Disclaimer:** This guide is a general installation reference. Always validate installation procedures, package requirements, and commands against the certified operating-system platform and exact Oracle 19c Release Update.
