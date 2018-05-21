---
layout: post
title: "Eye Tracker Reviews: Pupil Labs, Tobii, Eye Tribe, XLabs"
description: ""
category:
tags: ["review", "eye tracking"]
---
{% include JB/setup %}

During my time at the [UWaterloo HCI Lab](http://hci.cs.uwaterloo.ca/) I've had the opportunity to try out 5 different eye trackers and compare them.
These eye trackers span the price range from free to $10,000+ and use a variety of different tracking methods. These trackers are also not always direct
alternatives, they are often meant for very different scenarios.

Disclaimer: These are the results that I got for myself using these eye trackers. Eye tracking performance varies wildly between people so it is likely that
for some of these trackers I got atypically bad or good performance. When my results don't square with claimed performance or performance I've seen in videos
I'll try and note that.

Also, I have not done exact degrees accuracy tests on any of these trackers. I may however give figures in degrees, here's what I mean when I mean by these:
Whenever I test these out, the tracked point or the filtered point (if there is jitter) is with high probability within a given distance of my real gaze point.
I then use trigenometry to work out the degree angle corresponding to that distance, a handy rule of thumb is that each degree corresponds to about a centimeter of
distance at a typical screen-head distance ( `tan(1.0*(pi/180))*60 = 1.04` ).

With that out of the way lets move on to the trackers:

# Pupil Labs Headset: My favourite research eye tracker

My lab has a [Pupil Labs](https://pupil-labs.com/store/) eye tracking headset with a high speed world camera and 120hz binocular eye cameras.
It's well suited for a variety of research, and is the only eye tracker with amazing open source software.

#### Pros:
- Good tracking: very high precision (i.e low jitter) and fairly high accuracy immediately after calibration (~1.5 degrees)
- Allows free head motion because the eye tracker is fixed to your head.
- Robustly tracks markers in order to map gaze onto surfaces like screens.
- The open source software is amazing. Really good interface, easy to use, tons of features, and unlike *every other eye tracker* you can add any features you need yourself.
- You don't need a computer screen and you can do eye tracking experiments in other environments.
- Good price for a research eye tracker (on the order of $1000), especially with academic discount.
- Tolerates other IR devices. Since the tracking doesn't use glints you can use other IR lights like an IR head tracker at the same time. It is the only eye tracker like this.
- Fully cross platform: Windows, OSX and Linux.

#### Cons:
- The headset can easily be jostled if you move your head too much or crinkle your face, and when that happens accuracy drops proportional to the change in position.
  The technique I'm researching requires head motion and I typically see accuracy of ~3 degrees after some head movements slightly move the headset.
- Doesn't fit with other glasses very well, and if it does fit the reflections make it worthless.
- You have to wear something on your head. It is fine at first but after an hour or two can start to feel quite uncomfortable.
- You have to recalibrate every single time you put it on, unlike some remote eye trackers.

#### Watch out for:
- Eye cameras can't adjust to get a good view of eyes very near the center of the face, I had a participant like this and it still worked but lost tracking at larger gaze angles.
- If your ears move when your face moves, it will move the eye tracker out of calibration almost immediately. I had a participant like this.

# Tobii EyeX / Steelseries Sentry: Best consumer eye tracker

The [Tobii EyeX](http://www.tobii.com/xperience/) (or the identical Steelseries Sentry) is an incredible consumer eye tracker. One downside is it only works on Windows, but I've gotten around this by running
the EyeX software in a VMWare Fusion VM and [piping the data to my mac over UDP](https://gist.github.com/trishume/b25492f25fc8ebe01dd9). Two caveats are that in order to switch to the mac and have tracking continue you have to [lock the
VM's screen resolution](http://dannyman.toldme.com/2014/05/15/vmware-retina-thunderbolt-constant-resolution/). Also if the load gets too high on the VM sometimes the tracker will stop
and take a couple seconds before it automatically restarts, this is only an issue in VMs and can be mostly avoided by running no other programs on the Windows VM.

#### Pros:
- Extremely robust to head motion: your calibration will last practically forever. You can move your head around as much as you want and still maintain decent (2-3 degrees accuracy) tracking.
  This means you don't have to calibrate every time you sit down, just keep your one calibration for an arbitrarily long time. The magnetic mount is extremely repeatable so it doesn't need to be recalibrated.
- Good accuracy even on large screens: Although the accuracy degrades near corners, in general the tracker gives me ~2-3 degrees of accuracy, which is quite decent.
- Comes with very nice software. The SDK is nice and the software gives you a nice calibration test screen, a very pretty gaze trace, and some handy eye tracking desktop enhancements like warping your mouse cursor.

#### Cons:
- Low precision. There is quite a bit of jitter, but it is bounded (it is almost never more than 2cm from the center of the jitter), so can be mostly eliminated by filtering.
- Windows only.
- You may not record gaze data. This is a developer SDK term meant to make you buy Tobii's more expensive trackers, it is not an issue if you're developing interaction techniques or just using the tracker.
- Your head needs to be relatively low with respect to the monitor. I prefer my head to be near the top of my monitor but this is outside the non-adjustable view of the tracker from the monitor's bottom edge.
  You can fix this by tilting your monitor upwards, I was lucky that my monitor had an adjustable stand.

# [Edit] Tobii 4C: New best consumer eye tracker

I've now had a chance to use the [Tobii 4C](https://tobiigaming.com/eye-tracker-4c/) for a while and it's fantastic. Everything I said about the EyeX above applies, with the following new notes:

- All the processing is now done on the device, this means very low CPU and USB loads. It now works flawlessly in VMWare Fusion.
- Accuracy is similar or maybe somewhat better. It's the most accurate eye tracker I've used personally.
- Tobii is now working on a macOS implementation of the Stream Engine SDK (the low level C API). I've tried out an alpha and it works quite well. I used it to implement [FusionMouse](https://github.com/trishume/FusionMouse).
- I tried it out in combination with a TrackIR 5 and it didn't interfere with the tracking much, which let me combine eye tracking and head tracking that is higher accuracy than the tracking Tobii provides on Windows. I remember having problems when I tried the TrackIR with the EyeX, so either they fixed something or my setup changed enough that it works now.

The restrictions on recording data still apply though, so it's still difficult to legally use for research, other than research on interactive eye tracking systems.

Another tip I picked up: The adhesive on the magnetic strips for attaching the 4C/EyeX to a monitor have very strong permanent adhesive that's difficult to remove without breaking or bending anything. If you use double-sided foam tape you can attach the strip to a monitor in a way that's much easier to remove. The extra distance also enables it to be mounted on some laptops.

# The Eye Tribe Tracker: Good but doesn't work well for me

The [Eye Tribe tracker](http://theeyetribe.com/) (I have the older $100 model) is a great piece of hardware at a great price, unfortunately it barely works for me.
I've seen it work well for other people in videos so I'm not claiming this is a common problem, just one that I invariably experience. I've tried it in tons of environments
with different computers, positions and eyewear. After [reverse engineering](http://thume.ca/2016/02/02/a-reverse-engineering-adventure-eye-tribes-usb-protocol/) it I think I have identified
the problem as due to extra glints on the side of my eyes when looking away from the center of my screen. I can calibrate in the center and get ~4 degrees of accuracy within a 1000 x 1000px area, but that isn't great.

As such, I've restricted my Pros and cons to discussing other issues than accuracy:

#### Pros:
- Great price, only $100.
- Works on OSX. This is better than the Tobii EyeX so if you're looking for a consumer tracker on OSX try the Eye Tribe.
- A great high speed high resolution infrared camera: I [reverse engineered](http://thume.ca/2016/02/02/a-reverse-engineering-adventure-eye-tribes-usb-protocol/) the control codes so you can use it for other purposes like motion tracking or writing your own eye tracking algorithms. This can't be done easily with the EyeX since it uses a much more locked down custom USB protocol.

#### Cons:
- Tripod mount means that if you bump it, pull the cable, or bump your monitor, you'll have to recalibrate. This is in contrast to the sentry, which mounts directly to your monitor.
  If you're ambitious you could improve your own clamping mount for the eye tribe tracker or fix the tripod and monitor in place.
- Limited software: The software does very little compared to Tobii's and Pupil's software. It is basically just a calibration and API server.

# Tobii X2-30: Great but overpriced

My lab has a [Tobii Pro X2-30](http://www.tobiipro.com/product-listing/tobii-pro-x2-30/) which in many ways is similar to the Tobii EyeX. The main hardware difference is that it uses two cameras instead of one, but I assume they are
lower resolution since it only needs USB 2.0 bandwidths instead of USB 3.0. The main legal difference is that you are allowed to record the gaze data with the pro models. The main practical difference is that the X2-30 costs over **50 TIMES** as much. The price is not public and I imagine they quote different prices to different people. I'm not sure if my lab signed any agreements with regards to giving away the price so I'll just say we paid somewhere over 50x the price of an EyeX.

The pros/cons and tracking performance are very similar to the Tobii EyeX. Unless you are doing a study where you need to record gaze data, the 50x increase in price is not worth it in my opinion.

#### Pros:
- Extremely robust to head motion: your calibration will last practically forever. You can move your head around as much as you want and still maintain decent (2-3 degrees accuracy) tracking.
  This means you don't have to calibrate every time you sit down, just keep your one calibration for an arbitrarily long time. The magnetic mount is extremely repeatable so it doesn't need to be recalibrated.
- Good accuracy: Although the accuracy degrades near corners, in general the tracker gives ~2.0 degrees of accuracy when not using a chin rest, which is quite good and slightly better than the EyeX.
- Comes with very nice software. The SDK is nice and the software gives you a nice calibration test screen, a very pretty gaze trace, and some handy eye tracking desktop enhancements like warping your mouse cursor.
- The new Analytics SDK 3.0 allows use with OSX and Linux.

#### Cons:
- The nice EyeX software it works with is Windows-only.
- Only specified to work on relatively small monitors by modern standards (22" diagonal).
- I found that sometimes the tracked gaze would jump for half a second or so to a wildly inaccurate position ~15cm away from where I was looking. This is bad because it is harder to filter out and distinguish from a saccade.
- Crazy expensive. This is not unique to Tobii. Basically every eye tracker intended for research (except the Pupil) is absurdly overpriced. Many research eye trackers cost in the range of $50,000.
- Your head needs to be relatively low with respect to the monitor. I prefer my head to be near the top of my monitor but this is outside the non-adjustable view of the tracker from the monitor's bottom edge.
  You can fix this by tilting your monitor upwards, I was lucky that my monitor had an adjustable stand.

# XLabs Gaze Chrome Plugin: Best webcam only eye tracker

The [XLabs](https://xlabsgaze.com/) chrome plugin allows you to do eye tracking on a web page using only a webcam and no special hardware.
I've only ever had good results when trying out their [EyesDecide](https://eyesdecide.com/) software, although I was also in a different environment when I tried it that way.

#### Pros:
- Basically your only option for eye tracking without special hardware. Allows you to do things like web usability eye tracking studies with only a laptop.
- Free! The SDK is currently free to use, although that may change, and you don't have to buy hardware.
- Rather decent tracking. Quite impressive for a webcam tracker, can achive 2-4 degree accuracies varying extensively by person, environment and calibration.
- Fully cross platform, because it is just a Chrome plugin.

#### Cons:
- Very long calibration process: If you want good results you need to go through a very long sequence of calibration dots, on the order of 30.
- Very short lived calibration. It is not as robust to head motion as other trackers and becomes miscalibrated within a few minutes unless you are constantly calibrating with their dynamic calibration.
- Very sensitive to lighting. You need bright light on your face, sitting near a window is best. If the lighting isn't right it can sometimes barely work at all.
- You can only use it within Chrome. No desktop apps.

# Others

There are tons of crazy expensive research eye tracking systems that I haven't tried for exactly that reason: they cost way too much. I'm sure some of them are quite excellent, but they cost as much of a car for hardware that certainly
isn't 1/10th that expensive to manufacture.

There's two other sub-$1000 eye trackers I have not tried but I have read a bit about:

#### Gazepoint GP3

The [Gazepoint GP3](http://www.gazept.com/product/gazepoint-gp3-eye-tracker/) is $500 and internally uses a [Point Grey camera](https://www.ptgrey.com/case-study/id/10423) which probably has a 752x480 resolution, which is much lower than the Eye Tribe tracker.
The only advantage it might have over the Eye Tribe is that it uses bright pupil tracking (so perhaps more robust) and their software might be better, but likely is not. Gazepoint's software is also Windows only.
I see no reason to consider this tracker over the cheaper and seemingly much better Tobii EyeX.

#### MyGaze

The [MyGaze](http://www.mygaze.com/) seems to be the deluxe consumer eye tracker. I haven't bought it since it is outside my "just trying it out" budget when I already personally own 2 consumer eye trackers.
However, there seems to be some glowing recommendations online from people who have tried other consumer eye trakers calling it the best of everything low cost. It is also made by engineers from SMI which is a
super fancy expensive high quality research eye tracker company. There's some recommendations and a video (that shows incredible <1 degree accuracy) [on this forum thread](http://www.apparelyzed.com/forums/topic/37302-questions-about-smis-500-mygaze-vs-200-eye-tribe-tracker-pro/). If you have the budget for it I recommend you try this tracker out (and then let me know how you like it).

One downside is that although the hardware only costs $500, you have to pay $900 to also get the developer SDK, unlike every other consumer eye tracker which gives away the SDK for free with the tracker.

#### The Eye Tribe Pro

The Eye Tribe is soon going to release a new tracker with new algorithms and supposedly better tracking on many dimensions for $200. I have no idea how good it will be or how it will compare to other low cost eye trackers.
