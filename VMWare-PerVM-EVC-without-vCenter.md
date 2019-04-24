# Enable Per-VM EVC on ESXi 6.7 without vCenter
This was done to solve a chicken and egg problem of enabling EVC on a VCSA without using vCenter.

## Process
1. Upgrade the hardware version of your VCSA to a minimum of version 6.7 (v14).
    - [Guide: Upgrade VMware’s VM Hardware Version on Next Server Reboot](https://virtualhackey.wordpress.com/2018/03/30/upgrade-vmwares-vm-hardware-version-on-next-reboot/)
    - Steps: 
        - In VCSA; Right-click on VM
        - Select Compatibility>Schedule VM compatibility upgrade
        - Set Version to 6.7 (v14)
        - Reboot VCSA
1. Enable SSH on your ESXi host containing the VCSA
1. Shut down VCSA
1. Navigate to your datastore directory for the VCSA
1. Create a backup of your VCSA `.vmx`
1. Append the following lines to the `.vmx` for Westmere Compatibility
    ```
    featMask.vm.cpuid.Intel = "Val:1"
    featMask.vm.cpuid.FAMILY = "Val:6"
    featMask.vm.cpuid.MODEL = "Val:0x25"
    featMask.vm.cpuid.STEPPING = "Val:1"
    featMask.vm.cpuid.NUMLEVELS = "Val:0xb"
    featMask.vm.cpuid.NUM_EXT_LEVELS = "Val:0x80000008"
    featMask.vm.cpuid.CMPXCHG16B = "Val:1"
    featMask.vm.cpuid.DS = "Val:1"
    featMask.vm.cpuid.LAHF64 = "Val:1"
    featMask.vm.cpuid.LM = "Val:1"
    featMask.vm.cpuid.MWAIT = "Val:1"
    featMask.vm.cpuid.NX = "Val:1"
    featMask.vm.cpuid.SS = "Val:1"
    featMask.vm.cpuid.SSE3 = "Val:1"
    featMask.vm.cpuid.SSSE3 = "Val:1"
    featMask.vm.cpuid.SSE41 = "Val:1"
    featMask.vm.cpuid.IBPB = "Val:1"
    featMask.vm.cpuid.IBRS = "Val:1"
    featMask.vm.cpuid.STIBP = "Val:1"
    featMask.vm.cpuid.SSBD = "Val:1"
    featMask.vm.cpuid.FCMD = "Val:1"
    featMask.vm.cpuid.POPCNT = "Val:1"
    featMask.vm.cpuid.RDTSCP = "Val:1"
    featMask.vm.cpuid.SSE42 = "Val:1"
    featMask.vm.cpuid.VMX = "Val:1"
    featMask.vm.hv.capable = "Val:1"
    featMask.vm.cpuid.AES = "Val:1"
    featMask.vm.cpuid.PCLMULQDQ = "Val:1"
    featMask.vm.vt.realmode = "Val:1"
    featureCompat.vm.completeMasks = "TRUE"
    ```
