---
layout: post
title: "Hard to discover tips and apps for making macOS pleasant"
description: ""
category:
tags: []
---
{% include JB/setup %}

Inspired by a few different conversations with friends who've switched to macOS where I give them a whole bunch of tips and recommendations I've learned about over many years which are super important to how I use my computer, but often quite hard to find out about, I decided to write them all down:

## Hidden macOS tips

- Dragging a file or folder onto a file open dialog selects it in the dialog. Similarly dragging onto a "Choose file" button.
- Dragging onto a terminal window pastes the full path of that file/folder
- You can drag the little file/folder icons at the top of many windows, useful in combo with previous tips.
- If you hold down `option` while clicking the "Scaled" radio button in the Display preferences it'll give you many more resolution options on external displays. If you want native resolution with no scaling on the built in display you'll still need an external tool like [SwitchResX](https://www.madrau.com/), [retina](https://github.com/lunixbochs/meta/tree/master/utils/retina) or [QuickRes](https://www.thnkdev.com/QuickRes/).
- In Finder, `return` is the shortcut for rename, `option`+drag copies, and `space` is quicklook preview
- In Preview if you open the Sidebar in a PDF you can drag pages around including between documents, hold option to copy, delete pages with backspace. This plus the edit toolbar solves 90% of my PDF munging needs.
- You can select multiple images in Finder and drag them onto the Preview dock icon to open them in one window with a Sidebar where you can quickly flip between them with arrow keys.
- In the Dock preferences there's a "Prefer tabs when opening documents" setting which automatically groups your windows with window tabs. I find this especially useful for Sublime Text.
- `cmd+backtick` is like `cmd+tab` but between windows of the same app. Adding `shift` (i.e., `cmd+shift+backtick`) reverses the order. You can add `shift` to `cmd+tab` to go backwards too.
- Drag your most frequently used folders into the Finder sidebar for easy access including in file select dialogs.
- Select multiple similarly named files in Finder, right-click, and choose "Rename <X> Items..." for a reasonably powerful batch file renamer.
- In the Finder preferences you can add your computer and drives to the sidebar.
- `cmd+shift+4` pops up a crosshair to take a screenshot of a region. Hit `spacebar` to switch to a mode that takes a screenshot of an entire window.
- You can [disable the popup for accented characters when you hold a key](https://www.defaults-write.com/disable-press-and-hold-option-in-mac-os-x-10-7/) and  [increase key repeat rate beyond the normal maximum](https://apple.stackexchange.com/questions/10467/how-to-increase-keyboard-key-repeat-rate-on-os-x).
- The `open` command lets you use the normal macOS file opening mechanism from the command line, I most frequently use `open .` to navigate to my current directory in my file browser.
- Display "scales" other than 1x or 2x the physical resolution work by rendering at 2x the resolution then down-scaling. This causes apps to need to render a bunch of pixels that are mostly scaled away, consuming power and sometimes causing lag. It can also lead to weird aliasing issues in some contexts like shimmering of thin fonts when scrolling, as well as rendering in general not being pixel-perfect. I recommend trying to stick to either 1x or 2x scaling if you don't lose much from it, then just adjusting your default web page scale and font sizes.
- Text fields [support a bunch of powerful movement and editing shortcuts based on Emacs](https://jblevins.org/log/kbd).
- `option+2` types the `™` symbol, for use with sarcasm™. I probably use this more than the `^` symbol. You can open the keyboard viewer (you may have to enable "Show keyboard and emoji viewers in menu bar" in Keyboard Preferences) and hold down option to see all the other symbols you can type like this. The "Emoji & Symbols" pallete is also a great UI for finding handy Unicode characters, especially if you use the gear menu to add more symbol category pages.


## Apps

A big part of why I prefer macOS is this list of macOS-only native apps which often don't have adequate substitutes on Linux:

- [Dash](https://kapeli.com/dash): An amazing fast offline documentation search app. Cuts down a ton on the amount I Google for docs. It's very quick to use especially when summoned with a keyboard shortcut and has tons of documentation sets.
- [Hammerspoon](https://www.hammerspoon.org/): My favorite app for getting the benefits of a Linux tiling window manager. I have home row shortcuts on my left hand bound to switch directly to my most frequently used apps, and my right hand to maximize windows, move them between screens and tile them to the left and right halves of the screen. [Here's my config.](https://github.com/trishume/dotfiles/blob/d12f869062b2fa2d4b3f72eeed2f0e05df5a8657/hammerspoon/hammerspoon.symlink/init.lua)
- [Screenie](https://www.thnkdev.com/Screenie/): I only use this for the feature where dragging from the menu bar icon lets you put your most recent screenshot in say messaging apps. It also offers search and things. [CleanShot X](https://cleanshot.com/) and [Zappy](https://zapier.com/zappy) also look like good screenshot apps but I haven't tried them yet.
- [Karabiner Elements](https://karabiner-elements.pqrs.org/): A powerful keyboard remapping tool. I use it to bind right command to control and caps lock to `ctrl+cmd+option+shift` for use with Hammerspoon.
- [Alfred](https://www.alfredapp.com/): A mildly better spotlight alternative, but for me the main benefit over spotlight is [this workflow for indexing git repos](https://github.com/deanishe/alfred-repos).
- [Path Finder](https://cocoatech.com/#/): A fancier version of Finder with multiple panes and various other advanced features. Other third party file managers you may want to try include [Forklift](https://binarynights.com/), [Commander One](https://mac.eltima.com/file-manager.html), [Nimble Commander](https://magnumbytes.com/), [Marta](https://marta.yanex.org/) and [fman](https://fman.io/). I use Path Finder because it's the only one with a good columns view and that's my favorite view for browsing.
- [Spark](https://sparkmailapp.com/): A nice email app with categorized inbox functionality.
- [iStat Menus](https://bjango.com/mac/istatmenus/): All sorts of system monitoring in a menu bar. I really like the weather, and I also have a combined menu which shows my current power draw in watts and GPU selection in the icon.
- [Tweetbot](https://tapbots.com/tweetbot/mac/): A native Twitter client that syncs with a similar IOS client. I really like how it just keeps your position in an infinite scroll where new tweets get added to the top, so I can easily read every new tweet from people I follow without seeing any likes, algorithmic suggestions or ads.
- [Hex Fiend](https://github.com/ridiculousfish/HexFiend/): A really good hex editor/viewer. I like their "Templates" feature where you can describe a binary format with a script and it will overlay the parse tree on the hex view.
- [iTerm2](https://iterm2.com/): An alternative Terminal with just *so many features*. I particularly like the ability to split windows into panes, which Apple's Terminal does not have.
- [nvAlt](https://brettterpstra.com/projects/nvalt/): A note taking app that I like, although it's kinda bare-bones and has some bugs. It's currently unmaintained because the author is working on [nvUltra](https://nvultra.com/) which isn't released yet.
- [ImageOptim](https://imageoptim.com/mac): Easy app where you drag image files onto it and it reduces their size.
- [VMWare Fusion](https://www.vmware.com/products/fusion.html): Great for running Linux and Windows VMs. The reason I chose it over [Parallels](https://www.parallels.com/products/desktop/pro/) is that I knew it had virtualized PMC support, which enables using [rr](https://rr-project.org/) in VMs. But apparently Parallels also has this in the Pro version, and it might be nicer in other ways, not sure which is better.
- [Calca](http://calca.io/): A weird live math calculator notebook thing with units. The editing can be kind of glitchy but the basic functionality is really cool. [Soulver](https://soulver.app/) is a similar but more expensive app with a nicer UI but less powerful underlying calculator language.
- [Quartz Debug](https://developer.apple.com/download/more/): There are some apps that reduce your battery life in an insidious way where it doesn't show as CPU usage for their process but as increased `WindowServer` CPU usage. If your `WindowServer` process CPU usage is above maybe 6-10% when you're not doing anything, some app in the background is probably spamming 60fps animation updates. As far as I know you can only figure out which app is at fault by getting the Quartz Debug app from [Apple's additional developer tools](https://developer.apple.com/download/more/), enabling flash screen updates (and no delay after flash), then going to the overview mode (four finger swipe up) and looking for flashing. This same problem can also occur on Linux and Windows but I don't know how much power it saps there.
- [Sublime Text](https://www.sublimetext.com/) and [Merge](https://www.sublimemerge.com/): These aren't exactly macOS-only apps but they're some of my favorite apps and they integrate excellently with macOS so I'm putting them here anyways.

## Bonus: Browsers

- Middle click opens links in a new tab and middle clicking on a tab closes it
- There's lots of lesser-known handy shortcuts: cmd/ctrl+l focuses the search filed, cmd/ctrl+w closes a tab
- [Vimium](https://vimium.github.io/) and [OctoTree](https://www.octotree.io/) are my favorite browser extensions.
- I believe YouTube in Chrome and Firefox default to VP8/9 video codecs which can't be hardware-decoded so use lots of CPU and thus battery power especially at 2x speed or high resolutions. The [h264ify](https://github.com/alextrv/enhanced-h264ify) family of extensions can force usage of GPU-supported h264 codecs. This can close some of the battery life gap with Safari.
- If you use Safari, Chrome and Firefox have much better sounding audio resampling for watching videos on 1.5x or 2x speed. This is the only reason I don't use Safari.

## Bonus: IOS

IOS also has a bunch of hidden UI features, especially if you have a medium-old model of iPhone that still has force touch sensors.

- Swiping left and right on the home bar at the bottom of the screen on phones since the iPhone X quickly switches between recent apps. This is absolutely essential to how I use my phone and such a huge boost to multitasking fluidity I feel bad for all the people who don't know about it.
- Force or long pressing on the keyboard (maybe just the spacebar on some phones), brings up a moveable cursor in text fields.
- If you have force touch try it on everything, tons of widgets in the pull down settings have force touch features, notifications do, links do.
- I've tried a lot of calculator apps and Kalkyl is my favorite for launch time and UI design for quick simple calculations. I also recommend Unread for RSS, and Apollo as possibly the best Reddit experience on any platform.
- [Is It Snappy](https://isitsnappy.com/) lets you use an IOS device's high speed camera to measure full-system interaction latency and find out that you have a slow keyboard, mouse or monitor. I have not found a similar app for Android.
- Not exactly a software tip, but a non-obvious purchasing option: I contend buying an iPhone X on Ebay offers outstanding price/quality ratio even in 2020. It has basically the same screen/form factor/build quality as an iPhone 11 Pro, and I find it plenty fast and the camera sufficiently good, and those are basically the only things that improved. You even get force touch, which I really like as having lower latency than the more press-and-hold "3D Touch". Meanwhile it's less than half the price. I got mine discounted after the iPhone XS replaced it, and if mine broke I'd probably just buy another one now.

## Bonus: The Chromium Catapult Trace Viewer

The motivation to write this post was caused by a conversation with a friend about macOS, which was in turn kicked off by [a tweet](https://twitter.com/trishume/status/1302069073640120320?s=20) about the [The Chromium Trace Viewer (AKA Catapult)](https://aras-p.info/blog/2017/01/23/Chrome-Tracing-as-Profiler-Frontend/). Catapult is super easy to get started with for visualizing trace data and I know lots of different people and projects who use it. Almost none of them know about this incredibly helpful first tip until I tell it to them, so they're stuck with having to switch to the zoom tool in the toolbar:

- Use `alt+scroll` to zoom. This really ought to be in noticeable text on their UI not buried in a shortcuts pane you have to press `?` to see.
- The search bar in the top left searches not only names but also arguments values, which you can use to search for IDs or add special tags like `top100` for the 100 slowest events. Press `f` to zoom to a span once you've selected it with the search arrow buttons.
- The JSON event format also supports "flow" arrows, which lets you draw arrows between your boxes to visualize dependencies.
- [Perfetto](https://perfetto.dev/), [Tracy](https://github.com/wolfpld/tracy) and [Speedscope](https://www.speedscope.app/) can all visualize the same JSON format with different UIs and potentially without a trace size cap.
