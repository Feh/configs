-- Jetzt ist alles tighter und macht Fun wie Tony Hawk!
--                                                 -KKS
-- ----------------------------------------------------

--  Ideen:
--    - Passthrough -> globalkeys durch eine Taste ersetzen, die eine
--      Kopie der Globalkeys zurückschreibt. Für: VNC!
--    - Eigenes Tag-Management: dyntag-Modul schreiben!
--        - immer per Nummer zugreifen
--        - Shortcut angeben (Mod+hift+erster buchstabe)
--        - Rule hinzufügen
--        - Löschen wenn leer

-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require("vicious")

-- Load Debian menu entries
require("debian.menu")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers

naughty.config.presets.normal.position         = "bottom_right"
naughty.config.presets.normal.margin           = 5
-- naughty.config.presets.normal.width            = 700

beautiful.init("/home/feh/.config/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "editor"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
    awful.layout.suit.tile,
    -- awful.layout.suit.tile.left,
    -- awful.layout.suit.tile.bottom,
    -- awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    -- awful.layout.suit.spiral,
    -- awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    -- awful.layout.suit.max.fullscreen,
    -- awful.layout.suit.magnifier,
    awful.layout.suit.floating
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
-- tags = {}
tags = {}
t = {
    -- screen one
    {
        "1:main",
        "2:www",
        "3:mucke",
    },
    -- screen two
    {
        "1:main",
        "2:www"
    }
}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    tags[s] = awful.tag(t[s], s, layouts[1])
end
-- awful.tag.viewonly(tags[1][1])
-- }}}

-- {{{ Rules
tagrules = {
    { rule = { class = "gimp" }, tag = "gimp" },
    { rule = { class = "Iceweasel" }, tag = "www" }
}

-- simplerules = 
--     -- All clients will match this rule.
--     { rule = { class = "MPlayer" },
--       properties = { floating = true } },
--     { rule = { class = "gimp" },
--       properties = { floating = true } },
--     -- Set Firefox to always map on tags number 2 of screen 1.
--     { rule = { class = "Iceweasel" },
--       properties = { tag = tags[1][6] } },
--     -- XXX
-- }
-- }}}

function find_by_name(name)
    local s = client.focus and client.focus.screen or mouse.screen
    tags[s] = screen[s]:tags()
    for i, tag in ipairs(tags[s]) do
        if tag.name == name or string.sub(tag.name, 3, -1) == name then
            return tag
        end
    end
    return nil
end
function add_tag()
    local s = client.focus and client.focus.screen or mouse.screen
    local t = awful.tag({ " " }, s, awful.layout.suit.fair)[1]
    tags[s] = screen[s]:tags()
    auto_place_tag(t)
    -- awful.tag.viewonly(t)
    -- -> steckt in auto-place!
    rename_tag(t)
    return t
    -- function terminates here!!
    -- (even before entering new name)
