FROM radial/busyboxplus:curl
WORKDIR /
# i486 for toybox (which needs a c library)
RUN   curl "https://e82b27f594c813a5a4ea5b07b06f16c3777c3b8c.googledrive.com/host/0BwnS5DMB0YQ6bDhPZkpOYVFhbk0/musl-1.1.6/crossx86-x86_64-linux-musl-1.1.6.tar.xz" | unxz | tar x \
  &&  curl "https://e82b27f594c813a5a4ea5b07b06f16c3777c3b8c.googledrive.com/host/0BwnS5DMB0YQ6bDhPZkpOYVFhbk0/musl-1.1.6/crossx86-i486-linux-musl-1.1.6.tar.xz"   | unxz | tar x

#make-4.1 uses OLDGNU tar format that busybox doesn't support, use our own tar
# alternative: https://sourceforge.net/projects/s-tar/files/
COPY sltar.c sltar.c
# alternative to make-4.1.tar.bz2: http://fossies.org/linux/privat/bmake-20141111.zip
RUN   /x86_64-linux-musl/bin/x86_64-musl-linux-gcc sltar.c -DVERSION="\"9000\"" -static -o sltar \
  &&  curl "http://ftp.gnu.org/gnu/make/make-4.1.tar.bz2" | bunzip2 | ./sltar x \
  &&  ( \
            cd make-4.1 \
        &&  ./configure PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH CC="/x86_64-linux-musl/bin/x86_64-linux-musl-gcc" LDFLAGS="-static" \
        &&  ./build.sh \
        &&  cp make /usr/bin/ \
      ) \
  && rm -rf make-4.1

ENV PATH /usr/local/bin:$PATH

#RUN  curl http://ftp.gnu.org/gnu/cpio/cpio-2.11.shar.gz | gunzip | sh
#RUN  cd cpio-2.11; ./configure LDFLAGS=-static CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc
#RUN  cd cpio-2.11; PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH make
#RUN  cd cpio-2.11; make install
RUN   curl http://ftp.gnu.org/gnu/cpio/cpio-2.11.shar.gz | gunzip | sh \
  &&  ( \
            cd cpio-2.11 \
        &&  ./configure LDFLAGS=-static CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
        &&  PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH make \
        &&  make install \
      ) \
  &&  rm -rf cpio-2.11 || true
# || true is a workaround for something that looks like a docker bug (in 1.6) that makes it impossible to delete deep paths

RUN   curl http://www.nasm.us/pub/nasm/releasebuilds/2.11.08/nasm-2.11.08.tar.xz | unxz | tar x \
  &&  ( \
            cd nasm-2.11.08 \
        &&  ./configure LDFLAGS="-static" CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
        &&  make \
        &&  make install \
      ) \
  &&  rm -rf nasm-2.11.08 \
  &&  nasm; if [[ $? != 1 ]]; then echo "no nasm"; exit 1; fi

RUN   curl https://www.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.xz | unxz | tar x \
  &&  curl -o /usr/bin/perl http://staticperl.schmorp.de/bigperl.bin \
  &&  chmod +x /usr/bin/perl
# isolinux.bin and ldlinux.c32 already exist here... this is why building is commented out
#RUN FILE=$(find . -name "isolinux.bin" -print); if [[ "$FILE" != "" ]]; then echo -e "found\n$FILE"; else echo "didn't find file"; exit 1; fi
#RUN FILE=$(find . -name "ldlinux.c32" -print); if [[ "$FILE" != "" ]]; then echo -e "found\n$FILE"; else echo "didn't find file"; exit 1; fi
#partly works but disabled
#RUN make -C syslinux-6.03 PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc || true

# works, disabled cause it's unnecessary
#RUN (cd syslinux-6.03/bios/lzo && /x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static -o prepcore prepcore.o lzo.a) && \
#	make -C syslinux-6.03 com32 PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc

# results in errors:
#  [HOSTCC] util/zbin
#make[4]: gcc: Command not found
#RUN make -C syslinux-6.03 bios PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc

RUN   curl -L http://sourceforge.net/projects/libuuid/files/libuuid-1.0.3.tar.gz/download | gunzip | cpio -mi \
  &&  ( \
          cd libuuid-1.0.3 \
      &&  ./configure \
            --prefix=/x86_64-linux-musl/x86_64-linux-musl \
            CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
            LDFLAGS=-static\
      ) \
  &&  make -C libuuid-1.0.3 \
        PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
        AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=: \
  &&  make -C libuuid-1.0.3 \
        install \
        AUTOCONF=: AUTOHEADER=: AUTOMAKE=: ACLOCAL=: \
  &&  rm -rf libuuid-1.0.3

