---
layout: post
title: "Numderline: Grouping digits using OpenType shaping"
description: ""
category:
tags: [engineering]
assetid: numderline
good: true
---
{% include JB/setup %}

I recently worked on a fun side project to make a font that used font shaping trickery to make it easier to read large numbers by underlining alternating digit groups or inserting fake commas.

I wrote about it on the Jane Street tech blog since I started work there recently and I came up with the idea to help me visually parse tables of latency numbers for my job.

You can read the post here: <https://blog.janestreet.com/commas-in-big-numbers-everywhere/>

![Screenshot of the font]({{PAGE_ASSETS}}/numderline.png)

You can also check out [the font demo and download site](/numderline) and the [Github repo for the font patcher](https://github.com/trishume/numderline).

There's one other large public technical document I've written off of my own site that I might as well link here as well, which is my documentation of how the Xi text editor's CRDT works. Although it's written more as documentation than as a generally accessible blog post, you may still find it interesting, it has lots of diagrams. You can read it [here](https://github.com/xi-editor/xi-editor/blob/e8065a3993b80af0aadbca0e50602125d60e4e38/doc/crdt-details.md)
