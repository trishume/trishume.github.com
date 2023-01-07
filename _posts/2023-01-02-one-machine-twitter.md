---
layout: post
title: "Production Twitter on One Machine? 100Gbps NICs and NVMe are fast"
description: ""
good: true
category: 
assetid: twitterperf
tags: []
---
{% include JB/setup %}

In this post I'll attempt the fun stunt of designing a system that could serve the full production load of Twitter with most of the features intact on a single (very powerful) machine. I'll start by showing off a Rust prototype of the core tweet distribution data structure handling 35x full load by fitting the hot set in RAM and parallelizing with atomics, and then do math around how modern high-performance storage and networking might let you serve a close-to-fully-featured Twitter on one machine.

I want to be clear this is meant as educational fun, and not as a good idea, at least going all the way to one machine. In the middle of the post I talk about all the alternate-universe infrastructure that would need to exist before doing this would be practical. There's also some features which can't fit, and a lot of ways I'm not really confident in my estimates.

I've now spent about a week of evenings and a 3 weekends doing research, math and prototypes, gradually figuring out how to fit more and more features (images?! ML?!!) than I initially thought I could fit. We'll start with the very basics of Twitter and then go through gradually more and more features, in what I hope will be a fascinating tour of an alternative world of systems design where web apps are built like high performance trading systems. I'll also analyze the minimum cost configuration using multiple more practical machines, and talk about the practical disadvantages and advantages of such a design.

Here's an overview of the features I'll talk about and whether I think they could fit:

- **Timeline and tweet distribution logic**: Based on a prototype, fits easily on a handful of cores when you pack recent tweets in RAM supplemented with NVMe.
- **HTTP(S) request serving**: Yes. HTTP fits, HTTPS fits only because of session resumption.
- **Image serving**: A close fit with rough estimates, but maybe doable with multiple 100Gbit/s networking cards. You need effort to avoid extreme bandwidth costs.
- **Video, search, ads, notifications**: Probably these wouldn't fit, and it's really tricky to estimate whether they might.
- **Historical tweet and image storage**: Tweets fit on a specialized server, *but images don't*, you could fit maybe 4 months of images with a 48x HDD storage pod.
- **ML-based timeline**: A100 GPUs are insane and can run a decent LM against every tweet and dot-product the embeddings with every user.

Let's get this unhinged answer to a [common systems design interview question](https://www.geeksforgeeks.org/design-twitter-a-system-design-interview-question/) started!

## Core Tweet Distribution

Let's start with the original core of Twitter: Users posting text-based tweets to feeds which others follow with a chronological timeline. There's basically two ways you could do this:

