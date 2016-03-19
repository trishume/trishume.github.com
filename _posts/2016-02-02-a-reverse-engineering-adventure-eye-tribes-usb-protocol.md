---
layout: post
title: "A Reverse Engineering Adventure: Eye Tribe's USB Protocol"
description: ""
category:
tags: ["reversing", "eye tracking", "UVC", "hardware"]
---
{% include JB/setup %}

**Update:** See bottom of the article for recent progress. I've managed to get a full 10-bit high def video feed and have released example code.

In 2014 I bought an [Eye Tribe eye tracker](http://theeyetribe.com/) hoping to work on some neat eye tracking projects.
Unfortunately I've never been able to reach the fingertip level accuracy they claim and that I have seen in videos.
I always get around +/- 5cm (2 inches) or more of jitter. Recently I've been working on eye tracking research again
and I thought I would take a crack at debugging my accuracy issues.

There's just one problem: The Eye Tribe's tracking software is closed source and doesn't have a debug view or a raw camera
feed API. I've been wanting to try my hand at reverse engineering lately so I set myself the goal of reverse engineering
the tracker's USB protocol so that I could turn the tracker's IR lights on and capture the IR video feed.

The Eye Tribe tracker is really just a USB 3.0 [UVC](https://en.wikipedia.org/wiki/USB_video_device_class) camera (the standard webcam protocol) that shoots
in monochrome IR. It also has bright IR LEDs that light up the user's face since there isn't much ambient IR indoors.
Capturing the video is easy, the hard part is that the LEDs are controlled through a proprietary extension to the USB video camera protocol.

Thus I started on my quest to discover the special commands that would turn on those LEDs. In the end I figured out some cool techniques,
and helped diagnose out my issue (haven't solved it yet though). What could be useful to others is that the Eye Tribe is effectively
a low cost ([alternatives](https://www.ptgrey.com/) are >$500), high resolution, high frame rate IR camera with built in illuminators.
This could be used for all sorts of computer vision projects like a cheap [Vicon](http://www.vicon.com/) style motion capture system or an
open source eye tracker.

## Exploration

I started by [installing USB Prober](http://superuser.com/questions/781982/how-can-i-install-usb-prober-from-the-developer-sdk-on-mac-os-x), a dev tool that lets you inspect the metadata of devices connected by USB. You can get practically the same
information in the USB section of the built in "System Information" app but I installed USB Prober in case it gave more info.

I started looking through the [USB info dump for the Eye Tribe tracker](https://github.com/trishume/EyeTribeReversing/blob/master/USBProber.txt) and
discovered some good clues. First of all that it was a UVC camera, and that it was only a UVC camera, no other fancy USB control endpoints.
I also noticed that there was a `VDC (Control) Extension Unit` interface: this was probably where the custom lights control messages could be sent.

I also figured out some other interesting things like the camera module being manufactured by [Leopard Imaging](https://www.leopardimaging.com/)
and that it could capture high resolution 2304x1536 video at 27fps (that's more than 1080p) and 768x1024 at 60fps. There are also a bunch of intermediate
resolutions it can do at intermediate frame rates.

## Attempting to Log

My next step was to try and log the USB traffic between the tracker and the eye tracking data server program The Eye Tribe provides.
Unfortunately, Apple hasn't updated the kernel extensions for USB logging for the latest OSs. Last time I tried installing them I nearly
bricked my laptop because it couldn't read any USB HID input, including the internal USB hub for the laptop's keyboard and trackpad.
I only rescued it by copying the Kext files from the recovery partition onto my main drive, I started backing up my entire disk instead of just
my important files after that incident.

So instead I took the advice in [this mail thread](http://lists.apple.com/archives/usb/2015/Jan/msg00004.html) and tried `usbtrace` and `dtrace`
instead. Unfortunately `usbtrace` showed megabytes per minute of all my system's USB traffic in a not very useful format.
`dtrace` showed me that control messages were being sent by the tracking server, and from what call stack, but not which messages and what they contained.

## Disassembly

After logging failed, I tried a different approach. I downloaded the trial of [Hopper 3](http://www.hopperapp.com/) and loaded up the Eye Tribe server executable.
Most of the method names were just numbered symbols but I managed to find an Objective C method called `setUvcControl:withValue:` that belonged to a class called
`UVCCameraControl`. I tried tracing the callers to see if I could find any obvious light control code, but with no function symbol names, no source code, and
only vaguely knowing x86_64 assembly, I wasn't able to do it.

Instead I used [class-dump](http://stevenygard.com/projects/class-dump/) on the server executable to look at the other methods. I Googled some of the method names
and found [it was open source](http://phoboslab.org/log/2009/07/uvc-camera-control-for-mac-os-x) (code on [Github here](https://github.com/HBehrens/CamHolderApp/blob/master/CamHolderApp%2FUVCCameraControl.m)). Now I had the source code for the mechanism used to send the messages, but I didn't know what they were called with.

I read through the source of that class and started looking at the [UVC protocol spec](http://www.cajunbot.com/wiki/images/8/85/USB_Video_Class_1.1.pdf) to make sense of what I found.
I learned that auxiliary parameters of a camera are controlled and inspected by UVC control requests like `SET_CUR` and `GET_CUR` on different interfaces and with different control selectors.
I figured out through reading the source code that the bit fields described in the protocol corresponded with the fields of OSX's [IOUSBDevRequest](https://developer.apple.com/library/mac/documentation/Kernel/Reference/USB_kernel_header_reference/index.html#//apple_ref/c/tdef/IOUSBDevRequest).

## Debugging

I started on a new approach to try and log the control requests sent by the server through intercepting the method calls made by it.
If I could print out the contents of the `IOUSBDevRequest` structs being sent, I could probably figure out which ones turned on the lights. So I fired up [LLDB](http://lldb.llvm.org/)
and set a breakpoint at the hex address of [sendControlRequest:](https://github.com/HBehrens/CamHolderApp/blob/master/CamHolderApp%2FUVCCameraControl.m#L255) from the disassembly.

I started the server with the tracker connected and LLDB hit the breakpoint, but since there were no debug symbols, all I could look at was registers and assembly.
I had no idea what the calling conventions were for Objective-C code and looking them up and peeking at some memory didn't seem to find the right things.
So I kept stepping and reached down into `IOUSBInterfaceClass::interfaceControlRequest(void*, unsigned char, IOUSBDevRequest*)` which although it didn't have debug info,
at least had an unobfustucated function name. I Googled this and found that Apple [published the source code](http://www.opensource.apple.com/source/IOUSBFamily/IOUSBFamily-203.4.7/IOUSBLib/Classes/IOUSBInterfaceClass.cpp)!

The registers and assembly weren't helping me very much until after an hour or two I figured out how to find where the struct I wanted was located.
The source code for `IOUSBInterfaceClass::interfaceControlRequest(void*, unsigned char, IOUSBDevRequest*)` showed it copying a `IOUSBDevRequest` into an `IOUSBDevRequestTO` and not much else.
So I looked at the dissassembly for that method in the debugger and saw a bunch of mov instructions copying the fields of the struct. They all looked something like:

    0x100ae2fb0 <+14>: movb   %al, -0x28(%rbp)
    0x100ae2fb3 <+17>: movb   0x1(%rbx), %al

Aha! At that point the struct I want must be pointed to by register `%rbp`. I stepped to that point, and after a figuring out the right casting and pointer indirection I printed out the second byte:

    (lldb) e (int)((char*)$rbx)[1]
    (int) $22 = 129

The second byte of the struct I wanted should be the `UInt8 bRequest` field which should correspond to one of the [constants in the UVCCameraControl](https://github.com/HBehrens/CamHolderApp/blob/master/CamHolderApp%2FUVCCameraControl.h#L16). Sure enough after using `irb` to convert `129` to hex I got `0x81` which is the request code for `UVC_GET_CUR`, I had found it!

## Logging (for real this time)

Now I needed to figure out how to print out the other fields and the data pointed to by the `void *pData` field. All fast enough so that the tracking server wouldn't get messed up.
My strategy for this was to try and script LLDB to break at the exact right instruction, print out all of the fields, and then continue automatically.

I read about LLDB's Python scripting capabilities, but the Python interface was poorly documented and could only really do anything with debug info, which I didn't have.

So instead I figured out all the right casting invocations to print out the fields of the struct, which took a while.
Then I figured out the exact offset from the start of the dynamic library I wanted to break at (the absolute address changed every time I started up the tracking server), set a breakpoint there
and added a breakpoint command which printed the fields and then continued:

    breakpoint set -a <address of IOUSBLib I found>+0x7fae
    breakpoint command add 1
    e ((uint64_t*)$rbx)[0]
    e ((uint64_t*)$rbx)[1]
    p *(uint32_t(*)[15])(((uint32_t**)$rbx)[1])
    e ((uint32_t*)$rbx)[4]
    c
    DONE

Then I ran the code, connected the eye tracker, started the tracking UI (which turns on the lights), waited a bit, and shut down the tracking UI (turning off the lights).
It output a bunch of data which I copy pasted into some [text](https://github.com/trishume/EyeTribeReversing/blob/master/log2.txt) [files](https://github.com/trishume/EyeTribeReversing/blob/master/log3.txt).

## Analysis

Now I had a log of the control requests, but as a couple 64 bit decimal integers in a copy-pasted LLDB log. So I had to write a script to parse out the various fields of the `IOUSBDevRequest` struct.
I did this in Ruby, eventually producing [this script](https://github.com/trishume/EyeTribeReversing/blob/master/parsedump.rb).

First I had to parse the format, then I used bitwise operators to extract the various fields of the struct out of the integers and into fields of a Ruby hash.
Now I had the raw data from the struct, but all the fields were still opaque numbers: next I had to interpret them.

I started by going back to the [UVC protocol spec](http://www.cajunbot.com/wiki/images/8/85/USB_Video_Class_1.1.pdf) and copy-pasted some of the name tables in the appendix into hash literals in my script. I tried using these to map the numbers to names, but ended up with weird results. Then came a couple hours of fiddling, confusion and reading, as well as looking at [how the records were constructed](https://github.com/HBehrens/CamHolderApp/blob/master/CamHolderApp%2FUVCCameraControl.m#L286) and correlating that with the spec. After the 5th try at mapping I figured out which fields came from where: I had to use the `Terminal ID` from USB Prober to decide which table to look up the control selector (high byte of the `wValue` field) in based on the `unitID` field (high byte of `wIndex`).

Finally I got results that made sense: before the lights turned on the server sent a couple `UVC_SET_CUR` requests to the extension unit. It looked like this:

    {:bmRequestType=>33, :bRequest=>1, :wValue=>768, :wIndex=>768, :wLength=>2, :selector=>3, :unitId=>3, :req=>"UVC_SET_CUR", :unit=>"VC_EXTENSION_UNIT"}
    [15, 0]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>1024, :wIndex=>512, :wLength=>2, :selector=>4, :unitId=>2, :req=>"UVC_SET_CUR", :unit=>"VC_PROCESSING_UNIT", :msg=>"PU_GAIN_CONTROL"}
    [63, 0]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>1024, :wIndex=>768, :wLength=>8, :selector=>4, :unitId=>3, :req=>"UVC_SET_CUR", :unit=>"VC_EXTENSION_UNIT"}
    [250, 0, 240, 0, 250, 0, 240, 0]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>1536, :wIndex=>768, :wLength=>2, :selector=>6, :unitId=>3, :req=>"UVC_SET_CUR", :unit=>"VC_EXTENSION_UNIT"}
    [44, 1]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>512, :wIndex=>768, :wLength=>4, :selector=>2, :unitId=>3, :req=>"UVC_SET_CUR", :unit=>"VC_EXTENSION_UNIT"}
    [0, 0, 0, 0]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>1024, :wIndex=>512, :wLength=>2, :selector=>4, :unitId=>2, :req=>"UVC_SET_CUR", :unit=>"VC_PROCESSING_UNIT", :msg=>"PU_GAIN_CONTROL"}
    [51, 0]
    ... more of the same message with small adjustments to the gain around level 51 ...
    {:bmRequestType=>33, :bRequest=>1, :wValue=>1024, :wIndex=>512, :wLength=>2, :selector=>4, :unitId=>2, :req=>"UVC_SET_CUR", :unit=>"VC_PROCESSING_UNIT", :msg=>"PU_GAIN_CONTROL"}
    [51, 0]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>768, :wIndex=>768, :wLength=>2, :selector=>3, :unitId=>3, :req=>"UVC_SET_CUR", :unit=>"VC_EXTENSION_UNIT"}
    [0, 0]
    {:bmRequestType=>33, :bRequest=>1, :wValue=>1024, :wIndex=>512, :wLength=>2, :selector=>4, :unitId=>2, :req=>"UVC_SET_CUR", :unit=>"VC_PROCESSING_UNIT", :msg=>"PU_GAIN_CONTROL"}

So it looks like there are a couple requests sent to the extension unit, but only selector `3` is sent with a positive value when the lights are turned on and later a zero when the lights are turned off.

## Capture

Now I just had to test my theory by writing an app that sent the right UVC control requests. I used [OpenFrameworks](http://openframeworks.cc/) since it comes with a camera capture example that uses
QtKit (which is deprecated but allegedly `UVCCameraControl` doesn't work with `AVFoundation`). I linked in the [ofxUVC](https://github.com/atduskgreg/ofxUVC) addon but ended up just calling the Obj-C
class directly. I started by fiddling with the gain setting and managed to even see myself a little bit without the IR illuminators turned on.

Then I tried sending selector `3` with a value of `15` to turn the lights on, and **it worked first try**! The lights didn't turn off when I shut down my test app, but that was an easy fix of adding another control message setting it to `0`.

## Victory!

![Captured frame](https://camo.githubusercontent.com/3927cebd93eaf9e4c75858a4fad0b10d38cb6ad2/687474703a2f2f692e696d6775722e636f6d2f6733495855646f2e6a7067)

That picture is captured with a gain level of around `0` but I noticed in the logs that the tracking server was setting the gain level around `51`. But when I adjusted the gain that high,
the 8 bit green values used to hold the image started wrapping around leading to a messed up image. This might be the cause of the tracking quality issues I've been having, but the real server
might do something to mitigate this. **Edit:** I've since discovered that lowering the exposure to compensate negates this issue, so I assume the real server uses a higher frame rate and lower exposure so they need the high gain setting. Another neat thing about the exposure is if you set it really long it can effectively take still pictures without the LEDs on.

Next I used the feature of the demo app to save a video to my drive, which interestingly started replacing some frames with pure green, which didn't happen at all in the live preview.
I later discovered that the 1 minute movie it saved was *10 gigabytes* because it wasn't using any compression. It is possible the dropped frames were my SSD bottlenecking the video capture.
Anyhow I compressed it down with Handbrake and uploaded it to Youtube, sorry for the annoying green frames.

In the video below you can see me looking at the four corners of my screen, and then some things on the screen. I then slowly adjust the gain setting upwards until it reaches `51` at which
point I wave my arms around to mark the time. Then I continue adjusting the gain up to maximum.

<iframe width="660" height="495" src="https://www.youtube.com/embed/8CguH2EJqUo" frameborder="0" allowfullscreen></iframe>

## Update

After I first published this post I emailed The Eye Tribe with my info and story, and I got some help and info from them.
It turns out that the eye tracker isn't working in as large of an area as it should (not sure why) so I can only use a 12" diagonal area of my screen instead of the full 24".
If I use the small area I get much better accuracy, closer to +/- 1cm of jitter and a 0-4cm offset from my true gaze location. This is still not as good accuracy as advertized
and it works on a much smaller area than advertized, but it is better than before. It is still entirely useless to me though, the accuracy is good enough for my project, but the area is too small.
Note that I have seen videos of other people achieving the claimed accuracy, it is likely that there is still some special complicating factor with my unit or setup, most customers probably have no issues.

This is post is also not ment to bash The Eye Tribe. They're my second favourite eye tracking company after [Pupil Labs](https://pupil-labs.com/pupil/). Despite their closed source software they are
still significantly more open than most other eye tracking companies with orders of magnitude lower cost.

## Update 2

I've now figured out how to properly retrieve high resolution 60fps video at the full 10 bit depth.
The tracker has a variety of resolutions available, higher resolutions only work with lower frame rates.
The highest resolution is 2304x1536 which is available at 27FPS. Some of the resolutions offered are scaled down versions of the full image, whereas others are cropped areas of it.
In order to get the full 60FPS you have to lower the exposure time, which significantly increases the noiseness of the image.

The pixels are encoded in YUY2 format where the lowest 8 bits of brightness are in the Y component and the highest 2 are in the UV component.

I've created a [project on Github called SmartGaze](https://github.com/trishume/SmartGaze) where I've done a little bit of work on implementing eye tracking algorithms for the Eye Tribe.
So far I've retrieved the raw feed using [libuvc](https://github.com/ktossell/libuvc), found the eye regions using glints, and then used an implementation of the [Starburst algorithm](http://thirtysixthspan.com/openEyes/software.html)
to locate the iris ellipse. The repo is released under the GPLv2 but [an earlier commit](https://github.com/trishume/SmartGaze/tree/d8cc7a767f6a451d69905a9d67a95e16d14f401a) containing just the code to read the raw 10 bit feed is released under the MIT license. I may or may not decide to finish this given that I recently got a [Steelseries Sentry](https://steelseries.com/gaming-controllers/sentry-gaming-eye-tracker) that works well for me when I run it in a Windows VM and [pipe the data over UDP](https://gist.github.com/trishume/b25492f25fc8ebe01dd9) to my mac.

Here's a video of the raw feed. The fact that you can hardly see the pupils in this video is a product of how I reduced the 10 bit image down to 8 bits, as well as not setting the PU_GAIN UVC control.
More recent commits of SmartGaze use a much brighter video, but one that washes out details of the face.

<iframe width="660" height="495" src="https://www.youtube.com/embed/nfCrLg9DnGc" frameborder="0" allowfullscreen></iframe>
