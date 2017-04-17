---
layout: post
title: Generating the language of a context-free grammar in Haskell
---

In this little article, I will show you how to obtain the language of context-free grammars in Haskell, using its mechanisms for nondeterminism. Furthermore, I show you how to use the results to grade students' homework. ;)

## Motivation

Recently, I was facing the task of correcting a huge amount of students' exams. In these exams, students had to create a context-free grammar (CFG) for a given formal language:

\\[ L=\\left\\{ s_1+\\dots+s_n\\mid n\\geq1, s_i \\in \\{x\\} \\cup \\mathbb{B}\\right\\}, \\]

where \\( \\mathbb{B} \\) is the set of binary numbers without leading zeros.

Examples for words in this grammar include "x+101+0+x" and "1000"; words which are *not* included in the grammar are e.g. the empty word, "y", "001+x".

A grammar solving this exercise could look like this:

~~~
S -> T | S + S
T -> B | x
B -> 0 | 1C
C -> 0 | 1 | 0C | 1C
~~~

This context-free grammar models the problem in a straightforward way:

* A sum (S) is either a token (T) or the sum of two sums.
* A token is either a boolean constant (B) or the variable x.
* A boolean constant is either just 0 or starts with 1 (to avoid leading zeros).

You can also solve this with a right-linear grammar:

~~~
S -> x + S | 0 + S | 1B | 0 | 1 | x
B -> 0B | 1B | 0 | 1 | + S
~~~

Easy, right? (After several hours of correcting these exams, this flows off my fingers like water. ^^)
However, some students gave solutions like the following:

~~~
S -> T | x | xM | 0M | 0 | 1
T -> 1A | 1T | 1M
M -> +T | +S
A -> 0 | AA | M | 0T
~~~

Do you immediately see whether this grammar correctly models the language given in the exercise? I do not. (No wonder, given that the language equivalence of CFGs is undecidable.) Worse yet, I wanted to give students counter-examples of words which their languages do not model (to justify my grading), but sometimes this was very hard.

For this reason, I wanted to make a program that generates a bunch of words of a context-free grammar, so that I could have a quick look at its output and see apparent mistakes. For the implementation of this program, I chose Haskell, because it's awesome.


## The program

First, we have to decide how to model context-free grammars. We basically have two basic building blocks, i.e. atoms, in CFGs: Nonterminals and terminals. Nonterminals are characters, while variables can be characterised by their production rules. Let's write this in Haskell:

~~~ haskell
type     Rule = [Atom]
type Variable = [Rule]

data Atom = T Char | V Variable
~~~

Here we also wrote that each production rule is actually a sequence of atoms.

Now that we have modeled context-free grammars, we would like to obtain the list of words (i.e. the language) they generate. How do we do that?
The language of a terminal is just the character of the terminal. The language of a variable (nonterminal) is more complicated: Let's demonstrate this with an example:

~~~
X -> a
Y -> bX
Z -> X | Y
~~~

To generate the language of variable Z, we have to pick one of its production rules.
We have two options for productions:

~~~
Z => X => a
Z => Y => bX => ba
~~~

