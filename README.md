# MT4 Wine Compiler

![Docker](https://github.com/d0whc3r/mt4-wine-compiler/actions/workflows/docker-publish.yml/badge.svg)

A Docker image designed to compile MetaTrader 4 (MT4) `.mq4` files into `.ex4` executables using a headless Wine environment. This tool allows you to integrate MT4 compilation into your CI/CD pipelines or run it on Linux/macOS systems without needing a full Windows VM.

## Features

- **Base Image**: Ubuntu Noble (via `linux/amd64` emulation for Wine compatibility).
- **Wine**: Latest stable WineHQ version for reliable Windows emulation.
- **Ease of Use**: Simple entrypoint script handles compilation arguments automatically.
- **CI/CD Ready**: Includes tests and a GitHub Actions workflow for easy integration.
- **Optimized**: Uses Docker layer caching for fast builds.

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your machine.

### Installation

You can pull the pre-built image from the GitHub Container Registry:

```bash
docker pull ghcr.io/d0whc3r/mt4-wine-compiler:master
```

Or build it locally:

```bash
git clone https://github.com/d0whc3r/mt4-wine-compiler.git
cd mt4-wine-compiler
docker build -t mt4-compiler .
```

## Usage

### Basic Compilation

To compile a single `.mq4` file, mount the directory containing your source code to `/home/wine/src` inside the container and pass the file path as an argument.

```bash
docker run --rm -v $(pwd)/src:/home/wine/src ghcr.io/d0whc3r/mt4-wine-compiler:master /home/wine/src/Expert.mq4
```

The compiled `Expert.ex4` file will be created in the same directory as the source file.

### Custom Output Path

You can specify a different destination for the compiled file by providing a second argument:

```bash
docker run --rm -v $(pwd)/src:/home/wine/src ghcr.io/d0whc3r/mt4-wine-compiler:master /home/wine/src/Expert.mq4 /home/wine/src/Compiled/Expert.ex4
```

### Using Custom Includes and Libraries

If your EA relies on custom include files (`.mqh`) or libraries (`.ex4`/`.dll`) that are not part of the standard MT4 distribution, you need to ensure they are available to the compiler.

The compiler expects includes to be relative to the source file or in the standard include path. The easiest way is to mount your entire project structure.

**Example Project Structure:**
```
my-project/
├── Experts/
│   └── MyExpert.mq4
├── Include/
│   └── MyLib.mqh
└── Libraries/
    └── MyLib.ex4
```

**Command:**
```bash
docker run --rm -v $(pwd)/my-project:/home/wine/project ghcr.io/d0whc3r/mt4-wine-compiler:master /home/wine/project/Experts/MyExpert.mq4
```

### Batch Compilation (Multiple Files)

To compile multiple files or an entire project, you can use a simple shell script to iterate over your source files.

**Example `compile_all.sh`:**

```bash
#!/bin/bash

# Directory containing your project
PROJECT_DIR="$(pwd)/my-project"

# Find all .mq4 files in the Experts directory
find "$PROJECT_DIR/Experts" -name "*.mq4" | while read source_file; do
    # Calculate relative path for display
    rel_path=${source_file#$PROJECT_DIR/}
    echo "Compiling $rel_path..."
    
    # Run the compiler container
    # We mount the project root to /home/wine/project so includes work correctly
    # We pass the full path to the source file inside the container
    docker run --rm \
        -v "$PROJECT_DIR:/home/wine/project" \
        ghcr.io/d0whc3r/mt4-wine-compiler:master \
        "/home/wine/project/Experts/$(basename "$source_file")"
        
    if [ $? -eq 0 ]; then
        echo "✅ Success: $rel_path"
    else
        echo "❌ Failed: $rel_path"
    fi
done
```

### Docker Compose

You can define the compiler as a service in `docker-compose.yml` for reproducible builds.

**Simple Example:**

```yaml
services:
  compiler:
    image: ghcr.io/d0whc3r/mt4-wine-compiler:master
    volumes:
      - ./src:/home/wine/src
    # Override command to compile a specific file
    command: ["/home/wine/src/Expert.mq4"]
```

**Complex Project with Dependencies:**

For projects with multiple components and dependencies, it's best practice to create a dedicated build script instead of using inline commands.

**Project Structure:**
```
my-mt4-project/
├── project/
│   ├── Experts/
│   │   ├── MyEA1.mq4
│   │   └── MyEA2.mq4
│   ├── Include/
│   │   └── MyLibrary.mqh
│   └── lib/              (optional: external libraries)
│       └── external-lib/
├── scripts/
│   └── build_project.sh
├── docker-compose.yml
└── artifacts/            (output directory)
```

**`docker-compose.yml`:**
```yaml
services:
  compiler:
    image: ghcr.io/d0whc3r/mt4-wine-compiler:master
    entrypoint: ["/bin/bash"]
    command: ["/home/wine/scripts/build_project.sh"]
    volumes:
      - ./project:/home/wine/project
      - ./scripts:/home/wine/scripts
      - ./artifacts:/home/wine/artifacts
```

**`scripts/build_project.sh`:**
```bash
#!/bin/bash
set -e

echo "Starting MT4 project build..."

# Copy project sources to Wine environment
cp -r /home/wine/project/Experts /home/wine/.mt4/drive_c/mt4/
cp -r /home/wine/project/Include /home/wine/.mt4/drive_c/mt4/

# Copy library dependencies (if you have external libraries)
if [ -d "/home/wine/project/lib" ]; then
    mkdir -p /home/wine/.mt4/drive_c/mt4/Include/External
    cp -r /home/wine/project/lib/* /home/wine/.mt4/drive_c/mt4/Include/External/
fi

# Compile all .mq4 files
find "/home/wine/.mt4/drive_c/mt4/Experts" -name "*.mq4" | while read source_file; do
    /home/wine/entrypoint.sh "$source_file" || exit 1
done

# Copy compiled files to artifacts
mkdir -p /home/wine/artifacts
cp /home/wine/.mt4/drive_c/mt4/Experts/*.ex4 /home/wine/artifacts/ 2>/dev/null || true

echo "✅ Build completed!"
```

**Run the build:**
```bash
docker-compose up
```

> **Note**: See `examples/` directory for complete working examples.

## Testing

To run the tests locally, first install dependencies:

```bash
pnpm install
```

Then run the tests:

```bash
pnpm test
```

This will:
1. Build the Docker image (if not already built).
2. Run a suite of BATS tests to verify successful compilation and error handling.

## Troubleshooting

### "File not found" errors
Ensure you are mounting the volume correctly. The path inside the container (`/home/wine/src`) must match the path you are passing to the command.

### "Cannot open include file"
If your code uses `#include <MyLib.mqh>`, make sure `MyLib.mqh` is either in the same directory as your source file or in a directory that is mounted and accessible. The compiler searches in standard locations and relative to the source.

### Platform warnings on ARM (M1/M2/M3 Macs)
You might see a warning like `WARNING: The requested image's platform (linux/amd64) does not match the detected host platform`. This is normal. The image forces `linux/amd64` because Wine and the MT4 compiler are 32-bit Windows applications that require x86 architecture. Docker's emulation handles this automatically.
