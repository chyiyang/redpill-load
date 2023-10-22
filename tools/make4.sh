#!/usr/bin/env bash
          echo 'Clean Directory!!!!!!!!!!!!!'
          rm -rf /opt/build/pat
          rm -rf /opt/build/synoesp

          #pataddress="https://global.download.synology.com/download/DSM/release/7.1.1/42962-1/DSM_RS3618xs_42962.pat"
          pataddress="https://global.download.synology.com/download/DSM/release/7.1.1/42962/DSM_SA6400_42962.pat"
          toolchain="https://downloads.sourceforge.net/project/dsgpl/Tool%20Chain/DSM%207.0.0%20Tool%20Chains/Intel%20x86%20Linux%204.4.180%20%28Broadwellnk%29/broadwellnk-gcc750_glibc226_x86_64-GPL.txz"
          linuxsrc="https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.180.tar.xz"

          patfile=$(basename ${pataddress} | while read; do echo -e ${REPLY//%/\\x}; done)
          echo "::set-output name=patfile::$patfile"
          
          # install bsdiff
          apt-get install -y bsdiff cpio xz-utils
          # install libelf-dev, libssl-dev
          apt-get install libelf-dev libssl-dev

          #ls -al $GITHUB_WORKSPACE/
          [ ! -d /opt/build ] && mkdir /opt/build
          [ ! -d /opt/dist ] && mkdir /opt/dist
          cd /opt/build
          [ ! -f ds.pat ] && curl -kL ${pataddress} -o ds.pat
          [ ! -f toolchain.txz ] && curl -kL ${toolchain} -o toolchain.txz
          [ ! -f linux.tar.xz ] && curl -kL ${linuxsrc} -o linux.tar.xz
          
          # download old pat for syno_extract_system_patch # thanks for jumkey's idea.
          [ ! -f oldpat.tar.gz ] && curl -kL https://global.download.synology.com/download/DSM/release/7.0.1/42218/DSM_DS3622xs%2B_42218.pat -o oldpat.tar.gz
          [ ! -d /opt/build/synoesp ] && mkdir synoesp && tar -C ./synoesp/ -xf oldpat.tar.gz rd.gz
          cd synoesp
          xz -dc < rd.gz >rd 2>/dev/null || echo "extract rd.gz"
          echo "finish"
          cpio -idm <rd 2>&1 || echo "extract rd"
          mkdir extract 
          cd extract
          cp ../usr/lib/libcurl.so.4 ../usr/lib/libmbedcrypto.so.5 ../usr/lib/libmbedtls.so.13 ../usr/lib/libmbedx509.so.1 ../usr/lib/libmsgpackc.so.2 ../usr/lib/libsodium.so ../usr/lib/libsynocodesign-ng-virtual-junior-wins.so.7 ../usr/syno/bin/scemd ./
          ln -s scemd syno_extract_system_patch
          cd ../..
          mkdir pat
          #tar xf ds.pat -C pat
          ls -lh ./
          LD_LIBRARY_PATH=synoesp/extract synoesp/extract/syno_extract_system_patch ds.pat pat || echo "extract latest pat"
          echo "test4"
          # is update_pack
          if [ ! -f "pat/zImage" ]; then
            cd pat
            ar x $(ls flashupdate*)
            tar xf data.tar.xz
            cd ..
          fi
          echo "test5"
          [ ! -d /opt/build/toolchain ] && mkdir toolchain && tar xf toolchain.txz -C toolchain
          [ ! -d /opt/build/linux-src ] && mkdir linux-src && tar xf linux.tar.xz --strip-components 1 -C linux-src
          # extract vmlinux
          ./linux-src/scripts/extract-vmlinux pat/zImage > vmlinux
          # sha256
          sha256sum ds.pat >> checksum.sha256
          sha256sum pat/zImage >> checksum.sha256
          sha256sum pat/rd.gz >> checksum.sha256
          sha256sum vmlinux >> checksum.sha256
          cat checksum.sha256
          # patch vmlinux
          # vmlinux_mod.bin
          # New fabio patching method 
          echo "Patching Kernel"
          curl --insecure -L https://github.com/pocopico/tinycore-redpill/raw/main/tools/bzImage-to-vmlinux.sh -o bzImage-to-vmlinux.sh
          curl --insecure -L https://github.com/pocopico/tinycore-redpill/raw/main/tools/kpatch -o kpatch
           
          chmod 777 kpatch
          chmod 777 bzImage-to-vmlinux.sh
           
          echo "Current path `pwd`"

          ls -ltr 

          ./kpatch /opt/build/vmlinux /opt/build/vmlinux_mod.bin 
          git clone https://github.com/kiler129/recreate-zImage.git
          chmod +x recreate-zImage/rebuild_kernel.sh
          cd linux-src
          # ---------- make zImage_mod
          # Make file more anonymous
          export KBUILD_BUILD_TIMESTAMP="1970/1/1 00:00:00"
          export KBUILD_BUILD_USER="root"
          export KBUILD_BUILD_HOST="localhost"
          export KBUILD_BUILD_VERSION=0
          export ARCH=x86_64
          export CROSS_COMPILE=/opt/build/toolchain/x86_64-pc-linux-gnu/bin/x86_64-pc-linux-gnu-
          #make olddefconfig
          make defconfig
          # change to lzma
          sed -i 's/CONFIG_KERNEL_GZIP=y/# CONFIG_KERNEL_GZIP is not set/' .config
          sed -i 's/# CONFIG_KERNEL_LZMA is not set/CONFIG_KERNEL_LZMA=y/' .config
#          << see_below
          make clean
          sed -i 's/bzImage: vmlinux/bzImage: /' arch/x86/Makefile
          make vmlinux -j4 || true # make some *.o inspire by UnknowO
          cp ../vmlinux_mod.bin vmlinux # vmlinux_mod.bin is already stripped of debugging and comments, strippe again should be ok
          make bzImage
          sed -i 's/bzImage: /bzImage: vmlinux/' arch/x86/Makefile
          cp arch/x86/boot/bzImage ../zImage_mod
          make clean
#          see_below
          sed -i 's/ ld -/ ${CROSS_COMPILE}ld -/' ../recreate-zImage/rebuild_kernel.sh
          sed -i 's/(ld -/(${CROSS_COMPILE}ld -/' ../recreate-zImage/rebuild_kernel.sh
          sed -i 's/ gcc / ${CROSS_COMPILE}gcc /' ../recreate-zImage/rebuild_kernel.sh
          sed -i 's/ nm / ${CROSS_COMPILE}nm /' ../recreate-zImage/rebuild_kernel.sh
          sed -i 's/ objcopy / ${CROSS_COMPILE}objcopy /' ../recreate-zImage/rebuild_kernel.sh
          sed -i 's/(objdump /(${CROSS_COMPILE}objdump /' ../recreate-zImage/rebuild_kernel.sh
          sed -i 's/ readelf / ${CROSS_COMPILE}readelf /' ../recreate-zImage/rebuild_kernel.sh
          ../recreate-zImage/rebuild_kernel.sh $PWD/../linux-src ../vmlinux_mod.bin ../zImage_mod
          # ----------
          cd ..
          bsdiff pat/zImage zImage_mod diff.bsp
          echo '---copy file---'
          #cp vmlinux /opt/dist
          #cp vmlinux_mod.bin /opt/dist
          cp diff.bsp /opt/dist
          cp checksum.sha256 /opt/dist
          echo '---END---'
