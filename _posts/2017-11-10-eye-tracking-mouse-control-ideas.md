---
layout: post
title: "Eye Tracking Mouse Control Ideas"
description: "Ideas on how to refine eye tracking information for mouse replacement"
category:
tags: ["eye tracking", "ideas"]
---
{% include JB/setup %}

This is a list of ideas for using eye tracking as a mouse replacement, specifically solving the problem that eye tracking often isn't quite accurate enough to use raw. There's lots of targets on a normal computer that are just too small for even the best fingertip-size eyetracker accuracies, like selecting individual characters, or small buttons. For some people, like me, eye trackers tend just not to work too well and only are accurate within maybe a 4 cm diameter, much too large to specify most targets.

There's also reason to suspect that this situation won't improve. People have been working on eye tracking for years and accuracy is still bad. A few papers I've read have said that in fact the muscles that point the eyes may even not be accurate enough to point as precisely as a mouse, and even if they can that fixating gaze precisely leads to eye fatigue quite quickly.

Why would you want to replace the mouse with an eye-tracking based solution?

- Disabilities
- Repetitive Stress Injuries: There's lots of approaches to addressing RSIs, but it's also a much larger market.
- People who don't want to take their hands off the keyboard: Programmers go to crazy lengths to learn shortcuts to avoid reaching for the mouse, if there was a fast system of hands-free mousing, some may like it.


I'm writing this list for two reasons:

1. So that I can get the WaybackMachine to archive it to have evidence of prior art in case anybody tries to patent these. I try to explore as much of the space of possible ideas people could try patenting as possible. Of course, it's possible one or more of these already falls under some patent, because there's patents on a lot of obvious ideas, but I don't know of any.
1. As a survey of the possibilities, to look at what's possible and possibly inspire someone to try something out. Eye tracking has such potential, but is sadly rarely used outside of research.

Before proceeding I'd like to emphasize that **not all these ideas are good**, many wouldn't be that nice to use or would have other issues, I aimed much more for breadth in creating this list than depth.

There's three broad categories to these ideas:

## Combining with another input method

There's a lot of alternative mousing methods that work but are quite slow. But, if you use eye tracking for coarse but fast narrowing of position, and then another technique for refinement, they can be quite efficient.

[Polymouse](https://github.com/trishume/PolyMouse)
: Using head tracking for refinement and eye tracking for large movements, you can achieve speeds equal to a good trackpad and approaching a normal mouse. This is the main technique I've put effort into and was the focus of my research at the Waterloo HCI lab. I use a version of the "Animated MAGIC" technique to quickly move the mouse cursor along the path to the target based on eye tracking. I'm currently working towards making this technique available in a low-cost and convenient system for daily use.

Combining with a mouse
: This just allows you to use less mouse movement. This is built into Tobii's consumer software.

Combining with voice
: There's a lot of things on a screen to click, and it's hard to describe them, but given a small region from eye tracking, you can use OCR or accessibility APIs to find interactible things near the gaze and disambiguate what to do via voice. For example "click find" when looking near the "Find file" button on Github.

Combining with a keyboard
: Within a region around the eye, you could offer a number of options for things to interact with, presented as letters or colours overlayed on the screen, and then use different keyboard keys to select which one was the true target. The places to put the markers could be done via a pattern, machine learning, text recognition or an accessibility API. Similar to [this](https://github.com/trishume/mjolnir.th.hints).

Combining with button timing
: When the click button is pressed, instead of emitting a click event it could start move the cursor in for example a grid or spiral pattern around the gaze location, and when the user releases it clicks in that location. This could also be combined with likely target data, see the next section. This would be slow but doesn't require extra hardware, it uses timing information as the additional source.

Face Gestures
: Camera data could be fed into a face tracking algorithm and face gestures could be used to refine the cursor position. For example moving the lips around like a joystick, or twitching cheeks to nudge left and right. Most eye trackers are actually just IR cameras so this may not even require a separate camera.

## Predicting the target

When you have eye tracking data that is fairly good but not perfect, the effective accuracy can be improved by guessing good targets within the gaze region.

Good targets can be things like buttons, words to select, and other UI controls. Even when some place is interactible, it may make sense to choose a better target anyway, for example preferring selecting entire words rather than characters within a word, and the right side of a tab targetting the close button and the left side targetting clicking the tab.

Given a source of information about likely targets, there's various things you can do with the information:

Snapping
: The gaze cursor or clicks snap to the nearest likely target. Possibly with snappiness determined by a measure of likelihood of clicking the target.

Draw the cursor towards it
: This is basically a softer form of snapping. It could be like gravity, or fancier. For example modelling the gaze data as a probability distribution over true targets, and target information as a prior distribution, and then using Bayesian calculations to find the maximum likelihood target. I think I prefer the simpler and more consistent idea of snapping though.

There's a few ways I can think of getting the target information, a system could use either one or many of these:

Use accessibility APIs
: Accessibility APIs can tell you the pixel location of buttons, text and other likely targets.

Likelihood Neural Net
: Use machine learning (probably a CNN) to train a model that given a screenshot, predicts a likelihood distribution (think heatmap) of click targets. It could be trained on data from recording a screenshot and the mouse position on every click during normal computer use.

Prediction Neural Net
: Similar to the above, but using Gaze data. A model would be trained on the gaze location and screen contents to predict the true mouse click target. One way to do this would be to feed the net patches of the screen centered on the gaze target. Training data would be gathered by saving data from every click and training on the true click position.

Classical Computer Vision
: There's a number of possible computer vision techniques that could be used to identify targets without machine learning. For text anything from full OCR to algorithms that detect where text is without recognizing it (like in my [KeySelect](https://github.com/trishume/KeySelect) demo). Buttons also often have text, but controls could also be recognized using image patches recognized from previous clicks. You could even use heuristics like "coloured things" or "visually complex things".

## Disambiguate with just gaze

It's also possible to disambiguate targets with gaze alone, but this generally requires modifying or overlaying on the screen targets to manipulate the gaze.

Magnifying
: The simplest one is just magnifying the error around the gaze, either continuously or on dwell. This allows the user to refine their gaze on larger targets. The magnification can be either a rectangle or something fancier like a fisheye.

Moving Markers
: Similar to keyboard disambiguation, overlay likely targets with a marker that moves around in some pattern. Check if the gaze data is following one of the patterns. This works because eye trackers are better at detecting direction and timing of motion than absolute position. See the [Orbits paper](https://www.youtube.com/watch?v=x6hbicxEFbg) for an example of this kind of system.

Moving Distortion
: Similar to the previous except instead of markers, distort the screen are around the gaze in a moving pattern where different parts move in different patterns. Then the user just follows what they want to click with their gaze.

Eye Gestures
: Extra eye movements could be used to refine the position. For example darting the eyes in a position could nudge the cursor in that direction relative to where it was before the dart. Or winking an eye could move it left or right a small amount.

## How to click

Clicking is a separate issue, but there's also lots of possibilities here:

- Using a button: This could be a normal mouse or any other button.
- A foot pedal
- Dwell clicking
- Mouth noises: This is what I tried in my research, see [PopClick](https://github.com/trishume/PopClick)
- Face, head or eye gestures
- Voice recognition
- A keyboard

## Conclusion

Like I said, this was originally written primarily as prior art for patents. But I hope it was at least somewhat interesting to think about the numerous possibilities for eye tracking as a mouse replacement, even if a lot of the ideas have issues.
