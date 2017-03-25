# Miscellaneous Tweaks for Arch Linux

Random, bite-sized configuration changes for a better Arch experience.

### Optimize pacman's mirrorlist
---

[reflector](https://wiki.archlinux.org/index.php/Reflector) can overwrite ```/etc/pacman.d/mirrorlist``` with the most current mirrors, sorted by speed.

1. Backup current mirror list in case something goes wrong:

    * ```sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup```

2. Install and run reflector, populating your list with 200 most recently synced mirrors sorted by download rate:

    * ```sudo pacman -S reflector && sudo reflector --verbose -l 200 -p http --sort rate --save /etc/pacman.d/mirrorlist```
    
### Use pacman's easter egg progress bar
---

Change [pacman](https://wiki.archlinux.org/index.php/Pacman)'s (package manager) progress bar to a colorful ASCII Pacman (game character) eating power pills:

1. Open ```/etc/pacman.conf``` for editing.

2. Find the ```# Misc Options``` header. Uncomment the line ```#Color``` underneath.

3. Still underneath ```# Misc Options```, add the line ```ILoveCandy```.

4. Once finished, your  ```# Misc Options``` section might look something like:

```
# Misc options
#UseSyslog
Color
ILoveCandy
#TotalDownload
CheckSpace
#VerbosePkgLists
```

### Quickly setup a sane host firewall default
---

[ufw](https://wiki.archlinux.org/index.php/Uncomplicated_Firewall) is a simple CLI for configuring the netfilter firewall.

1. Install ufw:

    * ```sudo pacman -S ufw```
    
2. Configure ufw to deny all incoming traffic (silent drop), and allow all outgoing traffic:

    * ```sudo ufw default deny incoming```
    
    * ```sudo ufw default allow outgoing```
    
3. Apply settings and verify that ufw is indeed running:

    * ```sudo ufw enable```
    
    * ```sudo ufw status verbose```
    
4. Enable ufw as a service, so that it starts with these settings every boot:

    * ```sudo systemctl enable ufw```

    

    
