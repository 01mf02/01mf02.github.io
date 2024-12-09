---
title: Five Years of Rust
date: 2024-12-09
---

About five years ago, I made my first steps with the programming language Rust.
This recapitulates my Rust journey since then.

In late 2019, I had just started my postdoc with Deducteam at ENS Paris-Saclay.[^ens]
I was to work with a tool called [Dedukti](https://deducteam.github.io/),
which is a so-called proof checker.
Quickly, I got sidestepped from working *with* Dedukti to working *on* Dedukti.
Dedukti is written in OCaml, and at that time, I was a Haskell adept.
After a few discussions with my collegues, I wanted to try whether I could rewrite
a part of Dedukti in Haskell and achieve better performance than in OCaml.
This was a [short voyage](https://github.com/01mf02/kontroli-hs) full of pain:
Although I believe that I was not a bad Haskell programmer,
using it I struggled to barely match the speed of OCaml.
At that point, I was disappointed by my then favourite programming language.
A bit of research later, I found out about Rust and gave it a shot.[^rust-139]
After about one week of learning Rust from zero, I had a working parser for
Dedukti whose performance exceeded all my previous Haskell efforts,
and which started to match the performance of Dedukti.
This was the beginning of an amazing journey for me.

[^ens]: ENS Paris-Saclay was actually located neither in Paris nor in Saclay, but in a cute suburb of Paris called Cachan, to which I cycled every day from Paris.

[^rust-139]: At that time, by the way, the current Rust version was [1.39](https://blog.rust-lang.org/2019/11/07/Rust-1.39.0.html), which stabilised `async fn`s. One of the Rust features I basically never use.

In the following months, I reimplemented more and more parts of Dedukti in Rust,
which gave rise to the proof checker that I called [Kontroli](https://github.com/01mf02/kontroli-rs).
At this point, I have to thank my then-supervisors Gilles Dowek and Frédéric Blanqui
for having been so open-minded and tolerant towards these efforts of mine ---
I'm not that sure that they were initially so happy with my diverging so much
from my original agenda. :)
At a certain point, my proof checker was a bit faster than Dedukti.
That was when my colleagues tried to convince me to make Kontroli multi-threaded,
given Rust's reputation for high-performance concurrency.
I was reluctant at first, because I had vague memories of
my previous concurrency adventures
having been rather painful (in C, C++, and Java) or
having gained relatively little performance (Haskell).
In the end, I gave in, and after a few weeks of work
(the first Covid lockdown in France had just started!),
I had a fully functional concurrent proof checker
([commit](https://github.com/01mf02/kontroli-rs/commit/6edf1baef1843678e2fb00a4d7b07e8cbe96c864)).
The first version still had some bottlenecks,
but a second version removed these and allowed using the same code for
both single-threaded and multi-threaded operation without overhead.
That unlocked significant performance gains,
reducing runtime by up to 8x compared to Dedukti!
I managed to publish [two papers](https://doi.org/10.1145/3573105.3575686)
about this engineering feat.

In 2020, I started a postdoc in Amsterdam.
My originally planned work was severely compromised by the fact that
due to Covid, all my colleagues (including my supervisor)
were in home-office, some even from abroad.
So my natural tendency to diverge from originally planned agendas kicked in again,
when I was just setting out to analyse some JSON data.
After some language research, I found the jq language to manipulate JSON data,
but I was flabbergasted when I found that starting jq took a whopping 50 milliseconds,
which limited the rate of files that I was able to process to 20/second!
However, I regularly had several thousands of files to process,
and I did not want to wait for several minutes each time.
That was when I repeated my Dedukti experiment:
How fast could I make a tiny clone of jq that could allow me to perform my research?
Five days later, I had a functional prototype
(see [research journal](https://github.com/01mf02/adam-notes?tab=readme-ov-file#2020-12-04))
that had the performance that I wished for.
In the next months, I sporadically hacked on this prototype
that I called [jaq](https://github.com/01mf02/jaq),
and built more and more of jq's functionality into it.
At some point, I [wrote about it on the Rust Reddit](https://www.reddit.com/r/rust/comments/ucyq01/announcing_jaq_a_jq_clone_focussing_on/),
at which point the popularity of the project skyrocketed.
I had never before created such an impact with another piece of work before,
and I was quite happy about this.

After finishing my postdoc, I was unemployed for about one year,
during which I continued my work on jaq in my free time.
I looked for interesting programming jobs, but at that point,
the only jobs in my home town ([Innsbruck](https://en.wikipedia.org/wiki/Innsbruck)) used
languages like C/C++/Java/Python, and I could not bring myself to work with these,
because these languages felt to me like a too large step back from Rust.
Eventually, I heard about the [NLnet Foundation](https://nlnet.nl/),
which sponsors open source projects.
I applied and got [funded to work on jaq](https://nlnet.nl/project/jaq/) for several months.
I am incredibly grateful to NLnet for having granted me this opportunity,
because I love to work for the common good
(by providing my software to the public for free),
yet at the end of the day, I have to pay for my food and rent like everyone else.

As part of my NLnet project, I wrote a
[document](https://github.com/01mf02/jq-lang-spec/) using [Typst](https://typst.app/),
a typesetting program written in Rust that aims to be a
more user-friendly and performant alternative to LaTeX.
However, the NLnet people were concerned about Typst not being able to export to HTML,
which they felt was the right format for my document to be published in.
I believe that I jokingly told them that if Typst could not still not export to HTML
by the time my NLnet grant was over, I could just
apply for another NLnet grant to implement this functionality myself.
And that is what eventually happened.
In December 2024, I started working on
[HTML export from Typst](https://nlnet.nl/project/Typst-HTML/),
which is a functionality that many people (including myself)
have yearned to use since a long time already.

Rust has accompanied my programming life since five years, and I
am very grateful to the Rust community for having created this language.
I still enjoy working with Rust every day, and for me,
it comes very close to being a perfect programming language.
Before Rust, I had mainly worked with languages that were
fast, but unsafe (C/C++), or
safe, but slow (Haskell).[^ocaml]
Rust not only achieves the trifecta of enabling programs that are at the same time
fast, safe, and concurrent.
It has also reconciled two worlds that previously seemed unreconcilable to
me, namely the worlds of imperative and functional programming.
This means that it has led functional programmers like me to embrace imperative programming, and
I hope that it will continue to lure imperative programmers into functional programming.
All for the benefit of creating fast, safe, and beautiful programs.

To many more years of Rust!

[^ocaml]: OCaml strikes an interesting middle ground, being a relatively fast and safe language. However, it makes the use of global mutable variables so easy that I found many OCaml programs to use this feature quite extensively, which led to extensive hair loss on my side.
