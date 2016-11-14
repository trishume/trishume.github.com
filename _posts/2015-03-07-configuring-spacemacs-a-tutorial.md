---
layout: post
title: "Configuring Spacemacs: A Tutorial"
description: "A guide to configuring the Spacemacs Emacs distribution."
category: howto
tags: [spacemacs, tutorial, emacs]
---
{% include JB/setup %}

**Edit:** Some things in this post are now outdated. I'm currently using Sublime Text with Vim keybindings instead of Spacemacs so I haven't been keeping up. I've fixed some things (Thanks Fabien!) but others may remain. If you want to fix something outdated [submit a PR to my website](https://github.com/trishume/trishume.github.com/blob/master/_posts%2F2015-03-07-configuring-spacemacs-a-tutorial.md).

A few months ago I switched to using [Spacemacs](https://github.com/syl20bnr/spacemacs) as my text editor of choice. It has great vim keybindings and extensive default configs for a variety of packages. I've become one of the top contributors to Spacemacs and I've learned a few things about configuring it in the process. This post will function as a tutorial to get you started with configuring Spacemacs to your liking.

You can get started using Spacemacs by following the installation instructions in the [readme](https://github.com/syl20bnr/spacemacs) and perusing the in-depth [documentation](https://github.com/syl20bnr/spacemacs/blob/master/doc/DOCUMENTATION.org).

# The .spacemacs File

The `~/.spacemacs` file is your main starting point for configuring Spacemacs. If you don't have this file you can install a template pressing `SPC : dotspacemacs/install RET` in Spacemacs, where `SPC` is space and `RET` is the enter key. At any time you can press `SPC f e d` to edit this file.

The template comes with many variables that you can customize and use to set things like font sizes and window preferences. Once you are done editing, save the file and either press `SPC f e R` in the file to reload it or just restart Spacemacs.

Some parts of this file are more important than others:

## dotspacemacs/user-config

This function is run after Spacemacs sets itself up, in here you can customize variables and activate extra functionality you want. Perhaps the most important thing to know is that this is generally where you can paste random snippets of Emacs Lisp you find on the internet. If a page says to put a snippet into your `init.el` file **don't do that**, put it in `dotspacemacs/user-config` instead.

Another thing this function is useful for is setting the default state of some toggleable editor preferences. If you press `SPC t` you will see some of the things you can toggle, these include line numbers, line wrapping, current line highlight, etc...

Most of these toggles actually enable and disable "minor modes", if you want some of these on or off by default you can put things like these in your `dotspacemacs/user-config` function:

{% highlight lisp %}
(defun dotspacemacs/user-config ()
  (global-hl-line-mode -1) ; Disable current line highlight
  (global-linum-mode)) ; Show line numbers by default
{% endhighlight %}

## dotspacemacs-configuration-layers

This brings us to **configuration layers** the most core concept of Spacemacs. Not all parts of Spacemacs are enabled by default, there are a large number of user contributed "layers" that add packages and configs for things like programming languages, external tools and extra functionality. Layers specify which packages they want Spacemacs to install for them, how to load the package and often include some default configs to make the package integrate well with the rest of Spacemacs.

The `dotspacemacs-configuration-layers` variable, set in the `dotspacemacs/layers` function near the top of the template is where you specify which layers you want to include. When you find yourself wondering "does Spacemacs come with support for X?" you can simply type `SPC f e h` and search through the built in layers. Once you find one you want to include simply include it in the list in the variable set statement. This is what mine looks like:
{% highlight lisp %}
dotspacemacs-configuration-layers '(extra-langs auctex
  company-mode git c-c++ haskell html javascript ruby ycmd
  smex dash colors lua trishume markdown finance)
{% endhighlight %}
Yah, I use a lot of layers; you should too, they're pretty important! You can see staples like "html" and "ruby" as well as fancier functionality ones like "company-mode". Try looking through [the "layers" directory](https://github.com/syl20bnr/spacemacs/tree/master/layers) to see all the available contributed layers and their Readme's and source code.

# Your Own Layers!

You too could be the author of your very own layer! In fact, you'll likely find you want to after you have used Spacemacs for a while. The most important purpose of layers is adding [MELPA](http://melpa.org/) packages and the configuration and keybindings for them. **Don't** try and just install packages with the default Emacs package manager like the internet might tell you to do!

If you want to install a package you found online, like [2048-game](http://melpa.org/#/2048-game), you'll want to create a layer that includes the package and sets it up. Another option for small things is to add the package to the `dotspacemacs-additional-packages` list. There are a couple of places you can put this layer, which is really just a folder with some emacs lisp files:

## The "private" Directory

This is a folder in the main Spacemacs directory where you can put configuration layers for your own personal use.
You can create a template layer in this directory using `<SPC> : configuration-layer/create-layer RET`.

The descriptive comments in the template `packages.el` do a pretty good job of explaining what to do. Basically you add the package you want to include to the `yourlayernamehere-packages` list and then create `yourlayernamehere-init-yourpackagenamehere` functions where you use [use-package](https://github.com/jwiegley/use-package) to load the package and set it up. Take a look at [existing layers](https://github.com/syl20bnr/spacemacs/tree/master/layers/%2Btools/finance) for examples of how to set up packages and keybindings.

Once you have written a layer **you have to load it in .spacemacs** just like any other layer. Add your layer's name to `dotspacemacs-configuration-layers`.

## dotspacemacs-configuration-layer-path

If you want to keep your layers in a git repository or Dropbox sync or some other folder, you can use the `dotspacemacs-configuration-layer-path` variable in `.spacemacs` to set another folder where you can load layers from. Then you can just copy the layer directory that Spacemacs puts in the private directory into this directory and Spacemacs will be able to load it from there.

## The "contrib" Directory

If you are adding some awesome new functionality to Spacemacs, which you probably are, you should seriously consider contributing it back. This is how Spacemacs has grown into the awesome distribution that it is. Don't worry about people finding it hacky or not useful, we won't mind and might even help you make it better.

This is what I do, I'm proud to say that I only have 1 private layer, [every](https://github.com/syl20bnr/spacemacs/tree/064a598bff56f7cef1ac2ddf1c43684357dde56a/contrib/company-mode) [other](https://github.com/syl20bnr/spacemacs/tree/064a598bff56f7cef1ac2ddf1c43684357dde56a/contrib/lang/extra-langs) [layer](https://github.com/syl20bnr/spacemacs/tree/064a598bff56f7cef1ac2ddf1c43684357dde56a/contrib/ycmd) [I've](https://github.com/syl20bnr/spacemacs/tree/064a598bff56f7cef1ac2ddf1c43684357dde56a/contrib/auctex) [written](https://github.com/syl20bnr/spacemacs/tree/064a598bff56f7cef1ac2ddf1c43684357dde56a/contrib/ranger-control) has been contributed back to Spacemacs. It's as simple as forking Spacemacs, adding your layer to `contrib` and submitting a Github pull request.

## Tips For Writing Layers

There's a couple things that are nice to know when writing layers. The most important thing to know is some of the features of [use-package](https://github.com/jwiegley/use-package). You use this in the init functions in `packages.el` to load the package and set it up. The function takes a package name and some attributes containing things like functions to run on load. You use use-package **instead of** doing whatever loading step the package readme tells you to do, generally you don't include things like `(require 'blah)`.

### Basic Format

{% highlight lisp %}
(defun finance/init-ledger-mode ()
  (use-package ledger-mode
    ; Use :mode to set language modes to automatically activate on certain extensions
    :mode ("\\.\\(ledger\\|ldg\\)\\'" . ledger-mode)
    ; :defer t activates lazy loading which makes startup faster
    :defer t
    ; The code in :init is always run, use it to set up config vars and key bindings
    :init
    (progn ; :init only takes one expression so use "progn" to combine multiple things
      ; You can configure package variables here
      (setq ledger-post-amount-alignment-column 62)
      ; Using evil-leader/set-key-for-mode adds bindings under SPC for a certain mode
      ; Use evil-leader/set-key to create global SPC bindings
      (evil-leader/set-key-for-mode 'ledger-mode
        "mhd"   'ledger-delete-current-transaction
        "m RET" 'ledger-set-month))
    :config ; :config is called after the package is actually loaded with defer
      ; You can put stuff that relies on the package like function calls here
      (message "Ledger mode was actually loaded!")))
{% endhighlight %}

### Things that aren't packages

If you want to bundle up some snippet or config that isn't related to a package you can use the `config.el`
file in the layer. In here you can just put Emacs Lisp code and functions that will be evaluated when a layer is loaded.

### Dependencies

Sometimes you want to hook something in your layer into another package. This is most common for making sure your alayer works well with default packages like smartparens. To do this you'll want to use `eval-after-load`. [Here's an example](https://github.com/syl20bnr/spacemacs/blob/064a598bff56f7cef1ac2ddf1c43684357dde56a/contrib/ansible/packages.el#L24) of a package adding extra functionality to `yaml-mode`.

# Other Information

This guide hopefully gave you enough info to get started, but there's so much more to Spacemacs that isn't here. There's a bunch of other sources of information that you should look at if you can't find what you want:

## The Gitter Chat

Please visit the [Gitter chat room](https://gitter.im/syl20bnr/spacemacs) if you have any questions about configuring or using Spacemacs that you can't figure out, or just come to chat with other Spacemacs users. There's always tons of knowledgeable people there, including the awesome maintainer @syl20bnr, who will help you out.

## The Documentation

Most of these layer concepts and mechanics are explained in depth in the massive [Documentation](https://github.com/syl20bnr/spacemacs/blob/master/doc/DOCUMENTATION.org). It also has information on lots of the functionality available in Spacemacs.

## The Source Code!

If you want deep insight into the workings of Spacemacs you should really take a look at the [source code](https://github.com/syl20bnr/spacemacs) on Github. The main difference between me and the average Spacemacs user is that I have read lots of the source and thus I know a lot about how Spacemacs works. I swear it's really not that complicated, you'll discover that most of Spacemacs is actually just the `spacemacs` layer which is just like any other configuration layer except it is included by default. You can also read the code for the contrib layers for ideas, although the techniques these use might be less consistent since they were written by lots of differnt people, many of them newbies. For a good start I recommend skimming through this [packages.el](https://github.com/syl20bnr/spacemacs/blob/master/layers/%2Bdistributions/spacemacs-base/packages.el) file. You can also use `SPC h SPC` to search for layers and hit enter to visit their source.

# Conclusion

I hope this helped you on your way to become a Spacemacs power-user. This guide was rather specific to configuration but I plan on maybe writing other tutorials on basic use and other tips. Don't forget to say hi to me and all the other awesome Spacemacs people in the [Gitter chat](https://gitter.im/syl20bnr/spacemacs), we always love hearing from other Spacemacs users!
