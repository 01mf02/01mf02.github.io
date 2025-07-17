---
title: The `string_chars` problem and how internal references solve it
date: 2025-07-17
---

In this post, I write about a common pain point that I encountered
when working with Rust's `Iterator` trait, which can be demonstrated by
a simple example that I call the "`string_chars` problem".
I then explore the potential of Niko Matsakis's "[internal references]" proposal
to remedy this problem.

But first, I'll start with my experiences with LLMs to deal with hard programming problems, which is what got the ball rolling for this post.

[internal references]: https://smallcultfollowing.com/babysteps/blog/2024/06/02/the-borrow-checker-within/#step-4-internal-references


## LLM Experiments

This post was motivated by a conversation with my LLM-loving colleagues
about my experiences with LLMs.
After that conversation, I gave my colleagues a little live demo of how
LLMs fail to address seemingly very simple programming tasks.
The game goes as follows: You come up with a prompt à la:

> Write me a Rust function `fn f(...) -> ...`.

The LLM wins if and only if
it comes up with code that compiles or
if it shows that the function cannot be implemented.[^llm-game]

[^llm-game]: We are not even talking about writing code that actually "works", just about code that actually compiles. Rust is particularly suited for this game, because the type system is so expressive, so we can actually express many cool properties in the function signature that we could not do in, say, Python.

The first example I tried was:

> Write me a Rust function `fn<T, U>(x: T) -> U`.

The LLM (ChatGPT in my case) answered:

> In Rust, writing a function with the signature `fn<T, U>(x: T) -> U` is not possible without additional constraints.

It then explains quite thoroughly why this is not possible, and
how to modify the original function signature to make it implementable.
Fair enough. The LLM wins this round.

### The `string_chars` Problem

Let's try another one, which I call the "`string_chars` problem":

> Write me a Rust function `fn string_chars(s: String) -> impl Iterator<Item = char>`.

ChatGPT answers the following:

~~~
fn string_chars(s: String) -> impl Iterator<Item = char> {
    s.chars()
}
~~~

