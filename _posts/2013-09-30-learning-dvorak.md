---
layout: post
title: "Typing Faster"
description: "Learn to type the correct way by taking away your training wheels."
category:
tags: [dvorak, typing]
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

<i>Enjoy the calculator, actual article coming soon...</i>

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
