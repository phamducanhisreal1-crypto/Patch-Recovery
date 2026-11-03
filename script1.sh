
#!/usr/bin/env bash
set -Eeuo pipefail

# Usage: ./script1.sh recovery.download

INPUT="${1:-}"

if [[ -z "$INPUT" || ! -f "$INPUT" ]]; then
    echo "ERROR: Input recovery image not found."
    exit 1
fi

for cmd in file lz4 openssl; do
    command -v "$cmd" >/dev/null 2>&1 || {
        echo "ERROR: Missing dependency: $cmd"
        exit 1
    }
done

echo "[1/3] Detecting recovery image format..."

if lz4 -t "$INPUT" >/dev/null 2>&1; then
    echo "LZ4 compressed image detected."

    rm -f r.img
    lz4 -d -f "$INPUT" r.img
else
    echo "Not an LZ4 stream. Using input as raw image."

    cp "$INPUT" r.img
fi

if [[ ! -s r.img ]]; then
    echo "ERROR: Extracted image is empty."
    exit 1
fi

echo "[2/3] Recovery image prepared:"
file r.img
ls -lh r.img

echo "[3/3] Checking AVB key..."

if [[ ! -s phh.pem ]]; then
    echo "Generating RSA 4096-bit key..."
    openssl genrsa -f4 -out phh.pem 4096
fi

openssl rsa -in phh.pem -check -noout

echo "SHA256:"
sha256sum r.img

echo "Process 1 completed successfully."
