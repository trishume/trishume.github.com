---
layout: post
title: "Making a keyboard to display latency tester with a light sensor"
description: ""
category: 
tags: [hardware]
assetid: latencytester
---
{% include JB/setup %}

For a long time when I've wanted to test the latency of computers and UIs I've used the [Is It Snappy](https://isitsnappy.com/) app with my iPhone's high speed camera to count frames between when I press a key and the screen changes. However the problem with that is it takes a while to find the exact frames you want, which is annoying when doing a bunch of testing as well as makes it difficult to find out what the variability of latency is like. I made this kind of testing easier [by adding a mode to my keyboard firmware which changes the LED color after it sends a USB event](/2017/12/29/fixing-my-keyboards-latency/), but that only made it more precise and a bit faster.

So I followed in the footsteps of my friend [Raph](https://raphlinus.github.io/) and made a hardware latency tester that sends keyboard events and then uses a light sensor to measure the time it takes for the screen to change! It was quite easy and in this post I'll explain how you can build one yourself and some interesting things I've measured with it. Basically it's a light sensor module from Amazon held by an adjustable holder wired to a [Teensy LC](https://www.pjrc.com/teensy/teensyLC.html) microcontroller which presses "a" and waits until the light level changes, then deletes it and keeps collecting samples as long as a button is held. Then with a short press of that one button it will type out a nice latency histogram that looks like this:

```
lat ins= 59.0 +/-   8.0, all= 47, del= 36 (n= 60) | 137559 _                     |
```

This line tells me the average latency of insertions, deletions and both put together, the standard deviation of insertion times, and a little ascii histogram where each character is a 10ms bucket and the digits proportionally represent how full the bucket is. The `_` represents a bucket with at least one sample but not enough to be at least one ninth of the top bucket so I can see tail latencies. Here's what it looks like:

![The final product]({{PAGE_ASSETS}}/final_product.jpeg)

## How to make one

Here's the parts list:

- **$12**: A [Teensy LC](https://www.pjrc.com/teensy/teensyLC.html) or any other Teensy 3+. You could also use an Arduino, but the Teensy's USB library uses 1000hz polling (1ms latency) while most USB devices default to 125hz (an extra 8ms of random latency in your measurements). It's possible you may be able to get your microcontroller of choice to do 1000hz polling though. If you don't want to have to solder the pins get one with pre-soldered pins, this might require getting the more expensive Teensy 3 if you want Amazon Prime shipping.
- **$12**: A [light sensor module](https://www.amazon.com/gp/product/B01N1FKS4L/ref=ppx_yo_dt_b_asin_title_o03_s01?ie=UTF8&psc=1) (Amazon only has 10 packs, I only used 1). You could make your own circuit for this but these modules save a lot of time and are easy to integrate.
- **$13**: A [helping hand](https://www.amazon.com/gp/product/B07SBZRF6S/ref=ppx_yo_dt_b_asin_title_o02_s00?ie=UTF8&psc=1) to hold the light sensor up to your screen in a stable position.
- A button/switch of some kind to trigger testing
- Wires to connect the light sensor, Teensy and button
- Electrical tape to make a black soft shield to restrict the view of the sensor
- A USB micro-B cable to connect the Teensy to your computer

There's an awful lot of flexibility in exactly how you assemble it. You just need to somehow connect 3 wires (3V, ground, analog out) from the light sensor module to the corresponding pins on the Teensy (3V, ground and any analog-capable pin). The easiest way to do this which doesn't even require any soldering if you buy a Teensy with pre-soldered header pins is to use 3 [female to female jumper wires](https://www.amazon.com/Uxcell-a16072600ux1043-Female-Jumper-Breadboard/dp/B01M1CDI7M/ref=sr_1_8). Then you just need some kind of switch to activate the latency test where you wire one pin to ground on the Teensy and another pin to a digital IO pin. This can be as simple as two wires that you touch together if you're really lazy!

To make sure the light sensor module only sees a limited area of the screen I wrapped the sensor in a little cylinder of electrical tape and snipped off the end cleanly with scissors. This made a little round window I could press up against the screen with the helping hand to minimize outside interference and get the cleanest signal.

I had already made a [foot pedal box](https://twitter.com/trishume/status/950585012700684288) with a Teensy LC and a little breadboard inside, and it had an extra [TRRS jack](https://www.cablechick.com.au/blog/understanding-trrs-and-audio-jacks/) on the side I had put on anticipating this sort of project, so for me the project was soldering the light sensor module to a TRRS cable. Then I could just use one of my existing foot pedals to control the testing!

For the soldering I was in luck since I had conveniently bought magnetic helping hands for the project which I could use for the soldering process. Inconveniently I realized that I actually didn't own many substantial chunks of iron for them to attach to, so I ended up using a cast iron pan when soldering and [my tungsten cube](/2019/03/03/my-tungsten-cube/) when on my desk (which turns out to be slightly ferromagnetic).

![Soldering]({{PAGE_ASSETS}}/soldering.jpeg)

I encourage you to have fun and try to make something fancier than just dangling jumper wires. For my foot pedal box I bought a plastic project box from a local electronics shop, used a drill press to put some holes in the sides and installed large and small headphone jacks and a little breadboard so I could reconfigure how things connect. There's tons of foot pedals on Amazon for tattoo machines and electric pianos that use 1/4" phone plugs that you can pick and choose from. [These](https://www.amazon.com/Casio-SP3-SP-3-Sustain-Pedal/dp/B00070E8I8/ref=sr_1_3?) are my favourites for feel and silence but there are cheaper options that can be unreliable, hard to press or loud.

I wouldn't recommend following my use of a TRRS jack for the sensor module though, they're nice and small and there's lots of cables available, but I used them before I realized the problem that they cause a lot of shorting of different connections when plugging and unplugging. I tried to minimize this by putting power and ground on opposite ends, but you should consider some better cable type like maybe a [phone cable](https://en.wikipedia.org/wiki/Registered_jack).

![Pedal box insides]({{PAGE_ASSETS}}/pedal_box.jpeg)

## The firmware

Once you've assembled it you just need a program to run on it. Install the [Teensyduino](https://www.pjrc.com/teensy/teensyduino.html) software and then you can use [my latency tester Arduino sketch](https://gist.github.com/trishume/bbdae75792d2888708a01d5625fa9229) which also doubles as foot pedal box code but you can comment that stuff out and configure it to use the right pins. Then just long press your switch to take samples and short press to type out the results!
