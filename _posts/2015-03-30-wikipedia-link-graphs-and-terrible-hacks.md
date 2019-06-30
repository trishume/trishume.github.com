---
layout: post
title: "Wikipedia Link Graphs and Terrible Hacks"
description: "Crunching through Wikipedia dumps to generate dense binary graphs for a hackathon project."
assetid: wikicrush
category:
tags: [wikipedia,graph,big data,hackathon,ruby]
---
{% include JB/setup %}

A couple months ago [Dave Pagurek](http://davepagurek.com/) and I decided on making an [arbitrary scale finder](http://ratewithscience.thume.net) for the upcoming UWaterloo ["stupid shit no one needs" hackathon](http://terriblehack.website). I decided that I would do this by finding paths in the links between Wikipedia pages. The thing is to do this I needed a good data set in the right format.

I did some research and found [Six Degrees of Wikipedia](http://mu.netsoc.ie/wiki/) which had some information but no data or source files. I then found [Graphipedia](https://github.com/mirkonasato/graphipedia) but discovered that Neo4j was not fast enough to do what I wanted. Thus I embarked on the adventure of creating my own Wikipedia link graph data set designed for efficient execution of common graph algorithms. The premise was compressing the whole graph into a small(ish) file that would fit entirely in memory, so I called it [Wikicrush](https://github.com/trishume/wikicrush).

I spent the next few weeks occasionally working on a set of Ruby scripts that in multiple stages processed the 10GB compressed `enwiki-20150205-pages-articles.xml.bz2` file into two 500mb files: `xindex.db` and `indexbi.bin`. For each stage in the process I ensured that it worked in O(n) time and reasonable memory. This way I could use crunch through the entire thing over a day on a cheap VPS. During development I would use the smaller Simple English wiki which I could process in a few minutes on my laptop. The advantage of the multi-stage design is that if I needed to tweak something I could just re-run the stages after that point rather than the whole thing. The intermediate files it created were also very useful for debugging and could be useful data sets in their own right.

![VPS Working Away]({{PAGE_ASSETS}}/ssh-screenshot.png)

I ended up with two files I'm rather proud of, one is a binary link graph in a custom format I designed myself designed to fit in memory and allow very efficient searching and processing. The other is simply an Sqlite index designed to translate article titles into offsets into the binary file and back again. The formats are fairly easy to work with in any imperative language and have many handy features. I documented the formats in detail in the [Wikicrush readme](https://github.com/trishume/wikicrush#primary-data). They work so well that my $10/month VPS can easily breadth first search through millions of articles in less than a second.

I had the initial version working fairly quickly but had to spend a bunch of time fixing small bugs to get it to accurately represent the actual link graph of Wikipedia. I had to fix things like following redirects, cutting out broken links, ignoring links in comments and proper handling of case in links (I ended up lowercasing everything). Although making your own Wikipedia data set may seem easy at first, there's plenty of ways things can go wrong. Many times I thought I had a good complete data set and only later would I realize something was wrong. One time I thought I had finally worked out the kinks and then discovered weeks later that it thought 70% of links on Wikipedia were invalid, which obviously isn't true. Even just yesterday I found and fixed a little bug that only affected 300 articles, but the perfectionist in me sent my VPS to slave away for another 40 hours of rebuilding.

**Edit:** I recently found another glitch and overhauled the entire process to be more robust. I now think I've shaken out all the bugs so I have put up a download of the final product.
You can find the link on the [Wikicrush readme](https://github.com/trishume/wikicrush). I also no longer need to lowercase everything. This is AFAIK the only Wikipedia link graph dataset available for public download.

## The Terrible Hacks Hackathon

During the hackathon some parts went very smoothly while others did not. Working with the files I had created was very easy, working with the Rust language for my first time was not. At some point I could not link my graph search algorithm to the [Iron](https://github.com/iron/iron) web framework because my algorithm and Sqlite connection were not thread safe and one can not disable type system based thread safety checks in Iron with Rust. I ended up with a suitably terrible hack which was having the Rust code communicate over stdin/stdout and having a Ruby Sinatra server interface with that. Along with that, all the paths were hard coded, it required a specific `rustc` commit and one had to manually fiddle with the `Cargo.toml` and `Cargo.lock` files to work around a bug in Cargo just to get it to compile. This made it practically impossible to install and run on anything but my laptop.

I eventually got things hacked together and by that time Dave had put together a fantastic front end with fancy CSS, autocomplete and REST loading. All I had to do was serve his static files and expose a JSON API.

Once we did that we had a product, and it ended up working great. The paths it generated were amusing and it was fun to use. Not to mention it looked pretty good for something put together in one afternoon:
![The Product]({{PAGE_ASSETS}}/rws-screenshot.png)

## The Rewrite

A week later I decided to kill two birds with one experimental statically-typed stone and learned the [Nim](http://nim-lang.org/) language by rewriting the project in it. I ran into a couple similar problems with the Jester web framework and loading the file into an int32 array but unlike the similar problems in Rust these had easy workarounds. In the end everything worked reasonably well with Nim especially after I got some help on IRC from its creator.

You can now visit and try out [Rate With Science](http://ratewithscience.thume.net/) powered purely by Nim and backed by Wikicrush.
