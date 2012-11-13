---
layout: page
title: Main
---
{% include JB/setup %}
{% capture GITHUB %}http://github.com/{{site.author.github}}{% endcapture %}

> I am a student at Bell High School in Ottawa, Canada interested in programming, electronics and science.

# About Me
## Things I Do

- I develop iPad apps for psychological research at [iPad Experiments](http://hume.ca/ix)
- I write programming contests in *Ruby*
- I program random things and push them To-Do [Github]({{GITHUB}})
- I develop [Open Turing](http://tristan.hume.ca/openturing), an open source fork of the Turing language.

# Projects

A selection of projects I have worked on:

[Improsent]({{BASE_PATH}}/improsent)
: A web app that allows you to improvise presentation slides while you present.

[The New Open Turing Editor](https://github.com/Open-Turing-Project/turing-editor-qt)
: A new editor for Open Turing written in Qt.

[DoubleVision]({{GITHUB}}/doubleVision)
: A ruby gem that that manipulates PNG files to create magic thumbnails.

[SquareGame]({{GITHUB}}/SquareGame)
: A simple, addictive cocos2d iPhone game.

[UTTT]({{GITHUB}}/Ultimate-Tic-Tac-Toe)
: A java applet for 9-board tic-tac-toe with a simple A.I.

[eyeLike]({{GITHUB}}/doubleVision)
: A work-in-progress eye tracker that requires only a normal webcam.

#Blog

<ul class="posts">
  {% for post in site.posts limit:10 %}
    <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ BASE_PATH }}{{ post.url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

# Stuff I've Done

{% include projects.md %}


