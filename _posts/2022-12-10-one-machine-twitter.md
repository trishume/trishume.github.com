---
layout: post
title: "Production Twitter on One Machine: Analyzing which features could fit"
description: ""
category: 
tags: []
---
{% include JB/setup %}

In this post I'll attempt the fun stunt of designing a system that could serve the full production load of Twitter with most of the features intact on a single (very powerful) machine. I'll start by showing off a Rust prototype of the core tweet distribution structure handling full load, and then do math around how a modern high-performance storage and networking might let you serve a close-to-fully-featured Twitter on one machine.

I want to be clear this is meant as educational fun, and not as a good idea, at least going all the way to one machine. There's some things which can't fit, and this is all theory-crafting which I'll try to make convincing, but I could easily miss something which makes some feature impossible. Real Twitter shouldn't and probably couldn't do this, although maybe could incorporate some elements to save costs and complexity.

I've now spent about a week of evenings and a couple weekends doing research, math and prototypes, gradually figuring out how to fit more and more features (images?! ML?!!) than I initially thought I could fit. We'll start with the very basics of Twitter and then go through gradually more and more features, in what I hope will be a fascinating tour of an alternative world of systems design from the typical paradigm of how web apps are built. I'll also analyze the minimum cost configuration using multiple more practical machines, and talk about the practical disadvantages and advantages of such a design.

Here's an overview of the features I'll talk about and whether I think they could fit:

- **Timeline and tweet distribution logic**: Based on a prototype, fits easily on a handful of cores when you pack recent tweets in RAM supplemented with nVME.
- **HTTP(S) request serving**: HTTP fits, HTTPS may not, session resumption via HTTP/3 should let it fit.
- **Image serving**: A close fit with rough estimates, but seems doable with multiple 100Gbit/s networking cards. Bandwidth is extremely costly.
- **Video serving**: I have no idea how much people watch videos on Twitter so can't estimate this.
- **Search**: Probably not? The index could fit on a few nVME drives per searchable year, but estimating CPU and IO load is hard.
- **Historical tweet and image storage**: Tweets fit, *but images don't*, you could fit maybe 1 quarter of images with a 48x HDD storage pod.
- **ML-based timeline**: A100 GPUs are insane and can run a decent LM against every tweet and dot-product the embeddings with every user. You could fit lots of ML on 8x A100s.

Let's get this unhinged answer to a common systems design interview question started!

## Core Tweet Distribution

Let's start with the original core of Twitter: Users posting text-based tweets to feeds which others follow with a chronological timeline. There's basically two ways you could do this:

