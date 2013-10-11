---
layout: post
title: "Typing Faster"
description: "Learn to type the correct way by taking away your training wheels."
category:
tags: [dvorak, typing]
assetid: typing
tangle: true
---
{% include JB/setup %}

What if you improved your typing speed from
<span class="TKAdjustableNumber" data-var="curWpm" data-min="5" data-max="100" data-step="5"> wpm</span>
to <span class="TKAdjustableNumber" data-var="newWpm" data-min="5" data-max="200" data-step="5"> wpm</span>?

Over <span class="TKAdjustableNumber" data-var="career" data-min="1" data-max="40"> years</span> typing <span class="TKAdjustableNumber" data-var="dailyTyping" data-min="5" data-max="500"> minutes</span> per work day you could:

- Spend <b data-var="ratio2" data-format="%.2f"> times</b> as much time typing saving <b data-var="savedHours" data-format="%.0f"> hours</b>.
- Or type <b data-var="ratio1" data-format="%.1f"> times</b> as many words jumping from <b data-var="totalWords" data-format="%.2f"> million words</b> typing to <b data-var="newWords" data-format="%.2f"> million words</b>.

If you earn <span class="TKAdjustableNumber" data-var="pay" data-min="1" data-max="400" data-format="$%.0f">&#8203;</span> per hour the extra productivity is worth <b data-var="worth" data-format="$%.0f">&#8203;</b>.

## Learning to Type Efficiently in 3 Weeks

Are you satisfied with your current typing speed? Do you even know what speed you type at?
If you don't know go test yourself on [KeyHero](http://www.keyhero.com/), I'll wait.
Typing faster and in the correct way has many advantages including productivity gains,
ergonomics and ability to look at the screen while typing. However, not everyone can simply
practice typing and improve their speed, sometimes more drastic action is required.
With the right method you can improve your speed from 25 wpm to 60 wpm in 3 weeks of casual effort like I did.
Two years later I now type properly at 80 wpm with no dedicated practice since those 3 weeks.

Most people improve their typing speed through practice on sites like [KeyHero](http://www.keyhero.com/).
This approach works in some cases but there are some cases where this approach is ineffective.
In order for your practice to be effective you have to continue typing faster and correctly afterwards during normal computer use.
For many years I typed at a dismal speed of 25 wpm with incorrect fingering and my eyes firmly focused on my keyboard.
I tried to practice typing correctly and would get up to 20 wpm without looking at the keyboard but as soon as I was done
and I wanted to program or chat with friends I would go back to my slightly faster but incorrect method of typing and lose my progress.
No matter how hard you practice if you immediately go back to looking at your keyboard or typing improperly afterwards you won't get any faster.

Salvation came a couple years ago when I discovered a method of kicking out my typing crutches: learning [Dvorak](http://en.wikipedia.org/wiki/Dvorak_Simplified_Keyboard).
Dvorak is a keyboard layout with a much more efficient design with the most common letters on the home row.
It is supposedly more efficient but I couldn't care less about that, what mattered to me is that all the keys were in different positions and the labels on the keys were wrong.
I basically threw away everything I knew about typing and started afresh typing properly and efficiently, at 0 wpm.
After a weekend of studying I had learned the layout. In only a week I beat my previous speed. In 2 weeks I doubled it and in 3 weeks I was typing at 60 wpm.
Interestingly, I was only practicing about one hour per day. The important thing was that I never switched my computer off of Dvorak and did everything in the new layout.

![Progress Graph Sketch]({{PAGE_ASSETS}}/Progress.png)

By starting from the beginning on a keyboard layout where you can't cheat and look at keys, you can eliminate
the bad habits that prevent you from becoming a fast typist.
If you look at your keyboard while you type you miss helpful auto-complete popups and typos you have made, leading to drastically lower effective wpm.
Not only this but if you truly need to look you are limiting your typing speed to how fast you can target the next letter.

Unlike Colemak, the Dvorak layout is available by default on most versions of OSX, Windows and Linux so even if you have to use someone else's computer you can switch the layout.
You don't have to buy a special keyboard and you might even get ergonomic benefits from using a more efficient layout and not having to contort your fingers so much.
After a few years of using Dvorak I haven't had any problems with using other people's computers or keyboards.
You can always fall back on hunt and peck if you can't be bothered to change the layout setting.

If your typing speed is below 40wpm or you have to look at the keyboard I highly recommend you learn Dvorak to get rid of your bad habits and improve your speed.
This trick helped me immensely and if you have trouble typing quickly because of bad habits, it can help you too.

## Specifics

To initially learn the basic layout so that I could type every letter, albeit slowly, I used two methods.
I practiced with lessons on [dvorak.nl](http://learn.dvorak.nl/) and printed off a sheet with the layout so that I could
memorize it away from the computer. I did this all in 2 days of focus so that I wouldn't have to switch back to QWERTY between
practices to get things done.

Once I could type everything I needed to I started using KeyHero, which is a nicer platform for both practicing and tracking your progress.
I also used Dvorak for everyday things like programming and writing. I was slow to begin with but very soon I could type faster than before.

<script>
var tangle = new Tangle(document, {
    initialize: function () {
        this.curWpm = 30;
        this.newWpm = 80;
        this.career = 10;
        this.dailyTyping = 30;
        this.pay = 40;
    },
    update: function () {
        this.ratio1 = this.newWpm / this.curWpm;
        this.ratio2 = 1.0 / this.ratio1;

        this.totalMins = this.career * 220 * this.dailyTyping;
        this.totalHours = this.totalMins / 60;
        this.newHours = this.totalHours * this.ratio2;
        this.savedHours = this.totalHours - this.newHours;

        this.totalWords = this.totalMins * this.curWpm / 1000000;
        this.newWords = this.totalWords * this.ratio1;

        this.worth = this.savedHours * this.pay;
    }
});
</script>
