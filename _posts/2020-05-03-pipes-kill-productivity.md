---
layout: post
title: "Fragile mismatched narrow laggy asynchronous pipes kill productivity"
description: ""
category: 
tags: []
---
{% include JB/setup %}

Something I've been thinking about recently is how when I've worked on any kind of distributed system, including systems as simple as a web app with frontend and backend code, probably upwards of 80% of my time is spent on things I wouldn't need to do if it weren't distributed. I came up with the following description of why I think this kind of programming requires so much effort: everything is fragile narrow laggy asynchronous mismatched pipes. I think every programmer who's worked on a networked system has encountered each of these issues, this is just my effort to coherently describe all of them in one place. I hope to prompt you to consider all the different hassles at once and think about how much harder/easier your job would be if you did/didn't have to deal with these things. This is related to the observation that SpaceX and Twitter have similar numbers of engineers yet one had a much more impressive decade, although I won't opine on how much is due to this vs other factors. While part of this inherent in physics, I think there's lots of ideas for making each part of this problem easier, many in common use, and I'll try to mention lots of them. I hope that we as programmers continually develop more of these techniques and especially general implementations that can be applied easily to a new place rather than needing to reimplement a common pattern each time, because I think there's a ton of developer time spent on these out there to save.

I'll go over each word in detail but briefly, whenever we introduce a network connection we usually have to deal with something that is:

- Fragile: The network connection or the other end can have hardware failures, these have different implications but both manifest as just a timeout. Everything needs to handle failure.
- Narrow: Bandwidth is limited so we need to carefully design protocols to only send what they need.
- Laggy: Network latency is noticeable so we need to carefully minimize round-trips.
- Asynchronous: Especially with >2 input sources (UIs count) all sorts of races and edge cases can happen and need to be thought about and handled.
- Mismatched: It's often not possible to upgrade all systems atomically, so you need to handle different ends speaking different protocol versions.
- Pipes: Everything gets packed as bytes so you need to be able to (de)serialize your data.

All of these things can be mostly avoided when programming things that run on one computer, that is unless you end up optimizing performance and realizing your computer is actually a distributed system of cores and some of them come back. Some domains manage to avoid some of these but I've experienced subsets of these problems working on [web apps, self-driving cars, a text editor, and trading systems](https://thume.ca/resume), they're everywhere.

This isn't even all the problems, just things about the network. Tons of effort is also expended on things like how various bottlenecks often entail a complicated hierarchy of caches that need to be kept in sync with the underlying data store.

One way you can avoid all this is to just not write a distributed system. There are plenty of cases you can do this and I think it's worthwhile to try way harder than some people do to pack everything into one process. However past a certain point of reliability or scale, physics means you're going to have to use multiple machines (unless you want to go the mainframe route).

## Fragile

