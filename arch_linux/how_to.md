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


    
