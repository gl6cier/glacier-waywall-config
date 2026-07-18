local waywall = require("waywall")
local helpers = require("waywall.helpers")
local waywall_config_path = os.getenv("HOME") .. "/.config/waywall/"
local keyboard_remaps = require("remaps").remapped_kb  -- base remaps
local other_remaps = require("remaps").normal_kb  -- remaps kept when toggling remaps
local pie_remaps = require("remaps").pie_kb -- remaps for pie lock
local menu_remaps = require("remaps").menu_kb -- remaps only in menu

local toggle_remaps = true
local ninbot_launched = false
local pieremaps_active = false
local pierebind_text = nil
local rebind_text = nil

local paths = {
	background_png = waywall_config_path .. "resources/background.png",
	overlay_png    = waywall_config_path .. "resources/stretched_overlay.png",
	ninja_jar      = waywall_config_path .. "resources/Ninjabrain-Bot-1.5.1.jar",
}

local config = {
    input = {
        layout = "icelandic",
        rules = nil,
        variant = "1",
        options = "caps:none",

        repeat_rate = 80,
        repeat_delay = 150,
        remaps = keyboard_remaps,
        sensitivity = 8,
        confine_pointer = false,
    },
    theme = {
        background_png = paths.background_png,
        font_path = "/usr/share/fonts/TTF/CozetteVector.ttf", -- waywall fork things
        font_size = 40,
        ninb_anchor = {
            position = "topright",
            x = 0,
            y = 0,  
        }
    },
    experimental = {
        debug = false,
        jit = false,
        tearing = true, -- tearing should be ON
        scene_add_text = true,
    },
    window = {
        fullscreen_width = 1920,
        fullscreen_height = 1200,
    }
}

helpers.res_mirror({ src = { x = 177, y = 7900, w = 30, h = 580 }, dst = { x = 0, y = 290, w = 768, h = 432 } }, 384, 16384) -- eyezoom
helpers.res_mirror({ src = { x = 0, y = 15980, w = 320, h = 180 }, dst = { x = 1160, y = 570, w = 216, h = 122 } }, 384, 16384) -- tall pie
helpers.res_mirror({ src = { x = 0, y = 680, w = 320, h = 180 }, dst = { x = 1145, y = 570, w = 216, h = 122 } }, 340, 1080) -- thin pie
helpers.res_mirror({ src = { x = 12, y = 36, w = 38, h = 9 }, dst = { x = 1160, y = 300, w = 216, h = 54 } }, 384, 16384) -- tall ecount
helpers.res_mirror({ src = { x = 12, y = 36, w = 38, h = 9 }, dst = { x = 1145, y = 300, w = 216, h = 54 } }, 340, 1080) -- thin ecount
helpers.res_mirror({ src = { x = 292, y = 16164, w = 26, h = 23 }, dst = { x = 1160, y = 369, w = 216, h = 184 } }, 384, 16384) -- tall numbers
helpers.res_mirror({ src = { x = 248, y = 860, w = 26, h = 23 }, dst = { x = 1145, y = 369, w = 216, h = 184 } }, 340, 1080) -- thin numbers
helpers.res_image(paths.overlay_png, { dst = { x = 0, y = 290, w = 768, h = 432 } }, 384, 16384) -- overlay image

local resolutions = {
    thin = helpers.ingame_only(helpers.toggle_res(340, 1080, 0)),
    tall = helpers.ingame_only(helpers.toggle_res(384, 16384, 0.2)),
    wide = helpers.ingame_only(helpers.toggle_res(1920, 270)),
    pre  = helpers.toggle_res(384, 16384, 0), -- preemptive
}

config.actions = {
    ["*-Alt_L"]  = function() 
        if waywall.get_key("F3") then return false end
        return toggle_remaps and resolutions.thin() end,
    ["*-T"] = function() 
        if waywall.get_key("F3") then return false end
        return toggle_remaps and resolutions.tall() end,
    ["*-G"] = function()
        if waywall.get_key("F3") then return false end
        return toggle_remaps and resolutions.wide() end,
    ["*-N"] = function()
        if waywall.get_key("F3") then return false end
        return toggle_remaps and resolutions.pre() end, -- preemptive
    
        ["*-Ctrl-P"] = waywall.toggle_fullscreen, --fullscreen

    ["*-F2"] = function()
    if pierebind_text then
        pierebind_text:close()
        pierebind_text = nil
    end

    if pieremaps_active then
        pieremaps_active = false
        waywall.set_remaps(keyboard_remaps)
    else
        pieremaps_active = true
        waywall.set_remaps(pie_remaps)

        pierebind_text = waywall.text("pie lock", {
            x = 960,
            y = 600,
            color = "#FFFFFF",
            size = 40
        })
    end
end,

    ["*-F9"] = function()
        if rebind_text then
            rebind_text:close()
            rebind_text = nil
        end
        if toggle_remaps then
            toggle_remaps = false
            waywall.set_remaps(other_remaps)
                waywall.set_keymap({
                    layout = nil,
                    rules = nil,
                    variant = nil,
                    options = nil,
                })

            rebind_text = waywall.text("remaps off", {
                    x = 960,
                    y = 600,
                    color = "#FFFFFF",
                    size = 40
                })
        else
            toggle_remaps = true
            waywall.set_remaps(keyboard_remaps)
                waywall.set_keymap({
                    layout = config.input.layout,
                    rules = nil,
                    variant = config.input.variant,
                    options = config.input.options
                })
        end
    end,

    ["*-Grave"] = function() -- ninbot (toggle and start with same key)
    if not ninbot_launched then
      waywall.exec("java -Dawt.useSystemAAFontSettings=on -jar " .. paths.ninja_jar)
      ninbot_launched = true
    else
      helpers.toggle_floating()
    end
end,
}

waywall.listen("state", function() -- change from menu_remaps to keyboard_remaps when in a menu
    local state = waywall.state()
    if state.screen == "inworld" and state.inworld == "menu" then
        waywall.set_remaps(menu_remaps)
    else
        waywall.set_remaps(keyboard_remaps)
    end
end)

local crosshair_image = nil
local crosshair_active = nil

local oneshot = {
    resx = 1920,
    resy = 1200,
    size = 100,
    key = "Shift-I",
    path = os.getenv("HOME") .. "/.config/waywall/resources/crosshair.png",
}

config.actions[oneshot.key] = function()
    if crosshair_image then
        crosshair_image:close(); crosshair_image = nil
    end
    if crosshair_active then
        crosshair_active = false
    else
        crosshair_active = true
        crosshair_image = waywall.image(oneshot.path, {
            dst = {
                x = (oneshot.resx - oneshot.size) / 2,
                y = (oneshot.resy - oneshot.size) / 2,
                w = oneshot.size,
                h = oneshot.size,
            }
        })
    end
end

-- TWITCH CHAT FORK. FILES NOT PROVIDED !!!!!!!

   local emote_downloader = require("fetch_emotes")
   local chat = require("chat")
   local chat1 = chat("glciers", 15, 700, 16)

   local emote_key = "Shift-Y"
   local open_chat_key = "Shift-H"

   config.actions[emote_key] = function()
      emote_downloader.Fetch("01K5Z5EVFM8Q8015A4HA8R334S") -- (REPLACE THIS WITH YOUR 7TV EMOTESET NUMBER)
   end

   config.actions[open_chat_key] = function()
      chat1:open()
   end

return config
