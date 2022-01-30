#!/bin/bash
# Set color variables
green='\033[0;32m'
red='\033[0;31m'
clear='\033[0m'

function timemachine2sparseimage {
    if [[ -z "$1" || -z "$2" || "$1" == "--help" || "$1" == "-h" ]]; then
    echo "${red}Usage:${clear} timemachine2sparseimage <volumeSize> <volumeFullPath>
Example: timemachine2sparseimage 250g /Volumes/Backups/myVolumeName.sparseimage"
    return 1
    fi

    local VOL_SIZE=$1
    local VOL_FULLPATH=$2
    local VOL_NAME="$(sed -e 's/\.sparsebundle//' -e 's/\.sparseimage$//' <<<"${VOL_FULLPATH##*/}")_TM"
    local VOL_PATH="${VOL_FULLPATH%/*}"
    local VOL_NEWPATH="${VOL_PATH}/${VOL_NAME}.sparseimage"
    set | grep ^VOL

    { #try
      hdiutil create -size "${VOL_SIZE}" -fs 'Case-sensitive APFS' -volname "${VOL_NAME}" "${VOL_NEWPATH}"
    } ||
    { #catch
      printf "${red}SparseImage creation failed:\nhdiutil create -size \"${VOL_SIZE}\" -fs 'Case-sensitive APFS' -volname \"${VOL_NAME}\" \"${VOL_NEWPATH}\"\n${clear}"
      set | grep ^VOL
      return 1
    }

    { #try
      open "${VOL_NEWPATH}" && sleep 3
    } || 
    { #catch
      printf "${red}Could not open volume \"${VOL_NEWPATH}\"\n${clear}"
      set | grep ^VOL
      return 1
    }

    local tmutilDestinations=($(tmutil destinationinfo | grep -Eo '[A-F0-9\-]{36}'))
    for destination in ${tmutilDestinations[@]}; do
      sudo tmutil removedestination "${destination}"
    done

    if [[ ! -e "/Volumes/${VOL_NAME}/" ]]; then
      printf "${red}Destination path does not exist: \"/Volumes/${VOL_NAME}\"\n${clear}"
      set | grep ^VOL
      return 1
    fi
    { #try
      sudo tmutil setdestination -a "/Volumes/${VOL_NAME}/"
    } || 
    { #catch
      printf "${red}Could not set destination \"/Volumes/${VOL_NAME}/\"\n${clear}"
      set | grep ^VOL
      return 1
    }
    tmutil addexclusion "${VOL_NEWPATH}" &> /dev/null || true
 
    printf "Done, now run:\n${green}sudo tmutil startbackup --auto\n${clear}"
}

echo "
# Nuke all existing snapshots so we can have a fresh starting point:
${green}sudo tmutil deletelocalsnapshots /
${clear}
# Then run:
${green}timemachine2sparseimage --help
${clear}"