1. The timeline page pulls tweets in reverse-chronological order from each follow until enough tweets are found, using a [heap](https://en.wikipedia.org/wiki/Heap_(data_structure)) to merge them. This requires retrieving a lot of tweets from different feeds, the challenge is making that fast enough.
2. Each tweet gets pushed into cached timelines. Pushing tweets might be faster than retrieving them in some designs, and so this might be worth the storage. But celebrity tweets have huge fanout so either need background processing or to be separately merged in, but you need a backup merge anyways in case a range of timeline isn't cached.

The [systems design interview](https://github.com/donnemartin/system-design-primer/blob/master/solutions/system_design/twitter/README.md) [answers](https://medium.com/@narengowda/system-design-for-twitter-e737284afc95) I can find take the second approach because merging from the database on pageload would be too slow with typical DBs. They use some kind of background queue to do the tweet fanout writing into a sharded timeline cache like a Redis cluster.

I'm not sure how real Twitter works but I think based on [Elon's whiteboard photo](https://miro.com/app/board/uXjVPBnTJmM=/) and some tweets I've seen by Twitter (ex-)employees it seems to be mostly the first approach using fast custom caches/databases and maybe parallelization to make the merge retrievals fast enough.

## How big is Twitter?

When you're not designing your systems to scale to arbitrary levels by adding more machines, it becomes important what order of magnitude the numbers are, so let's try to get good numbers.

So, how many tweets do we need to store? [This Twitter blog post from 2013](https://blog.twitter.com/engineering/en_us/a/2013/new-tweets-per-second-record-and-how) gives figures for daily and peak rates, but those numbers are pretty old.

Through intense digging I found a researcher who left a notebook public including tweet counts from many years of Twitter's [10% sampled stream API](https://developer.twitter.com/en/docs/twitter-api/enterprise/decahose-api/overview/decahose) and discovered the surprising fact that **tweet rate today is around the same as or lower than 2013**! Tweet rate peaked in 2014 and then declined before reaching new peaks in the pandemic. Elon recently [tweeted the same 500M/day](https://twitter.com/elonmusk/status/1598758363650719756) number which matches the Decahose notebook and 2013 blog post, so this seems to be true! Twitter's active users grew the whole time so I think this reflects a shift from a "posting about your life to your friends" platform to an algorithmic content-consumption platform.

I did all my calculations for this project using [Calca](http://calca.io/) and I'll be including all calculations as snippets from my calculation notebook.

<div class="calca">
  <pre><code><span class="d">daily active users</span> = <span class="n">250e6</span> <span class="t">=&gt;</span> <span class="n ans">250,000,000</span>
  </code></pre><pre><code><span class="d">avg tweet rate</span> = <span class="n">500e6</span>/<span class="u">day</span> <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">5,787.037</span>/<span class="u">s</span></span>
  </code></pre>
  <p>The Decahose notebook (which ends March 2022) suggests that tweet rate averages out pretty well by the level of a full day, the peak days ever in the dataset (during the pandemic lockdown in 2020) only have about 535M tweets compared to 340M before the lockdown surge.

  </p><p></p><pre><code><span class="d">major world event ratio</span> = <span class="n">535e6</span> / <span class="n">340e6</span> <span class="t">=&gt;</span> <span class="n ans">1.5735</span>
  </code></pre><pre><code><span class="d">max sustained tweet rate</span> = avg tweet rate * major world event ratio  <span class="t">=&gt;</span> <span class="ans"><span class="n">9,106.073</span>/<span class="u">s</span></span>
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
  <p></p><pre><code><span class="d">tweet content fixed size</span> = <span class="n">300</span> <span class="u">byte</span>
  </code></pre><pre><code><span class="d">tweet cache rate</span> = (tweet content fixed size + metadata size) * max sustained tweet rate <span class="k">in</span> <span class="u">GB</span>/<span class="u">day</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">264.3529</span> <span class="u">GB</span>/<span class="u">day</span></span>
  </code></pre>
  <p>Let's guess the hot set that almost all requests hit in is maybe 2 days of tweets. Not all tweets in people's timeline requests will be &lt;2 days old, but also many tweets aren't seen very much so won't be in the hot set.

  </p><p></p><pre><code><span class="d">tweet cache size</span> = tweet cache rate * <span class="n">2</span> <span class="u">day</span> <span class="k">in</span> <span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">528.7059</span> <span class="u">GB</span></span>
  </code></pre>
  <p>We also need to store the following graph for all users so we can retrieve from the cache. I need to completely guess a probably-overestimated average following count to do this.

  </p><p></p><pre><code><span class="d">avg following</span> = <span class="n">300</span>
  </code></pre><pre><code><span class="d">graph size</span> = avg following * daily active users * <span class="n">4</span> <span class="u">byte</span> <span class="k">in</span> <span class="u">GB</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">300</span> <span class="u">GB</span></span>
  </code></pre>
</div>

I think the main takeaway looking at these calculations is that many of these numbers are small numbers on the scale of modern computers!

## Hot set in RAM, rest on nVME

Given those numbers, I'll be using the "[your dataset fits in RAM](https://twitter.com/garybernhardt/status/600783770925420546?s=20)" paradigm of systems design. However it's a little more complicated since our dataset doesn't _actually_ fit in RAM.

Storing all the historical tweets takes many terabytes of storage. But probably 99+% of tweets viewed are from the last few days. This means we can use a hybrid of RAM+nVME+HDDs attached to our machine in a tiered cache. RAM will store our hot set cache and serve almost all requests, most of our performance will only depend on the RAM cache, it's common to fit 512GB-1TB of RAM in a modern machine. Modern nVME drives can store >8TB and do [over 1 million 4KB IO operations per second per drive](https://ci.spdk.io/download/performance-reports/SPDK_nvme_bdev_gen4_perf_report_2201.pdf) with latencies near 100us, and you can attach dozens of them to a machine. That's enough to serve all tweets, but we can lower CPU overhead and add headroom by just using them for long tail tweets and probably the follower graph (since it only needs one IO op per timeline request). Some extra 20TB HDDs can store the very old very cold tweets that are basically never accessed, especially at the 2x compression I saw with [zstd](http://facebook.github.io/zstd/) on tweet text from a [Kaggle dataset](https://www.kaggle.com/datasets/kazanova/sentiment140).

However, super high performance tiering RAM+nVME buffer managers which can access the RAM-cached pages almost as fast as a normal memory access are mostly only [detailed and benchmarked in academic papers](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/_my_direct_uploads/vmcache.pdf). I don't know of any good well-maintained open-source ones, [LeanStore](https://dbis1.github.io/) is the closest. You don't just need tiering logic, but also an nVME write-ahead-log and checkpointing to ensure persistence of all changes like new tweets. This is one of the areas where running Twitter on one machine is more of a theoretical possibility than a pragmatic one.

So I just prototyped a RAM-only implementation and I'll handwave away the difficulty of the buffer manager (and things like schema migrations) by saying it isn't that relevant to whether the performance targets are possible because most requests just hit RAM and [this paper shows that you can implement what is basically mmap with _much_ more efficient page faults](https://www.cs.cit.tum.de/fileadmin/w00cfj/dis/_my_direct_uploads/vmcache.pdf) for only a 10% overhead on non-faulting RAM reads.

## My Prototype

I made [a prototype](https://github.com/trishume/twitterperf) in Rust to benchmark the in-memory performance of timeline merging and show that I could get it fast enough to serve the full load. At it's core is a minimalist pooling-and-indices style representation of Twitter's data, optimized
to be fairly memory-efficient:

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
/// to cache lines for style points
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
    // This is a tiny custom pool I wrote which mmaps a vast amount of un-paged virtual
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

It also looks like adding tweets to the data structure shouldn't be a bottleneck, given it adds tweets at over 1M/core-sec when the highest peak Twitter had was 150k/sec. I don't know why adding tweets in the second batch is slower than the first, given it should be a constant time linked list add. I think it might be bottlenecked by some kind of paging in virtual memory, but I'm much worse at macOS profiling tools than Linux ones, regardless a Linux server with hugepages could eliminate that.

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

  <p>To estimate tweets per request, let's start by considering a Twitter without live timeline updating where a user opens the website or app a few times a day and then scrolls through their new tweets.

  </p><p></p><pre><code><span class="d">avg new connection rate</span> = <span class="n">3</span>/<span class="u">day</span> * daily active users <span class="k">in</span> <span class="n">1</span>/<span class="u">s</span> <span class="t">=&gt;</span> <span class="ans"><span class="n">8,680.5556</span>/<span class="u">s</span></span>
  </code></pre><pre><code><span class="d">tweets per request</span> = delivery rate / avg new connection rate <span class="k">in</span> <span class="n">1</span> <span class="t">=&gt;</span> <span class="n ans">133.3333</span>
  </code></pre>
</div>

Looks like **my estimate of the full average tweet delivery rate of Twitter is 35x less than what my 8 core laptop can fetch**! I also had chosen the average timeline size in the benchmark based on the estimate of normal timeline request sizes. It also looks like serving all the timeline RPCs is a fairly small amount of bandwidth during average load.

There's **lots of room for this to underestimate load or overestimate performance**: Peak loads could burst much higher, I could get average timeline sizes or delivery rates wrong, and a realistic implementation would have more overheads. My estimates could be wrong in lots of ways, but there's just **so much performance margin it should be fine**. My implementation even seems to scale linearly with cores, and there's another 10x left before it would start hitting memory bandwidth limitations. Right now it can only add tweets from one thread, which I only have a 20x performance margin on (from a known peak load this time), but with a little bit more effort with atomics that could be multi-core too.

This perhaps 350x safety margin, plus the fact that [high-performance batched](https://github.com/erpc-io/eRPC) [kernel-bypass RPC systems](https://smfrpc.github.io/smf/rpc/) can achieve overheads low enough to do 10M requests/core-s, means **I'm confident an RPC service which acted as the core database of simplified production Twitter could fit on one big machine**. In this most limited sense of running "Twitter" on one machine, you'd still have other stateless machines to act as web servers and API frontends to the high-performance binary RPC protocol, and of course this is only the very most basic features of Twitter.

## Conclusion-ish: Should you actually build systems this way?

If the nVME mmap-ish buffer manager plus some schema migration support existed as robust open source software it might be much simpler and easier than other approaches, but they don't so it isn't. You'd also probably want replication, but it's possible to bolt on Paxos/Raft with some replicas you stream the log to, which would need to part of the framework which isn't available.

Part of my point with this post is to gesture at the alternate universe of systems design which could exist. But there's a feedback loop where few companies in the web space scale this way, so the available open-source tooling for it is abysmal, which makes it really hard to scale this way. I think of scaling this way because I used to work for a [trading company](http://janestreet.com/), where systems scaled to handle millions of requests per second on one machine with microsecond latency kernel-bypass networking is just [the standard way to do things](https://signalsandthreads.com/multicast-and-the-markets/) and there's lots of infrastructure for it. More hardware-efficient systems are cheaper, but I think the main benefit is avoiding the classic distributed systems and asynchrony problems every attempt to split things between machines runs into (which I've [written a pseudo-manifesto on before](/2020/05/17/pipes-kill-productivity/)), which means there's potential for it to be way simpler too.

**That's all I originally planned for this post**, to show with reasonable confidence that you could fit the core tweet distribution of simplified Twitter on one machine using a prototype. But then it turned out I had tons of cores and bandwidth left over to tack on other things, so let's forge ahead and try to estimate which other features might fit using all the extra CPU!

## Directly serving web requests

The above simplified Twitter architecture doesn't serve the whole simplified Twitter from one machine, and relies on stateless frontend machines to serve the consumer API and web pages. Can we also do that on the main machine? Let's start by imagining we'll serve up a maybe 64KB static page with a long cache timeout, and uses some minimized JS to fetch the binary tweet timeline and turn it into DOM.

A [benchmark for fast HTTP servers](https://www.techempower.com/benchmarks/#section=data-r21&test=plaintext) shows a single machine handling 7M simple requests per second. That's way above our average-case estimate of 15k/s from above, so there's comfortable room to handle peaks and estimation error. Browser caches and people leaving tabs open on our static main page will probably also save us bandwidth serving it too. However HTTP is practically deprecated for providing no security.

I spent a bunch of time Googling for good benchmarks on HTTPS server performance. Almost everything I found was articles claiming [the performance penalty over HTTP is negligible](https://istlsfastyet.com/) by giving CPU overhead numbers in the realm of 1% which include application CPU. The symmetric encryption for established connections with [AES-ni instructions](https://calomel.org/aesni_ssl_performance.html) is actually fast at gigabytes per core-s, but it's the public key crypto to establish sessions that's worrying. When they do give out raw overhead numbers [they say numbers like 3.5ms to do session creation crypto](https://blogs.sap.com/2013/06/23/whos-afraid-of-ssl/) as if it's tiny, which it is for most people, but we're not being most people! That's only 300 sessions/core-s! I can find some [HTTPS benchmarks](https://h2o.examp1e.net/), but they usually simulate a small number of clients so don't test connection establishment.

What likely saves us is [session resumption and tickets](https://hpbn.co/transport-layer-security-tls/#tls-session-resumption), where browsers cache established crypto sessions so they can be resumed in future requests. This means we may only need to handle 1 session negotiation per user-week instead of multiple per day, and thus it's probably possible for an HTTPS server to hit [100k requests/core-s](https://h2o.examp1e.net/benchmarks.html) under realistic loads (before app and bandwidth overhead). So even though I can't find any actually good high-performance HTTPS server benchmarks, I'm going to say **The machine can probably directly serve the web requests too.**.

## Live updating and infinite scroll

The above is all assuming that people or a JS script refreshes with the latest tweets whenever a user visits a few times a day. But real Twitter offers live updates and infinite scrolling, can we do that?

## Images: Maybe!?

## Video and Search: Probably Not

## Algorithmic Timelines

## How cheaply could you serve Twitter: Pricing it out

- 8
-  $20k/month
