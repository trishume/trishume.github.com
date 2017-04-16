---
layout: page
title: Tristan's Site
---
{% include JB/setup %}
{% capture GITHUB %}http://github.com/{{site.author.github}}{% endcapture %}

> I am a student developer interested in programming, finance and electronics.
> I write Ruby, iPad, Rust, Qt and JS apps for fun, work and homework.
> I'm currently studying CS at the University of Waterloo.

# About Me

- I write open source [web](/indexView) [apps](http://ratewith.science/), [libraries](https://github.com/trishume/syntect) and [iPad apps](/stashline/).
- I frequently do [internships](/resume) at a variety of companies.
- I've done [research on eye tracking]({{GITHUB}}/PolyMouse) and wrote [webcam eye tracking code]({{GITHUB}}/eyeLike).
- I design and build things like [my custom keyboard](/2014/09/08/creating-a-keyboard-1-hardware/).
- I occassionally give [talks](/talks/).
- I program things and put them on [Github]({{GITHUB}}).

# Personal Projects

These are some of my personal software projects.

[StashLine](/stashline/)
: An iPad app for personal finance planning.

[IndexView](/indexView)
: A web app for visualizing long term stock market data.

[Rate With Science](http://ratewith.science/)
: A fun web app for path finding the Wikipedia link graph.

[The Open Turing Compiler](https://github.com/Open-Turing-Project/OpenTuringCompiler)
: An LLVM-based compiler for [Turing](https://en.wikipedia.org/wiki/Turing_(programming_language)) and an associated Qt-based editor.

[Dayder](http://dayder.thume.ca/)
: A fun web app for quickly finding spurious correlations in 390,000+ data sets.

[Syntect](https://github.com/trishume/syntect)
: A Rust library for fast high quality syntax highlighting using Sublime Text's grammar format.

[DoubleVision]({{GITHUB}}/doubleVision)
: A ruby gem that that manipulates PNG files to create magic thumbnails.

[Pro](http://github.com/trishume/pro)
: A Ruby command line tool for managing Git repositories.

# Recent Blog Posts

<ul class="posts">
  {% for post in site.posts limit:10 %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

# Stuff I've Done

{% include projects.md %}