RUN   make -C syslinux-6.03 \
        install \
        PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
        CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
  &&  rm -rf syslinux-6.03 \
  &&  rm /usr/bin/perl

# replace shebang to avoid using bash
#RUN   curl http://landley.net/toybox/downloads/toybox-0.5.2.tar.gz | gunzip | tar x \
#  &&  cd toybox-0.5.2 \
#  &&  sed -i -re '1 s,^.*$,#!/bin/sh,g' scripts/genconfig.sh \
#  &&  echo -e '#!/bin/sh\n/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static $@' > /usr/bin/cc \
#  &&  chmod +x /usr/bin/cc \
#  &&  make defconfig \
#  &&  rm /usr/bin/cc

RUN curl http://invisible-island.net/datafiles/release/byacc.tar.gz | gunzip | tar x
RUN   (     cd byacc* \
        &&  ./configure \
            LDFLAGS=-static \
            CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
        &&  make \
        &&  make install\
      ) \
  &&  rm -rf byacc*

RUN   curl http://ftp.gnu.org/gnu/m4/m4-1.4.17.tar.xz | unxz | tar x \
  &&  ( \
            cd m4-1.4.17 \
        &&  ./configure \
              LDFLAGS=-static \
              CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
        &&  make \
              PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
        &&  make install \
      ) \
  &&  rm -rf m4-1.4.17

# alternative for this method: a zip file: http://fossies.org/linux/misc/flex-2.5.39.zip
RUN curl -L http://sourceforge.net/projects/flex/files/flex-2.5.39.tar.xz/download | unxz | cpio -mi

## we can extract this with correct mtimes, if using sltar instead of cpio above (github uses the new tar format) (we need correct mtimes or we'd need autotools):
#RUN curl -L https://github.com/westes/flex/archive/flex-2.5.39.tar.gz | gunzip | tar x
## move directory contents and overwrite (archive to keep mtimes)
#RUN find flex-flex-2.5.39 -maxdepth 1 -mindepth 1 -exec cp -avrl "{}" /flex-2.5.39/ \; && rm -rf flex-flex-2.5.39

RUN   cd flex-2.5.39 \
  &&  grep -vE ' *doc *\\ *' < Makefile.am > temp \
  &&  mv temp Makefile.am \
  &&  grep -vE ' *doc *\\ *' < Makefile.in > temp \
  &&  mv temp Makefile.in \
  &&  ./configure --enable-static LDFLAGS=--static CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc

RUN   cd flex-2.5.39 \
  &&  make \
        PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH

RUN   cd flex-2.5.39 \
  &&  ./flex; if [[ $? != 1 ]]; then ls -ld flex; exit 1; fi

RUN   ( \
            cd flex-2.5.39 \
        &&  make \
              install \
              PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
      ) \
  &&  rm -rf flex-2.5.39

RUN   curl -L http://download.savannah.gnu.org/releases/lzip/lunzip/lunzip-1.7-pre1.tar.gz | gunzip | tar x \
  &&  ( \
            cd lunzip-1.7-pre1 \
        &&  ./configure \
              CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
              LDFLAGS=-static \
        &&  make \
        &&  make install \
      ) \
  &&  rm -rf lunzip-1.7-pre1

RUN   curl  http://ftp.halifax.rwth-aachen.de/gnu/ed/ed-1.11.tar.lz | lunzip | tar x \
  &&  ( \
            cd ed-1.11 \
        &&  ./configure \
              LDFLAGS=-static \
              CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
        &&  make \
        &&  make install \
      ) \
  &&  rm -rf ed-1.11

RUN   curl http://alpha.gnu.org/gnu/bc/bc-1.06.95.tar.bz2 | bunzip2 | cpio -mi \
  &&  ( \
            cd bc-1.06.95 \
        &&  ./configure \
              CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
              LDFLAGS=-static \
        &&  sed -i -re 's/ doc$//' Makefile.am Makefile.in \
        &&  make \
              PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
        &&  make install \
      ) \
  &&  rm -rf bc-1.06.95

# these were tested only with glibc (official gcc docker):
#RUN python -c "import urllib; urllib.urlretrieve('http://www.busybox.net/downloads/binaries/1.21.1/busybox-i486','initramfs/busybox-i486')" && chmod +x initramfs/busybox-i486
#RUN python -c "import urllib; urllib.urlretrieve('http://download.savannah.gnu.org/releases/tinycc/tcc-0.9.26.tar.bz2','/dev/stdout')" | tar jx && (cd tcc-0.9.26 && ./configure --enable-cross && make i386-tcc && make install) && rm -rf tcc-0.9.26

