---
layout: post
title: "Winning the DEF CON Quals CTF! Writeups: Easy Pisy, Flagsifier, Geckome"
description: ""
category:
tags: ["reversing", "ctf"]
assetid: dcquals18
good: true
---
{% include JB/setup %}

A friend invited me to join his CTF team ([Samurai](https://ctftime.org/team/1937)) this year for the Plaid CTF and the DEF CON qualifiers and I thought that sounded fun and wanted to learn more security and reverse engineering, so I did. For Plaid I just spent a couple hours tinkering with a few problems with my main accomplishment being reverse engineering a complicated APL program. For DEF CON I decided to go all out and dedicate my entire weekend to it. I had a really great time, and [we won](https://scoreboard.oooverflow.io/#/scoreboard)!

I solved three problems mostly by myself: Easy Pisy, Flagsifier and Geckome. The last two were the 6th and 1st least-solved challenges in the game, and the less people solved a challenge the more points it was worth. This corresponds a little to how much work was required, but also to how many lucky/clever/random insights are required, and how much effort other teams decided to put in. I'd say Flagsifier was genuinely tricky but Geckome, the least-solved challenge, was mostly luck and good tactics and wasn't much work compared to many other challenges.

I spent the last 4 hours of the CTF working on a solution to "adamtune", and I finished a whole bunch of work that did what I intended, it just turned out the results weren't very good. The way the problem worked it was impossible to tell ahead of time whether my approach would be good enough, so I just had to spend the time and it didn't pan out. Now that [the source](https://github.com/o-o-overflow/chall-adamtune/blob/master/src/adamtune.py) has been posted, it seems like my basic approach was correct, and that if I had used the Watson speech to text API instead of the Google one it may have given me the extra info I needed to make a good solution.

I also contributed a bit to discussion and reverse engineering on a few other problems, including "It's-a me!", "Tech Support" and "exzendtential-crisis".

Without further ado, here's my writeups for the problems that I solved:

## Easy Pisy

A web app gave us the ability to sign a PDF and then submit a signed PDF. There was accessible source for the PHP scripts and sample PDFS. The source and examples showed that the PDF's could contain two possible commands: `ECHO` and `EXECUTE` (which runs a shell command). The signing script would only sign `ECHO` PDFs so you couldn't trivially execute any command.

Running one of the sample PDFs through showed the commands being run included converting the PDF to a PPM file and then running `ocrad` (an OCR tool) to extract the text out of them.

One of the example PDFs ran `EXECUTE ls` and came with a signature, it showed there was a `flag` file in the working directory.

So the problem was how to get a signed PDF that shows the text `EXECUTE cat flag`, when we could only sign a PDF that had an `ECHO` command. This sounded a lot like it could involve the recent-ish PDF SHA1 collision. A quick check of the PHP docs showed that the `openssl_verify` function they used defaults to using SHA1 signatures!

My teammate `fstenv` found the <https://alf.nu/SHA1> website for generating colliding PDFs, and I quickly opened Pixelmator and drew up one JPEG that said `ECHO hi` in big Arial font and another that said `EXECUTE cat flag`. I ran it through the service and it spit out two PDFs with identical hashes. I then went through signing the echo one and executing the cat one and got the flag!

## It's-a Me

This challenge involved a binary that presented text-based menus for a pizza restaurant. A bunch of us opened up the binary in Binary Ninja and IDA and used [revsync](https://github.com/lunixbochs/revsync) to collaborate on naming symbols.

We found that it looked for emojis like tomato, pineapple and chicken as the pizza ingredients. If you ordered the Pineapple emoji as an ingredient, it yelled and banned you. We found other pineapple-related code at the cooking stage, so we needed to figure out how to get there without getting banned. Soon `aegis` figured out the cooking stage concatted the ingredients, so we could split the emoji's UTF-8 over 2 ingredients to get it through.

Then `aegis` found a code path that could write to a buffer before and after it being `free`'d, which could be the start of a heap corruption exploit. To get to that path we needed to make it think our pineapple pizzas were all an `ApprovedPizza` instead of a `CriminalPizza`.

So we found some bit field logic and `aegis` figured out that you could overflow the 4 bit fields and make it think all the pizzas were approved by cooking 16 pineapple pizzas and 1 tomato pizza. That let us corrupt the heap and get a segfault. Then `kileak` developed an exploit which he wrote up [here](https://kileak.github.io/ctf/2018/defconquals18-itsame/).

## Flagsifier

This one was tricky, it took me 4 hours of fiddling around in a [Juypter Notebook](https://gist.github.com/trishume/99a161c5c3653c08edfbf9e1cd6d27a5).

We were given a Keras convnet image classifer model, some sample images showing 38 MNIST-like letters spelling random words glommed together, and the name "Flagsifier". This suggested that the challenge was to extract an image of the flag from the model trained to recognize the flag.

![Flagsifier Sample Inpuw]({{PAGE_ASSETS}}/flagsifier_sample.png)

First I Googled "MNIST letters" and found the EMNIST dataset, which I suspected is what the samples and training data was made with. Next, I had two possible avenues of extraction:

1. Use something like Deep Dream to optimize an image for flag-ness: this would take a reasonable amount of effort to implement and might work straightforwardly, but ran the risk of outputting blurry or otherwise unreadable images.
2. Use the letters in the EMNIST dataset to optimize a flag string for flag-ness character by character. This would definitely give a readable result, but I wasn't sure if just hill-climbing a character at a time would reach the flag properly, since the final dense layer could theoretically learn not to activate basically at all until all the characters are right.

I figured that the second approach had a better effort to expected reward tradeoff and started work. First I set up the data loading code for the EMNIST dataset and extracted only the capital letters (the samples were all uppercase). Then I extracted the first letter from a sample and searched the dataset for it, confirming that the letters were from EMNIST. Later I figured out based on the "L"s in the samples that I needed to use the `ByMerge` version rather than the `ByClass` version and switched it.

Next I wrote a function that took a 38-character string and generated an image with random instances of each letter so that I could run things through the network. I needed to figure out which of the 40 class outputs was flag-ness, without having the flag.

The examples I had run through so far had all output `1.0` for one class and `0.0` for others, I figured first I needed more resolution to pick up on hints of flag-ness. To get this I needed to remove the final softmax layer. Unfortunately Keras compiled the model using settings only available inside the load command, so it wasn't easy to modify it after loading. I took the easy/clever/hacky/fastest way out and opened the model in a hex editor, found the JSON model description inside and changed `"softmax",` to `"linear" ,` with the space to maintain the length. This gave me a much higher resolution signal to look at and optimize.

I knew that all flags started with `OOO` so I composed an image with `OOO` and then blank space, and saw that channel 2 (zero-indexed) had the highest activation.

I started by looping through each character for each position starting from the beginning and filling it with the character that had the highest activation, using my same generator that picked random instances. This gave garbage results, so I made it average the activations of 20 samples for each character and it correctly picked up the `OOO` and then a bunch of random-seeming characters.

I rewrote my generator and optimizer to pick 30 random versions of each letter for each position and choose the best letter instance for each slot. Then I rewrote it again so it could start from a given string instead of an empty blank canvas. Then I re-ran the optimizer again starting with my last result and it tuned in each character with context.

This gave me `OOOSOMGAUTHKNTICIWTTILIGCWCCISRTQUIVCT`. That looked like the first part might be `OOOSOMEAUTHENTIC`, it was getting somewhere! So I posted it to the Samurai Slack channel. I was somewhat tapped out of ideas and my teammate wanted to try Deep Dream, so I tried a bit harder to get the best guess of a starting point for Deep Dream to optimize. I noted that the `ByMerge` dataset meant `L` and `I` were nearly indistinguishable, and given that and the context of an AI challenge it probably continued `OOOSOMEAUTHENTICINTELLIGENCEIS`. I couldn't decipher the last bit though so I prepared to wait for the deep dream results.

Then I got a Slack ping that the challenge had been solved, my teammate `shane` figured out that the last bit `RTQUIVCT` must be `REQUIRED`! We had managed to turn the garbled mess into the full flag.

## Geckome

In this challenge there was a page with Javascript that collected a bunch of info from the browser, put it all in a string, hashed it, and if it had the correct hash, passed it off to a PHP file that would give you the flag given the string.

We started by looking at the various Javascript, CSS and HTML features used on the page and tabulating which versions of which browsers could possibly have that combination of features, and came up with this table:

```
Thing           Firefox Chrome  Opera   Safari
onbeforeprint   <6      <63     <50     any
DataView        >=15    >=9     >=12.1  >=5.1
webkit anim     X       >=4     >=15    >=4
SubtleCrypto    >=34    >=37    >=24    >=11
link prerender  X       >=13    >=15    X
video tag       >=20    >=4     >=11.5  >=4
ping attr       X       >=15    >=15    >=6

The version expressions for onbeforeprint are
the browsers that don't support it, as suggested.
```

This didn't do much except rule out Firefox and Safari. We could also probably rule out Opera because it's rare, and the challenge was named "Geckome" which had "ome" from Chrome, but nothing from Opera. But there were still too many Chrome versions.

I modified the script to put all the important values to hash on the screen so that we could easily look at the results in different browsers:

```html
<pre id="log"></pre>
<script>
    var logText = "";
    function logme(thing,s) { logText += thing; logText += ": "; logText += String(s); logText += ";\n";}

    var f = "";
    if (navigator.onLine)
        f += "o";
    logme("online", navigator.onLine);
    f += navigator.vendor;
    logme("vendor", navigator.vendor);
    function p() {
        window.print();
    }

    f += navigator.mimeTypes.length;
    logme("mimes", navigator.mimeTypes.length);
    x=0; for ( i in navigator ) { x += 1; } f += x;
    logme("navlen", x);
    x=0; for ( i in window ) { x += 1; } f += x;
    logme("winlen", x);
    // hash
    function str2ab(str) {
        var buf = new ArrayBuffer(str.length*2); // 2 bytes for each char
        var bufView = new Uint16Array(buf);
        for (var i=0, strLen=str.length; i<strLen; i++) {
            bufView[i] = str.charCodeAt(i);
        }
        return buf;
    }
    function sha256(str) {
        // We transform the string into an arraybuffer.
        var buffer = str2ab(str);
        return crypto.subtle.digest({name:"SHA-256"}, buffer).then(function (hash) {
            return hex(hash);
        });
    }

    function hex(buffer) {
        var hexCodes = [];
        var view = new DataView(buffer);
        for (var i = 0; i < view.byteLength; i += 4) {
            // Using getUint32 reduces the number of iterations needed (we process 4 bytes each time)
            var value = view.getUint32(i)
            // toString(16) will give the hex representation of the number without padding
            var stringValue = value.toString(16)
            // We use concatenation and slice for padding
            var padding = '00000000'
            var paddedValue = (padding + stringValue).slice(-padding.length)
            hexCodes.push(paddedValue);
        }

        // Join all the hex strings into one
        return hexCodes.join("");
    }
    if(navigator.plugins.length > 0) {
        logme("plugin0name", navigator.plugins[0].filename);
        logme("plugin0desc", navigator.plugins[0].description);
    }
    if(navigator.plugins.length > 1) {
        logme("plugin1name", navigator.plugins[1].filename);
        logme("plugin1desc", navigator.plugins[1].description);
    }
    f += navigator.plugins[0].filename;
    f += navigator.plugins[1].description;

    logme("f", f);

    sha256(f).then(function(digest) {
        logme("digest", digest)
        if (digest == "31c6b7c46ff55afc8c5e64f42cc9b48dde6a04b5ca434038cd2af8bd3fd1483a") {
            logme("flag", "gotit!");
        } else {
            logme("flag", "fail!");
        }
        document.getElementById('log').innerHTML = logText;
    });
</script>
```

I then hosted a version of this and used [BrowserShots](http://browsershots.org/) to take screenshots of it in many versions. Most crashed for lack of various APIs/values and none were correct.

My next idea was to brute force the hash by trying all the reasonable combinations of numbers and plugin strings.

I spent an hour writing a Rust program to brute force it that computed the strings and digests in the same way, including UTF-16 conversion and converting to hex. Then I checked that it could find the values for my browser's digest. I entered a lot of possible plugin values and reasonable ranges for numbers based on the browser screenshots, but couldn't find the correct one despite searching millions of combinations.

**So, I gave up.** Then later got a Slack ping that my teammate `nopple` had solved it. He had taken my Rust program and added some extra plugin strings I had missed from the browser screenshots (`libpepflashplayer.so` turned out to be the key).

```rust
extern crate byteorder;
extern crate sha2;

use sha2::{Sha256, Digest};
use byteorder::{LittleEndian, WriteBytesExt};
use std::fmt::Write;

fn to_utf16(s: &str) -> Vec<u8> {
    let mut out = Vec::with_capacity(s.len()*2);
    for point in s.encode_utf16() {
        out.write_u16::<LittleEndian>(point).unwrap();
    }
    out
}

fn to_hex(bytes: &[u8]) -> String {
    assert_eq!(bytes.len(), 32);
    let mut s = String::with_capacity(64);
    for byte in bytes {
        write!(&mut s, "{:02x}", byte).unwrap();
    }
    s
}

fn hash(bytes: &[u8]) -> String {
    let mut hasher = Sha256::default();
    hasher.input(bytes);
    let output = hasher.result();
    to_hex(output.as_slice())
}

#[derive(Debug)]
struct Browser {
    online: bool,
    vendor: &'static str,
    mimes: u16,
    navs: u16,
    wins: u16,
    plug_name: &'static str,
    plug_desc: &'static str,
}

fn construct_f(b: &Browser) -> String {
    let mut s = String::with_capacity(64);
    if b.online { s.push('o'); }
    s.push_str(b.vendor);
    write!(&mut s, "{}", b.mimes).unwrap();
    write!(&mut s, "{}", b.navs).unwrap();
    write!(&mut s, "{}", b.wins).unwrap();
    s.push_str(b.plug_name);
    s.push_str(b.plug_desc);
    s
}

// Test target that's my browser
// const TARGET: &'static str = "31504a9568837f94e9f0afe8387cf945fb4929b81e53caf16bdf65c417e294e0";
// Real target
const TARGET: &'static str = "31c6b7c46ff55afc8c5e64f42cc9b48dde6a04b5ca434038cd2af8bd3fd1483a";

fn test(f: &str) -> bool {
    let utf16 = to_utf16(f);
    let hex_hash = hash(&utf16[..]);
    assert_eq!(hex_hash.len(), 64);
    hex_hash == TARGET
}

struct ForceConfig {
    navs_start: u16,
    navs_end: u16,
    wins_start: u16,
    wins_end: u16,
}

const PLUGNAMES: &'static [&'static str] = &[
    "internal-remoting-viewer",
    "internal-pdf-viewer",
    "widevinecdmadapter.plugin",
    "PepperFlashPlayer.plugin",
    "internal-nacl-plugin",
    "libpdf.so",
    "pepflashplayer.dll",
    "Flash Player.plugin",
    "WebEx64.plugin",
    "CitrixOnlineWebDeploymentPlugin.plugin",
    "googletalkbrowserplugin.plugin",
    "AdobePDFViewerNPAPI.plugin",
    "libpepflashplayer.so",
];

const PLUGDESCS: &'static [&'static str] = &[
    "",
    "This plugin allows you to securely access other computers that have been shared with you. To use this plugin you must first install the <a href=\"https://chrome.google.com/remotedesktop\">Chrome Remote Desktop</a> webapp.",
    "Portable Document Format",
    "Enables Widevine licenses for playback of HTML audio/video content. (version: 1.4.9.1070)",
    "Plugin that detects installed Citrix Online products (visit www.citrixonline.com).",
    "Shockwave Flash 9.0 r0",
    // SNIPPED: versions 10 through 28. These didn't end up being necessary.
    "Shockwave Flash 29.0 r0",
];

fn force(c: &ForceConfig) {
    let num_navs = (c.navs_end-c.navs_start) as usize;
    let num_wins = (c.wins_end-c.wins_start) as usize;
    let max_mime: u16 = 15;

    let total = num_navs*num_wins*(max_mime as usize-1)*PLUGNAMES.len()*PLUGDESCS.len();
    println!("Brute forcing {} combinations", total);

    let one_segment = total / 100;
    let mut tick = 0;

    for navs in c.navs_start..c.navs_end {
        for wins in c.wins_start..c.wins_end {
            for mimes in 1..max_mime {
                for plug_name in PLUGNAMES {
                    for plug_desc in PLUGDESCS {
                        let b = Browser {
                            online: true,
                            // vendor: "",
                            vendor: "Google Inc.",
                            // vendor: "Opera Software ASA",
                            mimes, navs, wins, plug_name, plug_desc,
                        };
                        let f = construct_f(&b);
                        let good = test(&f);
                        assert!(!good, "{:?}", b);

                        tick += 1;
                        if tick % one_segment == 0 {
                            println!("Done {}/{}", tick, total);
                        }
                    }
                }
            }
        }
    }
}

fn main() {
    let conf = ForceConfig {
        navs_start: 8,
        navs_end: 58,
        wins_start: 80,
        wins_end: 270,
    };
    force(&conf);
}
```

## AdamTune

This challenge involved passing a "voice print" test where you submitted an MP3 file that was allegedly [Adam Doupé](https://adamdoupe.com/) reading a sentence.

My teammates spent some time playing with training a text to speech model on a small hand-labeled dataset but that didn't produce good enough results and at 4 hours till the end of the contest we agreed there's no way it could work in time.

By recording challenges from the demo server, I discovered that a vocabulary of about 209 words completely covered most challenges. So we decided to try a concatenative approach. My teammates downloaded the audio for a bunch of Adam's talks and gave me cut up mono wav files. I fed these through the Google Speech To Text API and got word level timing information. I wrote a script that cut out wav files of individual words in the vocabulary from the transcript, a script that picked out the best instances of these words based on length and volume, and a script that strung together the best instances into sentences.

However, the results sounded really bad. A lot of the words were said quickly or muttered or included bits of other words, the results ended up being really difficult to understand.

I submitted it anyway and it actually passed the check that it said the right words, but failed the classifier that it was Adam. This was the opposite of what I expected, since it was Adam but didn't sound like it was saying the sentence cleanly.

Looking at the source after the contest, it seems the approach used in it is very similar except with the Watson speech API, which gives word-level confidences Google doesn't, allowing better filtering, and also might give better timestamps for less choppy cutouts.

My other guess for why we failed the classifier is that we used clips from Adam's livestreams doing pwnables instead of from his CS lectures, these sound very different because of different microphones and styles of speaking. We chose the pwnables because the audio was higher quality, but if the classifier used only lectures then that could easily explain why we failed the classifier.

