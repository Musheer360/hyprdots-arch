# hyprdots-arch

> A modernized, one-click Arch Linux + Hyprland rice installer and configuration suite.
> Featuring dynamic Material You (M3) theming powered by **Matugen**, animated Waybar island designs, GTK4 SwayNC notifications, Rofi launcher, and Hyprland 0.56+ with modern **Lua** configurations.

---

## Features

- **Hyprland 0.56+ with Lua Configuration**: Migrated fully to canonical Lua configuration (`~/.config/hypr/hyprland.lua`).
- **Dynamic Theming via Matugen 4**: Generate harmonious palettes on-the-fly for Hyprland, Waybar, Kitty, Rofi, Cava, GTK3/4, and Vesktop from any wallpaper.
- **awww Wallpaper Daemon**: Seamless transitions with the modern successor to `swww`.
- **Customizable Waybar**: 5 modular layouts and 4 aesthetic styles switchable via rofi menus.
- **GTK4 SwayNC**: Fully integrated notification and quick control center with volume sliders and media controls.
- **One-Click Automated Installer**: Fully idempotent setup script for a fresh Arch installation with base packages, AUR packages (`paru`), login manager (`greetd + tuigreet`), and Oh-My-Zsh shell.

---

## Requirements

- **OS**: Fresh Arch Linux (or Arch-based distribution).
- **User**: Non-root user with `sudo` privileges.
- **Disk Space**: At least 5 GB free disk space.
- **Network**: Active internet connection.

---

## Installation

Run the one-liner installer:

```bash
git clone https://github.com/Musheer360/hyprdots-arch.git ~/hyprdots-arch
cd ~/hyprdots-arch
./install.sh
```

### Automated / Non-interactive Installation

For unattended installations (e.g. CI or fresh scripts):

```bash
NONINTERACTIVE=1 ./install.sh
```

### Installer Options

| Flag | Description |
|---|---|
| `--no-extras` | Skip optional extra applications (`zen-browser-bin`, `vesktop-bin`) |
| `--dots-only` | Deploy dotfiles, runtime symlinks, wallpapers, and run self-validation |
| `--packages-only` | Install official + AUR packages and configure services only |
| `--skip-greetd` | Skip `greetd` + `tuigreet` login manager configuration |
| `-h, --help` | Show installer help message |

---

## Keybindings Reference

Default modifier: `SUPER` (Windows key).

| Keybinding | Action | Description |
|---|---|---|
| `SUPER + Return` | `kitty` | Launch terminal |
| `SUPER + SHIFT + Return` | `kitty (floating)` | Launch floating terminal window (800x550) |
| `SUPER + Q` | Close window | Gracefully close active window |
| `SUPER + D` | `rofi -show drun` | Application launcher |
| `SUPER + E` | `nautilus` | Graphical file manager |
| `SUPER + SHIFT + E` | `kitty yazi` | Terminal file manager (Yazi) |
| `SUPER + Space` | Toggle Float | Toggle active window floating state |
| `SUPER + P` | Pseudo Tile | Toggle pseudotiling (dwindle layout) |
| `SUPER + J` | Toggle Split | Toggle horizontal / vertical split direction |
| `SUPER + W` | Wallpaper Picker | Launch wallpaper picker with Matugen theme regeneration |
| `SUPER + SHIFT + S` | Screenshot | Interactive area screenshot (Grim + Slurp, saved & clipboard) |
| `SUPER + C` | Color Picker | Hyprpicker color picker copied to clipboard |
| `SUPER + L` | Lock Screen | Lock session via `hyprlock` |
| `SUPER + SHIFT + F` | Fullscreen | Toggle fullscreen mode |
| `SUPER + H` | Toggle Waybar | Hide / Show Waybar bar |
| `SUPER + R` | Restart Waybar | Restart Waybar & SwayNC processes |
| `SUPER + CTRL + B` | Waybar Styles | Choose Waybar visual style via Rofi menu |
| `SUPER + ALT + B` | Waybar Layouts | Choose Waybar layout preset via Rofi menu |
| `SUPER + 1 .. 0` | Workspace 1-10 | Switch to workspace 1 through 10 |
| `SUPER + SHIFT + 1 .. 0` | Move to Workspace | Move active window to workspace 1 through 10 |
| `SUPER + Arrows` | Focus Direction | Change window focus (left, right, up, down) |
| `SUPER + CTRL + Arrows` | Move Window | Move active window in direction |
| `SUPER + SHIFT + Arrows` | Resize Window | Resize active window (repeatable) |
| `SUPER + LMB Drag` | Move Window | Drag window to reposition |
| `SUPER + RMB Drag` | Resize Window | Drag window edge to resize |
| `CTRL + ALT + Delete` | Exit Session | Exit Hyprland |

