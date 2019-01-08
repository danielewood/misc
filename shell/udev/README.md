## udev/
#### udev rules to map SAS Expander ports consistently on HP SAS Expanders and Intel SCU HBAs.
1. Test with /usr/lib/udev/expander_id -d sda
1. Your output should be something like:
1. exp0x500056b37789ab-phy00
1. /usr/lib/udev/rules.d/68-expander_id.rules will:

    a. Feed the kernel device into /usr/lib/udev/expander_id, if it is on an expander bus
    
    b. SymLink /dev/disk/by-expander/exp0x500056b37789ab-phy00 --> /dev/sda