# this is for building toybox with tcc:
#RUN   curl http://landley.net/toybox/downloads/toybox-0.5.2.tar.gz | gunzip | tar x \
#  &&  ( \
#            cd toybox-0.5.2 \
#        &&  sed -i -re 's/-Wl,--as-needed//' scripts/make.sh \
#        &&  ln -s `which gcc` /usr/bin/cc \
#        &&  make defconfig \
#        &&  rm /usr/bin/cc \
#        &&  LDOPTIMIZE=" " CC="tcc" CFLAGS="-static -m32" ./scripts/make.sh \
#      ) \
#  &&  rm -rf toybox-0.5.2

RUN curl -L http://sourceforge.net/projects/s-make/files/smake-1.2.4.tar.bz2/download | bunzip2 | tar x
# make bootstrap smake:
RUN   cd smake-1.2.4/psmake \
  &&  LDFLAGS=-static CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc ./MAKE-all

#RUN smake-1.2.4/psmake/smake; if [[ $? != 1 ]]; then echo "no bootstrap smake"; exit 1; fi
#this ought to work, but smake can't detect the architecture correctly like this, i think it may be parsing the compiler path:
#RUN cd smake-1.2.4 && sed -i '274i	echo $(C_ARCH)' RULES/rules1.top && sed -i '2iecho "$@"' conf/makeinc && ./psmake/smake -WW -DD -d -r all CCOM=/x86_64-linux-musl/bin/x86_64-musl-linux-gcc

RUN   echo -e '#!/bin/sh\n/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static $@' > /usr/bin/gcc \
  &&  chmod +x /usr/bin/gcc \
  &&  ( \
            cd smake-1.2.4 \
        &&  make PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
        &&  make install\
      ) \
  &&  rm -rf smake-1.2.4 \
  &&  rm /usr/bin/gcc \
  &&  /opt/schily/bin/smake; if [[ $? != 1 ]]; then echo "no smake"; exit 1; fi

# needed for linux
RUN  curl http://ftp.gnu.org/gnu/bash/bash-4.3.30.tar.gz | gunzip | tar x \
  &&  ( \
            cd bash-4.3.30 \
         && ./configure \
              --prefix=/ \
              --without-bash-malloc \
              PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
              CC=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
              LDFLAGS=-static \
         && make \
              PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
         && make install\
      ) \
  &&  rm -rf bash-4.3.30 \
  &&  rm -r share

RUN   curl -L "http://sourceforge.net/projects/cdrtools/files/alpha/cdrtools-3.01a27.tar.bz2/download" | bunzip2 | tar x \
  &&  echo -e '#!/bin/sh\n/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static $@' > /usr/bin/gcc \
  &&  chmod +x /usr/bin/gcc \
  &&  PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH /opt/schily/bin/smake -C cdrtools-3.01 \
  &&  ln -fs /x86_64-linux-musl/bin/x86_64-linux-musl-gcc /usr/bin/gcc \
  &&  PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH /opt/schily/bin/smake -C cdrtools-3.01 install LDOPTX=-static \
  &&  rm -rf cdrtools-3.01 /usr/bin/gcc \
  &&  /opt/schily/bin/mkisofs; if [[ $? != 1 ]]; then echo "no mkisofs"; exit 1; fi

COPY config-3.17.8 .config
COPY isolinux.cfg CD_root/isolinux/
RUN curl http://mirror.techfak.uni-bielefeld.de/linux/kernel/v4.x/linux-4.0.tar.xz | unxz | tar x \
  &&  echo -e '#!/bin/sh\n/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static $@' > /usr/bin/gcc \
  &&  chmod +x /usr/bin/gcc \
  &&  ( \
            cd linux-4.0 \
        &&  mv ../.config . \
        &&  make oldconfig ARCH=i386 \
        &&  make ARCH=i386 PATH=/x86_64-linux-musl/x86_64-linux-musl/bin:$PATH \
        &&  ln arch/x86/boot/bzImage ../CD_root/bzImage \
      ) \
  &&  rm -rf linux-4.0 \
  &&  rm /usr/bin/gcc
#without bash, making would fail with this error:
#  MKCAP   arch/x86/kernel/cpu/capflags.c
#./arch/x86/kernel/cpu/mkcapflags.sh: line 9: syntax error: unexpected "("
#COPY 26.bzImage CD_root/

