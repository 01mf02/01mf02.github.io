---
title: Theorems in Pandoc
---

**Update 29.4.2019**:
This article has been made obsolete by a [follow-up article](/blog/scientific-pandoc).
In particular, that article presents a method to write LaTeX environments
(such as theorems/proofs) that contain several paragraphs.

When writing mathematical Markdown documents, definitions, lemmas and proofs
can add considerably noise to the document. For example:

~~~ latex
\begin{definition}[Iteration]
The iteration of a function is $\iterate(f, x) = f(x) \cup \iterate(f, f(x)).$
\end{definition}
~~~

Wouldn't it be nicer to write the following?

~~~
Definition (Iteration).
The iteration of a function is $iterate(f, x) = f(x) \cup \iterate(f, f(x)).$
~~~

I had enough of scratching this itch, so I bandaged it with a nice
Pandoc filter that allows to you write stuff like above and render it correctly
with LaTeX. For example, you can write the following:

~~~
This is a little example of how to use naturally-looking
mathematical environments in Pandoc.

Definition (Natural numbers). \label{def:nat}
Let $mathbb{N}$ the set ${0, 1, 2, \ldots}$.

We now use definition \ref{def:nat} to show a simple property.

Lemma. $\mathbb{N}$ is infinite.

Proof. Trivial.

This leads us to our main result.

Theorem (Greatest element). There does not exist a greatest element in $\mathbb{N}$.

Proof (Proof of the main theorem). Also trivial.
~~~

To use it, we first create a file where we put our environment definitions.
Call it "envs.tex", for example:

~~~ latex
\usepackage{amsthm}

\newtheorem{definition}{Definition}
\newtheorem{lemma}{Lemma}
\newtheorem{theorem}{Theorem}
~~~

Now, get ready for the main Pandoc filter.
Save it under "environmentalize.hs" and make it executable.

~~~ haskell
#!/usr/bin/env runghc
import Data.List (stripPrefix)
import Data.Maybe (isJust, fromJust, fromMaybe)
import Text.Pandoc.JSON

main :: IO ()
main = toJSONFilter replaceEnvs

-- | See stripPrefix.
stripPostfix :: Eq a => [a] -> [a] -> Maybe [a]
stripPostfix post l = reverse <$> stripPrefix (reverse post) (reverse l)

fromStr :: Inline -> Maybe String
fromStr (Str s) = Just s
fromStr _ = Nothing

stripStrPostfix :: String -> Inline -> Maybe String
stripStrPostfix post inline = fromStr inline >>= stripPostfix post

-- | If the list of Inlines starts with a Str that starts with the prefix
-- and the list contains a Str that ends with the postfix, then
-- return everything between prefix and postfix, as well as everything after.
--
-- Example:
--     inlineBetween "(" ")" [Str "(What", Space, Str "else?)", Str "Text"] =
--     Just ([Str "What", Space, Str "else?"], [Str "Text"])
inlineBetween :: String -> String -> [Inline] -> Maybe ([Inline], [Inline])
inlineBetween pre post (Str s : xs) | Just s' <- stripPrefix pre s =
  case break (isJust . stripStrPostfix post) (Str s' : xs) of
    (_, []) -> Nothing
    (x, y:ys) -> Just (x ++ [Str $ fromJust $ stripStrPostfix post y], ys)
inlineBetween _ _ _ = Nothing

envs :: [(String, String)]
envs =
  [ ("Definition", "definition")
  , ("Lemma", "lemma")
  , ("Theorem", "theorem")
  , ("Proof", "proof")
  ]

-- | Try all different environment types.
replaceEnvs :: Maybe Format -> Block -> Block
replaceEnvs fmt blk = foldr ($) blk (map (replaceEnv fmt) envs)

makeEnv :: String -> Maybe [Inline] -> Maybe String -> [Inline] -> [Inline]
makeEnv env name label text =
  maybe ([tex begin]) (\ n -> [tex $ begin ++ "["] ++ n ++ [tex "]"]) name ++
  maybe [] (\ l -> [tex $ "\\label{" ++ l ++ "}"]) label ++
  text ++ [tex end]
  where
    tex = RawInline (Format "latex")
    begin = "\\begin{" ++ env ++ "}"
    end   = "\\end{"   ++ env ++ "}"

-- | Try to read name and create environment.
nameEnv :: String -> Maybe String -> [Inline] -> Maybe Block
nameEnv env label ys = paraEnv <$> inlineBetween "(" ")." ys
  where paraEnv (name, rest) = Para $ makeEnv env (Just name) label rest

-- | Try to read label and name, and create environment.
labelNameEnv :: String -> [Inline] -> Maybe Block
labelNameEnv env ys = case ys of
  -- Example: Theorem pyth.
  Str (l:bld) : zs | l /= '(', Just bl <- stripPostfix "." bld ->
    Just $ Para $ makeEnv env Nothing (Just (l:bl)) zs
  -- Example: Theorem pyth (Pythagoras).
  Str (l:bl) : Space : zs | l /= '(' -> nameEnv env (Just (l:bl)) zs
  -- Example: Theorem (Pythagoras).
  _ -> nameEnv env Nothing ys
  

replaceEnv :: Maybe Format -> (String, String) -> Block -> Block
replaceEnv (Just (Format "latex")) (txt, latex) p@(Para (Str x : xs)) =
  if x == txt ++ "." then Para $ makeEnv latex Nothing Nothing xs
  else if x == txt then case xs of
    (Space : ys) -> fromMaybe p (labelNameEnv latex ys)
    _ -> p
  else p
replaceEnv _ _ x = x
~~~

Now, you can run Pandoc with the filter as follows (`-H` includes something
at the end of the *h*eader):

    pandoc --filter ./environmentalize.hs test.md -H envs.tex -o test.pdf

Have fun with mathematical environments in Pandoc! :)

P.S.: It is currently quite cumbersome to "parse" the `Inline` lists of Pandoc.
Something like Parsec for Pandoc would be definitely cool, and problems
like this one could probably be solved much more elegantly than with my
ad-hoc low-level parsing functions.