As you connect machines or increase reliability goals, the strategy of just crashing everything when one piece crashes (what multi-threaded/multi-core systems do) becomes increasingly unviable. Hardware will fail, wireless connections drop, entire data centers have their power or network taken out by [squirrels](https://en.wikipedia.org/wiki/Electrical_disruptions_caused_by_squirrels). Some domains like customers with flaky internet also inevitably entail connection failure.

In practice you need to write code to handle the failure cases and think carefully about what they are and what to do. This gets worse when merely noting the failure would drop important data, and you need to implement redundancy of data storage or transmission. Even worse, both another machine failing and a network connection breaking become visible just as some expected network packet not arriving after "too long", introducing not only a delay but an ambiguity that can result in [split-brain issues](https://en.wikipedia.org/wiki/Split-brain_(computing)). Often something like TCP implements it for you but sometimes you have to implement your own heartbeating to periodically check that another system is still alive.

Attempts to make this easier include exceptions, TCP, concensus protocols and off-the-shelf redundant databases, but no solution eliminates the problem everywhere. One of my favourite attempts is [Erlang's process linking, monitoring and supervising](https://rollout.io/blog/linking-monitoring-and-supervising-in-elixir/) which offers a philosophy that attempts to coalesce all sorts of failures into one easy to handle general case.

## Narrow

Network bandwidth is often limited, especially over consumer or cellular internet. It may seem like this isn't a limitation that often because you rarely hit bandwidth limits, but that's because limited bandwidth is ingrained into everything you do. Whenever you design a distributed system you need to come up with a communication protocol that communicates on the order of what's necessary rather than on the order of the total size of your data.

In a multi-threaded program, you might just pass a pointer to gigabytes of immutable or locked data for a thread to read what it wants from and not think anything of it. In a distributed system passing the entire memory representing your database is unthinkable and you need to spend time implementing other approaches.

This usually involves a message type for each query or modification to a shared data structure, and deciding when to ship over more data so local interactions are faster, or less data to avoid terrible bandwidth cases. It often goes further to various types of replicated state machine where each peer updates a model based on a replicated stream of changes, because sending the new model after every update would be too much bandwidth. Examples of this include [RTS games](https://www.gamasutra.com/view/feature/131503/1500_archers_on_a_288_network_.php) to [exchange](https://support.kraken.com/hc/en-us/articles/360027821131-How-to-maintain-a-valid-order-book-) [feeds](https://www.nasdaqtrader.com/content/technicalsupport/specifications/dataproducts/NQTVITCHspecification.pdf). However maintaining determinism and consistency in how each peer updates its state to avoid desyncs can be tricky, especially if different peers have different languages or software versions. You also often end up implementing multiple protocols because replaying events from the beginning of time is non-viable so you need a separate protocol to get a snapshot to catch up from.

Attempts to make this easier include RPC libraries just making it easier to send lots of different message types for different queries and updates rather than shipping data structures, caching libraries, and compression. Cool but less commonly used systems include things like [Replicant](https://hackingdistributed.com/2013/12/26/introducing-replicant/) that ensure synchronized state machine code and update streams on many devices to make replicated state machines easier and less fraught.

## Laggy

One network round trip can't be a problematic latency or you need better networking hardware or a different problem to solve. The problems come from avoiding implementing your solution in a way that needs too many network round trips. This can lead to needing to implement special combo-messages that do a sequence of operations on the server instead of just providing smaller primitive messages.

The web, with its especially large latencies, has had lots of problems of this type such as only having the font/image URLs after loading the HTML, or REST APIs that require multiple chained calls to get the IDs needed for the next. Lots of things have been built for these problems like resource inlining, [HTTP/2 server push](https://en.wikipedia.org/wiki/HTTP/2_Server_Push) and [GraphQL](https://graphql.org/).

A cool somewhat general solution is [Cap'n Proto promise pipelining](https://capnproto.org/news/2013-12-13-promise-pipelining-capnproto-vs-ice.html) and other systems that involve essentially shipping a chain of steps to perform to the other end (like SQL). That's essentially shipping a limited type of program to perform on the server, but you can run into the limitations of the language (e.g. adding 1 to your Cap'n Proto result before passing it to a new call requires a round trip). If you don't want to go the whole way to shipping functions to the server (a cool avenue for exploration!) you end up back at defining a new multi-step message type on the server. Adding a multi-step message for your use case is pretty easy if you control both ends, but can be harder if the other end is a company's API for third parties, or even just owned by a different team at a big company.

Another solution that can work in a data center is to use better networking. You can get [network](https://www.mellanox.com/products/ethernet-adapters/connectx-6dx) [cards](https://exablaze.com/exanic-x25) with [2us latencies and 100Gbps bandwidths](https://docs.microsoft.com/en-us/azure/virtual-machines/workloads/hpc/hc-series-performance) or better, but basically only HPC, simulations and finance use them. However these just reduce the constant factor and don't save you if your approach takes O(n) round trips.

## Asynchronous

As soon as you have 2+ sources of events that aren't synchronized then you start worrying about race conditions. This can be multiple servers, or just a web app with both user input and a channel to the server. There's always uncommon orderings like the user clicking the "Submit" button a second time before the next page loads. Sometimes you get lucky and the design of your system means that's fine, other times it's not and you either fix it to handle that case or get bug reports from customers who were billed twice. The more asynchrony the more cases you have to either think about or solve with an elegant design which precludes bad states.

Depending on your language/framework, asynchrony can also entail a change to the way you normally write code that makes everything bloated and uglier. Lots of systems used to and still do require you to use callbacks everywhere, sometimes without even providing you closures, making your code an enormous mess. Many languages have gotten better at this with features like [async/await](https://en.wikipedia.org/wiki/Async/await) or coroutines with small stack like [Go](https://tour.golang.org/concurrency/1), or just using threads and blocking I/O. Unfortunately some of these solutions introduce [function color problems](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/) where introducing asynchrony needs to change all your signatures.

Asynchrony edge cases are a reasonably fundamental problem themself, but there's lots of available patterns for solving different kinds of asynchrony. Including concurrency primitives like locks and barriers, protocol design ideas like [idempotency](https://en.wikipedia.org/wiki/Idempotence), and fancier things like [CRDTs](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type).

## Mismatched

Usually it's not possible to upgrade every component of a distributed system atomically when you want to change a protocol. This means for some time you'll have systems that want to talk a newer protocol version communicating with systems that only know an older protocol. This is just a problem you need to solve and there's two broad classes of common solutions with many subtypes:

- Have the new software version be able to speak both the old and new protocol version and negotiate to use the new version with upgraded peers, either by maintaining both implementations or mapping the old handlers onto the new ones.
- Use data structures that provide some degree of compatibility for free, then only upgrade your protocol in those ways. For example unrecognized fields in JSON objects are usually ignored so can be used for new functionality when recognized. Migrations can usually add new columns to a database table without it breaking queries. Then you usually go to great lengths to shoehorn every change into being this type of compatible.

The problem with both these cases is the first steps usually accumulate technical debt in the form of code paths to handle cases (for example of missing fields) that will never come up once all peers are upgraded past the protocol change. This usually entails multi-stage rollouts, for example introduce a new field as optional, roll out the new version everywhere, change the field to be mandatory now that all clients send it, do another rollout. I've definitely spent a lot of time planning multi-stage rollouts when I've wanted to change protocols used by multiple systems without leaving a mess.

There's lots of things that help with both of these approaches, both serialization systems that provide lots of compatible upgrade paths like [Protobufs](https://developers.google.com/protocol-buffers), to various [patterns for deserializing/upgrading old type versions](https://yave.handmade.network/blogs/p/2723-how_media_molecule_does_serialization).

## Pipes

Last and mostly least, everything has to be a stream of bytes or packets of bytes. This means you need to take your nice data structures that your language makes easy to manipulate and pack them into a different form from their in-memory representation in order to send on the wire. Luckily except in very few places easy [serialization](https://serde.rs/)/[RPC](https://grpc.io/) libraries have made this pretty easy, if occasionally somewhat slow. You can also sometimes use methods that allow you to pick out exactly the parts you want from the byte buffers without transforming it to a different representation, perhaps by casting your buffer pointer to a C structure pointer (when that's even close to safe-ish), or using something like [Cap'n Proto](https://capnproto.org/) that can generate accessors.

This is probably the one I've spent the least time fighting, but one case I can remember was when I wanted to send a large data structure, but the available serialization system could only serialize it all at once rather than streaming it packet by packet as the socket could accept it, and I didn't want to block my server for a long time doing the entire thing, creating tail latency. I ended up choosing a different design, but I could also have written custom code to break my data structure up into chunks and send it a little bit at a time.




