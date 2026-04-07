#!/usr/bin/env python3
"""Create QSPI flash image with system resources at correct offset."""

import os
import sys

# QSPI flash size (8MB for banglejs2/GD25Q64)
QSPI_SIZE = 0x800000

# System resources bank 0 offset for banglejs2 (from flash_region_mx25u.h)
# SYSTEM_RESOURCES_BANK_0 begins at 0x100000
RESOURCES_OFFSET = 0x100000


def create_spiflash_image(resources_file, output_file):
    """Create a QSPI flash image with resources at offset 0x200000 for asterix."""

    # Read resources
    with open(resources_file, "rb") as f:
        resources_data = f.read()

    print(
        f"Resources size: {len(resources_data)} bytes ({len(resources_data) / 1024:.1f}KB)"
    )

    # Create 8MB buffer initialized to 0xFF (erased flash)
    flash_data = bytearray([0xFF] * QSPI_SIZE)

    # Place resources at offset 0x100000
    offset = RESOURCES_OFFSET
    flash_data[offset : offset + len(resources_data)] = resources_data

    print(f"Placed resources at offset 0x{offset:06x}")

    # Write as binary first (for reference)
    bin_file = "/tmp/banglejs_pebbleos_spiflash.bin"
    with open(bin_file, "wb") as f:
        f.write(flash_data)
    print(f"Binary file written to: {bin_file}")

    # Create Intel hex format using proper algorithm
    hex_lines = []
    segment_size = 0x10000  # 64KB

    for segment in range(QSPI_SIZE // segment_size):
        segment_start = segment * segment_size
        segment_end = min(segment_start + segment_size, len(flash_data))
        segment_data = flash_data[segment_start:segment_end]

        # Skip segments that are all 0xFF (empty)
        if all(b == 0xFF for b in segment_data):
            continue

        # Write Extended Linear Address record for this segment
        high_address = (segment_start >> 16) & 0xFFFF
        # Extended linear address: 02 type 04 high_addr checksum
        ela_checksum = (
            0x02 + 0x04 + (high_address >> 8) + (high_address & 0xFF)
        ) & 0xFF
        ela_checksum = (256 - ela_checksum) & 0xFF
        hex_lines.append(f":02000004{high_address:04X}{ela_checksum:02X}")

        # Write data records for this segment
        for offset in range(0, len(segment_data), 16):
            chunk = segment_data[offset : offset + 16]
            if not chunk:
                break

            local_address = offset
            byte_count = len(chunk)

            # Calculate checksum: byte_count + address_high + address_low + type + data
            checksum = (
                byte_count
                + ((local_address >> 8) & 0xFF)
                + (local_address & 0xFF)
                + 0x00
            )
            for b in chunk:
                checksum = (checksum + b) & 0xFF
            checksum = (256 - checksum) & 0xFF

            hex_line = f":{byte_count:02X}{local_address:04X}00{chunk.hex().upper()}{checksum:02X}"
            hex_lines.append(hex_line)

    # End of file record
    hex_lines.append(":00000001FF")

    # Write hex file
    with open(output_file, "w") as f:
        f.write("\n".join(hex_lines))

    print(f"Intel hex file written to: {output_file}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: create_spiflash.py <pebbleos_dir> [output_file]")
        sys.exit(1)

    pebbleos_dir = sys.argv[1]
    output_file = (
        sys.argv[2] if len(sys.argv) > 2 else "/tmp/banglejs_pebbleos_spiflash.hex"
    )
    resources_file = os.path.join(pebbleos_dir, "build/system_resources.pbpack")

    if not os.path.exists(resources_file):
        print(f"Error: {resources_file} not found")
        sys.exit(1)

    create_spiflash_image(resources_file, output_file)
