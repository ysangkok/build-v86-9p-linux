#!/bin/sh -ex
rm -rf /var/www/v86/fsroot
cp -fr filledinitramfs/initramfs/. /var/www/v86/fsroot/
cat > /var/www/v86/fsroot/etc/fstab <<END
proc            /proc      proc     defaults     0      0
devtmpfs        /dev       devtmpfs defaults     0      0
sysfs           /sys       sysfs    defaults     0      0
END
cat > /var/www/v86/fsroot/etc/rcS <<END
#!/bin/bash -ex
/busybox-i486 mount -a
END
chmod +x /var/www/v86/fsroot/etc/rcS
cat > /var/www/v86/fsroot/etc/inittab <<END
::sysinit:/etc/rcS
::respawn:-/bin/bash
#ttyS1::respawn:-login -f root

# Stuff to do when restarting the init process
::restart:/sbin/init

# Stuff to do before rebooting
::ctrlaltdel:/sbin/reboot
::shutdown:/etc/shutdown
END
cat > /var/www/v86/fsroot/init <<END
#!/bin/bash -ex
#exec oneit -p /bin/bash
exec /busybox-i486 init
END
python /var/www/v86/fs2json.py /var/www/v86/fsroot --out ../fs.json
