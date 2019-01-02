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

### Automagically map physical ports to enclosure for ZFS vdev use
    #!/bin/bash
    # Remove all disks except for boot drives. Add boot drives to exclusion with grep -v
    # Use a SSD, insert it in each bay, sequentially of how you want it numbered, 
    #     starting with 0 (or change COUNT=0 to desired starting value)
    
    rm /tmp/vdev_id.conf 2>/dev/null
    rm /tmp/port-mapper.txt 2>/dev/null
    COUNT=0
    while true
    do
        PORTPATH="`find /dev/disk/by-path/pci-0000:03:00.0-sas-phy* | grep '\-phy' | grep -v '\-part'`"
        LASTLINE="`cat /tmp/port-mapper.txt 2>/dev/null | tail -1`"
        if [ "$PORTPATH" != "$LASTLINE" ]; then
            printf -v PADDED_COUNT "%02d" $COUNT
            echo "$PORTPATH" >> /tmp/port-mapper.txt
            echo "alias E$PADDED_COUNT $PORTPATH" | tee --append /tmp/vdev_id.conf
            let "COUNT++"
        fi
        sleep 1
    done
