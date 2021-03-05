# haxe #

An implementation of the haxe executable specified [here](https://github.com/HaxeFoundation/haxe/wiki/Haxe-haxec-haxelib-plan#haxe-the-frontend)

The main idea is that it acts like haxeshim, and still works with older versions of the compiler and haxelib.

## Build ##

To build the neko bytecode file, run build.hxml using the haxe compiler.

To build the executable, run

```nekotools boot -c run.n```

and then compile the generated c file.

## Setup ##

- Copy the install-haxe.cmd file if you are on Windows or otherwise the install-haxe.sh file into the haxe install directory
- Then, everytime you update haxe using the standard haxe installer, run this script and copy into this folder the new haxe executable
- The Windows script also sets up a `HAXEC_PATH` environment variable

## Usage ##

The haxe executable is used as the new frontend to the haxe compiler (haxec). It assumes the haxe compiler itself has been renamed to haxec.

It is used to run compilation commands, and before passing them onto the compiler it reads lock files, resolves all -lib flags, and finds the haxec executable to run.

Read [here](https://github.com/HaxeFoundation/haxe/wiki/Haxe-haxec-haxelib-plan#haxe-the-frontend) for more specific details

## Reverting back to a normal haxe setup ##

- Make sure that the haxe and haxec executables are not running
- Run the uninstall-haxe script in the `setup/` directory
- You're back to a normal setup!
- `HAXEC_PATH` environment variable is removed as well in the Windows script
