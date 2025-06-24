---
title: A Data Bridge from Rust to Haskell
date: 2025-06-24
---

This post describes a method to serialise a complex Rust data structure and
to deserialise it to a corresponding Haskell data structure,
without any external dependencies and with only minimal boilerplate.

## Problem & Research

Recently, I wanted to process some data (jq programs) in a Haskell program.
I had previously written a jq parser in Rust, so my first approach was to write a small jq parser in Haskell. However, I quickly found myself bored and annoyed to write one more parser for the same format.

Thus I started to think about using my Rust-written jq parser from my Haskell program. I would somehow need to serialise the output of my parser into some intermediate format, then deserialise from that format to a data structure in Haskell.
I additionally had a few constraints: In particular, I did not want to use any external dependencies on the Haskell side, because I had made some painful experiences with Haskell's package management from years ago. Furthermore, I also did not want to add any new dependencies to my Rust code. In addition, if possible, I wanted to write a minimum of code for this (de-)serialisation task.

At first, I found that GHC (Haskell's main compiler) ships a [binary en-/decoding package](https://hackage.haskell.org/package/binary). While that initially looked quite promising, I decided against using it because this library has a function `putStringUtf8` to *encode* a string, but it does not have a corresponding function `getStringUtf8` to *decode* a string. Given that strings are one of the data structures I need to encode the most and I did not find easily how to implement `getStringUtf8` myself, I reconsidered my choice of using this library.

Searching a bit more, I found Haskell's [`Read`](https://hackage.haskell.org/package/base/docs/Text-Read.html) class. This allows you to automatically generate a parser for your Haskell data types. Because writing data parsers is generally much harder than writing data printers, I figured that I could simply write data on the Rust side that can then be read by Haskell's automatically generated parser.

However, it gets even better: I found out that if I stick to a certain subset of data structures on both the Haskell and the Rust side, then I can automatically generate a printer on the Rust side using `#[derive(Debug)]` and automatically generate a parser on the Haskell side using `deriving Read`.

I will now write give you some example code that shows how to automatically
(de-)serialise data from Rust to Haskell.
You can find the full source code in the `ujq` folder of
[this repository](https://github.com/01mf02/jq-lang-spec/).

## Serialisation

Consider the following Rust code:

~~~ rust
#[derive(Debug)]
pub enum Term<S> {
    Id,
    Str(S),
    Arr(Option<Box<Self>>),
    Pipe(Box<Self>, Option<Pattern<S>>, Box<Self>),
}

#[derive(Debug)]
pub enum Pattern<S> {
    Var(S),
    Arr(Vec<Self>),
}
~~~

(I use `S` as a type parameter on the Rust side for unrelated reasons;
just pretend that I am using `String` in place for `S` everywhere.)

When printing a `tm: Term` with `println!("{tm:?}")`, this yields something like:

~~~
Arr(Some(Pipe(Id, Some(Arr([Var("$x"), Var("$y")])), Str("a"))))
~~~

## Deserialisation

Now to the Haskell side: How to deserialise a term that was output via Rust's `Debug`?
Let us first define data structures in Haskell analogous to the Rust side:

~~~ haskell
data Term =
    Id
  | Str(String)
  | Arr(Option Term)
  | Pipe(Term, Option Pattern, Term)
  deriving (Read, Show)

data Pattern = Var(String) | Arr([Pattern])
  deriving (Read, Show)
~~~

Here, we have our first problem: In Rust, we can define in the same module
multiple data types with constructors that have the same name;
in our example, we have `Term::Arr` and `Pattern::Arr`.
This is not possible in Haskell; therefore,
we cannot put `Term` and `Pattern` into the same file.

So we have to move `Pattern` to a different Haskell module and
import that from the `Term` module.

Note that I used some slightly non-idiomatic Haskell here:
In Haskell, you would rather write
`Pipe Term (Option Pattern) Term` instead of
`Pipe(Term, Option Pattern, Term)`.
However, when we use the more idiomatic version, the auto-generated
parser cannot parse terms of the shape `Pipe(a, b, c)`, only `Pipe a b c`.
Because Rust outputs terms of the shape `Pipe(a, b, c)`,
we use the less idiomatic version here.

Next, you might notice that I used an `Option` type on the Haskell side,
analogous to the Rust `Option` type --- but Haskell does not have `Option`.
Haskell has `Maybe`, baby.
No big deal.
I defined an `Option` type in Haskell the same way as in Rust, and
made a helper function to convert from `Option` to `Maybe`:

~~~ haskell
data Option a = None | Some(a)
  deriving (Read, Show)

toMaybe :: Option a -> Maybe a
toMaybe None = Nothing
toMaybe (Some(x)) = Just x
~~~

## Putting things together

I made a little shell script that passes its first argument to the Rust parser.
The Rust parser then writes its `Debug` output on stdout, from where
the Haskell program picks it up:

~~~
echo "$1" | ./rust-parser | ./haskell-reader
~~~

The Rust part reads from stdin, runs the parser, and serialises its output:

~~~ rust
fn main() {
    let s = std::io::read_to_string(std::io::stdin()).unwrap();
    let tm = parse(&s).unwrap();
    println!("{tm:?}");
}
~~~

The Haskell part captures the serialised Rust data on stdin and
parses it to the corresponding Haskell `Term` with `read`:

~~~
main :: IO ()
main = do
  stdin <- getContents
  let term :: Term = read stdin
  print term
~~~

And that just works nicely!

## Restrictions

On the Rust side, I have something like this:

~~~ rust
pub struct Def<S> {
    pub name: S,
    pub args: Vec<S>,
}
~~~

I tried to make a Haskell counterpart for this as follows:

~~~ haskell
data Def = Def {
  name :: String,
  args :: [String],
}
~~~

However, Haskell uses a different syntax than Rust to create values of such types:

~~~
-- Haskell
Def {name = "f", args = []}
// Rust
Def {name: "f", args: []}
~~~

That means that Haskell's auto-generated `Read` for `Def` cannot parse
the output of Rust's auto-generated `Debug` for `Def`.
Because I did not want to change the `Def` type on the Rust side,
I did simply create a custom `Debug` implementation for it:

~~~ rust
impl<S: Debug> Debug for Def<S> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "({:?}, {:?})", self.name, self.args)
    }
}
~~~

(That was the only change that I made to the Rust code base!)
On the Haskell side, I simply introduced:

~~~ haskell
type Def = (String, [String])
~~~

Alternatively, I could have written

~~~ rust
struct Def<S>(S, Vec<S>);
~~~

on the Rust side and

~~~ haskell
data Def = Def(String, [String])
~~~

on the Haskell side.

I noticed that Rust also has a slightly different way to print Unicode characters.
In particular, it prints stuff like `\u{1}`, which Haskell does not understand.
I do not expect such characters in my data, so I do not care about this.
