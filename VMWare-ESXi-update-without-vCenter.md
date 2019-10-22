# VMWare-ESXi-update-without-vCenter

    # Enable http through the firewall
    esxcli network firewall ruleset set -e true -r httpClient
    
    # Set VMWare Depot URL
    DEPOT_URL='https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml'
    
    # Get newest standard image for ESXi 6.7
    UPDATE_VER=$(esxcli software sources profile list -d ${DEPOT_URL} | grep -Eo 'ESXi-6.7.[0-9]-20[0-9]+\-standard' | sort | tail -1)
    
    # Initiate update
    esxcli software profile update -p ${UPDATE_VER} -d ${DEPOT_URL}
    
    # Reboot host when ready
    reboot

## Example
    Using username "root".
    Using keyboard-interactive authentication.
    Password:
    The time and date of this login have been sent to the system logs.

    WARNING:
       All commands run on the ESXi shell are logged and may be included in
       support bundles. Do not provide passwords directly on the command line.
       Most tools can prompt for secrets or accept them from standard input.

    VMware offers supported, powerful system administration tools.  Please
    see www.vmware.com/go/sysadmintools for details.

    The ESXi Shell can be disabled by an administrative user. See the
    vSphere Security documentation for more information.
    [root@ESXi67-test1:~] esxcli network firewall ruleset set -e true -r httpClient
    [root@ESXi67-test1:~] DEPOT_URL='https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml'
    [root@ESXi67-test1:~] UPDATE_VER=$(esxcli software sources profile list -d ${DEPOT_URL} | grep -Eo 'ESXi-6.7.[0-9]-20[0-9]+\-standard' | sort | tail -1)
    [root@ESXi67-test1:~] esxcli software profile update -p ${UPDATE_VER} -d ${DEPOT_URL}
    Update Result
       Message: The update completed successfully, but the system needs to be rebooted for the changes to be effective.
       Reboot Required: true
       Update Result
       VIBs Installed: <long list of vibs here>
   
   
