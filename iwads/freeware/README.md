# FreeDOOM WAD Builder

This directory contains scripts and a Dockerfile to build FreeDOOM WADs from source using Docker containers.

## Files

- `Dockerfile.freedoom` - Docker container definition for building FreeDOOM
- `build-freedoom.ps1` - PowerShell script (Windows)
- `build-freedoom.sh` - Bash script (Linux/macOS)

## Quick Start

### Windows (PowerShell)
```powershell
.\build-freedoom.ps1
```

### Linux/macOS (Bash)
```bash
./build-freedoom.sh
```

## What This Does

1. **Builds a Container**: Creates a Docker image with all dependencies needed to compile FreeDOOM
2. **Compiles FreeDOOM**: Downloads the latest FreeDOOM source and builds the WAD files
3. **Extracts WADs**: Copies the built WAD files to your local directory
4. **Cleans Up**: Removes temporary containers and images (unless specified otherwise)

## Output

The scripts will generate these files:
- `freedoom1.wad` - FreeDOOM Phase 1 (Doom I compatible)
- `freedoom2.wad` - FreeDOOM Phase 2 (Doom II compatible)

## Script Options

### PowerShell Script
- `-KeepContainer` - Don't remove the container after extraction
- `-KeepImage` - Don't remove the image after completion
- `-Verbose` - Show verbose output during build

### Bash Script
- `--keep-container` - Don't remove the container after extraction
- `--keep-image` - Don't remove the image after completion
- `--verbose` - Show verbose output during build
- `--help` - Show help message

## Example Usage

```powershell
# Build with verbose output and keep the image for future use
.\build-freedoom.ps1 -Verbose -KeepImage

# Build quietly (default)
.\build-freedoom.ps1
```

```bash
# Build with verbose output and keep the image for future use
./build-freedoom.sh --verbose --keep-image

# Build quietly (default)
./build-freedoom.sh
```

## Prerequisites

- Docker installed and running
- Internet connection (for downloading source code)
- Sufficient disk space (build process requires ~500MB temporarily)

## What is FreeDOOM?

FreeDOOM is a project to create a complete, free content IWAD for the Doom engine. It provides:

- **freedoom1.wad**: Compatible with Ultimate Doom (E1M1-E4M9)
- **freedoom2.wad**: Compatible with Doom II (MAP01-MAP32)

These WADs can be used with any Doom source port, including Odamex, without requiring the original commercial game files.

## Usage with Dockermex

After building the WADs:

1. Update your `.env` file to point `IWAD_FOLDER` to this directory
2. In your Odamex server configurations, specify:
   - `IWAD=freedoom1.wad` for Doom I maps
   - `IWAD=freedoom2.wad` for Doom II maps and most PWADs
3. Start your servers normally

## Troubleshooting

### "Docker not found"
Ensure Docker is installed and running on your system.

### "Dockerfile not found"
Make sure you're running the script from the `iwads/freeware` directory.

### "No WAD files found"
The build may have failed. Try running with `-Verbose` or `--verbose` to see detailed output.

### Build takes too long
The initial build downloads and compiles everything from source, which can take 5-15 minutes depending on your system and internet connection. Subsequent builds using a kept image will be much faster.

## Build Time

- **First build**: 5-15 minutes (downloads source, compiles everything)
- **Using kept image**: ~30 seconds (just runs the build)
- **Generated files**: ~20MB total

## License

FreeDOOM is released under a modified BSD license. The generated WAD files are free to use and distribute.
