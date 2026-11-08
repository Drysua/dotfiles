-- Original by wanakachi
-- Modified: Add (PiP) to window title for GlazeWM detection
-- Usage: Alt + P to toggle PiP mode

local pip_enabled = false
local original_options = {}
local original_force_title = nil

local utils = require 'mp.utils'

local function glaze(args)
    local cmd = {"glazewm", "command"}
    for _, a in ipairs(args) do table.insert(cmd, a) end
    mp.command_native_async({name = "subprocess", args = cmd, playback_only = false})
end

-- entering PiP

-- leaving PiP
-- Save original window properties
local function save_original_options()
    original_options.fullscreen = mp.get_property_bool("fullscreen")
    original_options.border = mp.get_property_bool("border")
    original_options.ontop = mp.get_property_bool("ontop")
    original_options.window_scale = mp.get_property_number("window-scale")

    original_force_title = mp.get_property("force-media-title")
end

-- Restore original window properties
local function restore_original_options()
    if original_options.fullscreen ~= nil then
        mp.set_property_bool("fullscreen", original_options.fullscreen)
    end

    if original_options.border ~= nil then
        mp.set_property_bool("border", original_options.border)
    end

    if original_options.ontop ~= nil then
        mp.set_property_bool("ontop", original_options.ontop)
    end

    if original_options.window_scale ~= nil then
        mp.set_property_number("window-scale", original_options.window_scale)
    end

    -- Restore original title
    mp.set_property("force-media-title", original_force_title or "")
end

-- Apply PiP settings
local function apply_pip_settings()
    mp.set_property_bool("fullscreen", false)
    mp.set_property_bool("border", false)
    mp.set_property_bool("ontop", true)
    mp.set_property_number("window-scale", 0.3)
end

-- Enter PiP mode
local function enable_pip()
    if pip_enabled then return end

    save_original_options()

    local media_title = mp.get_property("media-title") or "mpv"
    original_force_title = media_title
    mp.set_property("force-media-title", media_title .. " (PiP)")

    apply_pip_settings()

    pip_enabled = true
    mp.osd_message("PiP enabled")
end

-- Exit PiP mode
local function disable_pip()
    if not pip_enabled then return end

    -- Restore original window properties
    restore_original_options()

    -- Clear forced media title so mpv restores its normal title format
    -- mp.set_property("force-media-title", "")
    mp.set_property("force_media_title", original_force_title)
    pip_enabled = false
    glaze({"set-tiling"})
    mp.osd_message("PiP disabled")
end

-- Toggle PiP
local function toggle_pip()
    if pip_enabled then
        disable_pip()
    else
        enable_pip()
    end
end

-- Reapply PiP settings when a new file loads
mp.register_event("file-loaded", function()
    if pip_enabled then
        mp.add_timeout(0.1, function()
            apply_pip_settings()

            local media_title = mp.get_property("media-title") or "mpv"
            mp.set_property("force-media-title", media_title .. " (PiP)")
        end)
    end
end)

-- Fix unwanted borderless state
mp.add_timeout(0.1, function()
    if not pip_enabled and mp.get_property_bool("border") == false then
        mp.set_property_bool("border", true)
        mp.set_property_bool("ontop", false)
    end
end)

-- Monitor fullscreen changes
mp.observe_property("fullscreen", "bool", function(name, value)
    if value and pip_enabled then
        disable_pip()
        mp.set_property_bool("fullscreen", true)
    end
end)

-- Monitor maximized state changes
mp.observe_property("window-maximized", "bool", function(name, value)
    if value and pip_enabled then
        disable_pip()
        mp.set_property_bool("window-maximized", true)
    end
end)

-- Keyboard shortcut
mp.add_key_binding("alt+p", "toggle-pip", toggle_pip)
