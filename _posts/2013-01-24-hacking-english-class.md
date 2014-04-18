---
layout: post
title: "Hacking English Class"
description: "Writing Programs For English Class"
assetid: hackEnglish
category:
tags: [english, scripting]
---
{% include JB/setup %}

I was sitting in English class last year and thinking about how English was
about as far away from programming as you can get. We were discussing the
significance of characters in the novel *Lord of the Flies* and I thought "I
wonder if I could write a program to analyze this book, that would be ironic."

So that evening I wrote a Ruby script that analyzed the occurences of characters
names in *Lord of the Flies* and graphed it over time. It was a fun graph,
especially the most noticable feature being references to "Piggy" suddenly dropping.

I went on to write another script to analyze *Lord of the Flies* as well as
other scripts during English class this year. Here are some of the ones I have
come up with, starting with the most recent.

Most recently I wrote a program that reads entire stories and generates passages that
capture the texture of the story using Markov Trees.

![Markov Stories]({{PAGE_ASSETS}}/markov-poster.png)

In grade 11 my project was analyzing the most common colours in *The Great Gatsby*.
My teacher thought that yellow would be the most common but it turns out to be
white.

![Gatsby Colours]({{PAGE_ASSETS}}/Colours-of-Gatsby.png)

My other work this year was highlighting important words in the poem *Beowulf*.

[![Charged Words in Beowulf]({{PAGE_ASSETS}}/Beowulf.png)]({{PAGE_ASSETS}}/Beowulf.png)

As well as my two *Lord of the Flies* graphs.

![Lotf timeline]({{PAGE_ASSETS}}/lotf-1.png)

The second one shows words that appear close together, the saturation indicates
how often they occur close together.

[![Lotf co-occurence]({{PAGE_ASSETS}}/lotf-2.png)]({{PAGE_ASSETS}}/lotf-2.png)
