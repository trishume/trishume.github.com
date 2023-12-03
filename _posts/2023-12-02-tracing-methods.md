---
layout: post
title: "Tracing Methods"
description: ""
category: 
tags: []
assetid: tracing
---
{% include JB/setup %}

Ever wanted more different ways to trace the execution of your program? Here I catalogue a huge variety of tracing methods you can use for varying types of problems, and tracing has been such a long-standing interest of mine that some of these will novel and interesting to anyone who reads this. I'll guarantee it by including at least 3 novel tracing tools I've made and haven't shared before (look for this: <span style="color: blue;">*Tooling drop!*</span>).

What I see as the key parts of tracing are collecting data on what happened in a system, and then ideally visualizing it in a timeline UI instead of just as a text log. First I'll cover my favorite ways of really easily getting trace data into a nice timeline UI, because it's a superpower that makes all the other tracing tools more interesting. Then I'll go over ways to get that data, everything from instrumentation to binary patching to processor hardware features.

# Easily visualizing data on a trace timeline

Getting event data onto a nice zoomable timeline UI is way easier than most people think. Here's my favorite method I do all the time which can take you from logging your data to visualizing it in minutes:

```python
# from:
print("%d: %s %d" % (event_name, timestamp, duration))
# to:
with open('trace.json','w') as f:
  f.print("[")
  f.print('{"name": "%s", "ts": %d, "dur": %d, "cat": "hi", "ph": "X", "pid": 1, "tid": 1, "args": {}}\n' %
    (event_name, timestamp, duration))
  f.print("]") # this closing ] isn't actually required
```

This is the power of the [Chromium Event JSON Format](https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU/preview). It's a super simple JSON format that supports a bunch of different kinds of events, and is supported by a lot of different profile visualizer tools.

You can view the resulting tracing files in Google's Perfetto trace viewer by going to <https://ui.perfetto.dev/>, or in the older Catapult viewer (which is nicer for some traces) by going to `chrome://tracing` in Chrome. You can play around with it by [going to Perfetto](https://ui.perfetto.dev/) and clicking "Open Chrome Example" in the sidebar. Here's a screenshot showing an event annotated with arguments and flow event arrows:

[![Perfetto Screenshot]({{PAGE_ASSETS}}/perfetto.png)]({{PAGE_ASSETS}}/perfetto.png)

Me and my coworkers do this all the time at work, whip up trace visualizations for new data sources in under an hour and add them to our growing set of trace tools. We have a Python utility to turn a trace file into a clickable permanently-saved intranet link we can share with coworkers in Slack. This is easy to set up by building a copy of Perfetto and uploading to a file hosting server you control, and then putting trace files on that server and generating links using Perfetto's `?url=` parameter. We also write custom trace analysis scripts by loading the simple JSON into a Pandas dataframe.

