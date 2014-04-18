---
layout: post
title: "Hacking Math Homework"
description: "Writing Programs For Math Class"
assetid: mathSummative
category:
tags: [english, scripting]
---
{% include JB/setup %}

Many high school students complain about boring and repetitive homework, but I've found a fun way of dealing with this that I find actually helps me understand concepts even better.
When faced with large rote assignments I write programs to complete the homework like no human can: instantly, perfectly and on a large scale.
In the past I have written written [Literary Analysis Visualizations](/2013/01/24/hacking-english-class/), Punnet Square generators and [Graphing Programs](http://github.com/trishume/handyGraph).

Most of the time it takes way more time to write the program than it would take to do the homework but I end up learning a lot more and having more fun.
Recently I wrote my wrote my most outrageous program yet, it took 10 times longer than it should have and blew away my teacher and class.

Part of my Advanced Functions class summative this year was to create a series of piecewise functions that when graphed produce
a picture. Some examples given were line drawings of a smiley face and the Batman symbol. But I had an idea that would go beyond the intended simple line drawings so I spent my weekend implementing it.

I wrote a program that takes an image and composes equations of varying densities into hundreds of massive piecewise functions
so that when you graph them on a very large canvas and zoom out they replicate the image in greyscale. The output looks like this:

![Obama]({{PAGE_ASSETS}}/obama_small.png)
[![Function Collage]({{PAGE_ASSETS}}/collage_small.png)]({{PAGE_ASSETS}}/collage_small.png)

## Additional Resources

Another part of the program outputs a massive Latex document with all the large piecewise functions that produces a huge PDF.
You can [download a PDF]({{PAGE_ASSETS}}/summative.pdf) that explains all the parts and has some more examples.

## The Program

The program is written in Python and uses matplotlib, Numpy and Pillow.
Excuse the terrible code with the manual constants, global variables and terrible logic structure.
Not only was I learning Python while writing this but I had to finish the program by the next day and then
never use the program again.

<script src="https://gist.github.com/7881306.js">
</script>
