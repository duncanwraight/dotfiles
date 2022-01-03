# dunc's dotfiles

Until 23rd Dec 2021, this was a private repository containing dotfiles I've used with my Debian 11 laptop for about a year.

I'm starting a new role in January, and I'll be moving to Mac. Over the past couple of weeks I've been working on my dotfiles to allow me to transition as seamlessly as possible.

During this process I've found other people's dotfile repositories really useful, so I thought I'd take the opportunity to open mine up. Hopefully something contained within these files will prove useful to someone!

## Caveat

It's important to note that because of a few hardcoded paths, a private SSH submodule and device-specific builds in the Linux dotfiles, it's unlikely that following the installation instructions will work as expected.

However, if you had a totally fresh setup and just wanted to get up and running with Zsh and Neovim, you could amend the OS profiles found in `meta/profiles` to remove any of the "personal" stuff (e.g. the `ssh` config).

## Applications and configuration

The entire repository is managed by [Dotbot](https://github.com/anishathalye/dotbot) which is an incredible easy Python-based tool allowing us to set up symlinks between this repository and each dotfile's required location.

#### Linux

 - i3 window manager
 - Polybar
 - Rofi application launcher
 - Zsh with zsh-quickstart-kit (uses Zgenom and Oh My Zsh!)
 - Neovim

#### Mac

 - Zsh with zsh-quickstart-kit
 - Neovim
 - iTerm2 terminal
 - skhd for device-wide keyboard shortcuts

## Installation

### Mac
 1. Install Brew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
 2. Clone this repo...
 3. `cd` into the repository directory and run `git submodule update --init --recursive`
 4. Run `./install mac`
 5. Install the iTerm configuration from `iterm` folder (Preferences -> General and Profiles -> Import)

### Linux
Tested on Debian 11

 1. Install Git: `sudo apt update && sudo apt-get install git`
 2. Clone this repo...
 3. `cd` into the repository directory and run `git submodule update --init --recursive`
 4. Ensure that your `python` command returns version 3. If not, run `sudo apt-get install python-is-python3`
 5. Run `./install linux`

## Modifications

Each application has its own Dotbot configuration in `meta/configs`. Modify these files, or create your own.
Update an OS profile in `meta/profiles` by adding or removing the base name of a `meta/configs` `.yaml` file, e.g. `meta/configs/brew.yaml` simply becomes `brew` in `meta/profiles/mac`.