The problem is, [it does not compile](https://play.rust-lang.org/?version=stable&mode=debug&edition=2024&gist=bc2c2ad060b279a8cea21c70cc9a9071).

~~~
error[E0597]: `s` does not live long enough
 --> src/main.rs:2:5
  |
1 | fn string_chars(s: String) -> impl Iterator<Item = char> {
  |                 - binding `s` declared here
2 |     s.chars()
  |     ^--------
  |     |
  |     borrowed value does not live long enough
  |     opaque type requires that `s` is borrowed for `'static`
3 | }
  | - `s` dropped here while still borrowed
~~~

When telling ChatGPT "This does not compile.", it comes up with the following response:

> You're absolutely right — and thank you for pointing that out.
>
> The problem is that `s.chars()` borrows the `String`, but `s` is moved into the function, and the returned iterator would need to capture `s` by value (i.e. own it), which `chars()` alone doesn't do. This leads to a lifetime issue: the returned iterator would reference `s`, but `s` is dropped at the end of the function.

That sounds ... not too bad.

What follows is hilarious:

> ✅ Working version:
>
> ~~~ rust
> fn string_chars(s: String) -> impl Iterator<Item = char> {
>     s.into_chars()
> }
> ~~~
>
> Wait — actually, `String::into_chars()` doesn't exist.

At least, it is honest! Although it would be nice if it would think before it writes.
But that would presuppose that these language models can actually think.

ChatGPT's next attempt is fun too:

> So instead, we can use `std::iter::once` and `flat_map`:
>
> ~~~ rust
> fn string_chars(s: String) -> impl Iterator<Item = char> {
>     std::iter::once(s).flat_map(|s| s.chars())
> }
~~~

You know that often, when I read these solutions, my first reaction is like
"oh, this could actually work".
Until I'm quickly persuaded otherwise by the compiler.
More ChatGPT output:

> ✅ Alternative with `Box<dyn Iterator>` (trait object):
> 
> ~~~ rust
> fn string_chars(s: String) -> Box<dyn Iterator<Item = char>> {
>     Box::new(s.chars())
> }
> ~~~
> 
> This version avoids `impl Trait` and returns a boxed trait object instead, which works because the boxed iterator can own the `String` via closure capture.

To spoil it: *None* of the presented solutions even compiles.
The LLM loses the round.
I, for one, welcome our new AI overlords. ✅

I find this highly unfortunate.
I'm not talking about the lousy LLM performance here.[^llm]
I'm talking about the fact that there is no way to write a proper
`fn string_chars(s: String) -> impl Iterator<Item = char>` function
(without unsafe Rust or external libraries, see the [end of this post](#ps)).

[^llm]: In my humble opinion, the bad LLM performance is to be expected, because today's LLMs do not have access to programming tools, such as a Rust compiler. Today's LLMs only learn from what human beings have written about programming problems --- they cannot perform programming experiments themselves. Would you expect a medicine student who has read all existing medical literature, but who has never operated on a patient himself, to come up with a novel operation technique? And would you like to be the lucky first patient that this novel technique is tried on?

## Generalising the `string_chars` Problem

We can generalise the `string_chars` problem.
The underlying issue occurs whenever you have
a function that produces an `Iterator` from a reference `&T`, and
you call that function with an owned value `T` and return the resulting `Iterator`.

~~~ rust
struct T;
struct U;

fn f<'a>(_x: &'a T) -> impl Iterator<Item = U> + 'a {
    // just something that makes this code compile
    core::iter::empty()
}

fn g(x: T) -> impl Iterator<Item = U> {
    f(&x)
}
~~~

This triggers the same dreaded `error[E0597]: x does not live long enough`.

I have encountered this issue a *lot* of times during the last years.
It probably has to do with the fact that I am writing a program called
[`jaq`](https://github.com/01mf02/jaq)
which is very heavily based on `Iterator`s.
In particular, jaq consists of many functions that have the same shape as `g` above:
Take an owned value `T`, and return an iterator of values `U`.
This pattern is so deeply built into jaq's architecture that I cannot just write
my functions more akin to `f` above (take a `&T` instead of `T`).
Being unable to call iterator functions that take `&T` from
iterator functions that take `T` is very frustrating.

## Type Power

This issue violates an implicit assumption of mine about the power of types.
In my mental model, `T > &mut T > &T`.
In other words,
when you have a `T`, you can do everything with it that you can do with a `&mut T`, and
when you have a `&mut T`, you can do everything with it that you can do with a `&T`.
However, in this `Iterator` scenario, we can see that
having a `T` does not automatically enable to do the same things that you can do with `&T`.
Sometimes, `T` is worse than `&T`!
And I find that very confusing.


## Workarounds

When I saw people asking about similar `Iterator` problems on online forums,
chances are high that somebody will point out that you can do this:

~~~ rust
fn string_chars(s: String) -> impl Iterator<Item = char> {
    s.chars().collect::<Vec<_>>().into_iter()
}
~~~

In this particular case, that "works".
But it is a really poor solution, because it has to allocate memory.
And in some scenarios that are more complex than this toy example,
you cannot just `.collect().into_iter()` your way out:
For example, the underlying `Iterator` might yield infinitely many values.
Or the `Iterator` might yield values where each individual value is small enough to fit in memory, but all values together do not fit into RAM.
In these cases, it's game over.

Anyway, I hope that you agree with me that `.collect().into_iter()`
is a crutch --- it *might* get you where you want, but it's not elegant, and
good luck hiking up a mountain with it.


## Internal references

This brings me to one of my most anticipated developments in the Rust language: [internal references].
Niko Matsakis starts his blog post's section about them with the sentence:

> Rust today cannot support structs whose fields refer to data owned by another.

He then gives an example of a hypothetic Rust syntax where struct fields *can* refer to data:

~~~ rust
struct Message {
    text: String,
    headers: Vec<(&'self.text str, &'self.text str)>,
    body: &'self.text str,
}
~~~

Now where's the connection to the `Iterator` problem I outlined above?
Very simple: At some point, I wondered whether I could not make a struct
`StringChars` which I could construct from a `String` and on which I could then
implement `Iterator` manually myself.
`StringChars` would also need to hold on to a
[`core::str::Chars`](https://doc.rust-lang.org/core/str/struct.Chars.html)
(which is returned by [`str::chars`](https://doc.rust-lang.org/core/primitive.str.html#method.chars)),
and return its output whenever we call `StringChars::next()`.
How would this struct look like?

~~~ rust
struct StringChars {
    s: String,
    iter: core::str::Chars,
}
~~~

But this does not work:

~~~ rust
error[E0106]: missing lifetime specifier
 --> src/main.rs:3:22
  |
3 |     iter: core::str::Chars,
  |                      ^^^^^ expected named lifetime parameter
~~~

So what is the lifetime that we have to give to `Chars` here?
Enter internal references:

~~~ rust
struct StringChars {
    s: String,
    iter: core::str::Chars<&'self.s>,
}
~~~

Here, we say that `iter` lives as long as our `self.s`.
That would solve the `string_chars` problem!

My dream is that one day, we could even write the original "solution", and
Rust would create something like `StringChars` under the hood automatically:

~~~ rust
fn string_chars(s: String) -> impl Iterator<Item = char> {
    s.chars()
}
~~~


## Conclusion

I would love to see built-in internal references become a reality in Rust.
Rust's lack of internal references has already struck me as very awkward when I learnt the language,
and since then, I have continued to hit cases like the `string_chars` problem time and again.
These problems are especially hard to solve for newcomers, because
it is not clear from the naive definition of `string_chars` that
the underlying problem is that self-referential data is not allowed.
For that reason, internal references are clearly my #1 item on my wish list for Rust.


## Post Scriptum: Getting Internal References Today {#ps}

After having written the rest of this post, I found
[this very exhaustive answer](https://stackoverflow.com/a/32300133), which
links a few more self-referential struct libraries than Niko does.
In particular, I tried [ouroboros](https://crates.io/crates/ouroboros), but then
I quickly transitioned to [self_cell](https://crates.io/crates/self_cell),
because it has significantly fewer dependencies.

Lo and behold, here is a solution to the `string_chars` problem in today's Rust:

~~~ rust
use self_cell::self_cell;

type Chars<'a> = core::str::Chars<'a>;

self_cell!(
    struct StringChars {
        owner: String,

        #[not_covariant]
        dependent: Chars,
    }
);

impl Iterator for StringChars {
    type Item = char;
    fn next(&mut self) -> Option<char> {
        self.with_dependent_mut(|_owner, iter| iter.next())
    }
}

pub fn string_chars(s: String) -> impl Iterator<Item = char> {
    StringChars::new(s, |s| s.chars())
}

fn main() {
    let mut chars = string_chars("Hi!".to_string());
    assert_eq!(chars.next(), Some('H'));
    assert_eq!(chars.next(), Some('i'));
    assert_eq!(chars.next(), Some('!'));
}
~~~

In my opinion, *this* is the answer that an LLM should have given me.
But I cannot blame it;
the link between `string_chars` and self-referential structs is really not obvious.

Still, it would be nice if there was a more "built-in" way to do all this ...
