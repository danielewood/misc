## HDD Management/mapping/testing commands

### Find all sdX disk mappings
    find /dev/disk/ -type l -exec bash -c 'RL=`readlink -f {}`; echo $RL "{}"' \; | cut -c 6- | sort

### Use OpenSSL to rapidly generate incompressible data
    # 670MB/sec on a E5-2603 v1 @ 1.80GHz
    # 1.3GB/sec on a E5-2690 v2 @ 3.00GHz
    # 1.7GB/sec on a i7-3770 @ 3.40GHz
    dd bs=1M count=10000 iflag=fullblock status=progress of=/dev/null \
    if=<(openssl enc -aes-256-ctr -pass pass:"$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64)" -nosalt < /dev/zero) 

### Write 2GB of /tmp/test.file1 to /data over and over again with a unique filename each rotation
    while true; do dd if=/tmp/test.file1 of="/data/test`echo $(($(date +%s%N)/1000000))`" \
    bs=1M count=2000 status=progress; done

### Get HDD Temperature for all disks in /dev/disk/by-vdev/
    for x in `find /dev/disk/by-vdev/* ! -name '*part[0-9]' | sort`; \
    do hddtemp --quiet $x; done

### Find disks that failed any SMART test:
    for x in `find /dev/disk/by-vdev/* ! -name '*part[0-9]' | sort`; \
    do STATUS=`smartctl -l selftest $x | grep 'Completed: read failure'` && echo "Replace $x" ; done
    
### Get SMART Test Details
    for x in `find /dev/disk/by-vdev/* ! -name '*part[0-9]' | sort`; \
    do echo "$x "; smartctl -l selftest $x | grep -E 'Extended|Status'; done

### Get SMART Test Details (Current and last two tests)
    for x in `find /dev/disk/by-vdev/* ! -name '*part[0-9]' | sort`; \
    do echo $x; smartctl -a $x | grep -E '\%' | grep -vE 'by host|^\# [3-9]|# [1-9][0-9]' | sed -E 's/\t+/Current Test: /'; done
    
### Make netdata use ZFS's /dev/disk/by-vdev for available disk names
1. Edit /etc/netdata/netdata.conf, like this:
```
[plugin:proc:/proc/diskstats]
    path to /dev/disk/by-id = /dev/disk/by-vdev
    name disks by id = yes
```
    
2. Run: `systemctl restart netdata.service`

### crontab to log ZFS resilver/scrub activity to the systemd logger
    # Writes any scrubbing/resilvering status every minute to systemd logs, only triggers if $STATUS is not null
      *  *  *  *  * root STATUS=`zpool status data | sed 's/to go/to go,/' | grep -A1 'to go,$'` && echo zpool status data: $STATUS | systemd-cat -t zstatus
    
    # Display all zstatus entries with:
    # journalctl -t zstatus
    #
    # Expected Output:
    # Jan 05 16:18:01 localhost.localdomain zstatus[19366]: zpool status data: 32.6T scanned out of 67.5T at 1.27G/s, 7h49m to go, 0B repaired, 48.34% done
    # Jan 05 16:19:02 localhost.localdomain zstatus[27121]: zpool status data: 32.7T scanned out of 67.5T at 1.27G/s, 7h48m to go, 0B repaired, 48.45% done
### crontab syncoid task
    # Syncs datasets from SourceServer every day at 3pm.
    # The output redirect creates a per-line timestamped log file, useful to appending to any cron job to achieve the same function.
      0 15  *  *  * root /usr/local/bin/syncoid --recursive --no-sync-snap --debug --exclude 'dataset01\/\.system' root@SourceServer:dataset01 data | systemd-cat -t syncoid
    # Display all syncoid entries with:
    # journalctl -t syncoid
    
### misc crontab entries
    # Weekly mdadm array scrub (sends check command to all md devices)
      0  1  *  *  6 root find /sys/block/md*/md/sync_action -exec bash -c 'echo check > "{}"' \;

    # Weekly zfs array scrub
      0  1  *  *  6 root zpool scrub data

    # Weekly HDD SMART Extended Offline Scan (runs when drive is idle, so we dont need to worry if the ZFS scrub has finished)
      0  3  *  *  7 root find /dev/disk/by-vdev/ -name '[EFS][0-9][0-9]' -exec bash -c 'STATUS=`smartctl -t long {} | grep -Eo "^Test.+|^Please.+"`; echo Device: `readlink -f {}` \[{}\], $STATUS | systemd-cat -t smartd -p info' \;
    # Display all smartd entries with:
    # journalctl -t smartd
    #
    # Expected Output:
    # Jan 07 12:17:55 localhost.localdomain smartd[32237]: Device: /dev/sdaa [/dev/disk/by-vdev/F02], Testing has begun. Please wait 49440 seconds for test to complete. Test will complete after Tue Jan 8 02:01:55 2019

### Disable NCQ on CentOS 7:
    Edit /etc/default/grub
    Add libata.force=noncq to GRUB_CMDLINE_LINUX
    [ -d /sys/firmware/efi ] && `grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg` || `grub2-mkconfig -o /boot/grub2/grub.cfg`

### Enable persistent journal on CentOS 7:
    sed -i 's/\#Storage\=auto/Storage\=persistent/' /etc/systemd/journald.conf
    systemd-tmpfiles --create --prefix /var/log/journal
    systemctl restart systemd-journald
    
### Update firmware on HP SAS Expander to 2.10 on CentOS 7:
    # Modified from: https://serverfault.com/a/631575
    # Install newer sg3_utils
    yum -y install http://sg.danny.cz/sg/p/sg3_utils-libs-1.44-1.x86_64.rpm http://sg.danny.cz/sg/p/sg3_utils-1.44-1.x86_64.rpm
    # Download SAS Expander firmware
    curl -O http://downloads.hpe.com/pub/softlib2/software1/sc-linux-fw-array/p6670438/v96061/CP022989.scexe
    # Extract firmware and keep only PUF21000.bin
    mkdir tmp && chmod +x CP022989.scexe && ./CP022989.scexe --unpack=tmp && mv tmp/PUF21000.bin . && rm -r tmp/
    # Find all HP SAS Expanders version 2.09 or below
    lsscsi -g | grep -Eo 'HP SAS EXP Card  [12]\.[0][0-9].+'
    # Write new firmware
    sg_write_buffer --mode=dmc_offs_defer --bpw=4096 --in=PUF21000.bin /dev/sgX
    sg_write_buffer --mode=activate_mc /dev/sgX
    # Reboot and run lsscsi to validate.
    lsscsi -g | grep -Eo 'HP SAS EXP Card.+'
