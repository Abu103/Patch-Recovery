#!/bin/bash

# Create a folder to unpack the image and move into it
mkdir -p unpack
cd unpack

# Unpack the image using magiskboot
../magiskboot unpack ../r.img || exit 1

# Extract the ramdisk from the image
../magiskboot cpio ramdisk.cpio extract || exit 1

# Reverse fastbootd ENG mode check (this will apply hex patches to the recovery binary)
../magiskboot hexpatch system/bin/recovery e10313aaf40300aa6ecc009420010034 e10313aaf40300aa6ecc0094 # 20 01 00 35
../magiskboot hexpatch system/bin/recovery eec3009420010034 eec3009420010035
../magiskboot hexpatch system/bin/recovery 3ad3009420010034 3ad3009420010035
../magiskboot hexpatch system/bin/recovery 50c0009420010034 50c0009420010035
../magiskboot hexpatch system/bin/recovery 080109aae80000b4 080109aae80000b5
../magiskboot hexpatch system/bin/recovery 20f0a6ef38b1681c 20f0a6ef38b9681c
../magiskboot hexpatch system/bin/recovery 23f03aed38b1681c 23f03aed38b9681c
../magiskboot hexpatch system/bin/recovery 20f09eef38b1681c 20f09eef38b9681c
../magiskboot hexpatch system/bin/recovery 26f0ceec30b1681c 26f0ceec30b9681c
../magiskboot hexpatch system/bin/recovery 24f0fcee30b1681c 24f0fcee30b9681c
../magiskboot hexpatch system/bin/recovery 27f02eeb30b1681c 27f02eeb30b9681c
../magiskboot hexpatch system/bin/recovery b4f082ee28b1701c b4f082ee28b970c1
../magiskboot hexpatch system/bin/recovery 9ef0f4ec28b1701c 9ef0f4ec28b9701c

# Repack the ramdisk with the patched recovery image
../magiskboot cpio ramdisk.cpio 'add 0755 system/bin/recovery system/bin/recovery' || exit 1

# Repack the final boot image with the patched recovery
../magiskboot repack ../r.img new-boot.img || exit 1

# Move the newly packed image to the final output location
cp new-boot.img ../recovery-patched.img || exit 1

# Now sign the recovery image using AVB and a generated public key
python3 ../avbtool extract_public_key --key ../phh.pem --output ../phh.pub.bin || exit 1
python3 ../avbtool add_hash_footer --partition_name recovery --partition_size $(wc -c recovery-patched.img | cut -f 1 -d ' ') --image recovery-patched.img --key ../phh.pem --algorithm SHA256_RSA4096 || exit 1

# Create a folder for output and move the image into it
mkdir -p output && cd output
mv ../recovery-patched.img recovery.img || exit 1

# Package the recovery image into a tar file
tar cvf fastbootd-recovery.tar recovery.img || exit 1

# Create a checksum for the tar file and move it to the final location
md5sum -t fastbootd-recovery.tar >> fastbootd-recovery.tar
mv fastbootd-recovery.tar fastbootd-recovery.tar.md5 || exit 1
