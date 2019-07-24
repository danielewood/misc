#!/bin/bash
# shellcheck disable=SC2010

# Defaults
count=0
series='DSKAR'
output_path='/target'

#echo "Starting sctipt $0"
display_usage() {
  echo
  echo "Usage: $0"
  echo
  echo " -h    Display usage instructions"
  echo " -C    Specify Incremental Counter Value (default=0)"
  echo " -S    Specify Series Name (Default=DVXARZA)"
  echo " -d    Use ddrescue"
  echo " -s    Collect SMART data"
  echo " -f    Collect fdisk listing"
  echo " -l    Collect file listing of all partitions"
  echo " -o    Output Path for all output"
  echo " -m    Mount all partitions"
  echo " -u    Un-mount all partitions"
  echo " -k    Start at this drive number"
  echo " -i    Ignore this drive number"
  echo " -t    Process only starting drive"
  echo
}

while getopts hC:S:dsflo:muk:i:t option
do
case "${option}"
in
    h) display_usage;;
    C) count=${OPTARG};;
    S) series=${OPTARG};;
    d) ddrescue_trigger=1;;
    s) smart_trigger=1;;
    f) fdisk_trigger=1;;
    l) listing_trigger=1;;
    o) output_path=${OPTARG};;
    m) mount_trigger=1;;
    u) umount_trigger=1;;
    k) skip_trigger=${OPTARG};;
    i) ignore_trigger=${OPTARG};;
    t) oneshot_trigger=1;;
    *) exit 1
    esac
done

echo "output_path=$output_path"
[[ $ddrescue_trigger ]] && echo ddrescue_triigger
[[ $smart_trigger ]] && echo smart_triigger
[[ $fdisk_trigger ]] && echo fdisk_triigger
[[ $listing_trigger ]] && echo listing_triigger

system_disk=$(mount | grep -Eo '.* on / ' | sed 's/ on \/ //' | sed 's/[0-9]$//')
for path_disk in $(find /dev/disk/by-path/* | grep -v 'part' | sort -V)
do
    [[ $(readlink -f "$path_disk") == "$system_disk" ]] && continue
    printf -v prettycount "%02d" "$count"
    if [[ $skip_trigger ]]; then
        if [[ $count -lt $skip_trigger ]]; then
            echo "Skipping $series$prettycount"
            count=$(( count+1 ))
            continue
        fi
    fi
    if [[ $ignore_trigger ]]; then
        if [[ $count -eq $ignore_trigger ]]; then
            echo "Ignoring $series$prettycount"
            count=$(( count+1 ))
            continue
        fi
    fi
    disk_smart=$(smartctl -i "$path_disk")
    if grep -q 'Unknown USB bridge' <<< "$disk_smart"; then
        disk_capacity=$(fdisk -l "$path_disk" | grep -Eo '[0-9]+ bytes,' | grep -Eo '[0-9]+')
        if [[ ! $disk_capacity ]]; then
            count=$(( count+1 ))
            echo skipping
            continue
        fi
        disk_device=$(readlink -f "$path_disk" | grep -Eo 'sd[a-z]+')
        disk_model=$(dmesg | grep "$disk_device" -B9 | grep 'Product:' | sed 's/.*\://g' | tr -d " \.\t")
        disk_serial=$(dmesg | grep "$disk_device" -B9 | grep 'SerialNumber:' | sed 's/.*\://g' | tr -d " \.\t")
    else
        # Examples:
        # Namespace 1 Size/Capacity:          14,403,239,936 [14.4 GB]
        # User Capacity:    500,107,862,016 bytes [500 GB]
        disk_capacity=$(echo "$disk_smart" | grep 'Capacity: ' | sed 's/.*\://g' | awk -F'[' '{print $1}' | tr -d "[A-Za-z], \t")
        disk_model=$(echo "$disk_smart" | grep -E 'Device Model:|Product:|Model Number:' | sed 's/.*\://g' | tr -d " \t")
        disk_serial=$(echo "$disk_smart" | grep -i 'Serial number:' | grep -Eo '[0-9A-Za-z]+$')
        disk_vendor=$(echo "$disk_smart" | grep -E 'Model Family:|Vendor:' | sed 's/.*\://g' | tr -d " \t")
    fi
    disk_capacity="$(( disk_capacity / (1024*1024*1024) ))GB"
    disk_name="${series}${prettycount}_${disk_vendor}_${disk_model}_${disk_capacity}_${disk_serial}"
    disk_name=${disk_name//__/_}

    echo "$disk_name"
    echo "$path_disk"
    for disk_partition in $(ls "$path_disk"* | grep part)
    do
        grep -Eo '.*part[0-9]' <<<"$disk_partition"
    done
    if [[ ! $disk_serial ]]; then
        count=$(( count+1 ))
        echo skipping
        continue
    fi
    [[ $smart_trigger ]] && smartctl -a "$path_disk" > "$output_path"/"$disk_name".smartctl
    [[ $fdisk_trigger ]] && fdisk -l "$path_disk" > "$output_path"/"$disk_name".fdisk
    if [[ $listing_trigger ]]; then
        for disk_partition in $(ls "$path_disk"* | grep part)
        do
            part_num=$(grep -Eo 'part[0-9]' <<<"$disk_partition")
            mount_path="/tmp/$disk_name-$part_num"
            mkdir "$mount_path"
            mount -o ro "$disk_partition" "$mount_path"
            find "$mount_path" -type f -exec du -ah {} + | tee "$output_path/$disk_name-$part_num.filelist"
            umount "$mount_path"
        done
    fi
    if [[ $mount_trigger ]]; then
        for disk_partition in $(ls "$path_disk"* | grep part)
        do
            part_num=$(echo "$disk_partition" | grep -Eo 'part[0-9]')
            mount_path="/tmp/$disk_name-$part_num"
            mkdir "$mount_path"
            mount -o ro "$disk_partition" "$mount_path"
        done
    fi
    if [[ $umount_trigger ]]; then
        for disk_partition in $(ls "$path_disk"* | grep part)
        do
            part_num=$(echo "$disk_partition" | grep -Eo 'part[0-9]')
            mount_path="/tmp/$disk_name-$part_num"
            umount "$mount_path"
        done
    fi
    [[ $ddrescue_trigger ]] && ddrescue -d -f -r9 "$path_disk" "$output_path/$disk_name.img" "$output_path/$disk_name.ddrescue"
    count=$(( count+1 ))
    [[ $oneshot_trigger ]] && exit 0
done