I like Perfetto as its use of WebAssembly lets it scale to about 10x more events than Catapult (although it gets laggy), and you have the escape hatch of the native backend for even bigger traces. Its [SQL query feature](https://perfetto.dev/docs/analysis/common-queries) also lets you find events and annotate them in the UI using arbitrary predicates, including [special SQL functions](https://perfetto.dev/docs/analysis/stdlib-docs) for dealing with trace stacks.

**UI protip**: Press `?` in Perfetto to see the shortcuts. I use both `WASD` and `CTRL+scroll` to move around.

### Advanced Format: Fuchsia Trace Format

The Chromium JSON format can produce gigantic files and be very slow for large traces, because it repeats both the field names and string values for every event. Perfetto also supports the [Fuchsia Trace Format (FTF)](https://fuchsia.dev/fuchsia-src/reference/tracing/trace-format) which is a simple compact binary format with an incredible spec doc that makes it easy to produce binary traces. It supports interning strings to avoid repeating event names, and is designed around 64 byte words and supports clock bases so that you can directly write timestamp counters and have the UI compute the true time.

When I worked at Jane Street I [used this to log instrumentation events to a buffer directly in FTF](https://github.com/janestreet/tracing/blob/master/zero/writer.ml) as they occurred in <10ns per span (it would have been closer to 4ns if it wasn't for OCaml limitations).

### Advanced Format: Perfetto Protobuf

Another format which is similarly compact, and also supports more features is [Perfetto's native Protobuf trace format](https://github.com/google/perfetto/blob/master/protos/perfetto/trace/perfetto_trace.proto). It's documented only in comments in the proto files and is a bit trickier to figure out, but might be a bit easier to generate if you have access to a protobuf library. It enables access to advanced Perfetto features like including callstack samples in a trace, which aren't available with other formats. It's slower to write than FTF, although Perfetto has a [ProtoZero](https://perfetto.dev/docs/design-docs/protozero) library to make it somewhat faster.

# Tracing Methods

Now lets go over all sorts of different neat tracing methods! I'll start with some obscure and interesting low level ones but I promise I'll get to some more broadly usable ones after.

## Hardware breakpoints with perftrace

For ages, processors have supported **hardware breakpoint registers** which let you put in a small number of addresses and have the processor interrupt itself when any of them are hit. Linux exposes this functionality through `ptrace` but also through the [`perf_event_open` syscall](https://man7.org/linux/man-pages/man2/perf_event_open.2.html) and the [`perf record` command](https://man7.org/linux/man-pages/man1/perf-record.1.html). You can record a process like `perf record -e \mem:0x1000/8:rwx my_command` and view the results with `perf script`. It costs about 3us of overhead every time a breakpoint is hit.

<span style="color: blue;">*Tooling drop!*</span> I wrote [a tiny Python library called perftrace](https://github.com/trishume/perftrace) with a C stub which calls the `perf_event_open` syscall to record hardware breakpoint hits and also collect register values when the breakpoints were hit.

It currently only supports execution breakpoints but you can also breakpoint on reads or writes of any memory and it would be [easy to modify the code to do that](https://github.com/trishume/perftrace/blob/d074e65bf71e8af10335164111969f96263d283a/perftrace.c#L61). Hardware breakpoints are basically the only way to watch for accessing a specific memory address at a fine granularity which doesn't add overhead to code which doesn't touch that memory.

## GDB scripting

In addition to using it manually, you can automate the process of following the execution of a program using debugger breakpoints by using GDB's Python scripting interface. This is slower than perf breakpoints but gives you the ability to inspect and modify memory when you hit breakpoints. [GEF](https://github.com/hugsy/gef) is an extension to GDB that in addition to making it much nicer in general, also extends the Python API with a bunch of handy utilities.

<span style="color: blue;">*Tooling drop!*</span> [Here's an example GDB script I wrote using GEF which gives examples of how to puppeteer, trace and inspect a program](https://gist.github.com/trishume/fe3b3b90a7e524c976ecb98053bb7f86)

## Intel Processor Trace

[Intel Processor Trace](https://easyperf.net/blog/2019/08/23/Intel-Processor-Trace) is a hardware technology on Intel chips since Skylake which allows recording a trace of *every instruction the processor executes* via recording enough info to reconstruct the control flow in a super-compact format, along with fine-grained timing info. It has extremely low overhead since it's done by hardware and writes bypass the cache so the only overhead is reducing main memory bandwidth by about 1GB/s, I see no noticeable overhead at all on most program benchmarks I've tested.



You can access a dump of the assembly instructions executed in a recorded region using [`perf`](https://man7.org/linux/man-pages/man1/perf-intel-pt.1.html), [`lldb`](https://lldb.llvm.org/use/intel_pt.html) and [`gdb`](https://easyperf.net/blog/2019/08/30/Intel-PT-part2).

### magic-trace

However this isn't useful to most people, so when at Jane Street I created [magic-trace](https://github.com/janestreet/magic-trace) along with my intern Chris Lambert, which generates a trace file (using FTF and Perfetto as described above) which visualizes *every function call* in a program execution. Jane Street generously open-sourced it so anyone can use it! Since then it's been extended to support tracing into the kernel as well. I wrote [a blog post about how it works for the Jane Street tech blog](https://blog.janestreet.com/magic-trace/).

![magic-trace demo](https://github.com/janestreet/magic-trace/raw/master/docs/assets/stage-3.gif)

Processor Trace can record to a ring buffer, and `magic-trace` uses the hardware breakpoint feature described earlier to let you trigger capture of the last 10ms whenever some function that signals an event you want to look at happened, or when the program ends. This makes it great for a bunch of scenarios:

- Debugging rare tail latency events: Add a trigger function call after something takes unusually long, and then leave magic-trace attached in production. Because it captures everything you'll never have not logged enough data to identify the slow part.
- Everyday performance analysis: A full trace timeline can be easier to interpret than a sampling profiler visualization, especially because it displays the difference between a million fast calls to a function and one slow call.
    - It's typical to find performance problems on systems that had only ever been analyzed with a sampling profiler by noticing the first time you magic-trace the program that many functions are being called more times than expected or in locations you didn't expect.
- Debugging crashes: When a program crashes for reasons you don't understand, you can just run it under magic-trace and see every function call leading up to the crash, which is often enough to figure out why the crash happened without adding extra logging or using a debugger!

If you want to modify magic-trace to suit your needs, it's open-source OCaml. And if you like Rust more than OCaml someone made a simple Rust port called [perf2perfetto](https://github.com/michoecho/perf2perfetto).

Unfortunately, Processor Trace isn't supported on many virtual machines that use compatible Intel Hardware. Complain to your cloud provider to add support in their hypervisor or try bare-metal instances!

## Instrumentation-based tracing profilers

What most people use to get similar benefits to magic-trace traces, especially in the gamedev industry, is low-overhead instrumentation-based profilers with custom UIs. One major advantage of instrumentation-based traces is they can contain extra information about data and not just control flow, putting arguments from your functions into the trace can be key for figuring out what's going on. These tools often support including other data sources such as OS scheduling info, CPU samples and GPU trace data. Here's my favorite tools like this and their pros/cons:

### [Tracy](https://github.com/wolfpld/tracy)

[![Tracy screenshot](https://github.com/wolfpld/tracy/raw/master/doc/profiler.png)](https://github.com/wolfpld/tracy)

- Cross platform, including good Linux sampling and scheduling capture
- Overhead of only 2ns/span, supports giant traces with hundreds of millions of events
- Really nice and fast UI with tons of features (check out the [demo](https://www.youtube.com/watch?v=30wpRpHTTag) [videos](https://www.youtube.com/watch?v=_hU7vw00MZ4) in the readme)
- Integrates CPU sampling with detailed source and assembly analysis
- Popular so there are bindings in non-C++ languages like [Rust](https://docs.rs/tracing-tracy/latest/tracing_tracy/) and [Zig](https://github.com/nektro/zig-tracy).
- Con: Only supports a single string/number argument to events
- Con: Timeline is overly aggressive in collapsing small events into squiggles ([see my post on this](https://thume.ca/2021/03/14/iforests/)).

### [Optick](https://github.com/bombomby/optick)

[![Optick screenshot](https://github.com/bombomby/brofiler/raw/gh-pages/images/VideoThumbnail.jpg)](https://www.youtube.com/watch?v=p57TV5342fo)

- Cross-platform, lots of features, very nice UI
- Supports multiple named arguments per event
- Con: Not as fleshed-out for non-game applications
- Con: sampling integration only works on Windows

### [Perfetto](https://perfetto.dev/docs/instrumentation/tracing-sdk)

- Perfetto UI is nice, events can include arguments and flow event arrows
- Integrates with other Perfetto data sources like OS events and sampling
- Con: Higher overhead of around 600ns/span when tracing enabled
- Con: UI doesn't scale to traces as large as the above two programs

### Other programs

There's a bunch more similar small programs that generally come with their own instrumentation library and their own WebGL profile viewer. These are generally more lightweight and can be easier ot integrate. For example [Spall](https://gravitymoth.com/spall/spall-web.html), [microprofile](https://github.com/jonasmr/microprofile), [Remotery](https://github.com/Celtoys/Remotery), [Puffin (Rust-native)](https://github.com/EmbarkStudios/puffin), [gpuviz](https://github.com/mikesart/gpuvis). I must also mention the [OCaml tracing instrumentation library I wrote for Jane Street](https://github.com/janestreet/tracing) which has overheads under 10ns/span via a compile-time macro like the C++ libraries.

## eBPF

### bcc

### bpftrace

### bpftime

https://github.com/eunomia-bpf/bpftime

https://ebpf.io/applications/

## Binary Instrumentation

### Frida

### e9patch

## LD_PRELOAD

## QEMU Instrumentation

### cannoli

### QEMU TCG Plugins

### usercorn

## Sampling Profilers

- perf
- pprof
- https://github.com/mstange/samply

## Distributed Tracing

# Visualization Tools

## Catapult

## Perfetto

## SpeedScope

## Others

- Firefox Profiler
- Trace Compass
- Rerun
- pprof
