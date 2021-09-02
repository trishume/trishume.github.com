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

![Mighty homepage]({{PAGE_ASSETS}}/mightypage.png)

All that is to say, while I'm going to talk about issues with Mighty and how it could be improved, I expect many of these issues apply to other desktop app streaming systems as well. Mighty invited me into their beta knowing that I was going to latency test them and write about it publicly, without adding any conditions, and I really respect them for that.

## Typing latency

Let's start by testing the latency between pressing a key and it appearing on screen in a text field, since that's one of the simplest types of latency. I went to `about:blank` in Mighty and Chrome and added a `<textarea>` tag using the web inspector.

My latency tester sends USB events to repeatedly type `a` and backspace it, then types out summary lines. Here's some simplified summary lines annotated with what I was measuring:
```
109ms +/-  15.2 (n=75) |        _5933_ __         | Mighty 4k window
 42ms +/-   8.6 (n=77) |   791_                   | Chrome 4k window
 37ms +/-   3.9 (n=33) |   94                     | Chrome small window
 95ms +/-  18.5 (n=65) |     11359741_            | Mighty small window
212ms +/-  24.0 (n=53) |                  _79652_ | Mighty 3780x6676 window
```

Despite the fact that my network round-trip to my Mighty server is only 16ms, Mighty adds around 67ms of latency with a maximized 4k window. The results for a local Chrome of close to 40ms for varying window sizes are about as good as I've seen for any app when measured at the top of on my Dell S2721Q monitor like this was, which means they're close to the minimum latency a macOS desktop app can have.

