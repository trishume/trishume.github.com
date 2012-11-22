---
layout: post
title: "Using Slate: A Hacker's Window Manager for Macs"
description: "How to configure and use the Slate window manager."
category: howto
assetid: slate
tags: [slate,configuration,mac,tutorial]
---
{% include JB/setup %}

**Note: if you already know what Slate is and what it can do you can skip
to [Configuration](#configuration).**

Switching windows with the keyboard on Mac OSX is hilariously inefficient: it
involves repeatedly pressing command+tab through millions of programs until you
get to the right one when you could have just clicked the window and been done
with it. Moving windows is no better so people have resorted to paying for tools
like SizeUp and Divvy. I used to have these problems too until I <s>switched to
Linux</s> discovered a program called Slate.

Fancy window management is no longer just for Linux users and their XMonad.

## Enter Slate

[Slate](https://github.com/jigish/slate) is a keyboard-driven window management
program for Mac OSX. It is highly configurable and has tons of features. It has
permanently changed the way I use my Mac. Not only is it better than other
popular programs like Divvy, SizeUp and Moom, it beats their prices at being
**free**. Slate is the VIM/Emacs of window managers: it is less of a window
manager than a workflow changing tool you will never give up.

Slate has so much functionality that I think of it more as a shortcut-based
productivity tool than a window manager. Here is a sample of what it can do:

- **Move/Resize/Shift windows:** this can be done based on different screen size
  fractions and even mathematical formulae. There are commands for practically
  every window operation you can think of. It also supports the Divvy style
  sizing grid.
- **Switch Windows:** Slate can act as a complete replacement for command+tab in
  many ways. I will talk about this more in the "Window Switching" section.
- **Manage multiple monitors:** Slate can move windows between monitors as well as
  detecting your monitor configuration and automatically moving windows around
  when you plug in an external monitor.
- **Save window layouts:** Slate has a feature called "snapshots" that allows you to
  save your current window layout and restore it at any time. This is handy for
  having different layouts for different projects/tasks.

In this article I will describe the kind of things you can do with Slate and how
to configure it to do these things.

## Switching Windows

Slate allows me to switch to any window I want in one shortcut and a single key
press. I can do this using a feature called "Window Hints". If you have ever
used easyMotion for Vim or Vimperator/Vimium you will be familiar with this
concept.

When you press a shortcut (I use `cmd+e`), every window is instantly overlain with
a letter, starting with those on the home row of your keyboard. By pressing the
letter over a window your focus is transfered to that window. For windows that
are hidden behind others the application icon is displayed in the overlay.

### As usual, a picture is worth a thousand words:
[![Window Hints]({{PAGE_ASSETS}}/windowhints.jpg)]({{PAGE_ASSETS}}/windowhints.jpg)
Notes: There is an option to overlay the icons with a dark background so that it
is easier to read the letters. Also note the fancy Slate managed window layout.

### Switching Windows Even Faster

Even though window hints are super fast there are some applications I switch to
and from so often that I wanted to be able to do it in one shortcut. Luckily,
Slate had my back. Using Slate's focus command I was able to give my most commonly used programs
their own switching shortcuts. 

Inspired by [this article](http://stevelosh.com/blog/2012/10/a-modern-space-cadet/), I use a
program called "PCKeyboard Hack" (ironically mac only) to bind my caps lock key
to `command+option+shift+control` which I call "hyper".  I use this binding to
manage all my custom shortcuts. For example, `hyper+e` focuses on my browser,
`hyper+u` focuses on my editor, `hyper+i` focuses on iTerm, `hyper+m` focuses Mail,
etc...

## Moving Windows

Slate has numerous commands for moving and resizing windows. I personally only
use a small portion of them. The most common ones are the classic "resize to
left half", "resize to right half" and "fill the screen"; however, I also have
ones like "move this to my other monitor" and "layout my applications across
both monitors just the way I like them". All of these are bound to keyboard
shortcuts.

I started off with Slate by rebinding my numpad to window movement commands.
Whenever I need to type a number I use the ones along the top of the keyboard so
before Slate the numpad was just useless buttons. I bound the numpad keys like
to resize windows in the direction they pointed. For example, 5 was fullscreen,
4 was left half and 6 was right half. The other buttons were quarters, top and
bottom. Special numpad keys like * and + did things like display a window
resizing grid or arrange my windows in a certain layout.

I soon grew tired of reaching for my numpad so I added bindings to the home row
of my keyboard using the hyper key. This is more convenient for when I don't
have a numpad and it makes it so I don't have to reach over.

I have just scratched the surface of what Slate can do in terms of window
movement and resizing, Slate has commands for resizing windows incrementally,
nudging windows around, resizing to any fraction of the screen you want and even
moving windows to specific pixel positions.

<a name="configuration">
</a>
# Configuring Slate
### A.K.A How do I do all this cool stuff?

Like many amazing tools such as VIM and ZSH, Slate is configured through a
dotfile in the home directory called `.slate`. The [Slate
Readme](https://github.com/jigish/slate) file has very detailed information on
configuring Slate so I am just going to show some tricks that let you do
specific things.

The `~/.slate` file is made up of different commands. The top level commands are:
* `config`: for global configurations.
* `alias`: to create alias variables.
* `layout`: to configure layouts.
* `default` :to default certain screen configurations to layouts
* `bind`: binds a key to an action.
* `source`: to load configs from another file.

The `#` character is used for comment lines and `'` is used to delimit
strings.

### General Configuration

Using the `config` command, you can set a variety of options that change how
slate works. Here are some you options that I like to set:

    config defaultToCurrentScreen true
    # Shows app icons and background apps, spreads icons in the same place.
    config windowHintsShowIcons true
    config windowHintsIgnoreHiddenWindows false
    config windowHintsSpread true

### Window Hints

Along with the general configuration from the previous section, all you have to
do to use window hints is bind the hint operation to a key. I like to use
`command+e` as it is easy to type and not used in many mac applications.

To do this put the following in your `.slate` file:

    bind e:cmd hint ASDFGHJKLQWERTYUIOPCVBN # use whatever keys you want

You can choose which letters you want window hints to use. The letters will be
assigned to windows in the order specified by the `windowHintsOrder` config
option. If you have more windows than there are letters specified, some hints
will not be shown. I suggest you start with either the home row of your keyboard
or all the keys on one side of the keyboard so you only need one hand.

### Window Grid

If you are a fan of the Divvy style window positioning grid Slate can do
that too. To bind the window grid to a key use a command like:

    bind g:cmd grid padding:5 0:6,2 1:8,3

This particular command binds `command+g` to show a 6x2 grid on the first
monitor (monitor `0`) and a 8x3 grid on the second monitor (monitor `1`).

[![Window Grid]({{PAGE_ASSETS}}/grid.png)]({{PAGE_ASSETS}}/grid.png)

### Normal Window Management

Slate is so configurable that it allows you to specify any fraction of the
screen you want to move windows; however, this can be annoying if you just want
to use halves and fullscreen. To remedy this, Slate allows you to create aliases
that you can use for common commands.

Here are some aliases I use for common positions:

    # Abstract positions
    alias full move screenOriginX;screenOriginY screenSizeX;screenSizeY
    alias lefthalf move screenOriginX;screenOriginY screenSizeX/2;screenSizeY
    alias righthalf move screenOriginX+screenSizeX/2;screenOriginY screenSizeX/2;screenSizeY
    alias topleft corner top-left resize:screenSizeX/2;screenSizeY/2
    alias topright corner top-right resize:screenSizeX/2;screenSizeY/2
    alias bottomleft corner bottom-left resize:screenSizeX/2;screenSizeY/2
    alias bottomright corner bottom-right resize:screenSizeX/2;screenSizeY/2

You can then bind these commands to any keys you want. For example, you can use
the numpad to move windows around:

    # Numpad location Bindings
    bind pad1 ${bottomleft}
    bind pad2 push bottom bar-resize:screenSizeY/2
    bind pad3 ${bottomright}
    bind pad4 ${lefthalf}
    bind pad5 ${full}
    bind pad6 ${righthalf}
    bind pad7 ${topleft}
    bind pad8 push top bar-resize:screenSizeY/2
    bind pad9 ${topright}


### Layouts

Layouts allow you to tell Slate how you like your windows arranged so it can
arrange them for you. To create a layout you have to specify how you like your
applications arranged and then you bind the layout to a keyboard shortcut.

We can re-use the aliases from the last section in our layout definitions like
this:

    layout 1monitor 'iTerm':REPEAT ${bottomright}
    layout 1monitor 'Sublime Text 2':REPEAT ${lefthalf}
    layout 1monitor 'MacVim':REPEAT ${lefthalf}
    layout 1monitor 'Safari':REPEAT ${righthalf}
    layout 1monitor 'Mail':REPEAT ${righthalf}
    layout 1monitor 'Path Finder':REPEAT ${topright}
    layout 1monitor 'Xcode':REPEAT ${full}
    layout 1monitor 'Eclipse':REPEAT ${full}
    layout 1monitor 'iTunes':REPEAT ${full}

Then we can bind the layout to a key like this:

  bind l:cmd layout 1monitor

Now whenever we press `command+l` our apps will arrange themselves the way we
like. In this example I named my layout `1monitor1` but you can give it a
meaningful name and even have multiple layouts with different names.

### Ultra-Fast App Switching

To bind shortcuts directly to focusing an app you can use the focus command.
For example, we can bind `command+option+b` to focus our browser:

    bind b:cmd;alt focus 'Google Chrome'

### My .slate

Here is my `.slate` file in its entirety, do note that it is optimized for the
Dvorak keyboard layout, so some of the shortcuts may seem weird and the hint
keys are the Dvorak home row rather than qwerty.

<script src="https://gist.github.com/4121655.js?file=.slate">
</script>

