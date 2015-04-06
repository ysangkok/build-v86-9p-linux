#!/bin/sh -ex
rm -rf ../fsroot
cp -fr filledinitramfs/initramfs/. ../fsroot/
cat > ../fsroot/etc/fstab <<END
proc            /proc      proc     defaults     0      0
devtmpfs        /dev       devtmpfs defaults     0      0
sysfs           /sys       sysfs    defaults     0      0
END
cat > ../fsroot/etc/rcS <<END
#!/bin/bash -ex
/busybox-i486 mount -a
END
chmod +x ../fsroot/etc/rcS
cat > ../fsroot/etc/inittab <<END
::sysinit:/etc/rcS
::respawn:-/bin/bash
#ttyS1::respawn:-login -f root

# Stuff to do when restarting the init process
::restart:/sbin/init

# Stuff to do before rebooting
::ctrlaltdel:/sbin/reboot
::shutdown:/etc/shutdown
END
cat > ../fsroot/init <<END
#!/bin/bash -ex
#exec oneit -p /bin/bash
exec /busybox-i486 init
END
python /var/www/v86/fs2json.py ../fsroot --out ../fs.json