1. The timeline page pulls tweets in reverse-chronological order from each follow until enough tweets are found, using a [heap](https://en.wikipedia.org/wiki/Heap_(data_structure)) to merge them. This requires retrieving a lot of tweets from different feeds, the challenge is making that fast enough.
2. Each tweet gets pushed into cached timelines. Pushing tweets might be faster than retrieving them in some designs, and so this might be worth the storage. But celebrity tweets have huge fanout so either need background processing or to be separately merged in, but you need a backup merge anyways in case a range of timeline isn't cached.

The [systems design interview](https://github.com/donnemartin/system-design-primer/blob/master/solutions/system_design/twitter/README.md) [answers](https://medium.com/@narengowda/system-design-for-twitter-e737284afc95) I can find take the second approach because merging from the database on pageload would be too slow with typical DBs. They use some kind of background queue to do the tweet fanout writing into a sharded timeline cache like a Redis cluster.

I'm not sure how real Twitter works but I think based on [Elon's whiteboard photo](https://miro.com/app/board/uXjVPBnTJmM=/) and some tweets I've seen by Twitter (ex-)employees it seems to be mostly the first approach using fast custom caches/databases and maybe parallelization to make the merge retrievals fast enough.

## How big is Twitter?

When you're not designing your systems to scale to arbitrary levels by adding more machines, it becomes important what order of magnitude the numbers are, so let's try to get good numbers.

So, how many tweets do we need to store? [This Twitter blog post from 2013](https://blog.twitter.com/engineering/en_us/a/2013/new-tweets-per-second-record-and-how) gives figures for daily and peak rates, but those numbers are pretty old.

Through intense digging I found a researcher who left a notebook public including tweet counts from many years of Twitter's [10% sampled "Decahose" API](https://developer.twitter.com/en/docs/twitter-api/enterprise/decahose-api/overview/decahose) and discovered the surprising fact that **tweet rate today is around the same as or lower than 2013**! Tweet rate peaked in 2014 and then declined before reaching new peaks in the pandemic. Elon recently [tweeted the same 500M/day](https://twitter.com/elonmusk/status/1598758363650719756) number which matches the Decahose notebook and 2013 blog post, so this seems to be true! Twitter's active users grew the whole time so I think this reflects a shift from a "posting about your life to your friends" platform to an algorithmic content-consumption platform.

I did all my calculations for this project using [Calca](http://calca.io/) (which is great although buggy, laggy and unmaintained. I might switch to [Soulver](https://soulver.app/)) and I'll be including all calculations as snippets from my calculation notebook.

<div class="calca">
  <p>First the public top-line numbers:

  </p><p></p><pre><code><span class="d">daily active users</span> = <span class="n">250e6</span> <span class="t">=&gt;</span> <span class="n ans">250,000,000</span>
  </code></pre><pre><code><span class="d">avg tweet rate</span> = <span class="n">500e6</span>/<span class="u">day</span> <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">5,787.037</span>/<span class="u">s</span></span>
  </code></pre>
  <p>The Decahose notebook (which ends March 2022) suggests that tweet rate averages out pretty well at the level of a full day, the peak days ever in the dataset (during the pandemic lockdown in 2020) only have about 535M tweets compared to 340M before the lockdown surge.

  </p><p></p><pre><code><span class="d">traffic surge ratio</span> = <span class="n">535e6</span> / <span class="n">340e6</span> <span class="t">=&gt;</span> <span class="n ans">1.5735</span>
  </code></pre><pre><code><span class="d">max sustained tweet rate</span> = avg tweet rate * traffic surge ratio  <span class="t">=&gt;</span> <span class="ans"><span class="n">9,106.073</span>/<span class="u">s</span></span>
  </code></pre>
  <p>The maximum tweet record is probably still the 2013 Japanese TV airing, Elon said only 20k/second for the recent world cup.

  </p><p></p><pre><code><span class="d">max tweet rate</span> = <span class="n">150,000</span>/<span class="u">second</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">150,000</span>/<span class="u">second</span></span>
  </code></pre>
  <p>Now we need to figure out how much data that is. Tweets <a href="https://qntm.org/twitcodings">can fit a maximum of 560 bytes</a> but probably almost all Tweets are shorter than that and we can either use a variable length encoding or a fixed size with an escape hatch to a larger structure for unusually large tweets. One dataset I tried suggested an average length close to 80 characters, but I that was maybe from before the tweet length expansion so let's use a larger number to be safe and allow a fixed size encoding with escape hatch.

  </p><p></p><pre><code><span class="d">tweet content max size</span> = <span class="n">560</span> <span class="u">byte</span>
  </code></pre><pre><code><span class="d">tweet content avg size</span> = <span class="n">140</span> <span class="u">byte</span>
  </code></pre>
  <p>Tweets also have metadata like a timestamp and also some numbers we may want to cache for display such as like/retweet/view counts. Let's guess some field counts.

  </p><p></p><pre><code><span class="d">metadata size</span> = <span class="n">2</span>*<span class="n">8</span> <span class="u">byte</span> + <span class="n">5</span> * <span class="n">4</span> <span class="u">byte</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">36</span> <span class="u">byte</span></span>
  </code></pre>
  <p>Now we can use this to compute some sizes for both historical storage and a hot set using fixed-size data structures in a cache:

  </p><p></p><pre><code><span class="d">tweet avg size</span> = tweet content avg size + metadata size <span class="t">=&gt;</span> <span class="ans"><span class="n">176</span> <span class="u">byte</span></span>
  </code></pre><pre><code><span class="d">tweet storage rate</span> = avg tweet rate * tweet avg size <span class="k">in</span> <span class="u">GB</span>/<span class="u">day</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">88</span> <span class="u">GB</span>/<span class="u">day</span></span>
  </code></pre><pre><code>tweet storage rate * <span class="n">1</span> <span class="u">year</span> <span class="k">in</span> <span class="u">TB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">32.1413</span> <span class="u">TB</span></span>
  </code></pre>
  <p></p><pre><code><span class="d">tweet content fixed size</span> = <span class="n">284</span> <span class="u">byte</span>
  </code></pre><pre><code><span class="d">tweet cache rate</span> = (tweet content fixed size + metadata size) * max sustained tweet rate <span class="k">in</span> <span class="u">GB</span>/<span class="u">day</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">251.7647</span> <span class="u">GB</span>/<span class="u">day</span></span>
  </code></pre>
  <p>Let's guess the hot set that almost all requests hit is maybe 2 days of tweets. Not all tweets in people's timeline requests will be &lt;2 days old, but also many tweets aren't seen very much so won't be in the hot set.

  </p><p></p><pre><code><span class="d">tweet cache size</span> = tweet cache rate * <span class="n">2</span> <span class="u">day</span> <span class="k">in</span> <span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">503.5294</span> <span class="u">GB</span></span>
  </code></pre>
  <p>We also need to store the following graph for all users so we can retrieve from the cache. I need to completely guess a probably-overestimated average following count to do this.

  </p><p></p><pre><code><span class="d">avg following</span> = <span class="n">400</span>
  </code></pre><pre><code><span class="d">graph size</span> = avg following * daily active users * <span class="n">4</span> <span class="u">byte</span> <span class="k">in</span> <span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">400</span> <span class="u">GB</span></span>
  </code></pre>
</div>

I think the main takeaway looking at these calculations is that many of these numbers are small numbers on the scale of modern computers!

## Hot set in RAM, rest on NVMe

Given those numbers, I'll be using the "[your dataset fits in RAM](https://twitter.com/garybernhardt/status/600783770925420546?s=20)" paradigm of systems design. However it's a little more complicated since our dataset doesn't _actually_ fit in RAM.

Storing all the historical tweets takes many terabytes of storage. But probably 99% of tweets viewed are from the last few days. This means we can use a hybrid of RAM+NVMe+HDDs attached to our machine in a tiered cache:

- RAM will store our hot set cache and serve almost all requests, so most of our performance will only depend on the RAM cache. It's common to fit 512GB-1TB of RAM in a modern machine.
- Modern NVMe drives can store >8TB and do [over 1 million 4KB IO operations per second per drive](https://ci.spdk.io/download/performance-reports/SPDK_NVMe_bdev_gen4_perf_report_2201.pdf) with latencies near 100us, and you can attach dozens of them to a machine. That's enough to serve all tweets, but we can lower CPU overhead and add headroom by just using them for long tail tweets and probably the follower graph (since it only needs one IO op per timeline request).
- Some extra 20TB HDDs can store the very old very cold tweets that are basically never accessed, especially at the 2x compression I saw with [zstd](http://facebook.github.io/zstd/) on tweet text from a [Kaggle dataset](https://www.kaggle.com/datasets/kazanova/sentiment140).

However, super high performance tiering RAM+NVMe buffer managers which can access the RAM-cached pages almost as fast as a normal memory access are mostly only [detailed and benchmarked in academic papers](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/_my_direct_uploads/vmcache.pdf). I don't know of any good well-maintained open-source ones, [LeanStore](https://dbis1.github.io/) is the closest. You don't just need tiering logic, but also an NVMe write-ahead-log and checkpointing to ensure persistence of all changes like new tweets. This is one of the areas where running Twitter on one machine is more of a theoretical possibility than a pragmatic one.

So I just prototyped a RAM-only implementation and I'll handwave away the difficulty of the buffer manager (and things like schema migrations) by saying it isn't that relevant to whether the performance targets are possible because most requests just hit RAM and [this paper shows that you can implement what is basically mmap with _much_ more efficient page faults](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/_my_direct_uploads/vmcache.pdf) for only a 10% latency hit on non-faulting RAM reads plus some TLB misses from not being able to use hugepages. Although the real overhead is on the writes and faulting reads and from the handful of cores taken up for logging writes and managing checkpointing, cache reads and evictions.

## My Prototype

I made a prototype ([source on Github](https://github.com/trishume/twitterperf)) in Rust to benchmark the in-memory performance of timeline merging and show that I could get it fast enough to serve the full load. At it's core is a minimalist pooling-and-indices style representation of Twitter's data, optimized to be fairly memory-efficient:

```rust
/// Leave room for a full 280 English character plus slop for accents or emoji.
/// A real implementation would have an escape hatch for longer tweets.
pub const TWEET_BYTES: usize = 286;

// non-zero so options including a timestamp don't take any more space
// u32 since that's 100+ years of second-level precision and it lets us pack atomics
pub type Timestamp = NonZeroU32;
pub type TweetIdx = u32;

pub struct Tweet {
    pub content: [u8; TWEET_BYTES],
    pub ts: Timestamp,
    pub likes: u32, pub quotes: u32, pub retweets: u32,
}

/// linked list of tweets to make appending fast and avoid space overhead
/// a linked list of chunks of tweets would probably be faster because of
/// cache locality of fetches, but I haven't implemented that
pub struct NextLink {
    pub ts: Timestamp, // so we know whether to follow further
    pub tweet_idx: TweetIdx,
}

/// Top level feeds use an atomic link so we can mutate concurrently
/// This effectively works by casting NextLink to a u64
pub struct AtomicChain(AtomicU64);

/// Since this is most of our RAM and cache misses we make sure it's
/// aligned to cache lines for style points
#[repr(align(64))]
pub struct ChainedTweet {
    pub tweet: Tweet,
    pub prev_tweet: Option<NextLink>,
}
assert_eq_size!([u8; 320], ChainedTweet); // 5 cache lines

/// We store the Graph in a format we can mmap from a pre-baked file
/// so that our tests can load a real graph faster
pub struct Graph<'a> {
    pub users: &'a [User],
    pub follows: &'a [UserIdx],
}

pub struct User {
    pub follows_idx: usize, // index into graph follows
    pub num_follows: u32,
    pub num_followers: u32,
}

impl<'a> Graph<'a> {
    // We can use zero-cost abstractions to make our pools more ergonomic
    pub fn user_follows(&'a self, user: &User) -> &'a [UserIdx] {
        &self.follows[user.follows_idx..][..user.num_follows as usize]
    }
}

pub struct Datastore<'a> {
    pub graph: Graph<'a>,
    // This is a tiny custom pool which mmaps a vast amount of un-paged virtual
    // address space. It's like a Vec which never moves and lets you append concurrently
    // with only an immutable reference by using an internal append lock.
    pub tweets: SharedPool<ChainedTweet>,
    pub feeds: Vec<AtomicChain>,
}
```

Then the code to compose a timeline is a simple usage of Rust's built-in heap:

```rust
/// Re-use these allocations so fetching can be malloc-free
pub struct TimelineFetcher {
    tweets: Vec<Tweet>,
    heap: BinaryHeap<NextLink>,
}

impl TimelineFetcher {
    fn push_after(&mut self, link: Option<NextLink>, after: Timestamp) {
        link.filter(|l| l.ts >= after).map(|l| self.heap.push(l));
    }

    pub fn for_user<'a>(&'a mut self, data: &Datastore,
      user_idx: UserIdx, max_len: usize, after: Timestamp
    ) -> Timeline<'a> {
        self.heap.clear(); self.tweets.clear();
        let user = &data.graph.users[user_idx as usize];
        // seed heap with links for all follows
        for follow in data.graph.user_follows(user) {
            self.push_after(data.feeds[*follow as usize].fetch(), after);
        }
        // compose timeline by popping chronologically next tweet
        while let Some(NextLink { ts: _, tweet_idx }) = self.heap.pop() {
            let chain = &data.tweets[tweet_idx as usize];
            self.tweets.push(chain.tweet.clone());
            if self.tweets.len() >= max_len { break }
            self.push_after(chain.prev_tweet, after);
        }
        Timeline {tweets: &self.tweets[..]}
    }
}
```

I wrote a bunch of [support code to load](https://github.com/trishume/twitterperf/blob/cbc27693f90f184baa99ae0dbed24c640d5651d3/examples/load_graph.rs) an [old Twitter follower graph dump from 2010](https://snap.stanford.edu/data/twitter-2010.html), which is about 7GB in-memory. I used a dump so that I could capture a realistic distribution shape of follower counts and overlaps, while fitting on my laptop. I then wrote a load-generator which selects every user with more than 20 followers (around 7M) to tweet and every user with more than 20 follows (around 9M) to view. I then generate 30 million fresh tweets and then benchmark how long it takes to compose timelines with them on all 8 cores of my laptop and get the following results:

```
Initially added 15000000 tweets in 5.46230697s: 2746092.463 tweets/s.
Benchmarked adding 15000000 tweets in 5.456315988s: 2749107.646 tweets/s.
Starting fetches from 8 threads
Done 16714668 in 5.054423792s at 3306938.375 tweets/s. Avg timeline size 167.15 -> expansion 100.63
Done 16723580 in 5.072738523s at 3296755.771 tweets/s. Avg timeline size 167.24 -> expansion 100.69
Done 16724418 in 5.077739414s at 3293673.944 tweets/s. Avg timeline size 167.24 -> expansion 100.69
Done 16752863 in 5.079175123s at 3298343.253 tweets/s. Avg timeline size 167.53 -> expansion 100.86
Done 16715614 in 5.081238053s at 3289673.467 tweets/s. Avg timeline size 167.16 -> expansion 100.64
Done 16741876 in 5.083800824s at 3293180.945 tweets/s. Avg timeline size 167.42 -> expansion 100.80
Done 16729038 in 5.090990804s at 3286008.293 tweets/s. Avg timeline size 167.29 -> expansion 100.72
Done 16748782 in 5.096817055s at 3286125.796 tweets/s. Avg timeline size 167.49 -> expansion 100.84
```

So about **3.3M tweets distributed per core-second**, when retrieved with an average timeline chunk of 167. And because it's mostly cache misses, per-core performance only goes down to 2.5M/sec when using all 16 hyperthreads, allowing me to reach 40M tweets fetched per second on my laptop. Now I'm fully aware **my benchmark is not the full data size of Twitter** nor the most realistic load I could create, but I'm just trying to get an estimate of what the full scale performance would look like and I think this gives a reasonable estimate. My test data is way larger than my laptop cache and fully random so basically every load should be a cache miss, and profiling seems to align with this. So while I think memory access is marginally slower when you have more of it, the throughput should be similar on a server that had enough RAM on one NUMA node to fit the full-sized tweet cache. More realistically non-uniform load distributions I believe would just make it more likely that the L3 cache actually made things faster.

It also looks like adding tweets to the data structure shouldn't be a bottleneck, given it adds tweets at over 1M/core-sec when the highest peak Twitter had was 150k/sec.

## Can the prototype meet the real load? Very yes!

My prototype's performance should mainly scale based on number of tweets retrieved (because of cache misses retrieving them) and the size of retrieved chunks (larger chunks dilute the overhead of setting up the follow chain heap). The fixed overhead also scales with average follow count and variable with log follow count, which has probably grown since 2010 but I unfortunately don't have numbers on, and most of the time is spent in the variable segment anyhow. So let's see how those numbers stack up to calculations of real Twitter load!

<div class="calca">
  <p><a href="https://twitter.com/elonmusk/status/1598765633121898496">Elon tweeted</a> 100 billion impressions per day which probably includes a lot of scrolling past algorithmic tweets/likes that aren't part of the basic core version of Twitter, but corresponds to an average timeline delivery rate that's 2-3x the number of tweets on an average day from all the people I follow.

  </p><p></p><pre><code><span class="d">avg timeline rate</span> = <span class="n">400</span>/<span class="u">day</span>
  </code></pre><pre><code><span class="d">delivery rate</span> = daily active users * avg timeline rate <span class="t">=&gt;</span> <span class="ans"><span class="n">100,000,000,000</span>/<span class="u">day</span></span>
  </code></pre><pre><code>delivery rate <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">1,157,407.4074</span>/<span class="u">s</span></span>
  </code></pre><pre><code><span class="d">avg expansion</span> = delivery rate / avg tweet rate <span class="k">in</span> <span class="n">1</span> <span class="t">=&gt;</span> <span class="n ans">200</span>
  </code></pre>
  <p></p><pre><code><span class="d">delivery bandwidth</span> = tweet avg size * delivery rate <span class="k">in</span> <span class="u">Gbit</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">1.6296</span> <span class="u">Gbit</span>/<span class="u">s</span></span>
  </code></pre><pre><code>delivery bandwidth <span class="k">in</span> <span class="u">TB</span>/<span class="u">month</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">535.689</span> <span class="u">TB</span>/<span class="u">month</span></span>
  </code></pre>
  <p>But that's for the average, what if we assume that page refreshing spikes just as much as tweet rate at peak times. I don't think this is true, the tweet peak was set with tweeting synchronized on one TV event and lasted less than 30 seconds, but refreshes will be less synchronized even during busy events like the world cup. Let's calculate it anyways though!

  </p><p></p><pre><code><span class="d">per core</span> = <span class="n">2.5e6</span>/(thread*<span class="u">second</span>) * <span class="n">2</span> thread <span class="t">=&gt;</span> <span class="ans"><span class="n">5,000,000</span>/<span class="u">second</span></span>
  </code></pre><pre><code><span class="d">peak delivery rate</span> = max tweet rate * avg expansion <span class="t">=&gt;</span> <span class="ans"><span class="n">30,000,000</span>/<span class="u">second</span></span>
  </code></pre><pre><code><span class="d">peak cores needed</span> = peak delivery rate / per core <span class="t">=&gt;</span> <span class="n ans">6</span>
  </code></pre><pre><code><span class="d">peak bandwidth</span> = tweet avg size * peak delivery rate <span class="k">in</span> <span class="u">Gbit</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">42.24</span> <span class="u">Gbit</span>/<span class="u">s</span></span>
  </code></pre>
  <p>To estimate tweets per request, let's start by considering a Twitter without live timeline updating where a user opens the website or app a few times a day and then scrolls through their new tweets.

  </p><p></p><pre><code><span class="d">avg new connection rate</span> = <span class="n">3</span>/<span class="u">day</span> * daily active users <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">8,680.5556</span>/<span class="u">s</span></span>
  </code></pre><pre><code><span class="d">tweets per request</span> = delivery rate / avg new connection rate <span class="k">in</span> <span class="n">1</span> <span class="t">=&gt;</span> <span class="n ans">133.3333</span>
  </code></pre>
</div>

Looks like **my estimate of the full average tweet delivery rate of Twitter is 35x less than what my 8 core laptop can fetch**! I also had chosen the average timeline size in the benchmark based on the estimate of normal timeline request sizes. It also looks like serving all the timeline RPCs is a fairly small amount of bandwidth during average load.

There's **lots of room for this to underestimate load or overestimate performance**: Peak loads could burst much higher, I could get average timeline sizes or delivery rates wrong, and a realistic implementation would have more overheads. My estimates could be wrong in lots of ways, but there's just **so much performance margin it should be fine**. My implementation even seems to scale linearly with cores, and there's another 10x left before it would start hitting memory bandwidth limitations. Right now it can only add tweets from one thread, which I only have a 20x performance margin on (but from a known peak load), but with a little bit more effort with atomics that could be multi-core too.

This perhaps 350x safety margin, plus the fact that [high-performance batched](https://github.com/erpc-io/eRPC) [kernel-bypass RPC systems](https://smfrpc.github.io/smf/rpc/) can achieve overheads low enough to do 10M requests/core-s, means **I'm confident an RPC service which acted as the core database of simplified production Twitter could fit on one big machine**. This is a very limited sense of running "Twitter" on one machine, you'd still have other stateless machines to act as web servers and API frontends to the high-performance binary RPC protocol, and of course this is only the very most basic features of Twitter.

There's a bunch of other basic features of Twitter like user timelines, DMs, likes and replies to a tweet, which I'm not investigating because I'm guessing they won't be the bottlenecks. Replies do add slightly to the load when writing a tweet, because they'd need to be added to a secondary chain or something to make retrieving them fast. Some popular tweets have tons of replies, but users only can see a subset, and the same subset can be cached to serve to every user.

To make my hedged confidence quantitative, I'm 80% sure that if I had a conversation with a (perhaps former) Twitter performance engineer they wouldn't convince me of any factors I missed about Twitter load (on a much-simplified Twitter) or what machines can do, which would change my estimates enough to convince me a centralized RPC server couldn't serve all the simplified timelines. I'm only 70% sure for a version that also does DMs, replies and likes, because those might be used way more than I suspect, and might pose challenges I haven't thought about.

## Conclusion-ish: It's not practical to build this way, but maybe it could be

I don't actually think people should build web apps this way. Here's all the things I think would go wrong with trying to implement a Twitter-scale company on one machine, and the alternate universe system that would have to exist to avoid that problem:

- **Your one machine can die**: Systems can have [remarkable uptime](https://twitter.com/danluu/status/1586180166631706624?s=20) when there's just one machine, but that's still risking permanent data loss and prolonged outages. You'd use at number of machines in different buildings in any real deployment. The framework could handle this semi-transparently with some extra cores and bandwidth per-machine using [state machine replication](https://signalsandthreads.com/state-machine-replication-and-why-you-should-care/) and Paxos/Raft for failover.
- **RAM structures are easy but disks are tricky**: You'd need the kind of [NVMe virtual memory buffer manager](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/_my_direct_uploads/vmcache.pdf) I've mentioned hooked up with a transaction log so you can just write a Rust state machine like you would in RAM.
- **Bad code can use up all the resources**: You'd need a bunch of enforcement infrastructure around this. Your task system would need preemption and subsystem memory/network/cpu budgets. You'd need to capture busy day production traces and replay them in pre-deploy CI.
- **A bug in one part can bring down everything**: Normally network boundaries enforce design around failure handling and gracefully degrading. You'd need tools for in-system circuit breakers and failure handling logic, and static analysis to enforce this at the company level.
- **Zero-downtime deploys and schema evolution are tricky**: You'd need tooling to do something like generate getters that check version tags on your data structures and dispatch. Evolveable often conflicts with structures being fixed-size, which means an extra random read for many operations, or having to do deploys via rewriting the whole database and having another system catch up to the present incrementally before cutting over.
- **Kernel-bypass binary protocol networking is hard to debug**: It would take tons of tooling effort to catch up to the ecosystem of linux networking and text formats before debugging and observability would be as smooth.
- **What if you want to do something that doesn't fit on the machine?**: You'd want a system which could scale to multiple machines via some kind of state machine replication, remote paging and RPCs. If you want security boundaries between the machines that adds lots of access control complexity. Databases and multicore CPUs already have this kind of technology, but it's not available outside them.

It's possible to build systems this way right now, it just requires really deep knowledge and carefulness, and is setting yourself up for either disaster or _tons_ of infrastructure work as your company scales. There's a feedback loop where few companies in the web space scale this way, so the available open-source tooling for it is abysmal, which makes it really hard to scale this way. I think of scaling this way because I used to work for a [trading company](http://janestreet.com/), where scaling systems to handle millions of requests per second per machine with microsecond latency kernel-bypass networking is [a common way to do things](https://signalsandthreads.com/multicast-and-the-markets/) and there's lots of infrastructure for it. But they still use lots of machines for most things, and in many ways have a simpler problem (e.g. often no state persists between market days and there's downtime between).

I do kind of yearn for this alternate-universe open source infrastructure to exist though. More hardware-efficient systems are cheaper, but I think the main benefit is avoiding the classic distributed systems and asynchrony problems every attempt to split things between machines runs into (which I've [written a pseudo-manifesto on before](/2020/05/17/pipes-kill-productivity/)), which means there's potential for it to be way simpler too. It would also enable magic powers like time-travel debugging any production request as long as you mark the state for snapshotting. But there's so much momentum behind the current paradigm, not only in terms of what code exists, but what skills readily hireable people have.

**Edit:** A friend points out that [IBM Z mainframes](https://www.ibm.com/z) have [a bunch of the resiliency software and hardware infrastructure I mention](https://www.redbooks.ibm.com/redbooks/pdfs/sg248446.pdf), like lockstep redundancy between mainframes separated by kilometers. They also scale to massive machines. I don't know much about them and am definitely interested in reading more, and if it weren't for the insane cost I wouldn't be surprised if I actually ended up liking modern mainframes as a platform for writing resilient and scalable software in an easy way.

**That's all I originally planned for this post**, to show with reasonable confidence that you could fit the core tweet distribution of simplified Twitter on one machine using a prototype. But then it turned out I had tons of cores and bandwidth left over to tack on other things, so let's forge ahead and try to estimate which other features might fit using all the extra CPU!

## Directly serving web requests

The above simplified Twitter architecture doesn't serve the whole simplified Twitter from one machine, and relies on stateless frontend machines to serve the consumer API and web pages. Can we also do that on the main machine? Let's start by imagining we'll serve up a maybe 64KB static page with a long cache timeout, and uses some minimized JS to fetch the binary tweet timeline and turn it into DOM.

A [benchmark for fast HTTP servers](https://www.techempower.com/benchmarks/#section=data-r21&test=plaintext) shows a single machine handling 7M simple requests per second. That's way above our average-case estimate of 15k/s from above, so there's comfortable room to handle peaks and estimation error. Browser caches and people leaving tabs open on our static main page will probably also save us bandwidth serving it too. However HTTP is practically deprecated for providing no security.

<div class="calca">
  <p>Could we fit the bandwidth for 15k/s on a small NIC even without caching? Yes.</p>
  <pre><code><span class="d">home page rate on a small connection</span> = <span class="n">10</span><span class="u">Gbit</span>/<span class="u">s</span> / <span class="n">64</span><span class="u">KB</span> <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">19,073.4863</span>/<span class="u">s</span></span>
  </code></pre>
</div>

I spent a bunch of time Googling for good benchmarks on HTTPS server performance. Almost everything I found was articles claiming [the performance penalty over HTTP is negligible](https://istlsfastyet.com/) by giving CPU overhead numbers in the realm of 1% which include application CPU. The symmetric encryption for established connections with [AES-ni instructions](https://calomel.org/aesni_ssl_performance.html) is actually fast at gigabytes per core-s, but it's the public key crypto to establish sessions that's worrying. When they do give out raw overhead numbers [they say numbers like 3.5ms to do session creation crypto](https://blogs.sap.com/2013/06/23/whos-afraid-of-ssl/) as if it's tiny, which it is for most people, but we're not being most people! That's only 300 sessions/core-s! I can find some [HTTPS benchmarks](https://h2o.examp1e.net/), but they usually simulate a small number of clients so don't test connection establishment.

What likely saves us is [session resumption and tickets](https://hpbn.co/transport-layer-security-tls/#tls-session-resumption), where browsers cache established crypto sessions so they can be resumed in future requests. This means we may only need to handle 1 session negotiation per user-week instead of multiple per day, and thus it's probably possible for an HTTPS server to hit [100k requests/core-s](https://h2o.examp1e.net/benchmarks.html) under realistic loads (before app and bandwidth overhead). So even though I can't find any actually good high-performance HTTPS server benchmarks, I'm going to say **The machine can probably directly serve the web requests too.**

I think there's a 75% chance, conditional on an RPC backend fitting, that you could also serve web requests. Especially with a custom HTTP3 stack that used [DPDK](https://www.dpdk.org/) and very optimized static cached pages for a minimalist Twitter, with most uncertainty being maybe session resumption or caches can't hit that often.

*Post-prediction edit: Someone who worked at Twitter confirmed their actual request rates are lower than a fast HTTPS server could handle, but noted that crawlers mean a portion of the requests need to have the HTML generated server-side. I'm going to say crawlers are a separate feature, which I think might fit with careful page size attention and optimization, but might pose bandwidth and CPU issues.*

## Live updating and infinite scroll

The above is all assuming that people or a JS script refreshes with the latest tweets whenever a user visits a few times a day. But real Twitter offers live updates and infinite scrolling, can we do that?

<div class="calca">
  <p>In order to extend our estimates to live timelines, we'll assume a model of users connecting and then leaving a session open while they scroll around for a bit.

  </p><p></p><pre><code><span class="d">avg session duration</span> = <span class="n">20</span> <span class="u">minutes</span>
  </code></pre><pre><code><span class="d">live connection count</span> = avg session duration * avg new connection rate <span class="k">in</span> <span class="n">1</span> <span class="t">=&gt;</span> <span class="n ans">10,416,666.6667</span>
  </code></pre><pre><code><span class="d">poll request rate</span> = <span class="n">1</span>/<span class="u">minute</span> * live connection count <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">173,611.1111</span>/<span class="u">s</span></span>
  </code></pre><pre><code><span class="d">avg tweets per poll</span> = delivery rate / poll request rate <span class="k">in</span> <span class="n">1</span> <span class="t">=&gt;</span> <span class="n ans">6.6667</span>
  </code></pre>
  <p></p><pre><code><span class="d">frenzy push rate</span> = avg expansion * max tweet rate <span class="t">=&gt;</span> <span class="ans"><span class="n">30,000,000</span>/<span class="u">second</span></span>
  </code></pre>

  <p>To estimate the memory usage to hold all the connections I'll be using numbers from <a href="https://habr.com/en/post/460847/">this websocket server</a>.

  </p><p></p><pre><code><span class="d">tls websocket state</span> = <span class="n">41.7</span> <span class="u">GB</span> / <span class="n">4.9e6</span> <span class="k">in</span> <span class="u">byte</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">8,510.2041</span> <span class="u">byte</span></span>
  </code></pre><pre><code>live connection count * tls websocket state <span class="k">in</span> <span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">88.648</span> <span class="u">GB</span></span>
  </code></pre>
</div>

The request rate is totally fine, but the main issue is the size of each poll request has gone down, which raises our fixed overhead. We probably have enough headroom that it's fine, but we can do better either by caching the heap we use for iterating timelines and updating it with new tweets or directly pushing new tweets to open connections. This would require following the tweet stream and intersecting a B-Tree set structure of live connections with sorted follower lists from new tweets, or maybe checking a bitset for live users. This can be sharded trivially across cores and the average tweet delivery rate is low enough, if peaks are too much we can just slip on live delivery.

Infinite scrolling also performs better if we can cache a cursor at the end for each open connection, let's check how much each cached connection-cursor costs:

<div class="calca">
  <pre><code><span class="d">cached cursor size</span> = <span class="n">8</span> <span class="u">byte</span> * avg following <span class="t">=&gt;</span> <span class="ans"><span class="n">3,200</span> <span class="u">byte</span></span>
  </code></pre><pre><code>live connection count * cached cursor size <span class="k">in</span> <span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">33.3333</span> <span class="u">GB</span></span>
  </code></pre>
</div>

We can easily fit one at the start and one at the end in RAM! Given they can be loaded with one IO op it wouldn't even really slow things down if they spilled to NVMe.

## Images: Kinda!?

Images are something I initially thought definitely wouldn't fit, but I was on a roll so I checked! Let's start by looking at whether we can serve the images in people's timelines.

<div class="calca">
  <p>I can't find any good data on how many images Twitter serves, so I'll be going with wild estimates looking at the fraction and size of images in my own Twitter timeline.

  </p><p></p><pre><code><span class="d">served tweets with images rate</span> = <span class="n">1</span>/<span class="n">5</span>
  </code></pre><pre><code><span class="d">avg served image size</span> = <span class="n">70</span> <span class="u">KB</span>
  </code></pre><pre><code><span class="d">image bandwidth</span> = delivery rate * served tweets with images rate * avg served image size <span class="k">in</span> <span class="u">Gbit</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">132.7407</span> <span class="u">Gbit</span>/<span class="u">s</span></span>
  </code></pre>
  <p></p><pre><code><span class="d">total bandwidth</span> = image bandwidth + delivery bandwidth <span class="t">=&gt;</span> <span class="ans"><span class="n">134.3704</span> <span class="u">Gbit</span>/<span class="u">s</span></span>
  </code></pre><pre><code>total bandwidth * <span class="n">1</span> <span class="u">month</span> <span class="k">in</span> <span class="u">TB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">44,169.993</span> <span class="u">TB</span></span>
  </code></pre>
</div>

That seems surprisingly doable! I work with machines with hundreds of gigabits/s of networking every day and [Netflix can serve static content at 800Gb/s](http://nabstreamingsummit.com/wp-content/uploads/2022/05/2022-Streaming-Summit-Netflix.pdf). This does require aggressive image compression and resizing, which is pretty CPU-intensive, but we can actually get our users to do that! We can have our clients upload both a large and a small version of each photo when they post them and then we won't touch them except maybe to validate. Then we can discard the small version once the image drops out of the hot set.

However there's lots that could be wrong about this estimate, and there's less than 8x overhead from my average case to the most a single machine can serve. So traffic peaks may cause our system to have to throttle serving images. I think there's maybe a 40% chance I'd say it would fit without dropping images at peaks, upon much deeper investigation with Twitter internal numbers, conditional on the basics fitting.

But what would it take to store all the historical large versions?

<div class="calca">
  <p>Tweets with images are probably more popular, so my timeline probably overestimates the fraction of tweets with images that we need to store. On the other hand <a href="https://web.archive.org/web/20220414121946/https://highscalability.com/blog/2016/4/20/how-twitter-handles-3000-images-per-second.html">this page</a> says 3000/s but that would be fully half of average tweet rate so I kinda suspect that's a peak load number or something. I'm going to guess a lower number, especially cuz lots of tweets are replies and those rarely have images, and when they do they're reaction images that can be deduplicated. On the other hand we need to store images at a larger size in case the user clicks on them to zoom in.

  </p><p></p><pre><code><span class="d">stored image fraction</span> = <span class="n">1</span>/<span class="n">10</span>
  </code></pre><pre><code><span class="d">avg stored image size</span> = <span class="n">150</span> <span class="u">KB</span>
  </code></pre><pre><code><span class="d">image rate</span> = avg tweet rate * stored image fraction <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">578.7037</span>/<span class="u">s</span></span>
  </code></pre><pre><code><span class="d">image storage rate</span> = image rate * avg stored image size <span class="k">in</span> <span class="u">GB</span>/<span class="u">day</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">7,680</span> <span class="u">GB</span>/<span class="u">day</span></span>
  </code></pre><pre><code><span class="d">total storage rate</span> = tweet storage rate + image storage rate <span class="k">in</span> <span class="u">GB</span>/<span class="u">day</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">7,768</span> <span class="u">GB</span>/<span class="u">day</span></span>
  </code></pre><pre><code>total storage rate * <span class="n">1</span> <span class="u">year</span> <span class="k">in</span> <span class="u">TB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">2,837.2037</span> <span class="u">TB</span></span>
  </code></pre>
  <p>That amount of image back-catalog is way to big to store on one machine. Let's fall-back to using cold-storage for old images using the cheapest cloud storage service I know.

  </p><p></p><pre><code><span class="d">image replication bandwidth</span> = image storage rate * $<span class="n">0.01</span>/<span class="u">GB</span> <span class="k">in</span> <span class="u">$</span>/<span class="u">month</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">2,337.552</span>/<span class="u">month</span></span>
  </code></pre><pre><code><span class="d">backblaze b2 rate</span> = $<span class="n">0.005</span> / <span class="u">GB</span> / <span class="u">month</span>
  </code></pre><pre><code><span class="d">cost per year of images</span> = (image storage rate * <span class="n">1</span> <span class="u">year</span> <span class="k">in</span> <span class="u">GB</span>) * backblaze b2 rate <span class="k">in</span> <span class="u">$</span>/<span class="u">month</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">14,025.312</span>/<span class="u">month</span></span>
  </code></pre>
  <p>Luckily Backblaze B2 also <a href="https://www.backblaze.com/b2/solutions/content-delivery.html">integrates with Cloudflare</a> for free egress.

  </p>
</div>

So if we wanted to stick strictly to one server we'd need to make Twitter like SnapChat where your images dissapear after a while, maybe make our cache into a fun mechanic where your tweets keep their images only as long as people keep looking at them!

## Features that probably don't fit and are hard to estimate

### Video

Video uses more bandwidth than images, but on the other hand video compression is good and I think people view a lot less video on Twitter than images. I just don't have that data though and my estimates would have such wild error bars that I'm just not going to try and say we probably can't do video on a single machine.

### Search

Search requires two things, a search index stored in fast storage, and the CPU to look over it. Using [Twitter's own posts about posting lists](https://blog.twitter.com/engineering/en_us/topics/infrastructure/2020/reducing-search-indexing-latency-to-one-second) to get some index size estimates:

<div class="calca">
  <pre><code><span class="d">avg words per tweet</span> = tweet content avg size / <span class="n">4</span> (<span class="u">byte</span>/word) <span class="t">=&gt;</span> <span class="ans"><span class="n">35</span> word</span>
  </code></pre><pre><code><span class="d">posting list size per tweet</span> = <span class="n">3</span> (<span class="u">byte</span>/word) * avg words per tweet + <span class="n">16</span> <span class="u">byte</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">121</span> <span class="u">byte</span></span>
  </code></pre><pre><code><span class="d">index size per year</span> = avg tweet rate * posting list size per tweet * <span class="n">1</span> <span class="u">year</span> <span class="k">in</span> <span class="u">TB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">22.0972</span> <span class="u">TB</span></span>
  </code></pre>
</div>

It looks like a big NVMe machine could fit a few years of search index, although it would also need to store the raw historical tweets.

However I have no good idea how to estimate how much load Twitter's search system gets, and it would take more effort than I want to estimate the CPU and IOPS load of doing the searches. It might be possible but search is a pretty intensive task and I'm guessing it probably wouldn't fit, especially not on the same machine as everything else.

### Notifications

The trickiest part of notifications is that computing the historical notifications list on-the-fly might be tricky for big accounts, so it probably needs to be cached per user. This probably would need to go on NVMe or HDD and be updated with a background process following the write stream, which also would send out push notifications, and could fall behind during traffic bursts. This is probably what Twitter does given old notifications load slowly and very old notifications are dropped. Estimating whether this would fit would be tricky, the storage and compute budget is already stretched.

Someone who worked at Twitter noted that push notifications from celebrities and their retweets can synchronize people loading their timelines into huge bursts. Randomly delaying celebrity notifications per user might be a necessary performance feature.

### Ads

An ex-Twitter engineer who read a draft mentioned that a substantial fraction of all compute is ad-related. How much compute ads cost of course depends on exactly what kind of ML or real-time auctions go into serving the ads. Very basic ads would be super easy to fit, and Twitter makes $500M/year on "data licensing and other". How much revenue you need to run a service depends on how expensive it is! You could imagine an alternate universe non-profit Twitter which just sold their public data dumps and used that for all their funding if their costs were pushed low enough.

## Algorithmic Timelines / ML

Algorithmic timelines seem like the kind of thing that can't possibly fit, but one thing I know from [work at Anthropic](https://www.anthropic.com/) is that modern GPUs are absolutely ridiculous monsters at multiplying matrices.

I don't know how Twitter's ML works, so I'll have to come up with my own idea for how I'd do it and then estimate that. I think the core of my approach would be having a [text embedding](https://mccormickml.com/2019/05/14/BERT-word-embeddings-tutorial/) model turn each tweet into a high-dimensional vector, and then jointly optimize it with an embedding model on features about a user's activity/preferences such that tweets the user will prefer have higher dot product, then recommend tweets that have unusually high dot product and sort the feed based on that. Something like [Collaborative Filtering](https://en.wikipedia.org/wiki/Collaborative_filtering) might work even better, but I don't know enough about that to do estimates without too much research.

BERT is a popular sentence embedding model and clever people have managed to <a href="https://arxiv.org/abs/1909.10351">distill it at the same performance into a tiny model</a>. Let's assume we base our ML on those models running in bf16:

<div class="calca">
  <pre><code><span class="d">teraflop</span> = <span class="n">1e12</span> flop
  </code></pre><pre><code><span class="d">tinybert flops</span> = <span class="n">1.2e9</span> flop <span class="k">in</span> teraflop <span class="t">=&gt;</span> <span class="ans"><span class="n">0.0012</span> teraflop</span>
  </code></pre><pre><code><span class="d">a100 flops</span> = <span class="n">312</span> teraflop/<span class="u">s</span>
  </code></pre><pre><code><span class="d">a40 flops</span> = <span class="n">150</span> teraflop/<span class="u">s</span>
  </code></pre><pre><code>avg tweet rate * tinybert flops <span class="k">in</span> teraflop/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">6.9444</span> teraflop/<span class="u">s</span></span>
  </code></pre><pre><code>delivery rate * tinybert flops / a100 flops <span class="k">in</span> <span class="n">1</span> <span class="t">=&gt;</span> <span class="n ans">4.4516</span>
  </code></pre>
  <p>We need to do something with those BERT embeddings though, like check them against all the users. Normal BERT embeddings are a bit bigger <a href="https://www.sbert.net/examples/training/distillation/README.html#dimensionality-reduction">but we can dimensionality reduce them down</a>, or we could use a library like FAISS on the CPU to make checking the embeddings against all the users much cheaper using an acceleration structure:

  </p><p></p><pre><code><span class="d">embedding dim</span> = <span class="n">256</span>
  </code></pre><pre><code><span class="d">flops to check tweet against all users</span> = daily active users * embedding dim * flop <span class="k">in</span> teraflop <span class="t">=&gt;</span> <span class="ans"><span class="n">0.064</span> teraflop</span>
  </code></pre>
  <p>It's fine if the ML falls a bit behind during micro-bursts so let's use the average rate and see how much we can afford on some ML instances:

  </p><p></p><pre><code><span class="d">flops per tweet with p4d</span> = <span class="n">8</span> * a100 flops / avg tweet rate <span class="k">in</span> teraflop <span class="t">=&gt;</span> <span class="ans"><span class="n">0.4313</span> teraflop</span>
  </code></pre><pre><code><span class="d">flops per tweet with vultr</span> = <span class="n">4</span> * a40 flops / avg tweet rate <span class="k">in</span> teraflop <span class="t">=&gt;</span> <span class="ans"><span class="n">0.1037</span> teraflop</span>
  </code></pre>
</div>

Looks like the immense power of modern GPUs is up to the size of our task with room to spare! We can embed every tweet and check it against every user to do things like cache some dot products for sorting their timeline, or recommend tweets from people they don't follow. I'm not tied to this ML scheme being the best, but it shows we have lots of power available!

One way this estimate could go wrong is by using the theoretical flops. Generally you can approach that (but not actually get there) by using really large batch sizes, fused kernels and [CUDA Graphs](https://pytorch.org/blog/accelerating-pytorch-with-cuda-graphs/), but I generally work with much bigger models than this so it may not be possible! There's also a variety of things around PCIe and HBM bandwidth I didn't estimate, and maybe real Twitter uses bigger better models! Algorithmic timelines also add more load on the timeline fetching, since more tweets are candidates and the timelines need sorting, but we do have plenty of headroom there.

I can't put a number on this one because I'm confident I could fit _some_ ML, but it also probably wouldn't be as good as Twitter's actual ML and I don't know how to turn that into a prediction. Some ML designs also place much more load on other parts of the system, for example by loading lots of tweets to consider for each tweet actually delivered in the timeline.

## Bandwidth costs: They can be super expensive or free!

So far we've just checked whether the bandwidth can fit out the network cards, but it also costs money to get that bandwidth to the internet. It doesn't affect the machines it fits on, but how much does that cost?

<div class="calca">
  <p>OVHCloud offers <a href="https://us.ovhcloud.com/bare-metal/high-grade/hgr-hci-2/">unmetered 10Gbit/s public bandwidth</a> as an upgrade option from the included 1Gbit/s:
  </p><pre><code><span class="d">bandwidth price</span> = ($<span class="n">717</span>/<span class="u">month</span>)/(<span class="n">9</span><span class="u">Gbit</span>/<span class="u">s</span>) <span class="k">in</span> <span class="u">$</span>/<span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">0.0002</span>/<span class="u">GB</span></span>
  </code></pre>My friend says a normal price a datacenter might charge for an unmetered gigabit connection is $1k/month:
  <pre><code><span class="d">friend says colo price</span> = $<span class="n">1000</span>/(<span class="u">month</span>*<span class="u">Gbit</span>/<span class="u">s</span>) <span class="k">in</span> <span class="u">$</span>/<span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">0.003</span>/<span class="u">GB</span></span>
  </code></pre>This is the cheapest tier cdn77 offers without "contact us", and they're cheaper than other CDN providers:
  <pre><code><span class="d">cdn77 price</span> = (($<span class="n">1390</span>/<span class="u">month</span>)/(<span class="n">150</span> <span class="u">TB</span> / <span class="n">1</span> <span class="u">month</span>)) <span class="k">in</span> <span class="u">$</span>/<span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">0.0093</span>/<span class="u">GB</span></span>
  </code></pre><pre><code><span class="d">vultr price</span> = $<span class="n">0.01</span>/<span class="u">GB</span>
  </code></pre><pre><code><span class="d">cloudfront 500tb price</span> = $<span class="n">0.03</span>/<span class="u">GB</span>
  </code></pre>
  <p>The total cost will thus depend quite a bit on which provider we choose:

  </p><p></p><pre><code><span class="d">delivery bandwidth cost</span> = bandwidth price * delivery bandwidth <span class="k">in</span> <span class="u">$</span>/<span class="u">month</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">129.8272</span>/<span class="u">month</span></span>
  </code></pre><pre><code>delivery bandwidth cost(bandwidth price = cloudfront 500tb price) <span class="t">=&gt;</span> <span class="ans">$<span class="n">16,070.67</span>/<span class="u">month</span></span>
  </code></pre>
  <p>Things get much worse when we include image bandwidth:

  </p><p></p><pre><code><span class="d">total bandwidth cost</span> = bandwidth price * total bandwidth <span class="k">in</span> <span class="u">$</span>/<span class="u">month</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">10,704.8395</span>/<span class="u">month</span></span>
  </code></pre><pre><code>total bandwidth cost(bandwidth price = cdn77 price) <span class="t">=&gt;</span> <span class="ans">$<span class="n">409,308.6018</span>/<span class="u">month</span></span>
  </code></pre>
  <p>

  </p>
</div>

I was surprised by the fact that typical bandwidth costs are way way more than a server capable of serving that bandwidth!

But **the best deal is actually [Cloudflare Bandwith Alliance](https://www.cloudflare.com/bandwidth-alliance/)**. As far as I can tell Cloudflare doesn't charge for bandwidth, and some server providers like Vultr don't charge for transfer to Cloudflare. However if you tried to serve Twitter images this way I wonder if Vultr would suddenly reconsider their free Bandwidth Alliance pricing as you made up lots of their aggregate Cloudflare bandwidth.

## How cheaply could you serve Twitter: Pricing it out

Okay lets look at some concrete servers and estimate how much it would cost in total to run Twitter in some of these scenarios.

<div class="calca">
  <p>Basics and full tweet back catalog on one machine with bandwidth on <a href="https://us.ovhcloud.com/bare-metal/high-grade/hgr-sds-2/">OVHCloud</a>: 1TB RAM, 24 cores, 10Gbit/s public bandwidth, 360TB of NVMe across 24 drives
  </p><pre><code>$<span class="n">7,079</span>/<span class="u">month</span> <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">84,948</span>/<span class="u">year</span></span>
  </code></pre>
  <p>Basics, images, ML, replication and tweet back catalog with 8 <a href="https://www.vultr.com/products/bare-metal/#pricing">CPU Vultr machines</a> with 25TB NVMe, 512GB RAM, 24 cores and 25Gbp/s, plus one ML instance.
  </p><pre><code><span class="n">8</span> * <span class="n">2.34</span><span class="u">$</span>/<span class="u">hr</span> + $<span class="n">7.4</span>/<span class="u">hr</span> <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">228,963.2184</span>/<span class="u">year</span></span>
  </code></pre><pre><code>cost per year of images * <span class="n">5</span> <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">841,518.72</span>/<span class="u">year</span></span>
  </code></pre>
  <p>Basics, images and ML but not full tweet back catalog on one machine with a AWS P4D instance with 400Gbps of bandwith, 8xA100, 1TB memory, 8TB NVMe:
  </p><pre><code>$<span class="n">20,000</span>/<span class="u">month</span> <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">240,000</span>/<span class="u">year</span></span>
  </code></pre><pre><code>total bandwidth cost(bandwidth price = $<span class="n">0.02</span>/<span class="u">GB</span>) <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">10,600,798.32</span>/<span class="u">year</span></span>
  </code></pre>
  <p>To do everything on one machine yourself, I specced a Dell PowerEdge R740xd with 2x16 core Xeons, 768GB RAM, 46TB NVMe, 360TB HDD, a GPU slot, and 4x40Gbe networking:
  </p><pre><code><span class="d">server cost</span> = $<span class="n">15,245</span>
  </code></pre><pre><code><span class="d">ram 32GB rdimms</span> = $<span class="n">132</span> * <span class="n">24</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">3,168</span></span>
  </code></pre><pre><code><span class="d">samsung pm1733 8tb NVMe</span> = $<span class="n">1200</span> * <span class="n">6</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">7,200</span></span>
  </code></pre><pre><code><span class="d">nvidia a100</span> = $<span class="n">10,000</span>
  </code></pre><pre><code><span class="d">hdd 20TB</span> = $<span class="n">500</span> * <span class="n">18</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">9,000</span></span>
  </code></pre><pre><code><span class="d">total server cost</span> = server cost + ram 32GB rdimms + samsung pm1733 8tb NVMe + nvidia a100 + hdd 20TB <span class="t">=&gt;</span> <span class="ans">$<span class="n">44,613</span></span>
  </code></pre><pre><code><span class="d">colo cost</span> = $<span class="n">300</span>/<span class="u">month</span> <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">3,600</span>/<span class="u">year</span></span>
  </code></pre><pre><code>colo cost + total server cost/(<span class="n">3</span> <span class="u">year</span>) <span class="t">=&gt;</span> <span class="ans">$<span class="n">18,471</span>/<span class="u">year</span></span>
  </code></pre>
  <p>So you do well on the server cost but then get obliterated by bandwidth cost unless you use a colo where you can <a href="https://www.cloudflare.com/network-interconnect/">directly connect to Cloudflare</a>:

  </p><p></p><pre><code>total bandwidth cost(bandwidth cost=friend says colo price) <span class="k">in</span> <span class="u">$</span>/<span class="u">year</span> <span class="t">=&gt;</span> <span class="ans">$<span class="n">128,458.0741</span>/<span class="u">year</span></span>
  </code></pre>
  <p>
  </p>
</div>

Clearly optimizing server costs down to this level and below isn't economically rational, given the cost of engineers, but it's fun to think about. I also didn't try to investigate configuring an IBM mainframe, which stands a chance of being the one type of "machine" where you might be able to attach enough storage to fit historical images.

For reference in their [2021 annual report](https://s22.q4cdn.com/826641620/files/doc_financials/2021/ar/FiscalYR2021_Twitter_Annual_-Report.pdf), Twitter doesn't break down their $1.7BN cost of revenue to show what they spend on "infrastructure", but they say that their infrastructure spending increased by $166M, so they spend at least that much and presumably substantially more. But probably a lot of their "infrastructure" spending is on offline analytics/CI machines, and plausibly even office expenses are part of that category?

## Conclusion

The real conclusion is kinda up in the middle, but I had a lot of fun researching this project and I hope it conveys some appreciation for what hardware is capable of. I had even more fun spending tons of time reading papers and pacing around designing how I would implement a system that let you turn a Rust/C/Zig in-memory state machine like my prototype into a distributed fault-tolerant persistent one with page swapping to NVMe that could run at millions of write transactions per second and a million read transactions per second per added core.

I almost certainly won't actually build any of this infrastructure, because I have a day job and it'd be too much work even if I didn't, but I clearly love doing fantasy systems design so I may well spend a lot of my free time writing notes and drawing diagrams about exactly how I'd do it:

![Pipeline diagram]({{PAGE_ASSETS}}/pipeline.png)

*Thanks to the 5 ex-Twitter engineers, some of whom worked on performance, who reviewed this post before publication but after I made my predictions, and brought up interesting considerations and led me to correct and clarify a bunch of things! Also to my coworker [Nelson Elhage](https://nelhage.com/) who offered good comments on a draft around reasons you wouldn't do this in practice.*
