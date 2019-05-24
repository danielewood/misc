## Create a FreeNAS/Samba Time Machine with cross-subnet/interVLAN support without the need for a mDNS Reflector/Repeater

Recently Samba and in turn FreeNAS have added support for a Samba share to act as a SMB based Time Machine Target for Apple devices. We had a need for allowing multiple users to backup to a Time Machine Target but didn’t want them to have to enable encryption with a password they may forget and not be able to recover. At the same time, we didn't want users to be able to restore/browse someone else's backups.

The solution we came up was to change the create file mask/umask to give effectively the equivalent of `umask 077` or `chmod 700` to all newly created files/folders on the share. Samba and ACLs means that attempting things like `force create mode` or `force directory mode` have no effect when using FreeNAS.

One requirement was that the backups be self-maintaining and non-conflicting of storage allocation. To accomplish this, we set per-client storage quotas in addition to any quotas for the total backup volume.

Another feature we wanted was the ability to backup when on a network that was routable to the backup target fileserver, but not in the same subnet/VLAN. We found that you do not need to rely on mDNS broadcasts and use an Avahi mDNS Reflector (which we tried at first, it does not work for Time Machine Backups). What you can do instead is use `tmutil` from the command line to manually specify a Time Machine Backup Disk. This is persistent across reboots and will allow backups even over a VPN.

### TL;DR of the goals and solutions

1. Time Machine over SMB, hosted on Samba/FreeNAS
1. Multiple, concurrent users that cannot see each other’s backups.
1. Per-Computer Time Machine quotas to prevent consuming the entire network share.
1. Cross-subnet/VLAN backups so that the FreeNAS server does not need an interface in every VLAN.
1. The option to use Time Machine over VPN, or to disable it.

### Create a SMB Time Machine Target

