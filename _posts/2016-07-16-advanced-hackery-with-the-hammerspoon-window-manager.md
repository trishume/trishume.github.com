---
layout: post
title: "Advanced Hackery With The Hammerspoon Window Manager"
description: ""
category:
assetid: hammerspoon
tags: [hammerspoon, configuration]
---
{% include JB/setup %}

Along with [Dash](https://kapeli.com/dash), [Sketch](https://www.sketchapp.com/) and [Papers](http://papersapp.com/), one of the main reasons I haven't yet switched to Linux is [Hammerspoon](http://www.hammerspoon.org/). Hammerspoon gives me most of the power that a fancy Linux tiling window manager and configurable desktop would give me, without having to switch operating systems. It's fully configurable with Lua, has [tons of built in modules](http://www.hammerspoon.org/docs/index.html) and it is simple to write your own modules. I think of it more as a general-purpose tool for modifying OSX's user interface than just a window manager. This post explores some of the ways I've used Hammerspoon to greatly enhance my general OSX-using experience.

![Hints Screenshot]({{PAGE_ASSETS}}/hammerspoon.png)

## Window Hints

The first Hammerspoon module I wrote was a port of [Slate's window hints](/howto/2012/11/19/using-slate/#switching-windows), which if you've ever used Vimium or Vimperator, are like link hints for windows. They allow you to switch to any window with only two keystrokes: One shortcut to bring up icons and letters for every window, and then simply hitting the key corresponding to the window you want.

[The module](https://github.com/trishume/mjolnir.th.hints) was written mostly in a single evening as a native Lua module (originally for Mjolnir, the precursor to Hammerspoon).
It didn't take much time, and is very enjoyable to use, and because the module was added to the core Hammerspoon distribution, lots of other people can also benefit from it.

## Window Tabs

The second Hammerspoon module I wrote was one that allows you to add tabs to any OSX Application. The tabs sit in the top right of the title bar and allow you to easily switch between windows of an app with keyboard shortcuts (e.g `ctrl+tab number`) and later by clicking. This was originally motivated by my switching to [Spacemacs](http://spacemacs.org/) and it not having a good solution for working on many different projects like Vim tabs. This module allowed me to wrangle Emacs windows to more easily switch between different projects. I later repurposed it to switch between Sublime Windows for the same reason when I switched back to Sublime Text.

This module was very different to write since it was pure Lua. It uses Hammerspoon's various powerful built-in modules including the drawing module, the app watcher module, and the window listener module.

![Tabs Screenshot]({{PAGE_ASSETS}}/tabs.png)

## Mouth Noises

Most recently I [contributed](https://github.com/Hammerspoon/hammerspoon/pull/936) a [module for recognizing mouth noises](http://github.com/trishume/thume.popclick). It is based off some low-latency high-accuracy mouth noise recognizers I wrote during my research term at the UWaterloo HCI lab. Personally I use this module to scroll pages hands-free while lying down on the couch with my laptop. Previously I had to contort my hand into a cramped position on my chest to scroll with the trackpad while lying on my back. It's one of my zanier uses of Hammerspoon but it is nice to use nonetheless. Just goes to show the variety of user interface scripting tasks Hammerspoon can do.

## Custom Window Management Hotkeys

I love being able to customize my window management shortcuts perfectly for the kind of things I normally do. I have a custom modifier key on [my keyboard](/2014/09/08/creating-a-keyboard-1-hardware/) that is dedicated to window management I call `hyper`. Pressing `hyper` in combination with the left home row jumps directly between my most frequently used apps (Chrome, Sublime, iTerm2, Mail, Path Finder) and a pair of keys that mark a certain window and focus it, for all the other apps I use occasionally like PDF readers when writing LaTeX. Pressing `hyper` with the right home row moves a window between full screen, halves of the monitor, and between screens. Various other hyper shortcuts do things like toggling mouth noise recognition. I also have a hotkey I can hit when I plug in my external monitor that arranges all my apps between monitors in the way I like them instantly.

## Miscellaneous Hackery

I've used Hammerspoon for some one-off tasks, especially when I want to bind things to global keyboard shortcuts. An example of this is a weekend project I did to make a mouse controlled by head movements detected by an accelerometer on a microphone headset. I used Hammerspoon to send serial commands to the microcontroller when I pressed a shortcut to toggle the mousing on and off.

![Lookmouse]({{PAGE_ASSETS}}/lookmouse.jpg)

## Conclusion

I hope this has given you some ideas about how you can use Hammerspoon to make your computing experience more pleasant. Check out [my Hammerspoon config](https://github.com/trishume/dotfiles/blob/master/hammerspoon/hammerspoon.symlink/init.lua) to see how I configure everything and tie it all together. For more inspiration check out the amazing things [asmagill does in his config](https://github.com/asmagill/hammerspoon-config). He has experimental modules for all sorts of things like drawing calendars, custom app menus, fonts and speech control.

