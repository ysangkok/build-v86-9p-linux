#!/bin/sh -ex
#docker build -t 26-build -f Dockerfile-MakeOldKernel .
#docker cp $(docker create 26-build):/linux-2.6.39/arch/x86/boot/bzImage .
#mv bzImage 26.bzImage
docker build -t 9pkernel-done .
CONTAINER=$(docker create 9pkernel-done)
docker cp $CONTAINER:/9pboot.iso .
docker cp $CONTAINER:/initramfs/ filledinitramfs
cp -v 9pboot.iso /var/www/v86/images
cp -rv filledinitramfs/* /var/www/v86/fsroot/
cat > /var/www/v86/init <<END
#!/bin/bash
exec oneit /bin/bash
END
python /var/www/v86/fs2json.py > /var/www/v86/docs/samples/fs.json
