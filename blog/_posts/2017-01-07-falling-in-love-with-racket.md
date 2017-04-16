---
title: Falling in Love with Racket
---

In the last days, I discovered the [Racket programming language](http://racket-lang.org/)
following [a blog post of Alexis King](https://lexi-lambda.github.io/blog/2017/01/02/rascal-a-haskell-with-more-parentheses/).

My interest was further sparked as I discovered the online books of Matthew Butterick,
namely [Practical Typography](http://practicaltypography.com/)
and [Beautiful Racket](http://beautifulracket.com/).
The case he makes for Racket is that can be used as a framework to
define new languages, which is significantly easier than in other languages,
and that programs in the newly defined languages enjoy immediate support
from the Racket tooling.

For example, I was able to create a slideshow in one hour in a Racket-based language
using the amazing DrRacket IDE. The slideshow shows an animation and displays a plot:

~~~ scheme
#lang slideshow

(require slideshow/code)
(require slideshow/play)
(require plot)

 (play-n
 (lambda (n1 n2 n3)
   (vl-append
   (cellophane (t "Hello")
               (* n1 (- 1.0 n2)))
   (rectangle (* 10 n1) (* 10 n1))
   (arrow (* 30 n2) 0)
   (circle (* 10 n3))
   )
   )
 )

(slide
 (plot-pict (function sqr -1 1 #:label "y = x^2")))
~~~

Making even just the animation in the Haskell counterpart,
[Diagrams](http://projects.haskell.org/diagrams/), is an endeavour
that would probably have required me multitudes of the time
I took for this.
(And boy, did I try making graphics/animations with Diagrams.)

In contrast to the most other Lisp descendants, Racket also has
the most attractive website, which makes its community appear vibrant.
Did I also mention that the [Racket documentation](http://docs.racket-lang.org/)
is awesome? Like, the best I've ever seen?

While slowly getting hooked, I watched some talks from RacketCon,
namely one from Matthew Butterick about
his publishing system [Pollen](http://pollenpub.com/),
and one by a certain John Clements about functional sound generation:

* [Matthew Butterick — Like a Blind Squirrel in a Ferrari](https://www.youtube.com/watch?v=IMz09jYOgoc)
* [John Clements — Sound: why is it so darn imperative?](https://www.youtube.com/watch?v=DkIVzHNjNEA)

Both talks were very exciting. I also noted a certain high level of literacy
in nearly all of the Racket talks/prose -- is this an indication that
Lisp programmers have a certain affinity to good writing?
(Another good example of this is [Paul Graham](http://www.paulgraham.com/).
Just opened the website, read an interesting article about how Pittsburgh
could become a city attracting startups, and was hooked.
The same holds for Mr. Butterick. I wonder how you can write so much text
with such high quality ...)

Anyway, I have been able to come up in around one hour with a simple program
that produces an infinite lazy list (called "stream" in Racket),
consumes it as long as a certain condition holds, then applies a function
to all its elements.

~~~ scheme
#lang racket
(require racket/stream)

(define (stream-from n s) (stream-cons n (stream-from (+ n s) s)))

(define (stream-while s p)
  (let ([fst (stream-first s)])
  (if (p fst) (stream-cons fst (stream-while (stream-rest s) p)) empty-stream)))

(define test (stream-while (stream-from 0 1) (λ (x) (< x 100000))))

(stream-for-each println test)
~~~

This prints all numbers from 0 to 99999.
An equivalent Haskell version:

~~~ haskell
test = [0 ..]

main = mapM_ putStrLn (map show (takeWhile (< 100000) test))
~~~

The Haskell version is much smaller, but this can safely be attributed
to my being a novice in Racket, having written above program basically
directly after having done the obligatory "Hello World", with the
only goal of finding out whether lazy lists are nice to use in Racket.
(The answer is a clear "yes".)
On the other hand, when running the two programs with `racket` and `runghc`
respectively, the Racket version performed better, taking only 0.68s vs 1.28s.

Another quick experiment was to reverse every individual line of a file and
to print all resulting lines.

    (for-each (compose displayln list->string reverse string->list)
      (file->lines "problems.txt"))

The version above has the disadvantage that it first has to
read in the whole file, and only then starts processing it.
We can do better using "sequences", which allow us to iterate
over specific parts of an input, for example the lines of a file.
The following code was created in roughly 30 minutes and required
understanding Racket's "ports" and "sequences", both which were
relatively easy to grasp given the -- I reiterate -- excellent documentation:

    (call-with-input-file "problems.txt" (lambda (in)
      (sequence-for-each (compose displayln list->string reverse string->list)
        (in-lines in))))

As before, the Haskell version is a bit smaller, mostly because
strings are lists in Haskell. (This characteristic bites in other places.)
Furthermore, this example uses lazy I/O, which can cause surprises
and is therefore commonly discouraged in favour of streaming libraries.

    readFile "input.txt" >>= mapM_ putStrLn . map reverse . lines

In conclusion, I have really enjoyed learning the concepts of Racket,
and I was very astonished to see that so far, the lack of types
(which I would have considered an absolute no-go still one week ago)
has been much less of a problem than I thought.

The Racket community seems small, but extremely motivated,
leading me to believe that this language will gain momentum.
