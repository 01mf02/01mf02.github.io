---
title: Preventing supply chain attacks with pure crates
author: Michael Färber
---

I was deeply shocked by the discovery of the [XZ Utils backdoor].
In a nutshell, there was an malicious attempt to
introduce a security breach in a huge number of Linux systems,
which would have allowed a complete remote takeover of these systems.
This attack was extremely sophisticated, combining
social engineering and technical camouflage tactics
over the timespan of several years.

[XZ Utils backdoor]: https://en.wikipedia.org/wiki/XZ_Utils_backdoor

As the maintainer of [a fairly popular open-source tool][jaq],
I am concerned about the security of its users.
That means that I am trying to protect users of my software by
applying great care that my software only uses benign dependencies.
However, this task is quite nontrivial, and
I can confidently say that I would _not_ have detected
a sophisticated backdoor --- like the one in `xz` ---
in a dependency of my software.
I also do not have the motivation to
do a rigorous security check every time I update a dependency.
Therefore, I can actually not really be sure that
the software I am releasing does not ship some backdoor.
And I believe that the same holds true for
a large majority of open-source projects.
I find this quite disturbing.

[jaq]: https://github.com/01mf02/jaq

One of my worst nightmares as maintainer of an open-source software is:
I'm updating a dependency of my software, for example the [`regex`][regex] crate.
However, this dependency has been taken over by
a malicious actor (like `xz` has been), and
either at compile- or run-time, it discloses my credentials,
i.e. SSH keys and `crates.io` token.
This allows the malicious actor to create commits and to
upload new (infected) versions of my software, infecting all users downloading it.

[regex]: https://docs.rs/regex/latest/regex/

How can we prevent such a catastrophic scenario from happening?

## Inspiration: Rust's `no_std` feature

In Rust, we have an amazing feature that can serve as
inspiration for how to prevent future supply chain attacks.
It is called `no_std`.
In a nutshell, when this feature is used in a software, it disables
access to Rust's standard library and thus also to most "dangerous" functions,
such as loading/writing files, networking, and so on.
In the remainder of this text, I will call such functionality simply "I/O".
`no_std` serves the purpose of making a library _portable_,
because software that uses `no_std` can then be used in
environments without an operating system, such as embedded systems.

The `no_std` attribute has a soothing air to it;
since I heard of it, I use it in nearly all of my projects,
because it gives me a good feeling that
my projects are usable in more restricted environments.
However, `no_std` restricts only calls to
the parts of Rust's standard library that perform I/O,
but it does not prevent I/O altogether!
That means that a crate that is `no_std` can _still_
send your private data to the Internet, for example
by performing system calls via assembly code.

However, I suppose that in practice,
many `no_std` libraries are actually not doing any I/O.
For example, the aforementioned [`regex`][regex] crate is `no_std`, and
I think that most people would be very surprised if `regex` performed any I/O.
That's why compared to other language ecosystems,
Rust has a head-start in preventing supply chain attacks:
We already have a large potential number of crates that
do not perform I/O in order to be usable in `no_std` contexts.
However, we currently do not have a way to
assure that they are _really_ not doing any I/O,
because `no_std` does not guarantee that.

## My proposition: Pure crates

That's where my proposition comes in:
I propose to introduce the notion of _pure crates_.

A _pure crate_ is a crate that cannot perform any I/O,
neither at compile nor at run time.
By default, any crate is _impure_; that is, it can perform I/O.
Crates can be made pure by opt-in.

Pure crates need to satisfy a number of conditions:
- Inside a pure crate, we may not use language constructs
  that allow us to perform I/O, such as assembly, FFI, ...
