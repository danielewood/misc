Solaris OpenBoot Commands ([Reference](http://irtfweb.ifa.hawaii.edu/~spex/computers/spex1/techdocs/1201-hilodog/SunOBP_Quick_Ref.pdf)):

- `{ok} show-disks`
  + adds selected disk to myalias, so you can then do `{ok} boot myalias`
- `{ok} devalias`
  + shows system device aliases, such as default `disk`, `disk1`, `cdrom`, etc
- `{ok} probe-scsi`
  + probes main SCSI bus (only FC-AL on the Sun Blade 2000)
- `{ok} probe-scsi-all`
  + probes entire SCSI bus, including all secondary busses.
- `{ok} boot -rv`
  + rescan all disks, attempt to boot one of them automatically
  + use when you have swapped around disk configuration and now need to have the system auto-pick a boot device
- `{ok} printenv`
  + display Open Boot variables and current/default values
- `{ok} setenv auto-boot? false`
  + do not automatically boot from `boot-device`, operator must type boot
- `{ok} printenv auto-boot?`
  + if true, boot from devices listed in `printenv boot-device`
  + there can be multiple devices in `boot-device`:
   - `boot-device =         /pci@8,700000/scsi@6/disk@3,0:a /pci@8,700000/scsi@6/disk@1,0:a /pci@8,600000/SUNW,qlc@4/fp@0,0/disk@w21000014c3e53951,0:a /pci@8,600000/SUNW,qlc@4/fp@0,0/disk@w21000004cf2c3830,0:a`

- `{0} ok devalias`

```
screen                   /pci@8,700000/SUNW,m64B@1
disk1                    /pci@8,600000/SUNW,qlc@4/fp@0,0/disk@2,0
disk0                    /pci@8,600000/SUNW,qlc@4/fp@0,0/disk@1,0
disk                     /pci@8,600000/SUNW,qlc@4/fp@0,0/disk@1,0
scsi                     /pci@8,600000/SUNW,qlc@4
net                      /pci@8,700000/network@5,1:
cdrom                    /pci@8,700000/scsi@6/disk@6,0:f
tape                     /pci@8,700000/scsi@6,1/tape@4,0
tape1                    /pci@8,700000/scsi@6,1/tape@5,0
tape0                    /pci@8,700000/scsi@6,1/tape@4,0
beep                     /pci@8,700000/ebus@5/beep@1,32
floppy                   /pci@8,700000/ebus@5/floppy
ttyb                     /pci@8,700000/ebus@5/serial@1,400000:b
ttya                     /pci@8,700000/ebus@5/serial@1,400000:a
name                     aliases
```


-------------------

Sun Blade 2000:
```
Rear 68pin port with SCSI2SD on SCSI ID 6 (cdrom)
boot /pci@8,700000/scsi@6,1/disk@6,0:f

Rear 68pin port with SCSI2SD on SCSI ID 1 (hdd)
boot /pci@8,700000/scsi@6,1/disk@1,0:f

Internal 50pin port with SCSI2SD on SCSI ID 6 (cdrom)
boot /pci@8,700000/scsi@6,0/disk@6,0:f

Internal 50pin port with SCSI2SD on SCSI ID 1 (hdd)
boot /pci@8,700000/scsi@6/disk@1,0:a
boot /pci@8,700000/scsi@6,0/disk@1,0:f

Note:
SCSI ID 4 and 5 may be reserved for tape devices.
```


SunFire V210/V240:
```
Jumpers
JP4 1-2     = 1.00GHz CPU
JP4 1-2,3-4 = 1.28GHz CPU
J5  1-2 Alom/System Control off, (will get you to openboot ok prompt)
J13 1-2 Obp normal, 2-3 Halfboot
J11 1-2 Write protect OBP
```

Misc Solaris Shell commands:
```
du -skd * | sort -rn | more
find / -mount -ls | nawk '{size+=$1};END{print size / 1024 / 1024, $2}'
```

Solaris 8, fix locale issues:
```
cat <<EOF > /etc/default/init
# @(#)init.dfl 1.5 99/05/26
#
# This file is /etc/default/init.  /etc/TIMEZONE is a symlink to this file.
# This file looks like a shell script, but it is not.  To maintain
# compatibility with old versions of /etc/TIMEZONE, some shell constructs
# (i.e., export commands) are allowed in this file, but are ignored.
#
# Lines of this file should be of the form VAR=value, where VAR is one of
# TZ, LANG, CMASK, or any of the LC_* environment variables.
#
TZ=US/Pacific
CMASK=022
LANG=C
#LC_COLLATE=en_US.ISO8859-1
#LC_CTYPE=en_US.ISO8859-1
#LC_MESSAGES=C
#LC_MONETARY=en_US.ISO8859-1
#LC_NUMERIC=en_US.ISO8859-1
#LC_TIME=en_US.ISO8859-1

EOF
```


Solaris Links:
- Solaris Patch Clusters - `ftp://mirrors.rcs.alaska.edu/MIRRORS/retired/sun-patches/clusters/`
- [How to use Solaris Patch Clusters(idevelopment.info)](http://www.idevelopment.info/data/Unix/Solaris/SOLARIS_Patching_Solaris_2.8.shtml)
- [How to use Solaris Patch Clusters(i-justblog.com)](http://www.i-justblog.com/2009/02/solaris-recommended-patch-clusters.html)


Solaris Live Upgrade: (Only complete first portion to move OS to a new drive and repartition)
- [Known, but underused Solaris Features: Live Upgrade](http://www.c0t0d0s0.org/archives/4102-Known,-but-underused-Solaris-Features-Live-Upgrade.html)
- [Activating a Boot Environment (Solaris 9 Installation Guide)](https://docs.oracle.com/cd/E19683-01/816-7171/6md6pohs3/index.html)
- [Example of Upgrading With Solaris Live Upgrade](https://docs.oracle.com/cd/E18752_01/html/821-1910/luexample-100.html)
- [Copy a Solaris Boot Drive to a New Disk](https://web.archive.org/web/20161030144345/http://spiralbound.net/blog/2005/05/10/how-to-copy-a-solaris-boot-drive-to-a-disk-with-a-different-partition-layout/)

- [How to Manually clone a Solaris install to a new disk layout and make it bootable and modify fstab](https://www.experts-exchange.com/questions/28283756/dd-command-clone-for-Solaris-8.html)
