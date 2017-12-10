---
layout: post
title: "CVDisplayLink Doesn't Link To Your Display"
description: ""
category:
tags: ["reversing","graphics","macos"]
assetid: displaylink
---
{% include JB/setup %}

`CVDisplayLink` is the recommended way to synchronize your drawing/animation with the refresh of the display on macOS. Many people assume it calls your app just after each display vsync event, unfortunately this isn't the case at all. `CVDisplayLink` just fetches the refresh rate of your display, and sets a high resolution timer to call you every 16.6ms (for a 60hz display).

The major reason this is important is if your app has inconsistent rendering times and you get unlucky with the phase of your events, you'll end up painting twice in some frames and zero times in others, leading to visible dropped frames in your animations. [As illustrated by @jordwalke on Twitter](https://twitter.com/jordwalke/status/939064408986103808):

[![Timing]({{PAGE_ASSETS}}/timing.jpeg)](https://twitter.com/jordwalke/status/939064408986103808)

This is particularly insidious because depending on how variable your draw times are, a lot of the time you'll end up with consistent drawing, but every N runs it will be really bad. Even worse, your FPS measurements will still show 60fps because you're still drawing every 16.6ms.

Also, if you're using this for a game loop where you only process input at the start of every frame, you could have close to an entire extra frame of latency if you're unlucky at startup.

"But it's a special thing that has 'display' and 'link' right in the name, surely it must link up to the display vsync events!" you might say. That's what I thought too until I talked to [@pcwalton](https://twitter.com/pcwalton) at a Rust meetup and he said he'd disassembled `CVDisplayLink` and found it was just a timer. This was astonishing to me and I sat on this information somewhat skeptical for a while. But, today I finally got around to doing a bunch of investigation and found that he's right and `CVDisplayLink` does not link to the vsync.

First, I disassembled the `CoreVideo` framework where `CVDisplayLink` resides and found a bunch of code that fetches the display rate, calculates how often the timer should be triggered and waits on a timer. I didn't find any code that looked for vsync events.

Next, I did some experiments, because I might have missed some hidden synchronization. I used [Kris Yu's Water](https://github.com/KrisYu/Water) Metal sample app since that's sadly the only macOS Metal sample code I could find that built for me. I then disassembled `MTKView` and confirmed that as I suspected it just uses `CVDisplayLink` to call your `draw` method. Then I added `kdebug_signpost` calls in the `draw` method so that I could use Instrument's "Points of Interest" trace combined with the new display vsync information to see how they line up.

What I found is that as one would expect with a timer, within each run the `draw` call happens at a consistent time within the frame, but between different runs the `draw` call happens at completely different times depending on the phase the `CVDisplayLink` starts up in relation to the display vsync.

Here's some screenshots of different runs in Instruments. The red boxes on the bottom are the `draw` call, and the vsync display intervals are clearly visible as lining up very differently each run:

[![Display Traces]({{PAGE_ASSETS}}/traces.png)]({{PAGE_ASSETS}}/traces.png)

Now, the real question is, what do you do if you want actual vsync alignment? I actually don't know, I haven't done enough research yet, but I have some ideas that may or may not work:

- I think Cocoa animation or Core Animation draw callbacks may actually be linked to display vsync, in which case you can use those. I'm not sure though.
- OpenGL vsync might synchronize with the real vsync.
- Somehow Instruments gets at the real vsync times, they might come from a private API, but it also might be something public.
- There may be some other API I don't know about.

Note that I haven't tested `CADisplayLink` on IOS, but I've heard it works properly. Anyway, if you know anything about this issue or how to do things properly, email me at [tristan@thume.ca](mailto:tristan@thume.ca)! I may update this post if I learn anything new.
