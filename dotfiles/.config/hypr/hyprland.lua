-- hyprland.lua - Main entry point for hyprdots-arch

-- Required modules
require("looknfeel")
require("animations")
require("input")
require("keybinds")
require("windowrules")

-- Monitors: auto detect by default; commented example for user configuration
-- Example: hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "0x0", scale = "1" })
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

-- Environment variables
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Autostart
hl.on("hyprland.start", function()
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("waybar")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("swaync")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("hypridle")
end)

-- Permissions (hyprland-guiutils 0.53+)
hl.permission({ binary = "/usr/bin/grim", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/local/bin/grim", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/bin/hyprpicker", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/local/bin/hyprpicker", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/lib/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })
hl.permission({ binary = "/usr/libexec/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })

-- General layout & misc configuration
hl.config({
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },

    debug = {
        vfr = true,
    },

    render = {
        new_render_scheduling = true,
    },
})
