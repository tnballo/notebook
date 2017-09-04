# "How-To" Instructions for Misc Tasks on Arch Linux

Reference for those little tasks that are just uncommon enough to forget the steps involved.

### Mount a USB drive
---

1. List block storage devices:

    * ```sudo blkid```

2. Within the list, find the find the entry corresponding to the USB drive you want to mount.

    * Example entry: ```/dev/sda1: LABEL="WIN7ISO" UUID="AABE-7CAA" TYPE="vfat" PARTUUID="c3072e18-01```
    
3. Create a new mount point, if one doesn't already exist:

    * ```sudo mkdir /mnt/usbdrive```

4. Mount the USB drive, mapping the device (from the list entry) to the mount point:

    * ```sudo mount /dev/sda1 /mnt/usbdrive```

### Create a Temporary Python Virtualenv for Legacy Package Installs
---

1. Create a new python2 virtualenv in the current directory, then activate it:

    * ```virtualenv -p /usr/bin/python2 py2env```
    * ```source py2env/bin/activate```
    
2. When inside this environment, you should see ```(py2env)``` preceeding the normal terminal prompt. Now install the legacy package required with version explcitly specified:

    * ``` pip install dpkt==1.8.5```
 
3. When done running the legacy scripts, deactivate and remove the virtualenv:

    * ```deactivate```
    * ```rm -rf py2env/```

### Change System Timezone
---

1. Check current timezone:

    * ``` timedatectl```
    
2. List availible US timezones:

    * ```timedatectl list-timezones | grep "America"```
 
3. Set new timezone:

    * ```timedatectl set-timezone Zone/SubZone```
    
