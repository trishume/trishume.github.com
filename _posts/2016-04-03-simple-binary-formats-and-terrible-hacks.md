---
layout: post
title: "Simple Binary Formats and Terrible Hacks"
description: ""
category:
tags: []
assetid: binary
---
{% include JB/setup %}

Last weekend me and my friend [Marc](http://mlht.ca/) went to [TerribleHack III](https://medium.com/@tau/terriblehack3-1164c2541c3f) and made [Dayder](http://dayder.thume.ca/), a neat little website for finding [spurious correlations](http://tylervigen.com/spurious-correlations) in lots of time series data sets. I did the ingestion of our initial data set of causes of death over time, as well as the JS/HTML front end. Marc made the correlation finding web server in Rust and also did the final prettying up of the CSS. I'm quite proud of how well it turned out given that it was made in 12 hours.

![Dayder]({{PAGE_ASSETS}}/dayder.png)

The coolest part of Dayder is how fast it is. All the DOM and JS Canvas rendering code is custom built for rendering hundreds of graphs in milliseconds. Marc and I also designed a custom simple binary format for storing time series data in a compact way. We called the format [btsf™](https://github.com/trishume/dayder/blob/master/format.md) and it is a key reason why our app can quickly send tons of time series data sets to the client as well as store them on the server in a compact way. All 6591 time series fit in less than 1 megabyte of data, allowing them all to be sent to the client for instantaneous filtering.

The following week I gave a short talk at a UWaterloo CS Club event about simple binary formats and how they can make your project faster, easier and cooler:

<script async class="speakerdeck-embed" data-id="56dcaeddea6f466bb08d8ee28694f952" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

Now that I've used simple binary formats for both [Rate With Science](http://ratewith.science/) and Dayder, I'm a big fan. Although outside a hackathon context where I have time to learn libraries and where I don't have the incentive to design new formats for fun, I think I would probably go with something established like [Cap'n Proto](https://capnproto.org/) or [Thrift](https://thrift.apache.org/) instead of a custom format.
