---
title: Flamegraphs for recursive functions in Rust
---

Some time ago, I tried to create a flamegraph for a program of mine,
to find out which functions take which share of the program runtime.
However, I found that the flamegraph generated by `cargo flamegraph`
was completely unusable for me.
This was because my program used two mutually recursive functions
(functions that call each other repeatedly).
In this post, I will demonstrate the problem and how to solve it.

Let us make a new Rust project called `even-odd` by calling `cargo new even-odd`.
Then change to the `even-odd` directory and write the following to `src/main.rs`:

~~~ rust
fn even(n: usize) -> bool {
    if n == 0 {
        true
    } else {
        odd(n - 1)
    }
}

fn odd(n: usize) -> bool {
    if n == 0 {
        false
    } else {
        even(n - 1)
    }
}

fn main() {
    println!("{}", even(100_000));
}
~~~

This is a toy benchmark that contains two mutually recursive functions, `even` and `odd`.
(You can see that because `even` calls `odd` and `odd` calls `even`.)

Normally, you build code for good performance in release mode, by `cargo build --release`.
However, when building this toy benchmark in release mode,
the compiler realises that `even(100_000)` evaluates to true,
so `even(100_000)` is actually not evaluated at run-time.
Therefore, we are going to build this benchmark in dev mode, by `cargo build`.

Now, how to create a flamegraph?
I installed the `flamegraph` crate following
[its instructions](https://crates.io/crates/flamegraph).
Once this is done, `cargo flamegraph` builds and runs your program with profiling enabled.
However, watch out because unlike `cargo run`,
`cargo flamegraph` builds by default in release mode.
To have it build in dev mode (as needed here), use `cargo flamegraph --dev`.

To collect performance statistics, you will likely need to run the following
if you are on a Linux system:

    sudo sysctl -w kernel.perf_event_paranoid=1

(Source: <https://superuser.com/a/980757>)

Finally, we should be getting a result in `flamegraph.svg` that looks as follows:

{% include image.html caption="Tower of flame." media="high.svg" %}

A high tower, isn't it?
We can see sequences of `even`, `odd`, `even`, `odd`, ...,
which represent a snapshot of the call stack.
Unfortunately, if `even` or `odd` would call other functions to perform some actual work
(as was the case for my own application),
we could not easily see the cost of these other functions, as
we would not see the forest for the trees.

The solution is the following: Scrap `cargo flamegraph`.
We will manually fiddle with the perf output.

For this, I created a script that I called `graph.sh`.
It runs a given command and collapses recursive calls to a single call.

~~~ bash
#!/bin/bash

# name of the cargo package (substitute '-' with '_'!)
NAME=even_odd

# run the command given in the arguments and collect performance statistics
perf record --call-graph dwarf $@

# process the performance statistics:
# map the first occurrence of either `even` or `odd` in a flame to `eveod`, and drop the rest
perf script | inferno-collapse-perf | sed \
  -e 's/;'$NAME'::\(even\|odd\)/;'$NAME'::eveod/' \
  -e 's/;'$NAME'::\(even\|odd\)//g' > stacks.folded

# create the flamegraph
cat stacks.folded | inferno-flamegraph > flamegraph.svg
~~~

The magic is in the `sed` command.
To understand this, just run `perf script | inferno-collapse-perf` yourself.
This gives you a list of "snapshots", where every snapshot is a call trace.
In every call trace, `sed`
keeps the first occurrence of `even` or `odd`, mapping it to `eveod`, and
removes all remaining occurrences of `even` and `odd`.
(The replacement name `eveod` must not be a prefix of neither `even` nor `odd`,
otherwise it is erased by the second `sed` expression.)

To use this script:

    cargo build
    ./graph.sh target/debug/even-odd

Its output looks like this:

{% include image.html caption="A much nicer flamegraph." media="flat.svg" %}

We can now see that all calls to `even` and `odd` are represented by `eveod`.
If `even` and `odd` would be calling other functions,
we could now better estimate their costs.