1. Create a Dataset for your Time Machine Backups

    ![Freenas Dataset](https://imgur.com/UX4sT5U.png)

1. Create a Windows SMB, Time Machine Enabled Share

    ![Windows SMB, Time Machine Enabled Share](https://imgur.com/QKZCjoF.png)

1. Change the default permissions for the dataset:

    Note: If you already have permissions how you want them and only need to inherit permissions without changing the permissions of the root share. Modify the existing group/everyone ACLs and remove fd (inherit for files, inherit for directories). Then apply the second `setfacl` statement from below to remove all group/owner permissions for newly created files (umask of 077).

    ```bash
    chown nobody:employees /mnt/tank/TimeMachine
    getfacl /mnt/tank/TimeMachine

    setfacl -m owner@:rwxpDdaARWcCos:fd:allow,group@:rwxpDdaARWcCos::allow,everyone@:::allow /mnt/tank/TimeMachine
    setfacl -a 0 group@::fdi:allow,everyone@::fdi:allow /mnt/tank/TimeMachine
    ```

    If you followed the above script, your result should look like this:

    ```shell
    [root@FreeNAS ~]# getfacl /mnt/tank/TimeMachine
    # file: /mnt/tank/TimeMachine
    # owner: nobody
    # group: employees
               group@:--------------:fdi----:allow
            everyone@:--------------:fdi----:allow
               owner@:rwxpDdaARWcCos:fd-----:allow
               group@:rwxpDdaARWcCos:-------:allow
            everyone@:--------------:-------:allow
    ```

1. Set Per-Client Time Machine Quota

    Add the files to notify connecting Macs that this volume is Time Machine capable:

    ```bash
    touch /mnt/tank/TimeMachine/.com.apple.timemachine.supported
    ```

    Set a 600GB quota for each machine:

    ```bash
    cat <<'EOF' >> /mnt/tank/TimeMachine/.com.apple.TimeMachine.quota.plist
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
        <dict>
            <key>GlobalQuota</key>
            <integer>600000000000</integer>
        </dict>
    </plist>
    EOF
    ```

    Ensure that everyone can read the Time Machine configuration files:

    ```bash
    chmod 644 /mnt/tank/TimeMachine/.com.apple.*
    ```

    Set immutable bit on `.com.apple.*` to ensure they cannot be deleted or modified:

    ```bash
    chflags schg /mnt/tank/TimeMachine/.com.apple.*
    ```

### Connect to a SMB Time Machine Target on a different network

If your Time Machine Target and Client Machines will not always be on the same subnet, you can use `tmutil` to manually set a target. Then, as long as your Client has a route to the Target, your automatic backups will function. They will also function over VPN, which could be a good thing or a problem. For our organization, we added an Alias IP to the FreeNAS server and created a separate A-Record to point to it. This way, the same server can act as a fileserver to serve files to VPN clients as well as be a Time Machine Target. We did not want to consume our end-user's home/mobile upload bandwidth, so we blocked the Target's Alias IP at the firewall to prevent Time Machine from working over VPN.

1. Disconnect Time Machine Drives (Also useful if a user's password has been changed)

    ```bash
    DemoMac01:~ $ sudo tmutil removedestination `tmutil destinationinfo | grep -E '^ID' | head -n1 | awk -F' : ' '{print $2}'`
    ````

1. Map the Time Machine Service to the Share (Password will be saved across reboots)

    ```bash
    DemoMac01:~ $ sudo tmutil setdestination -a smb://username:password@TimeMachine.contoso.com/TimeMachine
    ```

1. Enable Automatic Backups

    ```bash
    DemoMac01:~ $ sudo tmutil enable
    ```

### End Result

- DemoMac01 (172.30.90/23) backing up to TimeMachine.Contoso.com (10.50.0.29/24):

    ![DemoMac01 backing up to TimeMachine.Contoso.com](https://imgur.com/J4lhjqG.png)

- Resulting File Permissions:

    ```shell
    root@FreeNAS:/mnt/tank/TimeMachine # ls -laho
    total 93
    drwxrwx---+  3 nobody    employees  uarch         7B May 14 22:09 .
    drwxrwxr-x+ 17 nobody    employees  uarch        18B May 14 17:54 ..
    -rwxrwxr-x+  1 root      wheel      uarch         0B May 14 17:54 .apple
    -r--r--r--   1 root      employees  schg,uarch  228B May 14 18:11 .com.apple.TimeMachine.quota.plist
    -r--r--r--   1 root      employees  schg,uarch    0B May 14 22:09 .com.apple.timemachine.supported
    -rwxrwxr-x+  1 root      wheel      uarch         0B May 14 17:55 .windows
    drwx------+  3 username  employees  uarch         9B May 14 22:12 DemoMac01.sparsebundle
    ````

### Additional Resources and References

- [ixsystems.com: Methods For Fine-Tuning Samba Permissions](https://www.ixsystems.com/community/threads/methods-for-fine-tuning-samba-permissions.50739/)
  - Reference for more details on modifying ACLs and how they work.
- [ixsystems.com: Set up Time Machine for multiple machines with OSX Server-Style Quotas](https://www.ixsystems.com/community/threads/how-to-set-up-time-machine-for-multiple-machines-with-osx-server-style-quotas.47173/)
- [cyberciti.biz: FreeBSD - How to write protect important file ( even root can NOT modify / delete file )](https://www.cyberciti.biz/tips/howto-write-protect-file-with-immutable-bit.html)
- [jamf.com: Time Machine Encryption](https://www.jamf.com/jamf-nation/discussions/7114/time-machine-encryption)
  - Use CocoaDialog to create Pop-Up, User Friendly Dialogs of `tmutil`
  - [cocoadialog.com: CocoaDialog Documentation](https://cocoadialog.com/v2/#)
  - [github.com: CocoaDialog Download](https://github.com/cocoadialog/cocoadialog/issues/108#issuecomment-396059785)
- [kirb.me: Using Linux or Windows as a Time Machine network server](https://kirb.me/2018/03/24/using-samba-as-a-time-machine-network-server.html)
- [east.fm: FreeNAS with SMB, AFP, and TimeMachine](https://east.fm/posts/freenas-smb-afp-timemachine/index.html)

### Notes for Linux Users with manual Samba Configs

- You must add the following to ***every*** share on the server if you do not use a dedicated hostname/IP for TimeMachine:
  - [samba.org: vfs_fruit — Enhanced OS X and Netatalk interoperability](https://www.samba.org/samba/docs/current/man-html/vfs_fruit.8.html)

  ```bash
  vfs objects = fruit streams_xattr
  fruit:resource = stream
  fruit:metadata = stream
    ```

Samba Config

```bash
[TimeMachine]
        aio write size = 0
        browseable = No
        path = "/mnt/tank/TimeMachine"
        read only = No
        veto files = /.snapshot/.windows/.mac/.zfs/
        vfs objects = zfs_space zfsacl fruit streams_xattr
        zfsacl:acesort = dontcare
        nfs4:chown = true
        nfs4:acedup = merge
        nfs4:mode = special
        fruit:volume_uuid = 4ac1e8c1-a7a2-4298-a06a-0fcdcac32100
        fruit:time machine = yes
        fruit:resource = stream
        fruit:metadata = stream
```
