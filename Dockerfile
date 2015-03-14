FROM gcc:4.9.2
WORKDIR /root
RUN python -c "import urllib; urllib.urlretrieve('http://sourceforge.net/projects/cdrtools/files/alpha/cdrtools-3.01a27.tar.bz2/download','/dev/stdout')" | tar jx && make -C cdrtools-3.01 CCOM=gcc && make -C cdrtools-3.01 install && rm -rf cdrtools-3.01
RUN python -c "import urllib; urllib.urlretrieve('http://www.nasm.us/pub/nasm/releasebuilds/2.11.08/nasm-2.11.08.tar.xz','/dev/stdout')" | tar Jx && (cd nasm-2.11.08 && ./configure && make && make install) && rm -rf nasm-2.11.08
RUN python -c "import urllib; urllib.urlretrieve('http://sourceforge.net/projects/libuuid/files/libuuid-1.0.3.tar.gz/download','/dev/stdout')" | tar zx && (cd libuuid-1.0.3 && ./configure) && make -C libuuid-1.0.3 && make -C libuuid-1.0.3 install && rm -rf libuuid-1.0.3
RUN python -c "import urllib; urllib.urlretrieve('https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz','/dev/stdout')" | tar Jx && make -C syslinux-6.03 && make -C syslinux-6.03 install && rm -rf syslinux-6.03
RUN python -c "import urllib; urllib.urlretrieve('https://www.kernel.org/pub/linux/kernel/v4.x/testing/linux-4.0-rc3.tar.xz','/dev/stdout')" | tar Jx
RUN python -c "import urllib; urllib.urlretrieve('http://alpha.gnu.org/gnu/bc/bc-1.06.95.tar.bz2','/dev/stdout')" | tar jx && (cd bc-1.06.95 && ./configure --prefix=/usr) && (cd bc-1.06.95 && sed -i -re 's/ doc$//' Makefile.am Makefile.in && make && make install) && rm -rf bc-1.06.95
WORKDIR /root/linux-4.0-rc3
COPY config-3.17.8 .config
RUN make oldconfig ARCH=i386
RUN make ARCH=i386
WORKDIR /root
COPY initramfs initramfs/
#RUN python -c "import urllib; urllib.urlretrieve('http://www.busybox.net/downloads/binaries/1.21.1/busybox-i486','initramfs/busybox-i486')" && chmod +x initramfs/busybox-i486
#RUN python -c "import urllib; urllib.urlretrieve('http://www.busybox.net/downloads/busybox-1.23.1.tar.bz2','/dev/stdout')" | tar jx && (cd busybox-1.23.1 && export TGTARCH=i486 && make defconfig && LDFLAGS="--static" make EXTRA_CFLAGS=-m32 EXTRA_LDFLAGS=-m32 && ln busybox ../initramfs/busybox-i486) && rm -rf busybox-1.23.1
RUN python -c "import urllib; urllib.urlretrieve('http://download.savannah.gnu.org/releases/tinycc/tcc-0.9.26.tar.bz2','/dev/stdout')" | tar jx && (cd tcc-0.9.26 && ./configure --enable-cross && make i386-tcc && make install) && rm -rf tcc-0.9.26
RUN python -c "import urllib; urllib.urlretrieve('http://landley.net/toybox/downloads/toybox-0.5.2.tar.gz','/dev/stdout')" | tar zx && (cd toybox-0.5.2 && sed -i -re 's/-Wl,--as-needed//' scripts/make.sh && ln -s `which gcc` /usr/bin/cc && make defconfig && rm /usr/bin/cc && LDOPTIMIZE=" " CC="tcc" CFLAGS="-static -m32" ./scripts/make.sh) && rm -rf toybox-0.5.2
COPY isolinux.cfg CD_root/isolinux/
#COPY 26.bzImage CD_root/
RUN (cd linux-4.0-rc3 && scripts/gen_initramfs_list.sh -o ../CD_root/initramfs_data.cpio.gz ../initramfs/) && ln linux-4.0-rc3/arch/x86/boot/bzImage CD_root/bzImage && ln /usr/share/syslinux/ldlinux.c32 /usr/share/syslinux/isolinux.bin CD_root/isolinux/ && /opt/schily/bin/mkisofs -allow-leading-dots -allow-multidot -l -relaxed-filenames -no-iso-translate -o 9pboot.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table CD_root
