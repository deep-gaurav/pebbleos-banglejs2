# PebbleOS BangleJS2 Port

This is a port of PebbleOS to the BangleJS2 smartwatch.

## Repository Structure

This is a metarepo containing references to all repositories needed for the BangleJS2 port:

- [PebbleOS](https://github.com/deep-gaurav/PebbleOS) - Main firmware (branch: `banglejs2`)
- [nrfx](https://github.com/deep-gaurav/nrfx) - Nordic RF driver (branch: `pebbleos-banglejs2`)
- [pebbleapp](https://github.com/deep-gaurav/pebbleapp) - Companion phone app
- [qspi-flasher](https://github.com/deep-gaurav/qspi-flasher) - QSPI flashing tooling
- [log-reader](https://github.com/deep-gaurav/log-reader) - Log reading tooling

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

```bash
# Build qspi-flasher
cd qspi-flasher
cargo build --release

# Build log-reader
cd log-reader
cargo build --release
```

## Flashing

Use the qspi-flasher tooling to flash QSPI via SWD port.

## Publishing Instructions

The repos were prepared locally. To publish:

1. Create the following repos on GitHub:
   - `deep-gaurav/PebbleOS`
   - `deep-gaurav/nrfx`
   - `deep-gaurav/pebbleapp`
   - `deep-gaurav/qspi-flasher`
   - `deep-gaurav/log-reader`
   - `deep-gaurav/pebbleos-banglejs2`

2. Push each repo:
   ```bash
   # PebbleOS (already pushed)
   cd PebbleOS
   git push origin banglejs2:refs/heads/banglejs2

   # nrfx (already pushed)
   cd ../nrfx-temp
   git push origin pebbleos-banglejs2

   # pebbleapp (already pushed)
   cd ../mobileapp
   git push origin master

   # qspi-flasher
   cd ../qspi-flasher-temp
   git remote add origin git@github.com:deep-gaurav/qspi-flasher.git
   git push -u origin master

   # log-reader
   cd ../log-reader-temp
   git remote add origin git@github.com:deep-gaurav/log-reader.git
   git push -u origin master

   # metarepo
   cd ../pebbleos-banglejs2
   git remote add origin git@github.com:deep-gaurav/pebbleos-banglejs2.git
   git push -u origin master
   ```

3. Add submodules to metarepo:
   ```bash
   cd pebbleos-banglejs2
   git submodule add git@github.com:deep-gaurav/PebbleOS.git PebbleOS
   git submodule add git@github.com:deep-gaurav/nrfx.git nrfx
   git submodule add git@github.com:deep-gaurav/pebbleapp.git pebbleapp
   git submodule add git@github.com:deep-gaurav/qspi-flasher.git qspi-flasher
   git submodule add git@github.com:deep-gaurav/log-reader.git log-reader
   git commit -m "Add submodules"
   git push origin master
   ```

## Notes

- Only SWD port is exposed on BangleJS2, requiring special tooling for QSPI flashing
- Memory buffer logging is used for debugging via SWD
- nrfx fork includes LOG_BUFFER memory region changes for host-accessible logging
