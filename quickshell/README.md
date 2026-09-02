# bork-quickshell-bar

Custom status bar built with Quickshell (only tested on hyprland)

# Screenshots
![Status Bar](https://files.catbox.moe/yvknzu.png)
![Entire Desktop](https://files.catbox.moe/ue8xww.png)

# Features

- Distro logo (by default Gentoo)
- Workspace indicator
- Clock (along with date and weekday)
- RAM usage display
- CPU usage display
- CPU temperature display
- Battery indicator
- Screen brightness indicator
- Volume bar
- Microphone indicator

# Installation

Keep in mind doas can be replaced with sudo or ran as root

## Gentoo
- doas emerge -aq eselect-repository
- doas eselect repository enable guru
- doas emerge --sync guru
- doas emerge -aq gui-apps/quickshell
- Clone this repository:
- git clone https://codeberg.org/iiBork/bork-quickshell-bar.git ~/.config/quickshell

- Run Quickshell: qs

## Arch (or arch based)
- yay -S quickshell-git (also avalible on pacman, but this has the latest updates and is the most likely to work)

- Clone this repository:
- git clone https://codeberg.org/iiBork/bork-quickshell-bar.git ~/.config/quickshell

- Run Quickshell: qs

## Fedora
- doas dnf install quickshell

- Clone this repository:
- git clone https://codeberg.org/iiBork/bork-quickshell-bar.git ~/.config/quickshell

- Run Quickshell: qs

## Debian
doas apt install quickshell
- Clone this repository:
- git clone https://codeberg.org/iiBork/bork-quickshell-bar.git ~/.config/quickshell

- Run Quickshell: qs

## Other distributions
If you need it on another distribution, just find out how to install quickshell on your distro of choice, and then do all steps starting on "git clone https://codeberg.org/iiBork/bork-quickshell-bar.git ~/.config/quickshell"


# Configuration

If you want to customize or fix anything, simply edit the shell.qml file located in ~/.config/quickshell

If you want to change the distro logo, swap out the ~/.config/quickshell/gentoo-logo.png file to whatever png or image file you'd like, then change the source in shell.qml on line 375.

I also recommend switching out the colors on the bar to colors matching your wallpaper, this can be done by switching the color code on line 163, to find the color code you want, just use an HTML color picker.

If some sensors aren't working (such as battery or cpu temps) it should be relatively easy to swap them out for correct ones, just find the part in the shell.qml file and swap out the source of the info.

# Requirements
- Quickshell (obviously)
- Hyprland (may work with other wayland compositors, but hyprland is the only one I have tested on)

# License
Do whatever you want
