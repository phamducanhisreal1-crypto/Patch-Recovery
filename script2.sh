
#!/usr/bin/env bash
set -Eeuo pipefail

echo "[1/5] Preparing workspace..."

rm -rf unpack
mkdir -p unpack
cd unpack

echo "[2/5] Unpacking recovery..."

../magiskboot unpack ../r.img

ramdisk=""

if [[ -f vendor_ramdisk/recovery.cpio ]]; then
    ramdisk="vendor_ramdisk/recovery.cpio"
elif [[ -f vendor_ramdisk_recovery.cpio ]]; then
    ramdisk="vendor_ramdisk_recovery.cpio"
elif [[ -f ramdisk.cpio ]]; then
    ramdisk="ramdisk.cpio"
else
    echo "ERROR: Recovery ramdisk not found."
    exit 1
fi

echo "Selected ramdisk: $ramdisk"

../magiskboot cpio "$ramdisk" extract

RECOVERY="system/bin/recovery"

if [[ ! -s "$RECOVERY" ]]; then
    echo "ERROR: system/bin/recovery not found."
    exit 1
fi

echo "[3/5] Patching recovery binary..."

PATCHES=(
"e10313aaf40300aa6ecc009420010034:e10313aaf40300aa6ecc0094"
"eec3009420010034:eec3009420010035"
"3ad3009420010034:3ad3009420010035"
"50c0009420010034:50c0009420010035"
"080109aae80000b4:080109aae80000b5"
"20f0a6ef38b1681c:20f0a6ef38b9681c"
"23f03aed38b1681c:23f03aed38b9681c"
"20f09eef38b1681c:20f09eef38b9681c"
"26f0ceec30b1681c:26f0ceec30b9681c"
"24f0fcee30b1681c:24f0fcee30b9681c"
"27f02eeb30b1681c:27f02eeb30b9681c"
"b4f082ee28b1701c:b4f082ee28b970c1"
"9ef0f4ec28b1701c:9ef0f4ec28b9701c"
"9ef00ced28b1701c:9ef00ced28b9701c"
"2001597ae0000054:2001597ae1000054"
"2001597ac0000054:2001597ac1000054"
"9ef0fcec28b1701c:9ef0fced28b1701c"
"9ef00ced28b1701c:9ef00ced28b9701c"
"24f0f2ea30b1681c:24f0f2ea30b9681c"
"e0031f2a8e000014:200080528e000014"
"41010054a0020012f44f48a9:4101005420008052f44f48a9"
)

for patch in "${PATCHES[@]}"; do
    OLD="${patch%%:*}"
    NEW="${patch#*:}"

    echo "Applying: $OLD"

    ../magiskboot hexpatch "$RECOVERY" "$OLD" "$NEW"
done

echo "[4/5] Updating ramdisk..."

../magiskboot cpio "$ramdisk" \
    "add 0755 $RECOVERY $RECOVERY"

echo "[5/5] Repacking recovery..."

../magiskboot repack ../r.img new-boot.img

if [[ ! -s new-boot.img ]]; then
    echo "ERROR: Repacked image not found."
    exit 1
fi

cp new-boot.img ../recovery-patched.img

echo "Recovery patch completed."
sha256sum ../recovery-patched.img
