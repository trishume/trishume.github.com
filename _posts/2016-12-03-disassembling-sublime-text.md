---
layout: post
title: "Disassembling Sublime Text"
description: "Interesting things I learned from Sublime Text's binary"
category:
assetid: sublimesecrets
tags: ["sublime", "reversing", "text-editors"]
---
{% include JB/setup %}

This afternoon I spent some time with the free trial of the
[Hopper Disassembler](https://www.hopperapp.com/) looking through the binary of
Sublime Text 3. I found some interesting things and some undocumented settings.

## Undocumented Settings

The most potentially useful and interesting thing I found were some undocumented
settings for Sublime Text. A couple of them could even be useful to some people:

- `draw_shadows`: A boolean that can disable the shadow effect when any line is longer
that the window. I personally like effect but if you want a cleaner look or your window
is only slightly wider than your text and the shadow effect kicks in early, you can use
this setting.
- `indent_guide_options`:
  - `solid`: This as an undocumented option that makes indent guides solid instead of dashed.
  Add this in addition to a `draw_*` option.
  - `draw_active_single`: Like `draw_active` but only draws the innermost indent guide your
  cursor is in instead of guides for every indent level down to it.
- `draw_debug`: A boolean that if true enables a special debugging text renderer. It seems to
  turn sections of the document either blue or red, and within the sections it turns tokens
  alternating light and dark shades of those colours. Note you have to set the setting to false
  to turn it off, not just delete it. These change sometimes when scrolling and editing but I
  can't figure out when and why.
- `wide_caret`: This just acts like adding to `caret_extra_width`, probably an old setting, not useful.

There's also the undocumented command line flags:

- `--multiinstance`: Starts a new instance of Sublime even if one is already running.
- `--debug`: Prints debug output to stdout, I think this is just the output that goes in the built-in console.

I discovered these settings by running `strings` on my `Sublime Text.app/Contents/MacOS/Sublime Text`
binary and looking near the things I knew where config options for things that looked like config
options, then trying them out.

![Debug rendering mode]({{PAGE_ASSETS}}/debug_render.png)
![Debug rendering mode]({{PAGE_ASSETS}}/configs.png)

## Libraries Used

The Sublime Text release binaries don't have symbol names stripped out, probably for debugging
reasons, and for that I'm very grateful because it's really cool. The assembly is still largely
indecipherable to me, but there are some cool things I can find out.

From the function names I can also see some of the libraries used in the making of Sublime Text.
Here's a partial list:

- Skia: It's been mentioned online this is used for rendering everything
- Google densehash: Faster hash map, used everywhere
- Oniguruma: Fallback for fancy regexes the custom engine can't handle
- Boost
- Google breakpad
- CryptoPP/Crypto++ (in old versions, now replaced with libtomcrypt)
- leveldb: Used to store symbol indexes I think
- snappy: Fast compression, not sure what it is used for
- Hunspell
- YAML (apparently actually yaml-cpp)
- lzma
- Hunzip: Probably what is used to unzip the zipped up package format
- libtomcrypt

## Internal names

I can also see some general architecture and what things are named. This is just cool trivia.

- `sregex`: The custom super fast regex engine. I think the special feature is that it can search for many different regexes on one piece of text at the same time. Because [when I wrote a sublime-syntax highighter](http://github.com/trishume/syntect) that's what I would have wanted.
- `skyline`: The name for Sublime's widgets framework. The centerpiece is `skyline_text_control`.
- `px`: The windowing and platform integration framework used for event handling, file management and other OS integration across Windows, Linux and OSX.
- `TokenStorage`: The class that stores and renders highlighted tokens.

God how I wish any of these were open source. Each of these would be useful in
many things other than text editors. There's no app I know of that has its own
custom-rendered UI framework that manages to be as fast and smoothly
integrated with the OS as `skyline` and `px` are. The custom regex engine
would be a handy library as well. I do understand that these goodies might not
have existed in the first place if Jon couldn't make money off of Sublime Text
though, so I'm grateful that I at least have one beautiful and fast cross-
platform app.

## More

I also tried to figure out how some parts of the editor work and why they are so fast,
but I couldn't figure out much from the assembly. All the key functions have hundreds of
basic blocks and are enormous with everything inlined. If I spent an entire day I might be
able to reverse engineer one function, but that wouldn't get me very far.

If there's anything you're interested in about Sublime Text's internals, leave a
comment and I might take a look. Especially if it's a tiny behaviour improvement that
isn't accessible to the plugin API but might be possible to patch in the binary,
with a debugger, or with something like [Frida](http://www.frida.re/).

## Edit: Updates

After this article was posted on [Hacker News](https://news.ycombinator.com/item?id=13100560)
and cross-posted to [the Sublime forum](https://forum.sublimetext.com/t/disassembling-sublime-text/24824),
@wbond, the Package Control maintainer and new Sublime developer replied with some corrections and new info.
I've updated the library listing above with the new info.
