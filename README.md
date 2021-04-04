# haxe

An implementation of the haxe executable specified [here.](https://github.com/HaxeFoundation/haxe/wiki/Haxe-haxec-haxelib-plan#haxe-the-frontend)

The main idea is that it acts similarly to [haxeshim](https://github.com/lix-pm/haxeshim), and still works with older versions of the compiler and haxelib.

This repository is not yet functional.

## Build

Before building, you must run `haxelib install build.hxml --always`, in order to ensure you have all the correct library versions.

An executable can be built with CMake, using the CMakeLists.txt file. For example, `cmake -S . -B bin`. (See [cmake website](https://cmake.org/) for more details).

On Windows, you can uncomment `-D hlgen.makefile=vs2019` in the `build.hxml`, and run `haxe build.hxml` to generate Visual Studio solution files which can then be built using Visual Studio.

## Setup

- If you are on linux and your haxe compiler is not located in `/usr/bin/`, set an environment variable `HAXEPATH` to the path where the executable is found
- Once you have built the executable in `bin/`, run the `install-haxe.cmd` script if you are on Windows or otherwise the `install-haxe.sh` script
- You have to run this script everytime you install a new version of the Haxe compiler using the standard haxe installer
- If you just want to update this executable and you haven't used the installer or otherwise updated your haxe compiler, run the script with an `update` argument, (i.e. `install-haxe update` or `./install-haxe.sh update`)

## Usage

The haxe executable is used as the new frontend to the haxe compiler (haxec). It assumes the haxe compiler itself has been renamed to haxec ([Setup](#Setup) takes care of this).

It is used to run compilation commands, and before passing them onto the compiler it reads lock files, resolves all `-lib` flags, and finds the haxec executable to run.

Read [here](https://github.com/HaxeFoundation/haxe/wiki/Haxe-haxec-haxelib-plan#haxe-the-frontend) for more specific details

### Additional functionality

Running `haxe lib-setup` can be used to configure the global repository path.
This was added because in order to remove the dependency on haxelib, the haxe executable itself should be able to set this path and manage it.

## Reverting back to a normal haxe setup

- Make sure that the haxe and haxec executables are not running
- If you are on linux and your haxe executable is not located in `/usr/bin/`, set an environment variable `HAXEPATH` to the path where the executable is found
- Run the uninstall-haxe script found in the `bin/` directory
- You're back to a normal setup!
