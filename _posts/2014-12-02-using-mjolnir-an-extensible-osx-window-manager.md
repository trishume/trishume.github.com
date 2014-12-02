---
layout: post
title: "Using Mjolnir: An Extensible OSX Window Manager"
description: "Configuring and using the Mjolnir window manager."
category: howto
assetid: mjolnir
tags: [mjolnir,tutorial,configuration]
---
{% include JB/setup %}

Recently I started using the amazing and highly configurable window manager called [Mjolnir](http://mjolnir.io/).
But really it isn't a window manager, it's an OSX wrapper around a Lua configuration file and event loop that
has a constellation of modules that allow you to configure all sorts of computer control tasks. The most common use
for Mjolnir is managing Windows but there are all sorts of modules that allow you to use it for doing things like
[unmounting your USB drives when you switch to battery power](https://github.com/asmagill/mjolnir-config/blob/master/utils/_actions/battery_usbdrives.lua).

Two years ago I wrote a blog post about [configuring Slate](/howto/2012/11/19/using-slate/), the configurable window manager
that I had been using until this month. However, the maintainer hasn't worked on Slate in years and there are dozens of pull requests sitting around without merge and comment. There have been [attempts](https://github.com/mattr-/slate) to revive it,
but there were still some rough edges and I decided to try something new.

Here I'll describe how I use Mjolnir and my experience with it so far.

## Getting Started

The instructions on [Mjolnir's homepage](http://mjolnir.io/) are pretty good as far as getting Mjolnir installed goes.
You'll need to get luarocks working and then create an `init.lua` file, which isn't very hard.
The basic install you get can't do much so you'll have to use some of the many [Mjolnir modules](https://rocks.moonscript.org/search?q=mjolnir).
Before you use a module you have to install it first, to install `mjolnir.hotkey` you would run

    luarocks install mjolnir.hotkey

## Window Management

Mjolnir makes managing windows really easy with great modules to help you with this most of which are built upon the basic
functionality found in [mjolnir.application](https://rocks.moonscript.org/modules/sdegutis/mjolnir.application).
That module provides basic access to running applications and their windows, which modules like
[mjolnir.bg.grid](https://github.com/BrianGilbert/mjolnir.bg.grid) use to provide things like the ability
to move windows around and resize on a grid. There are even fancier modules like
[mjolnir.tiling](https://github.com/nathankot/mjolnir.tiling) which automatically organize your windows
like a fancy Linux tiling window manager would do.

### Basic Key Bindings

Generally the way you want to start is by binding actions (really just Lua functions) to keys using the `mjolnir.hotkey`.
Here's an example from the Mjolnir homepage of binding a key that just nudges a window right:

{% highlight lua %}
hotkey.bind({"cmd", "alt", "ctrl"}, "D", function()
  local win = window.focusedwindow()
  local f = win:frame()
  f.x = f.x + 10
  win:setframe(f)
end)
{% endhighlight %}

Since it's just Lua code you can also just directly pass function names and use variables to refer to common chords:

{% highlight lua %}
local mash = {"ctrl", "shift"}
hotkey.bind(mash, "c", mjolnir.openconsole)
{% endhighlight %}

### Using a Grid

Personally I found the easiest way of doing window management was to use the [mjolnir.bg.grid](https://github.com/BrianGilbert/mjolnir.bg.grid) module. It provides functions that allow you to shuffle windows around a grid of a configurable number of rows and
columns (3x3 by default). Here's an example of some basic bindings inspired by [this config](https://github.com/vpetro/dotfiles/blob/master/.mjolnir/init.lua):

{% highlight lua %}
local grid = require "mjolnir.sd.grid"
local hotkey = require "mjolnir.hotkey"

grid.MARGINX = 0
grid.MARGINY = 0
grid.GRIDWIDTH = 2
grid.GRIDHEIGHT = 2

-- a helper function that returns another function that resizes the current window
-- to a certain grid size.
local gridset = function(x, y, w, h)
    return function()
        cur_window = window.focusedwindow()
        grid.set(
            cur_window,
            {x=x, y=y, w=w, h=h},
            cur_window:screen()
        )
    end
end

local mash = {"ctrl", "shift"}
hotkey.bind(mash, 'n', grid.pushwindow_nextscreen)
hotkey.bind(mash, 'a', gridset(0, 0, 1, 2)) -- left half
hotkey.bind(mash, 's', grid.maximize_window)
hotkey.bind(mash, 'd', gridset(1, 0, 1, 2)) -- right half
{% endhighlight %}

## Window Hints

One of my favourite parts of Mjolnir is that you can write your own modules in Lua and Objective C to hook into OSX
functionality that Mjolnir doesn't support by default. The great thing is other people have already written all sorts
of modules to do things like [controlling Spotify](https://github.com/Linell/mjolnir.lb.spotify)
and [playing sounds](https://github.com/asmagill/mjolnir_asm.ui/tree/master/sound).

Recently I wrote my own module in 4 hours or so that adds the window hints feature that I missed from Slate:
[mjolnir.th.hints](https://github.com/trishume/mjolnir.th.hints). Except I think I did it even better than Slate did.
It allows you to quickly switch apps and windows using "hints" that pop up when you hit a key that have a letter on them,
when you press the letter it switches to that app.

![Hints Screenshot](https://camo.githubusercontent.com/384052b64aa56146c1efb579b6fbdb60901987ea/687474703a2f2f692e696d6775722e636f6d2f6b744c6742574f2e706e67)

All you have to do is bind it to a key:

{% highlight lua %}
local hints = require "mjolnir.th.hints"
hotkey.bind({"cmd"},"e",hints.windowHints)
-- You can also use this with appfinder to switch to windows of a specific app
local appfinder = require "mjolnir.cmsj.appfinder"
hotkey.bind({"ctrl","cmd"},"k",function() hints.appHints(appfinder.app_from_name("Emacs")) end)
{% endhighlight %}

# My Config

My personal config is a bit fancier and more specific to me than you might want to start off with, but you might want to get
some ideas from it. You can find the latest version [in my dotfiles repo](https://github.com/trishume/dotfiles/blob/master/mjolnir/mjolnir.symlink/init.lua),
but I've included my config at the time of writing later on the page because it will probably be simpler than my
config at the time you read this.

It has fancy features like rebinding the keys on keyboard layout change (which doesn't always work).
Probably the best feature is a crappy implementation of something that mimics Slate's support for layouts.

{% highlight lua %}
-- Load Extensions
local application = require "mjolnir.application"
local window = require "mjolnir.window"
local hotkey = require "mjolnir.hotkey"
local keycodes = require "mjolnir.keycodes"
local fnutils = require "mjolnir.fnutils"
local alert = require "mjolnir.alert"
local screen = require "mjolnir.screen"
-- User packages
local grid = require "mjolnir.bg.grid"
local hints = require "mjolnir.th.hints"
local appfinder = require "mjolnir.cmsj.appfinder"

local definitions = nil
local hyper = nil

local gridset = function(frame)
	return function()
		local win = window.focusedwindow()
		if win then
			grid.set(win, frame, win:screen())
		else
			alert.show("No focused window.")
		end
	end
end

auxWin = nil
function saveFocus()
  auxWin = window.focusedwindow()
  alert.show("Window '" .. auxWin:title() .. "' saved.")
end
function focusSaved()
  if auxWin then
    auxWin:focus()
  end
end

local hotkeys = {}

function createHotkeys()
  for key, fun in pairs(definitions) do
    local mod = hyper
    if string.len(key) == 2 and string.sub(key,2,2) == "c" then
      mod = {"cmd"}
    end

    local hk = hotkey.new(mod, string.sub(key,1,1), fun)
    table.insert(hotkeys, hk)
    hk:enable()
  end
end

function rebindHotkeys()
  for i, hk in ipairs(hotkeys) do
    hk:disable()
  end
  hotkeys = {}
  createHotkeys()
  alert.show("Rebound Hotkeys")
end

function applyPlace(win, place)
  local scrs = screen:allscreens()
  local scr = scrs[place[1]]
  grid.set(win, place[2], scr)
end

function applyLayout(layout)
  return function()
    for appName, place in pairs(layout) do
      local app = appfinder.app_from_name(appName)
      if app then
        for i, win in ipairs(app:allwindows()) do
          applyPlace(win, place)
        end
      end
    end
  end
end

function init()
  createHotkeys()
  keycodes.inputsourcechanged(rebindHotkeys)
  alert.show("Mjolnir, at your service.")
end

-- Actual config =================================

hyper = {"cmd", "alt", "ctrl","shift"}
-- Set grid size.
grid.GRIDWIDTH  = 6
grid.GRIDHEIGHT = 8
grid.MARGINX = 0
grid.MARGINY = 0
local gw = grid.GRIDWIDTH
local gh = grid.GRIDHEIGHT

local gomiddle = {x = 1, y = 1, w = 4, h = 6}
local goleft = {x = 0, y = 0, w = gw/2, h = gh}
local goright = {x = gw/2, y = 0, w = gw/2, h = gh}
local gobig = {x = 0, y = 0, w = gw, h = gh}

local fullApps = {
  "Safari","Aurora","Nightly","Xcode","Qt Creator","Google Chrome",
  "Google Chrome Canary", "Eclipse", "Coda 2", "iTunes", "Emacs", "Firefox"
}
local layout2 = {
  Airmail = {1, gomiddle},
  Spotify = {1, gomiddle},
  Calendar = {1, gomiddle},
  Dash = {1, gomiddle},
  iTerm = {2, goright},
  MacRanger = {2, goleft},
}
fnutils.each(fullApps, function(app) layout2[app] = {1, gobig} end)

definitions = {
  [";"] = saveFocus,
  a = focusSaved,

  h = gridset(gomiddle),
  t = gridset(goleft),
  n = grid.maximize_window,
  s = gridset(goright),

  g = applyLayout(layout2),

  d = grid.pushwindow_nextscreen,
  r = mjolnir.reload,
  q = function() appfinder.app_from_name("Mjolnir"):kill() end,

  k = function() hints.appHints(appfinder.app_from_name("Emacs")) end,
  j = function() hints.appHints(window.focusedwindow():application()) end,
  ec = hints.windowHints
}

-- launch and focus applications
fnutils.each({
  { key = "o", app = "MacRanger" },
  { key = "e", app = "Google Chrome" },
  { key = "u", app = "Emacs" },
  { key = "i", app = "iTerm" },
  { key = "m", app = "Airmail" }
}, function(object)
    definitions[object.key] = function() application.launchorfocus(object.app) end
end)

init()
{% endhighlight %}