# CFLAGS and not LDFLAGS cause the example on the toybox website uses it like this:
# RUN   curl http://landley.net/toybox/downloads/toybox-0.5.2.tar.gz | gunzip | tar x \
RUN   curl -L https://github.com/landley/toybox/archive/4c182c325716776a3e40394b175de479738e31a6.tar.gz | gunzip | tar x \
  &&  ( \
           cd toybox-4c182c325716776a3e40394b175de479738e31a6 \
        && echo -e '#!/bin/sh\n/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static $@' > /usr/bin/cc \
        && chmod +x /usr/bin/cc \
        && make defconfig \
        && rm /usr/bin/cc \
      ) \
  &&  ( \
           cd /i486-linux-musl/bin \
        && ln -fs i486-linux-musl-gcc i486-linux-musl-cc \
      ) \
  &&  ( \
           cd toybox-4c182c325716776a3e40394b175de479738e31a6 \
        && echo -e '#!/bin/sh\n/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -static $@' > /usr/bin/gcc \
        && chmod +x /usr/bin/gcc \
        && PATH=/i486-linux-musl/bin/:$PATH \
           CFLAGS=-static \
           CROSS_COMPILE=i486-linux-musl- \
           PREFIX=/initramfs \
           make toybox install V=1 \
      ) \
  &&  ./toybox-4c182c325716776a3e40394b175de479738e31a6/toybox; if [[ $? != 0 ]]; then echo "no toybox: exit code: $?"; exit 1; fi \
  &&  rm /usr/bin/gcc \
  &&  rm -rf toybox-4c182c325716776a3e40394b175de479738e31a6 \
  &&  rm /i486-linux-musl/bin/i486-linux-musl-cc

#TODO fix prefix here:
RUN   curl http://ftp.gnu.org/gnu/bash/bash-4.3.30.tar.gz | gunzip | tar x \
  &&  ( \
             cd bash-4.3.30 \
         &&  ./configure \
                --enable-static-link \
                --build=i386-linux \
                --host=x86_64-linux \
                --prefix=/ \
                --without-bash-malloc \
                PATH=/i486-linux-musl/i486-linux-musl/bin:$PATH \
                LDFLAGS_FOR_BUILD=-static \
                CC_FOR_BUILD=/x86_64-linux-musl/bin/x86_64-linux-musl-gcc \
                CC=/i486-linux-musl/bin/i486-linux-musl-gcc \
         &&  make RANLIB=/i486-linux-musl/i486-linux-musl/bin/ranlib \
         &&  make install DESTDIR=/initramfs \
         &&  /i486-linux-musl/i486-linux-musl/bin/strip /initramfs/bin/bash \
      ) \
  &&  rm -rf bash-4.3.30

RUN  curl http://www.busybox.net/downloads/busybox-1.23.1.tar.bz2 | bunzip2 | tar x \
  && echo -e '#!/bin/sh\n/i486-linux-musl/bin/i486-linux-musl-gcc -static $@' > /usr/bin/gcc \
  && chmod +x /usr/bin/gcc
COPY busybox-1.23.1-config-only-switchroot /busybox-1.23.1/.config
RUN  ( \
          cd busybox-1.23.1 && sed -i -re '256s/-1/1/' include/libbb.h \
       && PATH=/i486-linux-musl/i486-linux-musl/bin:$PATH \
          make \
          TGTARCH=i486 \
          LDFLAGS="--static" \
          EXTRA_CFLAGS=-m32 \
          EXTRA_LDFLAGS=-m32 \
          HOSTCFLAGS="-D_GNU_SOURCE" \
       && ln busybox ../initramfs/busybox-i486 \
     ) \
 &&  rm -rf busybox-1.23.1 /usr/bin/gcc

# remove bash locale stuff
RUN rm -rv initramfs/share

# copying into the container
COPY initramfs initramfs/

RUN  ( \
          cd initramfs \
       && find . | cpio -o -H newc | gzip > ../CD_root/initramfs_data.cpio.gz \
     ) \
 &&  ln /usr/share/syslinux/ldlinux.c32 /usr/share/syslinux/isolinux.bin CD_root/isolinux/ \
 &&  /opt/schily/bin/mkisofs \
       -allow-leading-dots \
       -allow-multidot \
       -l \
       -relaxed-filenames \
       -no-iso-translate \
       -o 9pboot.iso \
       -b isolinux/isolinux.bin \
       -c isolinux/boot.cat \
       -no-emul-boot \
       -boot-load-size 4 \
       -boot-info-table CD_root
