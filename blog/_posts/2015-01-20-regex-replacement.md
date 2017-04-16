---
title: Replacing regular expressions
---

I present a problem which I wanted to solve with regular expressions, but for which a `sed` solution would be complicated. Consequentially, I show how to solve the problem with Haskell.


## Problem

For displaying images with captions on my website, so far I used HTML code as the following:

~~~ html
<div class="img-container">
  <img src="/media/Arcachon.jpg" />
  <p>Les Dunes.</p>
</div>
~~~

I wanted to replace this with Markdown syntax, which looks as follows:

~~~
![Les Dunes.](/media/Arcachon.jpg)
~~~

Much less to type that way. :) However, in my existing files, I used the img-container about 50 times, which was clearly too much for me to replace by hand. Therefore, I first considered giving my good old friend `sed` a spin to automatise the replacement. Unfortunately, I quickly found out via [Stack Overflow][sed post] that `sed` seems to work best if you process files line by line, and in my case, I had to match a pattern over multiple lines. For about one minute, I considered the advice in the Stack Overflow post to use Perl for the task, but as I do not know how to program in Perl and did not want to learn it for this apparently simple task, I researched a Haskell solution to this problem, which turned out to be very nice.


## Solution

In Haskell's [Text.Regex] module, you have a function called `subRegex`, which takes an input string and replaces all matches of a regular expression by a replacement string. After some fiddling, I came up with the following:

~~~ haskell
import Text.Regex

regex = unlines
  [ "<div class=\"img-container\">"
  , "  <img src=\"(.*)\" />" -- 1st capture group, filename
  , "  <p>(.*)</p>"          -- 2nd capture group, description
  , "</div>"
  ]

testText = unlines
  [ "<div class=\"img-container\">"
  , "  <img src=\"/media/Arcachon.jpg\" />"
  , "  <p>Les Dunes.</p>"
  , "</div>"
  ]

main = print $$ subRegex (mkRegex regex) testText "![\\2](\\1)\n"
~~~

Let us try it:

~~~
michi ~ $$ runhaskell regex.hs
"![Les Dunes.](/media/Arcachon.jpg)\n"
~~~

Yes, it works! (At this point, I confess that I took at least one hour to come up with this whole solution, including a countless number of "oh no, why does it not work?".)

I tested this with some other examples, and on one example, nothing was replaced. It was the following:

~~~ html
<div class="img-container">
  <img src="/media/2012-09-16-jai-besoin-dun-velo/Photo1473.jpg" />
  <p>Modèles de Calcul (während der Pause aufgenommen).</p>
</div>
~~~

What is wrong about this? It contains 'è' and 'ä'. "But we are in the 21th century, what about Unicode?", I hear you blubber out in disbelief. I concur, but apparently old habits die hard, and Unicode is still not supported everywhere. Fear not, for you have a remedy at hand: The [Text.Regex] module which I used is provided by several packages, the default one being [regex-compat][], which does seem to not support Unicode. However, as I found out via [Stack Overflow][regex-tdfa-post], there is a replacement called [regex-compat-tdfa][] which supports Unicode. One `cabal-install regex-compat-tdfa` later, I get a new error message:

~~~
michi ~ $$ ghci
GHCi, version 7.6.3: http://www.haskell.org/ghc/  :? for help
Prelude> import Text.Regex

<no location info>:
    Ambiguous module name `Text.Regex':
      it was found in multiple packages:
      regex-compat-tdfa-0.95.1.4 regex-compat-0.95.1
~~~

Sigh. I knew this was not going to be that easy. So I somehow have to remove the old regex-compat package. Luckily, it turned out that I had a package called libghc-regex-compat-dev on my Linux system, which I removed via my package manager. After that, I could load Text.Regex just fine, and it matched strings containing "strange" characters just as well. Great!

Now we are able to match simple test strings, but we want to search and replace within a whole file. How do we do that? Luckily, Haskell has an awesome function called `interact`, which reads from standard input, passes the input to a function, and writes the output of the function to standard output. The solution utilising `interact` is:

~~~ haskell
main = interact (\ f -> subRegex (mkRegex regex) f "![\\2](\\1)\n")
~~~

To use our program on an existing file, we have to `cat` the file to the Haskell script and pipe its output to a new file. To do this for multiple files, I used bash:

~~~ bash
mkdir modified
for i in *.md; do cat $$i | runhaskell regex.hs > modified/$$i; done
~~~

And that's it! For your reference, here is the final Haskell file:

~~~ haskell
import Text.Regex

regex = unlines
  [ "<div class=\"img-container\">"
  , "  <img src=\"(.*)\" />" -- 1st capture group, filename
  , "  <p>(.*)</p>"          -- 2nd capture group, description
  , "</div>"
  ]

main = interact (\ f -> subRegex (mkRegex regex) f "![\\2](\\1)\n")
~~~


[sed post]: http://unix.stackexchange.com/questions/26284/how-can-i-use-sed-to-replace-a-multi-line-string
[Text.Regex]: https://hackage.haskell.org/package/regex-compat/docs/Text-Regex.html
[regex-compat]: https://hackage.haskell.org/package/regex-compat
[regex-tdfa-post]: http://stackoverflow.com/questions/2098314/haskells-text-regex-subregex-using-tdfa-implementation
[regex-compat-tdfa]: https://hackage.haskell.org/package/regex-compat-tdfa