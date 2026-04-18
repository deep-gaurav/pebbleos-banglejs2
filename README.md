# PebbleOS BangleJS2 Port

This is a port of PebbleOS to the BangleJS2 smartwatch.

## Prerequisites

- **Docker** - For building firmware in a consistent environment
- **probe-rs** - For flashing firmware via SWD (`cargo install probe-rs-tools`)
- **Rust toolchain** - For building QSPI flasher tools and memory logger (`curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`)
- **Python 3** - For QSPI flash image creation

## Quick Start

```bash
# Clone the repository
git clone --recursive <repository-url>
cd pebbleos-banglejs2

# Initialize submodules (if not cloned with --recursive)
make init-submodules

# Build everything
make build

# Build and flash (requires hardware connected via SWD)
make flash
```

## Repository Structure

This is a metarepo containing references to all repositories needed for the BangleJS2 port:

- [PebbleOS](https://github.com/deep-gaurav/PebbleOS) - Main firmware (branch: `banglejs2`)
- [nrfx](https://github.com/deep-gaurav/nrfx) - Nordic RF driver (branch: `pebbleos-banglejs2`)
- [pebbleapp](https://github.com/deep-gaurav/pebbleapp) - Companion phone app (branch: `banglejs2`)
- [qspi-flasher](https://github.com/deep-gaurav/qspi-flasher) - QSPI flashing tooling
- [bangle-memory-logger](https://github.com/deep-gaurav/bangle-memory-logger) - Memory-based log reading tooling

## What's Working

- Watch functionality
- Good battery life (~20%/day)
- Color display
- Touch emulated as button
- Sleep mode
- Vibration motor (PWM-based)
- QSPI flash access

## What's Not Working

- Peripherals (accelerometer, GPS, heart rate sensor, temperature, pressure, etc.)

## Building with Makefile

**Initialize submodules:**
```bash
make init-submodules
```

**Build firmware only:**
```bash
make build-firmware
```

**Build all tools (QSPI flasher + memory logger):**
```bash
make build-tools
```

**Build everything:**
```bash
make build
```

**Clean build artifacts:**
```bash
make clean
```

## Build and Flash Options

### Using Makefile (Recommended)

**Flash everything (requires hardware):**
```bash
make flash
```

**Flash QSPI only:**
```bash
make flash-qspi
```

**Flash main firmware only:**
```bash
make flash-firmware
```

**Read logs (requires hardware):**
```bash
make logs
```

### Using Shell Script

A convenience script is provided in `scripts/build_and_flash.sh`:

```bash
./scripts/build_and_flash.sh
```

Options:
- `--no-flash` - Build only, skip all flashing
- `--no-qspi` - Skip QSPI flash, only flash main firmware

## Manual Tool Building

If not using the Makefile:

**QSPI flasher:**
```bash
# Firmware
cd qspi-flasher/qspi-flasher-fw
cargo build --release

# Host tool
cd qspi-flasher/qspi-flasher-host
cargo build --release
```

**Memory logger:**
```bash
cd bangle-memory-logger
cargo build --release
```

## Flashing

The device must be connected via SWD and powered on. Use `probe-rs` for flashing:

```bash
# Flash main firmware
probe-rs download --chip nRF52840_xxAA PebbleOS/build/src/fw/tintin_fw.elf
probe-rs reset --chip nRF52840_xxAA
```

For QSPI flashing, use the qspi-flasher tooling (see `make flash-qspi`).

## Reading Logs

The bangle-memory-logger tool reads log buffers from the device via SWD:

```bash
./bangle-memory-logger/target/release/log-reader --elf PebbleOS/build/src/fw/tintin_fw.elf | tee output.log
```

Options:
- `--elf <path>` - Path to the firmware ELF file (for symbol resolution)
- Use `tee` to both display and save logs

The device must be connected via SWD and powered on.

## Notes

- Only SWD port is exposed on BangleJS2, requiring special tooling for QSPI flashing
- Memory buffer logging is used for debugging via SWD
- nrfx fork includes LOG_BUFFER memory region changes for host-accessible logging
