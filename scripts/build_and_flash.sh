#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DOCKER_IMAGE="ghcr.io/coredevices/pebbleos-docker"

QSPI_FLASHER="$REPO_ROOT/qspi-flasher/qspi-flasher-fw/target/thumbv7em-none-eabihf/release/qspi-flasher-fw"
QSPI_FLASH_HOST="$REPO_ROOT/qspi-flasher/qspi-flasher-host/target/release/qspi-flasher-host"
CHIP="nRF52840_xxAA"

NO_FLASH=0
NO_QSPI=0
PEBBLEOS_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-flash)
            NO_FLASH=1
            shift
            ;;
        --no-qspi)
            NO_QSPI=1
            shift
            ;;
        *)
            PEBBLEOS_DIR="$1"
            shift
            ;;
    esac
done

if [ -z "$PEBBLEOS_DIR" ]; then
    PEBBLEOS_DIR="$REPO_ROOT/PebbleOS"
fi

if [[ "$PEBBLEOS_DIR" != /* ]]; then
    PEBBLEOS_DIR="$(pwd)/$PEBBLEOS_DIR"
fi

BUILD_OUTPUT="$PEBBLEOS_DIR/build/src/fw/tintin_fw.elf"
SPIFLASH_HEX="/tmp/banglejs_pebbleos_spiflash.hex"

echo "=========================================="
echo "PebbleOS Build and Flash"
echo "=========================================="
echo "PebbleOS directory: $PEBBLEOS_DIR"
echo "Chip: $CHIP"
echo "Flash: $([ $NO_FLASH -eq 1 ] && echo 'NO (all)' || echo 'YES')"
echo "QSPI Flash: $([ $NO_QSPI -eq 1 ] && echo 'NO' || echo 'YES')"
echo ""

if [ ! -d "$PEBBLEOS_DIR" ]; then
    echo "Error: PebbleOS directory does not exist: $PEBBLEOS_DIR"
    exit 1
fi

BUILD_START=$(date +%s)
echo "Building PebbleOS in docker (board=banglejs2)..."

docker run --rm \
    -v "$REPO_ROOT:/repo" \
    -v "$REPO_ROOT/scripts:/tools" \
    -w /repo/PebbleOS \
    "$DOCKER_IMAGE" \
    bash -c "
        git config --global --add safe.directory /repo && \
        git config --global user.email 'test@test.com' && \
        git config --global user.name 'Test User' && \
        pip install pillow freetype-py pyusb pyserial sh pypng pexpect 'cobs==1.0.0' 'ply==3.4' svg.path requests GitPython==1.0.1 pyelftools pycryptodome mock nose boto 'prompt_toolkit>=0.55' enum34 bitarray pep8 polib 'intelhex>=2.1,<3' protobuf grpcio-tools nanopb certifi libclang packaging pyftdi==0.56.0 pathlib libpebble2 && \
        cd /repo/PebbleOS && \
        rm -f build/.lock-waf_linux_build && \
        ./waf configure --board=banglejs2 --relax_toolchain_restrictions --nohash --no-pulse-everywhere && \
        ./waf build 
    "

if [ ! -f "$BUILD_OUTPUT" ]; then
    echo "Error: Build output not found: $BUILD_OUTPUT"
    exit 1
fi

BUILD_END=$(date +%s)
FIRMWARE_MTIME=$(stat -c %Y "$BUILD_OUTPUT" 2>/dev/null || stat -f %m "$BUILD_OUTPUT" 2>/dev/null)
if [ "$FIRMWARE_MTIME" -lt "$BUILD_START" ]; then
    echo "Error: Firmware timestamp is older than build start - build may have failed silently"
    exit 1
fi
echo "Build verified: $BUILD_OUTPUT"
echo "Build time: $((BUILD_END - BUILD_START))s"
echo ""

if [ $NO_FLASH -eq 1 ]; then
    echo "=========================================="
    echo "Build complete (no flash)!"
    echo "=========================================="
    exit 0
fi

if [ $NO_QSPI -eq 0 ]; then
    echo "=========================================="
    echo "Creating QSPI flash image..."
    echo "=========================================="
    python3 "$SCRIPT_DIR/create_spiflash.py" "$PEBBLEOS_DIR" "$SPIFLASH_HEX"

    echo ""
    echo "=========================================="
    echo "Flashing QSPI flasher firmware via probe-rs..."
    echo "=========================================="
    probe-rs download --chip "$CHIP" "$QSPI_FLASHER"
    probe-rs reset --chip "$CHIP"

    echo ""
    echo "=========================================="
    echo "Flashing QSPI contents via qspi-flasher-host..."
    echo "=========================================="
    "$QSPI_FLASH_HOST" --file "$SPIFLASH_HEX"
else
    echo "=========================================="
    echo "Skipping QSPI flash (--no-qspi)"
    echo "=========================================="
fi

echo ""
echo "=========================================="
echo "Flashing main firmware via probe-rs..."
echo "=========================================="
probe-rs download --chip "$CHIP" "$BUILD_OUTPUT"
probe-rs reset --chip "$CHIP"

echo ""
echo "=========================================="
echo "Build and flash complete!"
echo "=========================================="
echo "Firmware: $BUILD_OUTPUT"
echo "QSPI flash: $SPIFLASH_HEX"
