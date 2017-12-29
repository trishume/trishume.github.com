---
layout: post
title: "Fixing My Keyboard's Latency"
description: ""
category:
tags: [hardware, latency]
assetid: keyboardlatency
---
{% include JB/setup %}

While discussing [Dan Luu's keyboard latency experiments](https://danluu.com/keyboard-latency/) I realized that I had never tested my keyboard's latency. I use [a custom keyboard I designed and built](http://thume.ca/2014/09/08/creating-a-keyboard-1-hardware/), but when I wrote the firmware I was focused on getting it working and didn't pay any attention to latency. When I took a look at the source code and immediately saw a 10ms delay that was there for no other reason than paranoia, I knew I was in for some fun.

After a bunch of measuring, finding and squashing sources of latency, I managed to improve the latency of the main loop from 30 *milliseconds* to 700 *microseconds*. I then added a feature that changed the colour of the keyboard's RGB LEDs on every key press so that I could use the [Is It Snappy](http://isitsnappy.com/) app with my iPhone's high speed camera mode to do some latency testing.

The first thing I found was that with my improved firmware the end to end latency of typing a character in Sublime Text and XCode 9 near the top of my Macbook display is around 42ms[^fps]. This is pretty good, but the astonishing thing is that it means that before I fixed the firmware **my keyboard used to account for almost _half_ of my end-to-end typing latency**. This is measuring from the LED colour change so it doesn't count the around 15ms[^fps] according to my testing from starting to press one of my keys the switch activating.

<center>
  <video width="360" height="640" muted loop autoplay>
    <source src="{{PAGE_ASSETS}}/latency.mov" type="video/mp4">
  </video>
</center>

I also tested my Macbook keyboard, as well as a few older low speed USB Apple keyboards, and found that they had around 67ms[^fps] of end-to-end latency, measuring from when the switch was fully depressed while hitting the key as fast as I could. I suspect part of the reason for this is that these keyboards only poll at 8ms and 10ms intervals according to USB Prober (an old Apple dev tool), whereas the [Teensy](https://www.pjrc.com/store/teensy32.html) in my custom keyboard polls every millisecond. According to Dan's post newer Apple external keyboards also poll at 1000hz.

Note that the 700us main loop doesn't translate into 700us switch-to-USB latency, since the USB transfer is done asynchronously via DMA by the [Teensy](https://www.pjrc.com/store/teensy32.html)'s USB controller when it is polled, which happens at 1000hz.

It's interesting that I used my keyboard for 3 years without noticing that it added 30ms of latency. I have a few guesses why:

- Although I can perceive 30ms of latency in a comparison test, I have to pay attention, my keyboard having 30ms of extra latency just made it feel different, but that's unsurprising since it was different in a bunch of ways.
- My only comparison was other high-latency keyboards, like my Macbook's. 30ms of latency difference is more perceptiple than 5-10ms.

Anyhow here's how I managed to bring the latency down from 30ms to 700us:

1. I added some measurement code that printed the time spent in the main loop to the Serial console after every key press. This gave me the 30ms figure.
1. I removed the 10ms delay in the main loop, and everything still worked.
1. I searched for other delays and found one 2ms one between enabling a row for scanning and reading it, which I removed with no apparent consequences. I added back in a 2 microsecond delay just in case.
1. I had tried to make the display on my keyboard only update when it changed, but I messed this up somewhere else and it was taking 5ms to update on every key press.
1. The right half of my keyboard is scanned using an I/O expander over i2c since I didn't have enough pins on the Teensy. This is the same way the two halves of the [Ergodox](https://www.ergodox.io/) work. Based on some Ergodox firmware I saw, I reinitialized the direction registers of the I/O expander before every scan, just in case. Unfortunately this added 2ms and wasn't really necessary since unlike the Ergodox you can't disconnect the second half of my keyboard with a cable.
1. Now my loop was taking 3.8ms which was almost entirely the i2c communication with the I/O expander. A friend recommended I check out [nox771's fast i2c library](https://github.com/nox771/i2c_t3). Unfortunately, it wouldn't compile on the super old version of the Arduino/Teensyduino software I was using. I decided to upgrade, and after several hours in C++ compilation hell and accounting for a few changes, it worked. I bumped the i2c frequency up to 1.8 megahertz and now my loops took 700us!
1. Now I started running into bouncing problems that lead to the occasionally doubled letter, so I needed to implement debouncing. Some ways of implementing debouncing add latency but that's totally unnecessary. [I implemented](https://github.com/trishume/PolyType/commit/372c2056d705211fb5554a6975eeca34b59f0bc8) a simple technique that sends transitions immediately and then doesn't update a key for 5ms after.

The specifics are only relevant to other people building keyboard firmware, especially the fast i2c one which I don't think most ErgoDox firmwares use. But I think it's interesting to see how easy it was to improve the latency of software that wasn't designed for it with only a few hours work.

[^fps]: I use an iPhone 5S, which can only record at 120fps, so while these numbers are consistent over multiple measurements, they may be off by as much as 8ms.
