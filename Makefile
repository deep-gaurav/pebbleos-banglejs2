.PHONY: help build build-firmware build-tools build-qspi-flash build-memory-logger flash flash-qspi flash-firmware clean init-submodules logs

REPO_ROOT := $(shell pwd)
PEBBLEOS_DIR := $(REPO_ROOT)/PebbleOS
QSPI_FLASHER_FW := $(REPO_ROOT)/qspi-flasher/qspi-flasher-fw
QSPI_FLASHER_HOST := $(REPO_ROOT)/qspi-flasher/qspi-flasher-host
MEMORY_LOGGER := $(REPO_ROOT)/bangle-memory-logger
BUILD_OUTPUT := $(PEBBLEOS_DIR)/build/src/fw/tintin_fw.elf
QSPI_FLASHER_FW_BIN := $(QSPI_FLASHER_FW)/target/thumbv7em-none-eabihf/release/qspi-flasher-fw
QSPI_FLASHER_HOST_BIN := $(QSPI_FLASHER_HOST)/target/release/qspi-flasher-host
MEMORY_LOGGER_BIN := $(MEMORY_LOGGER)/target/release/log-reader
CHIP := nRF52840_xxAA
DOCKER_IMAGE := ghcr.io/coredevices/pebbleos-docker

help:
	@echo "PebbleOS BangleJS2 Build System"
	@echo ""
	@echo "Setup:"
	@echo "  init-submodules  - Initialize and update all git submodules"
	@echo ""
	@echo "Build:"
	@echo "  build            - Build everything (firmware + all tools)"
	@echo "  build-firmware   - Build PebbleOS firmware only"
	@echo "  build-tools      - Build all tools (QSPI flasher + memory logger)"
	@echo "  build-qspi-flash - Build QSPI flasher firmware and host tool"
	@echo "  build-memory-logger - Build memory logger tool"
	@echo ""
	@echo "Flash:"
	@echo "  flash            - Flash QSPI and main firmware (requires hardware)"
	@echo "  flash-qspi       - Flash QSPI only (requires hardware)"
	@echo "  flash-firmware   - Flash main firmware only (requires hardware)"
	@echo ""
	@echo "Other:"
	@echo "  logs             - Start reading logs via SWD (requires hardware)"
	@echo "  clean            - Clean all build artifacts"
	@echo ""

init-submodules:
	@echo "Initializing git submodules..."
	git submodule update --init --recursive

build: build-firmware build-tools
	@echo "Build complete!"

build-firmware:
	@echo "Building PebbleOS firmware..."
	docker run --rm \
		-v "$(REPO_ROOT):/repo" \
		-w /repo/PebbleOS \
		"$(DOCKER_IMAGE)" \
		bash -c " \
			git config --global --add safe.directory /repo && \
			git config --global user.email 'build@local' && \
			git config --global user.name 'Build' && \
			pip install pillow freetype-py pyusb pyserial sh pypng pexpect 'cobs==1.0.0' 'ply==3.4' svg.path requests GitPython==1.0.1 pyelftools pycryptodome mock nose boto 'prompt_toolkit>=0.55' enum34 bitarray pep8 polib 'intelhex>=2.1,<3' protobuf grpcio-tools nanopb certifi libclang packaging pyftdi==0.56.0 pathlib libpebble2 && \
			rm -f build/.lock-waf_linux_build && \
			./waf configure --board=banglejs2 --relax_toolchain_restrictions --nohash --no-pulse-everywhere && \
			./waf build \
		"
	@echo "Firmware built: $(BUILD_OUTPUT)"

build-tools: build-qspi-flash build-memory-logger

build-qspi-flash:
	@echo "Building QSPI flasher firmware..."
	cd $(QSPI_FLASHER_FW) && cargo build --release
	@echo "Building QSPI flasher host tool..."
	cd $(QSPI_FLASHER_HOST) && cargo build --release
	@echo "QSPI flasher tools built:"
	@echo "  Firmware: $(QSPI_FLASHER_FW_BIN)"
	@echo "  Host:     $(QSPI_FLASHER_HOST_BIN)"

build-memory-logger:
	@echo "Building memory logger..."
	cd $(MEMORY_LOGGER) && cargo build --release
	@echo "Memory logger built: $(MEMORY_LOGGER_BIN)"

flash: flash-qspi flash-firmware
	@echo "Flash complete!"

flash-qspi: build-qspi-flash
	@echo "Creating QSPI flash image..."
	python3 $(REPO_ROOT)/scripts/create_spiflash.py $(PEBBLEOS_DIR) /tmp/banglejs_pebbleos_spiflash.hex
	@echo "Flashing QSPI flasher firmware..."
	probe-rs download --chip "$(CHIP)" $(QSPI_FLASHER_FW_BIN)
	probe-rs reset --chip "$(CHIP)"
	@echo "Flashing QSPI contents..."
	$(QSPI_FLASHER_HOST_BIN) --file /tmp/banglejs_pebbleos_spiflash.hex
	@echo "QSPI flash complete!"

flash-firmware: build-firmware
	@echo "Flashing main firmware..."
	probe-rs download --chip "$(CHIP)" $(BUILD_OUTPUT)
	probe-rs reset --chip "$(CHIP)"
	@echo "Firmware flash complete!"

logs: build-firmware
	@echo "Reading logs (Ctrl+C to stop)..."
	$(MEMORY_LOGGER_BIN) --elf $(BUILD_OUTPUT) | tee output.log

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(PEBBLEOS_DIR)/build
	rm -rf $(QSPI_FLASHER_FW)/target
	rm -rf $(QSPI_FLASHER_HOST)/target
	rm -rf $(MEMORY_LOGGER)/target
	rm -rf $(REPO_ROOT)/pebbleapp/target
	rm -f /tmp/banglejs_pebbleos_spiflash.hex
	@echo "Clean complete!"
