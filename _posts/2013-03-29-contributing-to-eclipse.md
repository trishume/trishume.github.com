---
layout: post
title: "Contributing to Eclipse"
description: ""
category: 
tags: []
---
{% include JB/setup %}

## Background

When most programmers think of Eclipse they think of the Java IDE but Eclipse is
actually a huge group of projects with very little relation to each other except
that they are all managed by The Eclipse Foundation.

I had the privilege of working for [The Eclipse
Foundation](http://eclipse.org/org/foundation) this past semester at school as a
High School
co-op job. The Foundation does not actually employ developers but since I was
working for free I was able to actually work on the code base with expert
guidance from my supervisor Wayne Beaton at the Foundation.

This was an interesting experience. I worked on fixing bugs in various Eclipse
projects including one that had been around for 11 years and likely affected
thousands of developers. In this article I hope to share some of the knowledge I
gathered about contributing to Eclipse projects.

## One Does Not Simply Compile Eclipse

For my first week my supervisor had the idea of using me to figure out how difficult
it is to be a new contributor to Eclipse. I was given a bug to fix and no other
instruction.

I started off with the assumption that I would have to compile Eclipse. Which
seemed reasonable enough given my experience with other open source projects.

Unfortunately, I was **dead wrong**. I spent many hours reading through outdated
wiki pages and filling up my hard drive with build files until my supervisor
eventually told me what I had only seen briefly mentioned in a paragraph full of
adjectives: **you do not need to compile Eclipse to develop it**.

## The One True Path

Eclipse is actually developed within Eclipse using a plugin called the Plugin
Development Toolkit (PDT). This sounds like it is only useful for developing
plugins, and it is.

The thing is Eclipse is actually almost entirely made up of Eclipse plugins.
This is an excellent architecture once you start developing for it but it is not
necessarily easy for new contributors.

## Working on an Eclipse Project

Before following this procedure make sure you have the PDT plugin and the EGit
plugin installed.

This procedure only applies to plugins that are plugins to the Eclipse IDE.

1. Clone the right repository in EGit.
  - You can find all the repositories at <http://git.eclipse.org/c/>
  - You only need the repository you will be working on directly, it will use
    the binary plugins in your Eclipse installation for dependencies.
  - Make sure to select the import projects box in the clone dialog.
2. Create a new 'Eclipse Application' run configuration.
3. Make changes to the code and run or debug your configuration.

This will launch another copy of Eclipse with the changes that you have made.
You can even set breakpoints and run it in the debugger.

## Bugzilla

All Eclipse bugs are tracked on <http://bugs.eclipse.org/>. They use the loose
definition of the term 'bug' that includes feature requests and things that
should be made better.

Any code contribution you make as a non-commiter (which you probably are if you
are reading this article) must be made through Bugzilla. If you write a new feature
and want to contribute it you should create a new bug saying the feature should
be added and immediately submit a patch file.

You can either submit a patch by attaching a patch file to the bug or on some
projects by submitting a pull request with the bug id in the title to the Github
mirror of the project. Keep in mind that not all projects have active committers
on Github to see your pull request so you may want to link to it from the bug.

### Next Steps

With any luck a committer will see your patch and write a comment about it.
This could take anywhere from a day to many months depending on how active the
project is.

On some of my patches I got a helpful response within hours, on others I only
got a reply weeks later and some of my patches are still sitting there to this
day...

The committer may recommend some changes to your patch to fix bugs or make it better.
Once your patch is good enough the developer will commit it. They may ask you
some questions about originality or have you fill out a form as part of the
intellectual property process. I think my supervisor said they should have had me fill out a form but they never did.

Congratulations! You may now enjoy the warm fuzzy feeling that comes from
contributing to an Eclipse project!

## My Own Journey

I submitted patches for many bugs during my time at The Foundation.
I fixed many small bugs like having the Javadoc for a function show up in the
Javadoc view when you select it with autoComplete.

Some of my larger achievements:

- Helping fix bugs related to Retina displays so that Eclipse displays crisply
  on new Retina MacBook Pros.
- Updating the Eclipse Ruby DLTK project to support debugging ruby 1.9+ using
  the 'debugger' gem instead of the outdated 'ruby-debug' gem on 1.8.

My biggest achievement was fixing an 11 year old bug that affects any Eclipse
user who has ever had to forcefully stop Eclipse and then lost their place in
what they were working on. [Bug 2369](https://bugs.eclipse.org/bugs/show_bug.cgi?id=2369).

Eclipse is very good at auto-saving state when it is shut down properly but many
users like myself keep Eclipse open constantly and only ever start it up again
when it crashes or our computer crashes.

The reason nobody experienced had taken it on was probably because it was very
difficult. I toiled for weeks chasing through layer upon layer of abstraction trying to
untie the workbench save code from the shutdown code.

I eventually settled upon copying the entire workbench model and then cleaning
up the parts that were not supposed to be persisted in the copy. I gradually
found what parts had to be removed from the model by chasing the causes of
various duplicate menu items and toolbars.

I managed to fix the bug just one week before my coop term ended. And I got to
feel that warm fuzzy open source contribution feeling knowing that I made a
difference people would notice. And they did:

<div>
<blockquote class="twitter-tweet"><p>@<a href="https://twitter.com/mmmandel">mmmandel</a> wow, a 4 digit bug number. You can almost see the evolution of the platform UI team by reading through the comments.</p>&mdash; Ian Bull (@irbull) <a href="https://twitter.com/irbull/status/312241966857482240">March 14, 2013</a></blockquote>
<script src="//platform.twitter.com/widgets.js" charset="utf-8"></script>
</div>