- Pure crates can only depend on
  [`core`](https://doc.rust-lang.org/core/),
  [`alloc`](https://doc.rust-lang.org/alloc/), and other pure crates.
  This prevents hiding I/O in dependencies.
  As a result, every pure crate is automatically `no_std`.
  (However, not every `no_std` crate is pure.)
- The build process may not perform any I/O.
  Initially, that may be assured by forbidding the execution of
  build scripts, i.e. `build.rs`.
  Later, this restriction could be relaxed by
  allowing such execution, but sandboxing it with something like [watt].

[watt]: https://docs.rs/watt/latest/watt/

When updating from one crate version that is pure to another that is impure,
there should be an error in order to prevent the purity property from being broken silently.

When we have a pure crate, we can be sure that
neither building nor running it will perform I/O.
This gives us a way to identify a set of crates
that we can try and depend on safely, without having to worry about
security breaches, supply chain attacks etc.

For most `no_std` crates, the effort required to make it pure should be not too large.
From my own experience, I would say that most of my own `no_std` crates
could already today be declared pure without any changes to the source code.

## How to make pure crates a reality?

Implementing pure crates in the Rust ecosystem would require changes in several components:

- The Rust compiler would need to be adapted to disallow certain
  language constructs when compiling code marked as pure.
  This would only require a syntactic analysis of the source code,
  so it should not be too difficult to do.
  In particular, pure code should not be able to:
  - declare `extern` blocks:
    This is to disallow calling libraries in other languages (which may do I/O),
    see <https://doc.rust-lang.org/nomicon/ffi.html>.
    (Note that it would not be enough to prevent _calling_ code in `extern` blocks,
    because just exposing functions in `extern` blocks
    might make users call them, assuming that they are pure,
    when they might actually perform I/O.)
  - call [`asm!`](https://doc.rust-lang.org/core/arch/macro.asm.html):
    This is to disallow making syscalls via Assembly code.

  I am not sure whether these two restrictions are enough on the compiler side.
  Without `libstd`, can we perform I/O with some other methods than `extern` and `asm!`?
- The `cargo` tool would need to be adapted to verify that:
  - Building a pure package performs no side effects
    (initially by forbidding `build.rs`, later by sandboxing).
  - All dependencies of a pure package are pure or `liballoc`/`libcore`.
  - Updated versions of a pure package remain pure.

Purity should probably be a crate property that goes into `Cargo.toml`,
because dependencies also have to be pure.

## Open question: features

So far, everything was mostly magic and sparkles. Now comes the ugly part.

The biggest open question that I see concerns crates with features.
In particular, there are many crates like [`serde`] which are `no_std`, but
have a feature `std` which enables code to be generated for types in `libstd`.
This is used frequently to implement traits, such as for
[`Serialize` for `HashMap`](https://docs.rs/serde/latest/serde/ser/trait.Serialize.html#impl-Serialize-for-HashMap%3CK,+V,+H%3E).
Due to the [orphan rule](https://doc.rust-lang.org/book/ch10-02-traits.html#implementing-a-trait-on-a-type),
we can only implement `Serialize` for `libstd` types inside the `serde` crate itself.
With my current proposal above, such code could not be generated for a pure `serde`,
because a pure `serde` could not depend on `libstd`.

[`serde`]: https://docs.rs/serde

This is a huge block for the adoption of pure crates the way I introduced them above.
Addressing this question is likely the most controversial part of this whole proposal.

To solve this issue, we could think about making purity depend on feature flags, such as
"if the following feature is enabled, this crate becomes impure".
This could be written as follows:

~~~ toml
[features]
# the presence of this feature indicates that we are creating a pure crate
# however, when this feature is enabled, then this crate may contain impure parts
impure = []

alloc = []
default = ["std"]
derive = ["serde_derive"]
rc = []
std = ["impure"]
unstable = []
~~~

This means that by default, `serde` aspires to be a pure crate,
because we are defining the `impure` feature.
However, if the `std` feature is enabled, parts of the crate may become impure.
This would allow `serde` to implement traits for `libstd` types that are
conditionally compiled when the `std` feature is enabled.

That means that we can also divide features into pure and impure features.
Any feature that causes the `impure` feature to be enabled is an impure feature,
and all other features are pure features.

However, when following this approach naively, this could compromise security:
For example, suppose that we are working on an impure crate `A` and a pure crate `B`.
`A` depends on `B`. Furthermore,
`A` depends on some crate with impure features, e.g. `serde` with the `std` feature, and
`B` depends on the same crate with only pure features, say, `serde` with the `alloc` feature.

~~~
   features = std
A -------------------🡮
↓                  serde (features = std + alloc)
B -------------------🡥
   features = alloc
~~~

Because [features are additive](https://doc.rust-lang.org/cargo/reference/features.html#feature-unification),
`serde` would be compiled with the `alloc` AND the `std` features, making `serde` impure.
This would actually make `B`, a pure crate, depend on an impure crate!
This could be exploited by putting some code doing I/O into a function
and wrapping this code by `#[cfg(feature = "evil")]`.
Some dependency might then enable the `evil` feature for that crate,
which leads the I/O code to be executed.

We could address this issue by
restricting the use of `#[cfg(feature = ...)]` and friends in code.
For example, we could impose for a pure crate that if
`#[cfg(feature = ...)]` checks for an impure feature, then
it cannot modify code or types that would have been generated for pure features only.
For example, we could use `#[cfg(feature = "std")]` only to expose
new modules,
new functions,
new traits,
new trait implementations, but _not_ to
insert code into existing functions,
modify existing data types and so on.
For the example above, this means that all calls from the pure crate `B` to `serde`
will not perform any I/O, even if parts of the `serde` crate _may_ perform I/O,
due to impure features being enabled for it by `A`.

I think that this approach would be enough to address a large majority of
the use cases that would otherwise be excluded by
my initial --- pardon the pun --- more purist approach that did not consider feature flags.
However, this comes at some additional implementation cost in the Rust compiler.

## Conclusion

There exists a large number of crates for which
users assume that they do not perform I/O,
but in the current Rust ecosystem,
there is no way to machine-check these assumptions.
I propose the concept of pure crates to
make these assumptions explicit and verifiable.

While not all dependencies of a typical program will be pure,
pure crates have the potential to
drastically reduce the amount of code that we should review when
we include a new dependency or update an existing one, instead
allowing us to focus on impure packages in security analyses.

At the same time, I believe that the criteria to make a crate pure are
sufficiently lax to allow many `no_std` crates to be made pure with little effort.
This should nudge library authors towards using it, similarly to `no_std` today.

I believe that the implementation of pure crates would prevent a
very wide range of supply chain attacks in the Rust ecosystem.
For example, if the [`rust_decimal`][rust_decimal] crate would have been pure,
adding the malicious typo-squatting [`rustdecimal`][rustdecimal] crate
as a dependency to a pure crate would have failed,
because it would have been necessarily impure
(due to its backdoor installation involving I/O).
It could also serve to prevent accidental security breaches such as
the [Log4Shell] one in `Log4j`.
It would certainly make me sleep better.

[rust_decimal]: https://docs.rs/rust_decimal
[rustdecimal]: https://blog.rust-lang.org/2022/05/10/malicious-crate-rustdecimal.html
[Log4Shell]: https://en.wikipedia.org/wiki/Log4Shell


<!-- Other ideas:
One way would be to combine credentials, such as Git keys,
with 2FA, such that creating a new release could be made
to require signing with a FIDO token or similar.
This would already drastically increase my confidence,
given that I am not sitting on a time bomb of
having precious files lying around that any
process on my computer can access.

crates uploaded to crates.io are
_not_ guaranteed to correspond to any particular Git commit
build.rs can perform arbitrary syscalls during checking
However, it is not easy to sandbox build.rs scripts,
because many actually _have_ to call system utilities,
for example to run a C compiler, or `pkg-config` etc.
However, it would be already a nice thing if
we could somehow preserve certain invariants between
updates of a crate.
For example, we might check before using a crate that
it does not have a build script (`build.rs`),
and save this information somewhere, e.g. in `Cargo.toml`.
When an update then introduces a `build.rs`,
this should trigger an error.
The best thing would be some kind of mode in which
we only permit pure operations from crates,
and we have to specially whitelist crates which do anything
beyond this (such as performing I/O, syscalls, ...)
This would have helped to catch something like the log4j breach
as well as xz, because the xz library should actually not
have needed to perform any kind of I/O.
Of course, running functions from a library can also infect a system,
but at least in the latter case, `no_std` can be enforced
-->
