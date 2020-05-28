---
layout: post
title: "Measuring keyboard-to-photon latency with a light sensor"
description: ""
category: 
tags: [hardware]
assetid: latencytester
---
{% include JB/setup %}

For a long time when I've wanted to test the latency of computers and UIs I've used the [Is It Snappy](https://isitsnappy.com/) app with my iPhone's high speed camera to count frames between when I press a key and the screen changes. However the problem with that is it takes a while to find the exact frames you want, which is annoying when doing a bunch of testing as well as makes it difficult to find out what the variability of latency is like. I made this kind of testing easier [by adding a mode to my keyboard firmware which changes the LED color after it sends a USB event](/2017/12/29/fixing-my-keyboards-latency/), but that only made it a bit faster and more precise.

So I followed in the footsteps of my friend [Raph](https://raphlinus.github.io/) and made a hardware latency tester which sends keyboard events and then uses a light sensor to measure the time it takes for the screen to change! It was quite easy and in this post I'll go over some of the latency results I've found, talk about why good latency testing is tricky, and explain how to build your own latency tester.

Basically my latency tester is a light sensor module from Amazon held by an adjustable holder arm wired to a [Teensy LC](https://www.pjrc.com/teensy/teensyLC.html) microcontroller which presses "a" and waits until the light level changes, then deletes it and keeps collecting samples as long as a button is held. Then with a short press of that one button it will type out a nice latency histogram that looks like this:

```
lat i= 60.3 +/-   9.3, a= 60, d= 59 (n= 65,q= 41) |    239_                      |
```

This line tells me the average latency of insertions, deletions and both put together, the standard deviation of insertion times, measurement count and quality, and a little ascii histogram where each character is a 10ms bucket and the digits proportionally represent how full the bucket is. The `_` represents a bucket with at least one sample but not enough to be at least one ninth of the top bucket so I can see tail latencies. Here's what it looks like:

![The final product]({{PAGE_ASSETS}}/final_product.jpeg)

I also made it so if you press the button again, it will type out all the raw measurements like `[35, 35, 33, 44]` so you can do custom plotting:

![Plotly chart]({{PAGE_ASSETS}}/plot.png)

## Monitor latency

I'll start out with my favourite set of results:

```
Sublime Text, macOS, distraction-free full-screen mode on two 4k monitors:
lat i= 35.3 +/-   4.7, a= 36, d= 36 (n= 67,q= 99) |  193       | Dell P2415Q top
lat i= 52.9 +/-   5.0, a= 53, d= 54 (n= 66,q= 45) |   _391     | Dell P2415Q bottom
lat i= 65.1 +/-   5.0, a= 64, d= 63 (n=109,q=111) |    _292    | HP Z27 top
lat i= 79.7 +/-   5.0, a= 80, d= 80 (n= 98,q=114) |       89_  | HP Z27 bottom
```

There's a lot to observe here:

- First of all I like how the single-line fixed-width histogram format lets me put results next to each other in a text file and label them to the right for comparison.
- We can see the expected difference of 16ms between the latency at the top and bottom of each monitor from the time it takes to scan out the rows during a frame at 60hz.
- The standard deviation is just a touch over the [4.6ms](https://www.quora.com/What-is-the-standard-deviation-of-a-uniform-distribution-How-is-this-formula-determined) that's inherent to the uniformly-distributed variance that comes from being misaligned with a 16ms display refresh period.
- **The HP Z27 is around 30ms slower than the Dell P2415Q!** And that's measuring from the start of when the change is detectable, I'm pretty sure the Z27 also takes longer to transition fully. With the Z27 and Sublime almost half my end-to-end latency is unnecessary delay from the monitor!

## The perils of measurement

Taking good latency measurements is actually quite difficult in more ways than you might think. I tried harder than most people to get realistic measurements and still failed the first few times in ways that I had to fix.

### Actually measuring end to end latency

First of all, the reason to use a hardware latency tester is that there are many deceptive ways to measure end-to-end latency. There's a really excellent famous blog post called [Typing With Pleasure](https://pavelfatin.com/typing-with-pleasure/) that compares latency of different text editors on different operating systems with good analysis and pretty graphs.

However it does this by simulating input events and screen scraping using OS APIs. I haven't done any overlapping measurements with his so can't point to anything specifically wrong, but there's lots of potential issues with this. For example inspecting the screen buffer on the CPU might unduly penalize GPU-rendered apps due to window buffer copies under some ways that capture might work. Simulated input may hit different paths than real input. Regardless, even if it does give decent relative measurements (and you can't truly know without validating it against a hardware test), it doesn't tell you the full latency users experience.

### Using 1000hz USB polling

One source of latency users experience that my tester doesn't measure is [keyboard latency](https://danluu.com/keyboard-latency/). Many keyboards can introduce more latency than my entire keyboard-to-photon latency ([including mine in the past](/2017/12/29/fixing-my-keyboards-latency/)) due to 8ms USB polling intervals, low keyboard grid scan rates, slow firmware, and more debatably different mechanical design.

You can't just use any microcontroller that can emulate a keyboard to build a low-variance latency tester because they probably use default 125Hz polling.

### Making sure you have good signal strength

For the first while after I built my latency tester I didn't have any measurement of signal strength. Eventually I got confused by some measurements in slightly different scenarios with the same app and screen having wildly different results. I did some testing and figured out that sometimes with small fonts or poor sensor placement the change in screen contents would only barely be detectable so I'd measure until the monitor finished transitioning when usually I measure until when the monitor starts transitioning (its own tricky subjective measurement choice).

To avoid this I added a peak to peak signal strength measurement after the full transition to my output so I could ensure I was getting adequate resolution for my threshold of 5 steps to be near the beginning of the transition. These are the numbers you see after `q=`.

### Large variation from small differences

### Jittering so as not to sync up

The next fishy thing I noticed is that my variances seemed too low. I was sometimes getting standard deviations of 1ms when my understanding of how the system worked said I should be getting a standard deviation over 4.6ms due to screen refresh intervals.

I looked at my code and figured out that I was inadvertently synchronizing my measurement with screen refreshes. Whenever I measured a change, my firmware would wait exactly 300ms before typing 'a' or backspace again and taking another measurement. This meant the input was always sent about 300ms after a screen refresh and thus would land at a fairly constant spot in the screen refresh interval. I patched this issue by adding a 50ms random delay between measurements.

This mainly leads to incorrectly low variances but might lead to incorrect averages as well if the app will miss a paint deadline if the input event comes late in a frame but it never does during the test. I found this during testing for this post and couldn't be bothered to redo all the tests below, so you may notice some low variances, but I did recheck the means on important results like Sublime and VSCode.

## Text editors

## Terminals

## How to make one

Here's the parts list I used:

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

Before I wrote the firmware I played around with just sampling the light sensor every millisecond and using the Arduino serial plotter to plot them as I typed and backspaced a letter just to see what the signal looked like. You can see that some combination of the light sensor and the monitor take a while to fully transition:

![Trace]({{PAGE_ASSETS}}/wave.png)

I didn't write the fanciest possible firmware to find the beginning and ending of the transition, but I put a bit of effort into tweaking it to work well and adding various features so I recommend starting with my firmware. Install the [Teensyduino](https://www.pjrc.com/teensy/teensyduino.html) software and then you can use [my latency tester Arduino sketch](https://gist.github.com/trishume/bbdae75792d2888708a01d5625fa9229) which also doubles as foot pedal box code but you can comment that stuff out and configure it to use the right pins. Then just long press your switch to take samples and short press to type out the results!


