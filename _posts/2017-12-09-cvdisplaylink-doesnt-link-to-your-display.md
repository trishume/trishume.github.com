---
layout: post
title: "CVDisplayLink Doesn't Link To Your Display"
description: ""
category:
tags: ["reversing","graphics","macos","latency"]
assetid: displaylink
---
{% include JB/setup %}

**Edit 2017/12/10:** So I screwed up, I thought I was safe confirming it in two different ways but I was using an external monitor and all of the below is accurate only for the multi-monitor case. Skip to the bottom to read about my new results.

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

### Edit 2017/12/10: I was wrong, sorry

[@ametis_](https://twitter.com/ametis_/status/939739328397295617) on Twitter noted that the internal `CVCGDisplayLink::getDisplayTimes` method actually accesses a pointer to a [StdFBShmem_t](https://opensource.apple.com/source/IOGraphics/IOGraphics-517.17/IOGraphicsFamily/IOKit/graphics/IOFramebufferShared.h.auto.html). I poked around some more and confirmed that the shared memory for this is indeed mapped in in the initializer. I figured I might miss something like this, hence why I did the experiments. This shared memory contains real vsync times, and is apparently a way to get real vsync information from the Kernel. See [this StackOverflow post](https://stackoverflow.com/questions/2433207/different-cursor-formats-in-ioframebuffershared) for an example of code that maps it in. The question is, why do my experiments show that it still doesn't line up with vsync?

The `MTKView` I was testing with uses `CVDisplayLinkCreateWithActiveCGDisplays` which if you have multiple displays creates a `CVDisplayLink` "capable of being used with all active displays", i.e it doesn't use vsync. I was using an external monitor for my tests, there's nothing on my laptop display but I leave it open because there's a hardware issue where it messes with my trackpad if I close it. In this case a smarter `CVDisplayLink` could handle this case fine by realizing that only one of my displays was updating at the time, but it turns out it falls back to a timer.

I re-did my experiments in Instruments on my laptop display and found that it consistently fired the `draw` call half-way into the frame, about 7ms from the next vsync. I don't know why it does it in the middle rather than the start, but at least it was consistent across 6 runs.

So, basically this article is mostly wrong, provided you only have one display. You still have to worry about jank due to inconsistent frame times on a single monitor if you don't have GL/Metal vsync enabled and your frames jitter around 7ms though. And if you want events near the start of vsync you may still have a difficult task ahead of you.

It's probably even possible to get the correct events in a multi-monitor case, but you need some fancy code that watches which screen your monitor is on, and constructs a new `CVDisplayLink` with just that `CGDisplay` when the window moves.

Interestingly, [@ametis_](https://twitter.com/ametis_/status/939739328397295617)'s account was created just for that tweet, and figuring out that it uses `StdFBShmem_t` without a hint would have required way way better reversing skills than mine to trace the instance variable back to the init method through a bunch of offsets to a memory mapping of an opaque code, which they would have had to figure out is `kIOFBSharedConnectType` and look at that struct to find it contains the `vblTime` field. Either they're really good at reverse engineering, or they're an Apple engineer with access to the source code who looked into it after seeing my article. Regardless I'm happy they set me straight!

Thanks to other commenters on Hacker News and Twitter have pointed out a few things that I should add here:

- Someone on HN notes that the Apple docs don't promise that `CVDisplayLink` gives you refresh times. I had noticed this but didn't include it in my article, but I treated it as further evidence for my results though. Ooops, turns out it does sometimes, just not always.
- [@jordwalke](https://twitter.com/jordwalke) linked me to [this article](http://www.ananseproductions.com/game-loops-on-ios/) that explains how `CADisplayLink` works on IOS.
