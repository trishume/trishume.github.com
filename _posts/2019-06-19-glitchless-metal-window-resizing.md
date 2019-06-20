---
layout: post
title: "Glitchless Metal Window Resizing"
description: ""
category:
tags: [graphics, macos]
assetid: metalresize
---
{% include JB/setup %}

There's a problem with Apple's Metal [MTKView](https://developer.apple.com/documentation/metalkit/mtkview) on macOS which is that seemingly nobody can figure out how to get smooth window resizing to work properly. I just figured it out, more on that later. If you reposition the triangle in Apple's Hello Triangle program to the left (to make the rescaling more apparent) then you can see it judders horribly when the window is resized:

![Wobbly Hello Triangle]({{PAGE_ASSETS}}/wobbly_hello_triangle.gif)

What's happening is often the new Metal frame doesn't arrive in time and it draws a stretched version of the previous frame instead. There's a number of places on the internet dating back to 2017 with various people encountering the problem:

- [Stack Overflow: Resizing MTKView scales old content before redraw](https://stackoverflow.com/questions/45375548/resizing-mtkview-scales-old-content-before-redraw)
- [Apple Developer Forums: Redraw MTKView when its size changes](https://forums.developer.apple.com/thread/77901)
- [Apple Developer Forums: Unwanted MTKView content stretching when I resize/zoom the window](https://forums.developer.apple.com/thread/94765)
- [iTerm2 switches away from Metal to software rendering when resizing the window](https://github.com/gnachman/iTerm2/blob/ed8e2544726e686fe81d71fdec25cd8c5884be4d/sources/PTYTab.m#L5215)

Basically everyone who tries to make something with Metal that's not a game runs into this problem and it looks horrible. As far as I can tell nobody has figured out how to fix it properly before and posted about it afterwards. Note in the first dev forums thread that an Apple employee claimed they were looking into this problem almost a year ago with no resolution.

I started [a test project](https://github.com/trishume/MetalTest) to try out different ways of drawing with Metal during resize to see if I could get any of them to work properly. First I replicated the MTKView problems and tried to fix them by tweaking lots of different things, including all three modes of triggering draws listed in the docs and using `presentsWithTransaction` in the way the docs suggest but nothing helped. Then I made a version using Core Graphics and an NSView subclass and stacked it below my Metal view so that I could have a reference that worked properly.

## The Solution

Then I tried the accepted answer by Max on [the Stack Overflow post](https://stackoverflow.com/questions/45375548/resizing-mtkview-scales-old-content-before-redraw) which uses `CAMetalLayer` and some resizing-related properties. This reduced the frequency of glitches quite a bit, but didn't eliminate them. So I added in `presentsWithTransaction = true`, which wasn't enough on its own, but combining that with  `commandBuffer.waitUntilScheduled()` then presenting as suggested in the Apple `CAMetalLayer` docs fixed all the glitches! I also needed to do some size conversion to make the accepted answer's recipe draw crisply on high DPI displays.

## Working Code

I now have a Metal triangle test program that resizes smoothly and without judder.

Check out my test project: [Github repo](https://github.com/trishume/MetalTest)

And the specific code file containing the working recipe: [MetalLayerView](https://github.com/trishume/MetalTest/blob/master/MetalTest2/MetalLayerView.swift)

In the gif below the top is the broken `MTKView`, the middle `NSView`, and the bottom the working `CAMetalLayer` recipe. Contrast the shakey left edge of the top triangle with the stable bottom one:

![Metal Triangles]({{PAGE_ASSETS}}/metal_triangles.gif)




