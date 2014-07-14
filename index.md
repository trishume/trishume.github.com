---
layout: page
title: Tristan's Site
---
{% include JB/setup %}
{% capture GITHUB %}http://github.com/{{site.author.github}}{% endcapture %}

> I am a Canadian student developer interested in programming, economics and electronics.
> I write iPad, Ruby, Qt and Rails apps for fun, work and homework.

# About Tristan

- I write iPad apps [like this one for personal finance planning.](/stashline/)
- I am currently working on an open source [eye tracker.]({{GITHUB}}/eyeLike)
- I develop iPad apps for psychological research at [iPad Experiments](http://hume.ca/ix)
- I use Ruby to write programming contests like the Google Code Jam.
- I am a member of the Ottawa Group of Ruby Enthusiasts and occassionally give [lightning talks](/2013/02/06/ottawa-ruby-lightning-talks/)
  there.
- I program random things and put them on [Github]({{GITHUB}})
- I develop [Open Turing](http://tristan.hume.ca/openturing), an open source fork of the Turing language.

# Personal Projects

These are some of my personal software projects.

[StashLine](/stashline/)
: An iPad app for personal finance planning.

[Pro](http://github.com/trishume/pro)
: A Ruby command line tool for managing Git repositories.

[Improsent]({{BASE_PATH}}/improsent/)
: A web app that allows you to improvise presentation slides while you present.

[The New Open Turing Editor](http://tristan.hume.ca/openturing)
: An improved implementation of the Turing language, including a new editor written in Qt.
  I also wrote a [compiler](https://github.com/Open-Turing-Project/OpenTuringCompiler).

[DoubleVision]({{GITHUB}}/doubleVision)
: A ruby gem that that manipulates PNG files to create magic thumbnails.

[eyeLike]({{GITHUB}}/eyeLike)
: A work-in-progress eye tracker that requires only a normal webcam.

# Tristan's Blog

<ul class="posts">
  {% for post in site.posts limit:10 %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}/">{{ post.title }}</a></li>
  {% endfor %}
</ul>

# Stuff I've Done

{% include projects.md %}
