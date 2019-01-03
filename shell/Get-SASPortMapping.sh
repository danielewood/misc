#!/bin/bash
# Remove all disks you want mapped before executing this script.
# After executing, insert all drives, one by one, in desired numbering order.
rm -f /tmp/vdev_id.conf 2> /dev/null
find /dev/disk/by-path/* 2> /dev/null | grep -v '\-part' > /tmp/port-mapper.txt

green=`tput setaf 2;tput bold`
nc=`tput sgr0`

echo "${green}Current ports that will not be mapped:${nc}"
cat /tmp/port-mapper.txt
echo ""
read -p "Press ${green}[Enter]${nc} key to start mapping process..."
echo "Insert all drives, one by one, in desired numbering order"
echo "The completed vdev_id is at ${green}/tmp/vdev_id.conf${nc}"

COUNT=0
while true
do
    PORTPATH="`find /dev/disk/by-path/* | grep -v '\-part' | grep '\-phy' | grep -v -f /tmp/port-mapper.txt`"
    if [ "$PORTPATH" ]; then
       printf -v PADDED_COUNT "%02d" $COUNT
       echo "$PORTPATH" >> /tmp/port-mapper.txt
       echo "alias E$PADDED_COUNT $PORTPATH" | tee --append /tmp/vdev_id.conf
       let "COUNT++"
    fi
    sleep 0.25s
done