This isn't as bad as it may sound though. I can notice the difference, but mainly that it's just a bit less pleasant. An extra 70ms typing latency is at the level where if you added it to most people's computers between sessions, if it was consistent many wouldn't notice anything was wrong, it just feels a tiny bit worse. Many people use [keyboards that add 40ms of latency](https://danluu.com/keyboard-latency/) or [screens that add 30ms](https://thume.ca/2020/05/20/making-a-latency-tester/). This is a problem Mighty pays attention to, they actually have a keyboard latency graph window accessible in their Debug menu, which shows latencies about 20ms lower than my end-to-end measurements, presumably because they don't include the compositor/screen/USB stack.

### Encoding the whole window means latency scales with window size

The interesting thing about these tests is how they show that Mighty's latency scales with window size, even when only a small region changes. Most legacy remote desktop systems will use something called "damage regions" that apps provide to the OS compositor, in order to only process the pixels that change during small updates like typing. Even without such a system, it's possible to diff tiles of a 4k screen image in under 2ms on a single CPU core to detect the changed region.

One disadvantage of the hardware accelerated video encode approach is that using minimal damage regions is tricky, because all you have is a vendor-provided API to encode new full frames into a video stream, and you can't count on the vendor to optimize their encoder for large pixel-equal screen regions getting encoded very quickly. You could split the screen into many separate tile video streams, but that may or may not lead to encode/decode latency problems if the API/hardware isn't optimized for many small streams, and artifacts may be hard to avoid. Another approach might be to have a separate side channel stream where you quickly send the small changed image patch to paste over the video, then update the video stream in the background the usual way.

In the last test above I set the 4k monitor to one of macOSs non-integer scaled presets, when you do this macOS will internally render a larger resolution at 2x scaling and then downscale the image. This causes huge internal resolutions that can cause performance issues even on native apps, the Preferences screen warns "Using a scaled resolution may affect performance", and while some apps may seem fine, others like Mighty suffer. The full screen encoding approach relies on GPU encoding/decoding hardware keeping pace with growing screen resolutions, and can suffer when you try to jump to larger sizes.

### H264 is lower latency but not the default

The numbers above get better when you use Mighty's Debug menu to "Enable H264 encoding", where the default is H265:

```
109ms +/-  15.2 (n=75) |        _5933_ __         | Mighty 4k window H265
 99ms +/-   8.7 (n=37) |        2691_             | ^ same but H264
 95ms +/-  18.5 (n=65) |     11359741_            | Mighty small window H265
 83ms +/-   9.1 (n=57) |      _9842               | ^ same but H264
```

The modern H265 encoding standard is better at compression, allowing more changing pixels to be streamed over a lower bandwidth connection, but it comes at the cost of more time spent encoding and decoding, which is where most of the lag comes from on highly compressible changes like this typing latency test.

## Scrolling

Probably the most common operation while browsing the web is scrolling. I reconfigured my latency tester to scroll up and down small amounts, and then went to [figma.com](https://www.figma.com/) and had it scroll with the light sensor across a colored section transition:

```
119ms +/-  29.1 (n=94) |       _ 279921_      _   | Mighty 4k scroll H265
138ms +/-  12.9 (n=21) |           55997 1        | Mighty 4k scroll H265 50%
113ms +/-  11.5 (n=63) |         19551            | Mighty 4k scroll H264
146ms +/-  18.2 (n=60) |           234965 1       | Mighty 4k scroll H264 50%
 89ms +/-   6.5 (n=36) |      _9588_              | Chrome 4k smooth scroll
 49ms +/-   6.1 (n=52) |   _96                    | Chrome 4k non-smooth scroll
```

There's some interesting things to see here:

- Scrolling is a bit higher latency than typing. This is unsurprising given the approach, since even though motion vector encoding lets it not re-encode the whole image, it doesn't succeed at compressing the frames quite as much as with typing, and encoding/decoding may be more expensive.
- If we zoom the page out to 50% page zoom, scrolling gets slower despite the equivalent pixel count, presumably because there's more visual entropy on screen and so encoding/decoding gets more expensive and frames get larger. Here H256 encoding starts to win out presumably due to better compression.
- With the default macOS settings Chrome smooths USB mouse wheel scrolling to accelerate gradually, so it takes longer for the light sensor to cross the color transition, whereas Mighty scrolls instantly. If I disable macOS smooth scrolling for Chrome, it becomes nearly as fast as typing.

Scrolling is an interesting case for the video compression approach to display streaming. A compression approach specialized to scrolling could look for tiles of pixels at exact vertical offsets and then only send the tiles which aren't translated copies. I haven't found a major remote desktop system that does this, despite the importance of scrolling, but I implemented a version using an efficient tile row hashing technique which can process a 4k screen in 2ms on one core in [an unmerged xrdp branch](https://github.com/neutrinolabs/xorgxrdp/pull/167). This would dramatically cut encode/decode time and bandwidth for scrolling, and thus latency.

However, video compression systems use a much more general compression approach using motion vectors that gets at least some of the same bandwidth benefits, while being more robust. While my algorithm is great on normal scrolling, a fancy Apple product or startup website scrolljacking animation would cause lots of tiles not to be covered by the scrolling optimization and reduce it's effectiveness. Video compression would keep working great as long as the motion was smooth. Like damage regions, it's unfortunately tricky to integrate scrolling optimization with video compression, although again the approach of a separate lower latency side channel stream to preempt the video may work.

### Mighty's potential advantage, which they don't use

Above I talked about how to optimize scrolling from the perspective of general display streaming, but Mighty's specialization for Chrome gives them a potential huge advantage that they don't currently use. Mighty could in theory integrate with the Chrome renderer to render contents outside the current browser viewport and preemptively send it to the client. This would allow small scrolls to be resolved instantly on the client without any networking or decoding, and the networking could catch up behind.

There's a number of difficulties in this related to things like fixed position page elements, but interestingly solutions to all these problems are already implemented inside Chrome ([and other browsers](https://firefox-source-docs.mozilla.org/gfx/AsyncPanZoom.html)). Browsers already use a variation of this technique to avoid rendering latency on scrolling by rasterizing tiles of the page as layers, which the browser's compositor then re-composites as you scroll without having to hit the renderer. In fact these are sometimes implemented as separate processes in the browser communicating over an IPC channel, basically like a higher-bandwidth lower latency network!

In principle Mighty could work by forwarding the browser at the layer level as opposed to the composited pixel level, and get minimal damage regions and scrolling optimization for free. The catch is that there's some cases like YouTube videos and fancy animations that video compression would handle much better than remoting layers with static image compression would. This means if you don't want to have unintuitive performance cliffs you need to combine some kind of difference-based video compression with the layer remoting, and that could get super complex, especially if you try to use video compression hardware. I see why they chose the approach they did, at least for now.

## Gotchas on macOS

When undertaking any kind of unusual native app project, there's a bunch of tiny gotchas you need to know about to avoid your app being slower or more power-hungry than it needs to be. Approximately nowhere tells you about avoiding these things, hence why I'm writing about them! Let's look at some of the common macOS gotchas and whether Mighty gets them right:

- *Does it force use of the discrete GPU?* **Yes.** This is the most common mistake for GPU rendered apps to make, and it causes dual-GPU systems like my 16" Macbook Pro to go from around 10W idle to 15W. Avoiding this requires [some extra Metal API calls](https://developer.apple.com/documentation/metal/gpu_selection_in_macos/selecting_device_objects_for_graphics_rendering).
- *Does it constantly send 60fps compositor updates?* **No.** A lot of apps make this mistake but Mighty doesn't. If you mess it up it causes `WindowServer` to take an extra 10-20% CPU and extra power, not even attributable to the app without using [Quartz Debug](https://www.idownloadblog.com/2016/02/03/quartz-debug-framemeter/). The harder one to avoid is not having any animations that can get stuck going even with the window in the background, I've at least once had a Mighty tab stuck loading in the background, which caused updates to fire constantly.
- *Does it re-composite the entire window even for small changes?* **Yes.** This is purely a power optimization, but it's possible to tell the compositor when only a small part of your window changed, so it needs to do less work. A tiny loading spinner animation causes `WindowServer` to use an extra 10% of a core. The Core Animation APIs make it harder to avoid this on macOS than other platforms when using a custom renderer like Mighty, but Chrome uses a hack to manage it.
- *Does it use a transparent window for opaque content?* **No.** Most macOS windows use a large opaque compositor layer with tiny transparent corners, but if you use the wrong API you can get one giant transparent layer, causing extra compositing work. Firefox had this problem for a long time, Mighty does not.
- *Does live resize go blank?* **Yes.** Supporting smooth resizing can be tricky even for local GPU-rendered apps, Mighty has a much trickier distributed systems problem to solve, and it understandably goes blank when resizing.
- *Does it break when moving the window to a display with a different scale factor?* **Kinda yes.** Mighty initially appears to handle this case smoothly, but when I did testing on my 4k display at 1x scaling I experienced huge 1-10s latency spikes when doing things like switching tabs and latency is generally higher. My guess is the remote Linux is still rendering at 2x scaling so has to deal with an enormous 8k resolution and has trouble or something.

## Page loading

In my testing Mighty is only slightly faster at loading pages than my home 500Mbps connection:

- https://www.apple.com/iphone-12/: \~3.4s Mighty vs \~ 3.8s Chrome
- https://figma.com/: \~3.8s Mighty vs \~3.9s Chrome
- https://thume.ca/2017/06/17/tree-diffing/: \~240ms Mighty vs \~240ms Chrome

These were just done casually averaging a few tries using the Chrome network inspector with caching disabled, I don't claim they're super scientific. Just that I didn't notice a significant difference between my good home internet and their datacenter connection for page loading.

## General experience

All of the above is interesting from a technical discussion standpoint, but in terms of Mighty as a product it focuses on measurable and interesting things rather than what's important.

In general I'd say the overall smoothness of Mighty and its display streaming is quite good compared to other remote display technologies I've used. Although I haven't used Parsec or Teradici, which would be the two I would guess based on technology might be comparable or better. The scrolling at high resolutions especially is quite smooth. There's also no noticeable video compression artifacts, even on scrolling text, which is an issue I've noticed sometimes when video compression is added on to a legacy remote desktop system. Even watching YouTube videos works great.

Compared to my local Chrome though, Mighty isn't for me. I have a fairly powerful laptop with 32GB of RAM, and don't use any super heavy browser apps like [Onshape](https://www.onshape.com/en/), so Mighty is basically a straight downgrade. It drops frames when scrolling noticeably more often, interactions are noticeably just a bit laggier, it uses a bit more battery and integrates a little less smoothly (e.g no live resize). Those aren't huge downsides though, it's just that I don't experience any compensating upsides. If I was someone who regularly found my browser very laggy, due to having a much weaker computer or heavier browser apps, I could imagine using Mighty.

## Conclusion

Mighty is an interesting case study of how the new style of display streaming using hardware video compression can provide nicer experiences than older technologies while making it hard to implement further optimizations. Other systems like VNC, Citrix and Microsoft RDP which use custom CPU image patch compression make it really easy to implement all sorts of specialized tricks, but struggle on modern high resolutions, and fall off a cliff on hard cases like games and YouTube videos unless they adaptively switch to video compression.

I expect that higher bandwidth connections, new streaming technologies, and trends like increased working from home and potentially VR meeting rooms/offices, will make display streaming a field that remains interesting over the next few years. I find this area pretty interesting and hope to follow progress and maybe do some more tinkering. I would pitch myself as a consultant with this post as a work sample, but I have a full time job and my US visa status means I can't earn income any other way, so instead you can feel free to email me and maybe I'll be interested enough to chat about it.