That means that generating the language of a variable, we need to first pick a production rule, then obtain all the words for the atoms in the production rule and concatenate them. Phew, that sounds like a lot of work, but at this point, I remembered that [a chapter of "Learn You a Haskell for Great Good"](http://learnyouahaskell.com/a-fistful-of-monads#the-list-monad) mentioned how to use nondeterminism in Haskell: Given a variable, you can basically just say in your code "I pick an arbitrary production rule", and Haskell will then execute the code after that for *all* rules! When we then have the rule, we can do the same trick for the recursive step: We just say "give me one arbitrary word that is produced by my rule", and it will run this for *all* the possible words that can be produced! Sounds cool, huh? And the code is really short.

~~~ haskell
lang :: Atom -> [String]
lang (T t) = return [t]
lang (V rules) = do
  rule <- rules             -- pick a rule  
  words <- mapM lang rule   -- for each atom in the rule, produce a word from it
  return $ concat words     -- concatenate the resulting words
~~~

That's it. This code is supposed to generate all words producible by a context-free grammar. If you wonder more about how this works, I really recommend you to read the chapter I linked to above. Now to test this on some concrete example, let's write in Haskell the example grammar from above:

~~~ haskell
vx = V [[T 'a']]       -- X -> a
vy = V [[T 'b', vx]]   -- Y -> bX
vz = V [[vx], [vy]]    -- Z -> X | Y
~~~

Evaluating this in ghci will give:

~~~
$ ghci
Prelude> :l Lang.hs 
[1 of 1] Compiling Main             ( Lang.hs, interpreted )
Ok, modules loaded: Main.
*Main> lang vz
["a","ba"]
~~~

Cool, so we were really able to obtain all the words producible by Z!

What about grammars that can produce an infinite amount of words? For this we slightly modify our current grammar, such that it reads as follows:

~~~ haskell
vx = V [[T 'a'], [T 'a', vx]]  -- X -> a | aX
vy = V [[T 'b', vx]]           -- Y -> bX
vz = V [[vx], [vy]]            -- Z -> X | Y
~~~

We should now be able to construct words like:

~~~
Z => a
Z => ba
Z => aa
Z => baa
...
~~~

What does Haskell give us?

~~~
*Main> :l Lang.hs 
[1 of 1] Compiling Main             ( Lang.hs, interpreted )
Ok, modules loaded: Main.
*Main> lang vz
["a","aa","aaa","aaaa","aaaaa","aaaaaa","aaaaaaa","aaaaaaaa","aaaaaaaaa","aaaaaaaaaa", ...]
~~~

Oh noes! We have only strings which start with 'a', thus our second production rule of variable Z is never considered! Thinking more about it, that sounds reasonable, because Haskell does not pick production rules at random, but it will start with the first rule and try to generate all possible words for it before continuing with the second rule. However, as you can already generate an infinite amount of words with the first production rule, it never gets to the second rule. How to fix this?

Looking for the answer, I stumbled upon [a post on stackoverflow](http://stackoverflow.com/a/20719886) by Petr Pudlák, which pointed me to the Omega monad: This seems to be a drop-in replacement for the list monad, which I implicitly used for obtaining nondeterminism. Basically, what the Omega monad does it that when you pick a production rule, it will vary the actually chosen production rule such that all production rules are eventually evaluated. The nice thing about this monad is that we do not really have to change a lot of our code to benefit from it:

~~~ haskell
import Control.Monad.Omega

type     Rule = [Atom]
type Variable = [Rule]

data Atom = T Char | V Variable

lang :: Atom -> Omega String  -- we changed the signature ...
lang (T t) = return [t]
lang (V rules) = do
  rule <- each rules          -- ... and we added an "each"
  words <- mapM lang rule
  return $ concat words

-- we cannot run `lang' directly, because it returns a monadic result, but we
-- get the result out quite easily with this helper function
langO :: Atom -> [String]
langO = runOmega . lang
~~~

Now what happens if we run this Omega version?

~~~
*Main> take 10 $ langO vz
["a","aa","ba","aaa","baa","aaaa","baaa","aaaaa","baaaa","aaaaaa"]
~~~

We see that now sometimes the production rule starting with 'b' is also chosen -- great! :)


## Using it as an exam evaluation tool

Now that we saw how to generate the language of a grammar, we would like to enter a student's solution, and get possible counterexamples of words which his grammar produces and my reference solution grammar does not.
The sophisticated path to take here would be to generate a set of words of his grammar, then decide with an algorithm such as [CYK](http://en.wikipedia.org/wiki/CYK_algorithm) if all his words are accepted by my reference grammar. However, for CYK, you need Chomsky normal form, and we still have a pile of 60 exams to correct, so no time to implement that, right?
There is also a quick-and-dirty solution: You generate a set of let's say 50 words of the student's grammar, then generate let's say 500 words of your reference grammar, then display those of the 50 student words which are *not* contained in the 500 reference words. My experiments showed that in many cases this gives a very nice impression of errors the students made.

Let's look at a concrete example: For this, let us formalise my reference grammar and one of my students' grammars. In the following code snippet, I used `pure x` instead of `[x]`, because writing these brackets is such a pain when using an Austrian keyboard layout:

~~~ haskell
import Control.Applicative (pure)

-- terminals
tx, tp, t0, t1 :: Atom
tx = T 'x'
tp = T '+'
t0 = T '0'
t1 = T '1'

-- student grammar
vs = V [pure vt, pure tx, [tx, vm], [t0, vm], pure t0, pure t1]  -- S -> T | x | xM | 0M | 0 | 1
vt = V [[t1, va], [t1, vt], [t1, vm]]                            -- T -> 1A | 1T | 1M
vm = V [[tp, vt], [tp, vs]]                                      -- M -> +T | +S
va = V [pure t0, [va, va], pure vm, [t0, vt]]                    -- A -> 0 | AA | M | 0T

-- my grammar
vsum = V [pure vtok, [vsum, tp, vsum]]       -- S -> T | S + S
vtok = V [pure tx, pure vbool]               -- T -> x | B
vbool  = V [pure t0, [t1, vbool']]           -- B -> 0 | 1C
vbool' = V [[], [t0, vbool'], [t1, vbool']]  -- C -> ε | 0C | 1C
~~~

Now comes the code to compare two grammars:

~~~ haskell
import Data.Set ((\\), fromList)

v1 `langDiff` v2 =
  (fromList (take few l1) \\ fromList (take many l2),
   fromList (take few l2) \\ fromList (take many l1))
  where l1 = langO v1
        l2 = langO v2
        few = 50
        many = few * 100
~~~

First, I used the `\\` operator from Data.List to build the difference of the two lists, until I recognised that `\\` only deletes the first appearance of an element in a list. That did cost me an hour!

Anyway, what do we get if we now compare the student's grammar with mine?

~~~
*Main> vsum `langDiff` vs
(fromList ["10+x","1001","101","1011","11","1101","111","1111"],fromList [])
~~~

Okay, that should mean that my grammar (`vsum`) produces for example "10+x", but the student's grammar (`vs`) does not produce it. Is that true?

~~~
S => T => 1A => 1AA => 10A => 10M => 10+S => 10+x
~~~

Hm, so the program told us that 10+x could not be produced by the student's grammar, while in fact it could be, as shown by the production above. Such a thing is to be expected, because we use a quick-and-dirty solution! The fix is quite easy: Increase the number of words generated for the reference solution, by increasing the value of `many` in `langDiff` from `few * 100` to `few * 1000`. What does that give us?

~~~
*Main> vsum `langDiff` vs
(fromList ["1001","101","1011","11","1101","111","1111"],fromList [])
~~~

Great, so now the "10+x" has disappeared. When we manually check the remaining counterexamples, we see that in fact e.g. "11" cannot be produced from the student's grammar! The proof, as always, is left to the interested reader. ;)


## Problem of this approach

Not all is roses in the monad world, because we have to watch out when we formalise our grammars in Haskell. If we slightly change the order of our production rules in the student's grammar above, ...

~~~ haskell
-- before (works)
va = V [pure t0, [va, va], pure vm, [t0, vt]]
-- after (fails)
va = V [[va, va], pure vm, pure t0, [t0, vt]]
~~~

~~~
*Main> vsum `langDiff` vs
(fromList ^CInterrupted.
~~~

... Haskell consumes memory faster than you can say "swap is for losers". Needlessly to say, it probably will not terminate. I believe that this is because the Omega monad sometimes chooses production rules in such a way that an infinite loop can result. I was, so far, always able to fix this by moving production rules with terminals to the front, but there might be cases where this doesn't help.
Still, I found this approach very nice to work with, and as so often,
I was amazed by the shortness and conciseness of the Haskell code.
You can download my program with some examples from [here]({% include media %}/CFG.hs).
