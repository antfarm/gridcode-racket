# gridcode

A simple grid-based simulation framework for computational exploration.

## Installation

### Prerequisites

**Racket 8.0+**

macOS:
```bash
brew install racket
```

Linux (Ubuntu/Debian):
```bash
sudo apt install racket
```

Linux (Fedora/RHEL):
```bash
sudo dnf install racket
```

Windows: Download from [racket-lang.org](https://racket-lang.org/)

### Get the Project
```bash
git clone https://github.com/antfarm/gridcode.git
cd gridcode
```

### Install the Package
```bash
raco pkg install --link ../gridcode
```

## Usage

Programs are written using the GridCode DSL in `.grid` files with the `#lang gridcode` language. For reference, have a look at the example programs.

Run the examples:
```bash
# Conway's Game of Life
./bin/gridcode examples/life.grid

# Pong
./bin/gridcode examples/pong.grid

# Minimal Demo
./bin/gridcode examples/hello.grid
```