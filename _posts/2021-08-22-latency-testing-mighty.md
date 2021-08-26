---
layout: post
title: "Latency testing Mighty's remote browser: Why display streaming is hard"
description: ""
category: 
tags: []
assetid: mightylat
---
{% include JB/setup %}

Ever since I built [my light sensor based latency tester](https://thume.ca/2020/05/20/making-a-latency-tester/), I've wanted to use it to illuminate where the added latency of remote desktop / display streaming systems really comes from. I was recently let into the beta program of [Mighty](https://www.mightyapp.com/), which is a startup that makes an app to run Chrome in the cloud and stream what it renders to you as video. The idea is that you can save RAM on your machine and take advantage of powerful cloud computers with gigabit networking, but it means many interactions no longer take place on-device. I'll use various latency tests I did with Mighty to illustrate the challenges inherent in providing a nice remote display experience on high-resolution displays, and talk about optimizations they could make to be much snappier.

![Latency Tester]({{PAGE_ASSETS}}/latencytester.jpeg)

## Why Mighty?

Mighty is part of a new generation of app streaming systems which take advantage of GPU-accelerated encoding/decoding of common video compression formats. Examples include all the major game streaming services like [GeForce Now](https://www.nvidia.com/en-us/geforce-now/) and [Google's Stadia](https://stadia.google.com/). Unfortunately, there's a few things which make it tricky to use this approach to compete with legacy remote access systems let alone running locally for normal desktop apps like browsers. [Parsec](https://parsec.app/) looks like a good try at doing so, but I haven't tested it. I'm testing Mighty because unlike Parsec, they provide a GPU-equipped remote server a mere 16ms ping from my NYC apartment for me.

All that is to say, while I'm going to talk about issues with Mighty and how it could be improved, I expect many of these issues apply to other desktop app streaming systems as well. Mighty invited me into their beta knowing that I was going to latency test them and write about it publicly, without adding any conditions, and I really respect them for that.

## Old and new style remote display systems

A new breed of display streaming systems has been cropping up in the past few years, based on using GPU-accelerated encoding/decoding for common video compression formats to stream the entire screen as a video. Examples include all the major game streaming services like [GeForce Now](https://www.nvidia.com/en-us/geforce-now/) and [Google's Stadia](https://stadia.google.com/). [Parsec](https://parsec.app/) seems to be doing a good job applying this to normal desktop apps, although I haven't tested it.

Older remote desktop systems like VNC, Citrix and Microsoft's RDP work differently. They tend to use custom encoders specialized to desktop content which run on the CPU. However these CPU-based encoders tend to struggle with modern high resolution displays, and certain types of content like games, videos and CAD apps. Some, like [Citrix](https://docs.citrix.com/en-us/tech-zone/design/design-decisions/hdx-graphics.html) and [RDP](https://techcommunity.microsoft.com/t5/security-compliance-and-identity/remotei-desktop-protocol-rdp-10-avc-h-264-improvements-in-windows/ba-p/249588) have added hardware video encoding support, although in my experience they haven't done a good job and the experience is better with it disabled on normal desktop apps.

## Typing latency

Let's start by testing the latency between pressing a key and it appearing on screen in a text field, since that's one of the simplest types of latency. I went to `about:blank` in Mighty and Chrome and added a `<textarea>` tag using the web inspector.

My latency tester sends USB events to repeatedly type `a` and backspace it, then types out summary lines. Here's some simplified summary lines annotated with what I was measuring:
```
140ms +/-  14.9 (n=44) |           238912_        | Mighty 4k window
 42ms +/-   8.6 (n=77) |   791_                   | Chrome 4k window
 37ms +/-   3.9 (n=33) |   94                     | Chrome small window
 91ms +/-  13.1 (n=73) |      3498422             | Mighty small window
212ms +/-  24.0 (n=53) |                  _79652_ | Mighty 3780x6676 window
```

Despite the fact that my network round-trip to my Mighty server is only 16ms, Mighty adds around 100ms of latency with a maximized 4k window. The results for a local Chrome of close to 40ms for varying window sizes are about as good as I've seen for any app when measured at the top of on my Dell S2721Q monitor like this was, which means they're close to the minimum latency a macOS desktop app can have.

This isn't as bad as it may sound though. I can notice the difference, but mainly that it's just less pleasant. An extra 100ms typing latency is at the level where if you added it to most people's computers between sessions, if it was consistent many wouldn't notice anything was wrong, it just feels a bit worse. This is a problem Mighty pays attention to, they actually have a keyboard latency graph window accessible in their Debug menu, which shows latencies about 20ms lower than my end-to-end measurements, presumably because they don't include the compositor/screen/USB stack.

### Encoding the whole window means latency scales with window size

The interesting thing about these tests is how they show that Mighty's latency scales significantly with window size, even when only a small region changes. Most legacy remote desktop systems will use something called "damage regions" that apps provide to the OS compositor, in order to only process the pixels that change during small updates like typing. Even without such a system, it's possible to diff tiles of a 4k screen image in under 10ms on a single CPU core to detect the changed region. This approach gets noticeably bad with higher resolutions, like monitors of the future may have, and like macOS uses internally if you set non-integer scaling on a high-DPI monitor, like I did in the last test.

One disadvantage of the hardware accelerated video encode approach is that doing this is tricky, because all you have is a vendor-provided API to encode new full frames into a video stream, and you can't count on the vendor to optimize their encoder for large pixel-equal screen regions getting encoded very quickly. You could split the screen into many separate tile video streams, but that may or may not lead to encode/decode latency problems if the API/hardware isn't optimized for many small streams, and artifacts may be hard to avoid. Another approach might be to have a separate side channel stream where you quickly send the small changed image patch to paste over the video, then update the video stream in the background the usual way.

### h264 is better but not the default

### Tail latency issues with high resolutions

Another issue that wasn't present in the tests above, but showed up in other test runs and in Mighty's own keyboard latency graph, is bad tail latency. Often my first key press after not typing for a while would have a latency of 1-5s, especially on the textarea on <base64decode.org>, which also has higher base latency of around 200ms for some reason. Mighty is in beta, and this is probably debuggable, but tail latency issues like this are one of the hardest parts of desktop streaming:

![Latency Spike]({{PAGE_ASSETS}}/mightystats2.png)

Typing is just where they have a latency graph to show the spikes though. When using a maximized 4k window I often notice large latencies, for example switching tabs typically takes 1s and occasionally more like 7s. These issues only show up on large window resolutions though, when I make my window small things are snappy.

## Scrolling
## macOS gotchas
## General experience

## Page loading

9s vs 3s Mighty homepage