end
function del_tag()
    local s = client.focus and client.focus.screen or mouse.screen
    local t = awful.tag.selected()
    -- if tag exists and there's at least one other left...
    if t and #tags[s] > 1 then
        move_tag(t, #tags[s])
        t.screen = nil
        tags[s][#tags[s]] = nil
        -- handle "orphans":
        for _, c in pairs(client.get()) do
           if #c:tags() == 0 then
               c:tags({tags[s][1]}) -- will always exist
           end
        end
        renumber_tag_names()
        -- focus difficulties :-/
        awful.tag.history.restore(s)
    end
end
function dbg(d)
    naughty.notify( {
        text = tostring(d),
        timeout = 5,
        hover_timeout = 1000
    })
end
function tag_id(tag)
    local s = tag.screen
    for i=1,#tags[s] do
        if tags[s][i] == tag then
            return i
        end
    end
    return nil
end
function rename_tag(tag)
    -- find tag
    if not tag then return nil; end
    local s = tag.screen
    local i = tag_id(tag)
    if s and i then
        awful.prompt.run(
            -- args
            { ul_cursor = "single", text = tag.name,
                selectall = true, prompt = " " },
            -- textbox
            taglist[s][2*i],
            -- exe callback
            function (n)
                if n:len()>0 and n ~= " " then
                    tag.name = "x:" .. n
                    renumber_tag_names()
                else
                    awful.tag.viewonly(tag) -- mostly no necessary
                    del_tag()
                end
            end,
            -- completion cb
            nil,
            -- hist path
            nil,
            -- hist max
            nil,
            -- done cb
            function ()
                if tag.name == " " then
                    awful.tag.viewonly(tag)
                    del_tag()
                end
            end
        )
    end
end

-- function move_left, move_right
-- -> move_tag(tag, x mod y :-) )
-- function delete_active()
--      get selected tag
--      delete it
-- end
function move_tag(tag, pos)
    if tag and pos > 0 and pos <= #tags[tag.screen] then
        local s = tag.screen
        local pos_cur = tag_id(tag)
        local pos_new = 0
        tags[s] = screen[s]:tags()
        while pos_new ~= pos do
            if pos_new-pos < 0 then
                pos_new = pos_cur+1
            else
                pos_new = pos_cur-1
            end
            local temp = tags[s][pos_new]
            tags[s][pos_new] = tag
            tags[s][pos_cur] = temp
            pos_cur = pos_new
        end
        screen[s]:tags(tags[s])
        renumber_tag_names()
        awful.tag.history.restore(s)
        awful.tag.viewonly(tags[s][pos])

        -- awful.tag.history.restore()
        -- awful.client.focus.byidx(0) -- re-focus current client
        -- client.focus:redraw()
    end
end
function tag_update()
    renumber_tag_names()
    rewrite_rules()
end
function rewrite_rules()
    tr = {}
    for i=1,#tagrules do
        local t = find_by_name(tagrules[i].tag)
        if t then
            tr = awful.util.table.join(tr, { rule = tagrules[i].rule, properties = { tag=t } } )
            dbg("wrote rule: " .. tagrules[i].tag)
        end
    end
    awful.rules.rules = awful.util.table.join(alwaysrules, tr)
end
function renumber_tag_names()
    for s=1,screen.count() do
        for i=1,#tags[s] do
            tags[s][i].name = i .. string.sub(tags[s][i].name, 2, -1)
        end
    end
end
function move_tag_rel(n)
    local t = awful.tag.selected()
    move_tag(t, tag_id(t)+n)
    --- awful.tag.viewonly(t)
end
function auto_place_tag(tag)
    if tag then
        move_tag(tag, tag_id(awful.tag.selected())+1)
    end
end

-- {{{ Menu
-- Create a laucher widget and a main menu
-- myawesomemenu = {
--    { "manual", terminal .. " -e man awesome" },
--    { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
--    { "restart", awesome.restart },
--    { "quit", awesome.quit }
-- }
--
-- mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
--                                     { "Debian", debian.menu.Debian_menu.Debian },
--                                     { "open terminal", terminal }
--                                   }
--                         })
--
-- mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
--                                      menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget

spacer = widget({ type = "textbox" })
spacer.text = " "

mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
taglist = {}
taglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

    cpu_img = widget({ type = "imagebox", align = "right" })
    cpu_img.image = image("/home/feh/.awesome-icons/load.png")
    cpuwidget = awful.widget.graph({ layout = awful.widget.layout.horizontal.rightleft })
    cpuwidget:set_width(50)
    cpuwidget:set_height(10)
    cpuwidget:set_background_color('#494B4F')
    cpuwidget:set_border_color(nil)
    -- cpuwidget:set_color('#AECF96')
    cpuwidget:set_color(theme.fg_normal)
    cpuwidget:set_gradient_colors({ '#494B4F', theme.fg_normal, theme.fg_normal })
    vicious.register(cpuwidget, vicious.widgets.cpu, '$1', 3)
    awful.widget.layout.margins[cpuwidget.widget] = { top = 3, bottom = 3 }

    mem_img = widget({ type = "imagebox", align = "right" })
    mem_img.image = image("/home/feh/.awesome-icons/cpu.png")
    memwidget = awful.widget.progressbar({ layout = awful.widget.layout.horizontal.rightleft })
    memwidget:set_width(50)
    memwidget:set_height(10)
    memwidget:set_background_color('#494B4F')
    memwidget:set_border_color(nil)
    memwidget:set_color(theme.fg_normal)
    -- memwidget:set_gradient_colors({ '#00ff00', '#c3d72c', '#ff0000' })
    vicious.register(memwidget, vicious.widgets.mem, '$1', 13)
    awful.widget.layout.margins[memwidget.widget] = { top = 3, bottom = 3 }

    vicious.enable_caching(vicious.widgets.fs)
    hd_img = widget({ type = "imagebox", align = "right" })
    hd_img.image = image("/home/feh/.awesome-icons/mem.png")
    hdwidget = awful.widget.progressbar({ layout = awful.widget.layout.horizontal.rightleft })
    hdwidget:set_width(50)
    hdwidget:set_height(10)
    hdwidget:set_background_color('#494B4F')
    hdwidget:set_border_color(nil)
    hdwidget:set_color(theme.fg_normal)
    -- hdwidget:set_gradient_colors({ '#00ff00', '#c3d72c', '#ff0000' })
    vicious.register(hdwidget, vicious.widgets.fs, '${/ usep}', 599)
    awful.widget.layout.margins[hdwidget.widget] = { top = 3, bottom = 3 }

    wlan_img = widget({ type = "imagebox", align = "right" })
    wlan_img.image = image("/home/feh/.awesome-icons/net-wifi.png")
    wired_img = widget({ type = "imagebox", align = "right" })
    wired_img.image = image("/home/feh/.awesome-icons/net-wired.png")
    wlan_info = widget({ type = 'textbox', align = 'right' })
    vicious.register(wlan_info, vicious.widgets.wifi, '${ssid}(${link}):', 13, "eth0")
    -- race condition when defined inside the loop
    vicious.enable_caching(vicious.widgets.net)
    net = { widget({ type = 'textbox', align = 'right' }),
            widget({ type = 'textbox', align = 'right' }) }
    vicious.register(net[1], vicious.widgets.net,
        ' <span font_desc="silkscreen 6"><span color="green">${eth0 down_kb}K</span> <span color="white">/</span> <span color="red">${eth0 up_kb}K</span></span> ', 3)
    vicious.register(net[2], vicious.widgets.net,
        ' <span font_desc="silkscreen 6"><span color="green">${eth1 down_kb}K</span> <span color="white">/</span> <span color="red">${eth1 up_kb}K</span></span>', 3)


    temp_img = widget({ type = "imagebox", align = "right" })
    temp_img.image = image("/home/feh/.awesome-icons/temp.png")
    temp = widget({ type = "textbox", align = "right" })
    vicious.register(temp, vicious.widgets.thermal, '$1°C', 23, 'THM0')

    bat_img = widget({ type = "imagebox", align = "right" })
    bat_img.image = image("/home/feh/.awesome-icons/power-bat.png")
    batwidget = awful.widget.progressbar({ layout = awful.widget.layout.horizontal.rightleft })
    -- batwidget = widget({ type="progressbar", align="right"})
    batwidget:set_width(45)
    batwidget:set_height(10)
    -- batwidget:set_vertical(true)
    batwidget:set_background_color('#494B4F')
    batwidget:set_border_color(nil)
    batwidget:set_color(theme.fg_normal)
    -- batwidget:set_gradient_colors({ '#ff0000', '#c3d72c', '#00ff00' })
    vicious.register(batwidget, vicious.widgets.bat, '$2', 61, 'BAT0')
    awful.widget.layout.margins[batwidget.widget] = { top = 3, bottom = 3 }

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    taglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, taglist.buttons)

    -- Create a tasklist widget
    -- mytasklist[s] = awful.widget.tasklist(function(c)
    --                                           return awful.widget.tasklist.label.currenttags(c, s)
    --                                       end, mytasklist.buttons)



    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", height = 15, screen = s })
    -- Add widgets to the wibox - order matters
    mywibox[s].widgets = {
        {
            taglist[s],
            mylayoutbox[s],
            mypromptbox[s],
            layout = awful.widget.layout.horizontal.leftright
        },
        mytextclock,
        spacer, batwidget.widget, spacer, bat_img,
        spacer, temp, spacer, temp_img,
        spacer, memwidget.widget, spacer, mem_img,
        spacer, hdwidget.widget, spacer, hd_img,
        spacer, net[2], wired_img,
                net[1], wlan_info, spacer, wlan_img,
        spacer, cpuwidget.widget, spacer, cpu_img,
        -- s == 1 and mysystray or nil,
        -- mytasklist[s],
        layout = awful.widget.layout.horizontal.rightleft
    }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    -- awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),
    -- the special keys
    awful.key({}, "Menu", nil, function () awful.util.spawn("/home/feh/bin/dpms-all") end),
    awful.key({}, "XF86LaunchB", function () awful.util.spawn("mocp -G") end),
    awful.key({}, "XF86LaunchA", function () awful.util.spawn("mocp -r") end),
    awful.key({}, "XF86LaunchC", function () awful.util.spawn("mocp -f") end),
    awful.key({}, "XF86LaunchD", function () awful.util.spawn("amixer set Master 3->/dev/null") end),
    awful.key({}, "XF86LaunchF", function () awful.util.spawn("amixer set Master 3+>/dev/null") end),
    -- toggling mute is not easy with amixer!
    awful.key({}, "XF86LaunchE", function () awful.util.spawn("amixer set Master 0 >/dev/null") end),

    -- MOCP/music control
    awful.key({ modkey,           }, "n", function () awful.util.spawn("mocp -f") end),
    awful.key({ modkey,           }, "b", function () awful.util.spawn("mocp -r") end),
    awful.key({ modkey, "Shift"   }, "p", function () awful.util.spawn("mocp -G") end),
    awful.key({ modkey, "Shift"   }, "i", function () awful.util.spawn("/home/feh/bin/mocp_song_change.sh") end),
    awful.key({ modkey, "Control", "Shift"   }, "m", function () awful.util.spawn(terminal .. " -name mocp -e mocp -y") end),

    awful.key({ modkey, "Shift"   }, "u", function () awful.util.spawn("/home/feh/bin/clip-bit-ly") end),
    awful.key({ modkey,           }, "w",
        function ()
            awful.screen.focus(1)
            awful.tag.viewonly(find_by_name("www"))
        end),
    awful.key({ modkey, "Shift"   }, "m",
        function ()
            awful.screen.focus(1)
            awful.tag.viewonly(find_by_name("mucke"))
        end),
    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    -- awful.key({ modkey,           }, "l", function () awful.screen.focus_relative( 1) end),
    -- awful.key({ modkey,           }, "h", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "l", awful.tag.viewnext),
    awful.key({ modkey,           }, "h", awful.tag.viewprev),
    awful.key({ modkey            }, "BackSpace", function () awful.screen.focus_relative(1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Control", "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Control", "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () move_tag_rel( 1)      end),
    awful.key({ modkey, "Shift"   }, "h",     function () move_tag_rel(-1)      end),
    -- awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    -- awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    awful.key({ modkey },            "p",     function () mypromptbox[mouse.screen]:run() end),

    -- Tag handling
    awful.key({ modkey }, "q", add_tag ),
    awful.key({ modkey, "Control" }, "t", del_tag ),
    awful.key({ modkey, "Shift" }, "t", function () rename_tag(awful.tag.selected()) end ),
    awful.key({ modkey }, "t",
        function ()
            local c = client.focus
            local t = add_tag()
            if c then awful.client.movetotag(t, c) end
        end ),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  function(c)
        awful.client.floating.toggle()
        if awful.client.floating.get() then
            awful.titlebar.add(c, { modkey = modkey })
        else
            awful.titlebar.remove(c)
        end
    end                 ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    -- awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Compute the maximum number of digit we need, limited to 9
-- keynumber = 0
-- for s = 1, screen.count() do
--    keynumber = math.min(9, math.max(#tags[s], keynumber));
-- end
keynumber = 9

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

alwaysrules = {
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
}
awful.rules.rules = alwaysrules


-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Add a titlebar
    -- awful.titlebar.add(c, { modkey = modkey })

    -- Enable sloppy focus
    -- c:add_signal("mouse::enter", function(c)
    --     if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
    --         and awful.client.focus.filter(c) then
    --         client.focus = c
    --     end
    -- end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
