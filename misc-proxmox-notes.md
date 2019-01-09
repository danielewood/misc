# Proxmox

### Create SNMP view for SNMP Fencing of downed hosts on a NetApp CN1610
1. Note: The NAE-1101/CN1610 only supports restricting a view to a single IP. I suggest you make your RW community a long random string, and restrict the Switch to the secured Management VLAN for all management functions.

```
configure
snmp-server view "PROXMOX" ifAlias.1 included
snmp-server view "PROXMOX" ifAlias.2 included
snmp-server view "PROXMOX" ifAlias.3 included
snmp-server view "PROXMOX" ifAlias.4 included
snmp-server view "PROXMOX" ifAlias.5 included
snmp-server view "PROXMOX" ifAlias.6 included
snmp-server view "PROXMOX" ifAdminStatus.1 included
snmp-server view "PROXMOX" ifAdminStatus.2 included
snmp-server view "PROXMOX" ifAdminStatus.3 included
snmp-server view "PROXMOX" ifAdminStatus.4 included
snmp-server view "PROXMOX" ifAdminStatus.5 included
snmp-server view "PROXMOX" ifAdminStatus.6 included
snmp-server community "PROXMOX_WGmCl!M8F4cH" rw view PROXMOX
snmp-server community "public" ro

# Checking from one of the authorized hosts:
snmpwalk -v 2c -c PROXMOX_community 10.50.220.111
```