### Multimedia Keys

- `XF86AudioRaiseVolume` / `LowerVolume`: Adjust audio volume (via `volume.sh`)
- `XF86AudioMute`: Toggle mute
- `XF86AudioMicMute`: Toggle microphone mute
- `XF86MonBrightnessUp` / `Down`: Adjust screen backlight (via `brightness.sh`)
- `XF86AudioPlay` / `Pause` / `Next` / `Prev`: Media controls (`playerctl`)

---

## Customization

### Changing Wallpapers & Themes
Press `SUPER + W` to open the Rofi wallpaper picker. Selecting any image automatically:
1. Transitions the background via `awww`.
2. Runs `matugen image` to extract Material You colors.
3. Updates `colors.lua` (Hyprland), `colors.css` (Waybar, SwayNC), `colors.rasi` (Rofi), `colors.conf` (Kitty), GTK3/4 themes, and Vesktop discord theme.
4. Reloads active components seamlessly via post-hooks.

### Dark / Light Mode Toggle
Click the sun/moon icon in the Waybar system drawer or launch `~/.config/hypr/scripts/DarkLight.sh` to toggle between dark and light palette variations.

### Waybar Styles and Layouts
- `SUPER + CTRL + B` opens the Waybar Styles menu (`islands`, `bintang default`, `islands no transparent`, `full bar`).
- `SUPER + ALT + B` opens the Waybar Layouts menu.

---

## First Boot Notes

1. **Permissions (hyprland-guiutils)**:
   Hyprland 0.53+ uses a capability permission system. Pre-authorized rules for `screencopy` are included in `~/.config/hypr/hyprland.lua` for `grim`, `hyprpicker`, and `xdg-desktop-portal-hyprland`.
2. **awww Cache**:
   The `awww` daemon maintains a versioned cache in `$XDG_CACHE_HOME/awww/`. The installer runs the first `matugen` pass during setup so themes and wallpapers are immediately available upon login.
3. **Session Launching**:
   Always start your session via `start-hyprland` (configured automatically by `tuigreet` / `greetd`), not by invoking `Hyprland` directly.

---

## Credits & Upstream Projects

- Original Rice Configuration: [binnewbs/arch-hyprland](https://github.com/binnewbs/arch-hyprland)
- Helper Scripts & Inspiration: [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)
- Material You Generator: [InioX/matugen](https://github.com/InioX/matugen)
- Wayland Wallpaper Daemon: [LGFae/awww](https://codeberg.org/LGFae/awww)
- Wayland Compositor: [Hyprland](https://hyprland.org)
- Status Bar: [Waybar](https://github.com/Alexays/Waybar)
- Notification Daemon: [SwayNotificationCenter](https://github.com/ErikReider/SwayNotificationCenter)
- Application Launcher: [Rofi](https://github.com/davatorium/rofi)
- Terminal Emulator: [Kitty](https://sw.kovidgoyal.net/kitty/)

---

## License

This project is licensed under the MIT License. Upstream configurations, scripts, and artwork retain their original authors' licenses and copyrights.
