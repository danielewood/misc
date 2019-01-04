## HDD Management/mapping/testing commands

### Find all sdX disk mappings
    find /dev/disk/ -type l -exec bash -c 'RL=`readlink "{}"`; echo $RL "{}"' \; | cut -c 7- | sort

### Find all disks that failed last SMART test:
    for x in `find /dev/disk/by-vdev/* | grep -vE 'part|Cache' | sort`; \
    do STATUS=`smartctl -a $x | grep '# 1  Extended offline    Completed: read failure'` && echo "Replace $x" ; done

### Get HDD Temperature for all disks in /dev/disk/by-vdev/
    for x in `find /dev/disk/by-vdev/* | grep -vE 'part|Cache' | sort`; \
    do echo "`hddtemp --quiet $x`"; done

### Use OpenSSL to rapidly generate incompressable data (~670MB/sec on a 1.8GHz E5-2603 V2)
    dd if=<(openssl enc -aes-256-ctr -pass pass:"$(dd if=/dev/urandom bs=128 count=1 2>/dev/null | base64)" -nosalt < /dev/zero) \
    bs=1M count=10000 iflag=fullblock status=progress of=/dev/null

### Write 2GB of /tmp/test.file1 to /data over and over again with a unique filename each rotation
    while true; do dd if=/tmp/test.file1 of="/data/test`echo $(($(date +%s%N)/1000000))`" \
    bs=1M count=2000 status=progress; done

### Get SMART Test Details
    for x in `find /dev/disk/by-vdev/* | grep -vE 'part|Cache' | sort`; \
    do echo "$x "; smartctl -l selftest $x|grep -E 'Extended|Status'; done

### Make netdata use ZFS's /dev/disk/by-vdev for available disk names
1. Edit /etc/netdata/netdata.conf, like this:
```
[plugin:proc:/proc/diskstats]
    path to /dev/disk/by-id = /dev/disk/by-vdev
    name disks by id = yes
```
    
2. Run: `systemctl restart netdata.service`

### crontab to log ZFS resilver/scrub activity to dmesg
    # Replace data with your pool name, echo only triggers if $SCRUB is not null.
    # /etc/crontab
    *   *  *  *  * root STATUS=`zpool status data | sed 's/to go/to go,/' | grep -A1 'to go,$'` && echo `date --iso-8601=seconds` zpool status data: $STATUS > /dev/kmsg
    
    
    # Expected Output:
    # [ 8459.371314] 2019-01-02T18:34:01-0800 zpool status data: 12.7T scanned out of 67.5T at 1.70G/s, 9h11m to go, 1.55T resilvered, 18.76% done
    # [ 8519.454816] 2019-01-02T18:35:01-0800 zpool status data: 12.8T scanned out of 67.5T at 1.70G/s, 9h10m to go, 1.56T resilvered, 18.92% done

### crontab syncoid task
    # Syncs datasets from SourceServer every day at 3pm.
    # The output redirect creates a per-line timestamped log file, useful to appending to any cron job to achieve the same function.
      0 15  *  *  * root /usr/local/bin/syncoid --recursive --no-sync-snap --debug --exclude 'dataset01\/\.system' root@SourceServer:dataset01 data &> >(while read line; do echo "`date --iso-8601=seconds`: $line" >> /var/log/syncoid.log; done;)
    
### misc crontab entries
    # Weekly mdadm array scrub (sends check command to all md devices)
      0  1  *  *  6 root find /sys/block/md*/md/sync_action -exec bash -c 'echo check > "{}"' \;

    # Weekly zfs array scrub
      0  1  *  *  6 root zpool scrub data

    # Weekly HDD SMART Offline Scan (runs when drive is idle, so we dont need to worry if the ZFS scrub has finished)
      0  9  *  *  6 root find /dev/disk/by-vdev/ -name '[EFS][0-9][0-9]' -exec bash -c 'smartctl -t offline {}' \; > /dev/null

