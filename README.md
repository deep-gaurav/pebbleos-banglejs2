# PebbleOS BangleJS2 Port

This is a port of PebbleOS to the BangleJS2 smartwatch.

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

## Building

### Firmware

```bash
cd PebbleOS
git submodule update --init --recursive
./waf configure --board BANGLEJS2
./waf build
```

### Tools

**qspi-flasher:**
```bash
# Firmware (from qspi-flasher-fw/ directory)
cd qspi-flasher/qspi-flasher-fw
cargo build --release

# Host tool (from qspi-flasher-host/ directory)
cd qspi-flasher/qspi-flasher-host
cargo build --release
```

**bangle-memory-logger:**
```bash
cd bangle-memory-logger
cargo build --release
```

## Build and Flash Script

A convenience script is provided in `scripts/build_and_flash.sh` that handles the complete build and flash workflow:

```bash
./scripts/build_and_flash.sh
```

Options:
- `--no-flash` - Build only, skip all flashing
- `--no-qspi` - Skip QSPI flash, only flash main firmware

## Flashing

Use the qspi-flasher tooling to flash QSPI via SWD port.

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
