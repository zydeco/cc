# cc

My random collection of computercraft things

## pkg

Minimal package manager.

* Download packages from github based on own `pkg` format
    * See `pkg` files in this repo for examples
* Does not support dependencies

### Installation

    wget https://raw.githubusercontent.com/zydeco/cc/main/pkg.lua

### Install packages

by github path or full URL

    pkg install zydeco/cc/ui
    pkg install zydeco/cc/colony

### Uninstall packages

by package name

    pkg uninstall ui

### List installed packages:

    pkg list

## ui

UI framework used by some other apps here.

### Installation

    pkg install zydeco/cc/ui

### Usage

Poorly documented. I added features as I needed them.

See `ui_demo.lua` for a simple example.

## colony

UI app that shows all kinds of info from [Minecolonies](https://minecolonies.com) using an [AdvancedPeripherals](https://github.com/SirEndii/AdvancedPeripherals) colony integrator.

Runs well on a pocket computer and also on external monitors. Can replace the minecolonies clipboard, resource scroll and the UI of several buildings for viewing information.

Using modems, a server can run on one computer with a colony integrator, and the UI can run as a client on another with a modem (wired, wireless, or ender).

### Installation

    pkg install zydeco/cc/colony

### Usage

Run with directly attached colony integrator:

    colony

Run with directly attached colony integrator, on external monitor on the left side:

    colony --monitor=left --scale=0.5

Run server through modem on left side:

    colony/server left

List remote colonies (modem side defaults to back):

    colony --remote=?

Run for remote colony called "My Awesome Colony", with modem on the left side:

    colony "--remote=My Awesome Colony" --modem=left


## netex

Network Explorer: shows all connected devices (directly or through modems), their exposed functions, and allows calling them.

Useful to explore the API of different machines.

### Installation

    pkg install zydeco/cc/netex

### Usage

    netex

## imged

Image Editor

Can edit images up to the screen size. Images can be loaded and drawn by the UI framework.

### Installation

    pkg install zydeco/cc/imged

### Usage

Create new file:

    imged filename width height

Open existing file:

    imged filename


There are two brushes, for left and right click. Click or right-click to paint.

* Hold ctrl for menu. While in menu:
    * Click colors to change
    * Click or right-click a character to use it as brush
* Press q to quit without saving
* Press s to save

