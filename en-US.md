# Custom Resolution Manager for Linux

A bash script to easily manage custom display resolutions on Linux using xrandr.

## Features

- Create custom resolutions with specified width, height, and refresh rate
- Adjust display position
- Remove custom resolutions
- Remove or restore black borders
- Automatic startup configuration
- Save previous resolution settings

## Requirements

- xrandr
- cvt
- Linux-based operating system

## Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/custom-resolution-for-linux.git
cd custom-resolution-for-linux
chmod +x custom-resolution.sh
./custom-resolution.sh
```
## Command Line Arguments

When creating a new resolution the script accepts these arguments:

- `--no-apply`: Creates the custom resolution but doesn't apply it immediately
- `--apply-on-startup`: Configures the custom resolution to be applied automatically on system startup

Examples:
```bash
./custom-resolution.sh --no-apply
./custom-resolution.sh --apply-on-startup
```

## File Locations

The script manages several files across your system:

### Configuration Files
- Main config directory: `~/.config/custom-resolution/`
- Resolution setup script: `~/.config/custom-resolution/setup.sh`
- Previous resolution backup: `~/.config/custom-resolution/previous_resolution`

### Autostart Entry
- Desktop entry: `~/.config/autostart/custom-resolution.desktop`
