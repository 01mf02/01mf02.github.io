---
layout: post
title: Running Turing machines in Haskell
---

Creating a Turing machine simulator qualifies as a "been there, done that" project. So I set out to create my own simulator in Haskell, trying to see how simple I could make it.


## Turing machine description

Let us shortly recall what a Turing machine is. A Turing machine consists of:

* A tape, which stores a sequence of symbols.
* A tape head, which can be read and write symbols on the tape.
* A finite set of states, among which there is a unique starting, accepting and rejecting state.
* A transition function δ.

(This is only one possible way to describe a Turing machine. There are approximately a gazillion other approaches.)

The purpose of a Turing machine is to determine for a given input word whether it accepts or rejects this word. To do so, at first the input word is written to the tape, the tape head is placed on the first symbol of the input word, and the machine's current state is set to its starting state.
In each state, the machine does the following:

1. Read the symbol on the tape under the tape head.
2. Replace tape symbol by a new symbol.
3. Move tape head by one position left or right.
4. Set the machine's current state to a new state.

More formally, the exact behaviour of the machine in each state is determined by the machine's transition function δ(s, c) = (s', c', d): When the machine is in the state s and it reads the symbol c from the tape head, it will overwrite the symbol c under the tape head with c', move the tape head in the direction determined by d ∈ {→, ←}, and it will finally set its new state to s'.

As soon as the machine reaches its accepting or rejecting state, it halts -- the word is accepted respectively rejected. It can also be the case that the machine will never reach an accepting or rejecting state, in which case the machine will run forever (or at least as long as nobody pulls the plug) -- it does not terminate.

Let us pay some attention to the tape: The tape has finite length, namely at first the length of the input word. However, when the tape head goes beyond the tape (either to the left or to the right), the tape gets automatically extended by one, and the tape head reads a blank symbol. That way, the Turing machine can allocate a principally infinite amount of memory on the tape.


## Haskell

The implementation of the Turing machine as described above turned out to be relatively easy. The most complicated part turned out to be how to represent the tape and the tape head efficiently: I represent these by the sequence of symbols on the tape to the left of the tape head, the symbol under the tape head, and finally the sequence of symbols to the right of the tape head. One could represent these sequences by Haskell lists, but consider that when the tape head moves left, we have to obtain the rightmost (i.e. last) symbol from the tape part to the left of the the tape head position, and obtaining the last element of a list in Haskell is slow. For this reason, I chose Haskell's Sequence datatype, which, among other nice features, allows constant-time retrieval of the last sequence element. Here I'd like to quote Dan Burton, who called Haskell's sequences ["functional awesomesauce"](http://stackoverflow.com/a/9613203).

Now, without further ado, here is the code:

~~~ haskell
module Turing where

import           Data.Foldable (toList)
import qualified Data.List as L
import qualified Data.Sequence as Seq
import           Data.Sequence (Seq, (<|), (|>), ViewL (..), ViewR(..))

type State = Int
type Symbol = Char

-- | Tape head movement direction.
data Direction = MoveLeft | MoveRight

data Machine = Machine {
  -- | @'transition' s smb@ defines the behaviour of the machine when it
  -- is in state @s@ and @smb@ is the symbol under the tape head.
  -- The function returns the next state of the machine,
  -- the symbol overwriting the current symbol under the tape head,
  -- and the direction in which the tape head should move after overwriting.
  --
  -- If @smb@ is @'Just' x@, that signifies that @x@ is the current symbol
  -- under the tape head.
  -- If @smb@ is 'Nothing', that means that the tape head is over a
  -- tape position that has not been initialised yet.
  transition :: State -> Maybe Symbol -> (State, Symbol, Direction)

, startState, acceptState, rejectState :: State
}

data TapeCfg = TapeCfg {
  leftSyms  :: Seq Symbol    -- ^ symbols to the left of tape head
, currSym   :: Maybe Symbol  -- ^ symbol under the tape head
, rightSyms :: Seq Symbol    -- ^ symbols to the right of tape head
}

data MachineCfg = MachineCfg {
  currState :: State
, tapeCfg :: TapeCfg
}

instance Show TapeCfg where
  show (TapeCfg l c r) = toList l ++ [maybe ' ' id c] ++ toList r

instance Show MachineCfg where
  show (MachineCfg s t) =
    show t ++ "\n" ++ replicate (Seq.length $ leftSyms t) ' ' ++ "| q" ++ show s
  showList = showString . L.intercalate "\n\n" . map show

-- | Replace symbol under tape head with new symbol, then move tape head.
updateTapeCfg :: TapeCfg -> Symbol -> Direction -> TapeCfg
updateTapeCfg (TapeCfg lSyms _ rSyms) newSym MoveLeft =
  case Seq.viewr lSyms of EmptyR -> TapeCfg Seq.empty Nothing right
                          lInit :> lLast -> TapeCfg lInit (Just lLast) right
  where right = newSym <| rSyms
updateTapeCfg (TapeCfg lSyms _ rSyms) newSym MoveRight =
  case Seq.viewl rSyms of EmptyL -> TapeCfg left Nothing Seq.empty
                          rHead :< rTail -> TapeCfg left (Just rHead) rTail
  where left = lSyms |> newSym

-- | Execute one transition step for given machine and config.
updateMachineCfg :: Machine -> MachineCfg -> MachineCfg
updateMachineCfg m (MachineCfg state tape) =
  let (state', newSym, dir) = transition m state (currSym tape)
  in MachineCfg state' $ updateTapeCfg tape newSym dir

-- | Initialise tape with input word.
initTapeCfg :: [Symbol] -> TapeCfg
initTapeCfg [] = TapeCfg Seq.empty Nothing Seq.empty
initTapeCfg (x:xs) = TapeCfg Seq.empty (Just x) (Seq.fromList xs)

-- | Initialise machine config with input word.
initMachineCfg :: Machine -> [Symbol] -> MachineCfg
initMachineCfg m input = MachineCfg (startState m) (initTapeCfg input)

-- | Return true if the machine is in a final state.
machineCfgFinal :: Machine -> MachineCfg -> Bool
machineCfgFinal m (MachineCfg {currState = c}) =
  c == acceptState m ||
  c == rejectState m

-- | Return sequence of machine configs for given input word until final state.
runMachine :: Machine -> [Symbol] -> [MachineCfg]
runMachine m =
  break' (machineCfgFinal m) . iterate (updateMachineCfg m) . initMachineCfg m
  where
    -- | Like 'break', but also return first element that fulfills condition
    break' p xs = let (prefix, rest) = break p xs in prefix ++ [head rest]
~~~

Now we would like to test this code on an example machine. For this, I made a very simple Turing machine: It starts in state 0 and will move to the right as long as it reads any symbol (`Just x` in the code below) on the tape. As soon as the tape head goes beyond the tape (represented by `Nothing` in the code below), it writes an 'E' there and goes to state 1. In this state, it will just move the tape head all the way back to the left until the start of the tape, at which point it will write an 'S' to the tape and go into state 2, which is the accepting state.
It is easy to see that this machine terminates on all possible inputs.


~~~ haskell
-- | A Turing machine accepting all input.
testMachine :: Machine
testMachine =
  Machine { transition = t
          , startState = 0
          , acceptState = 2
          , rejectState = 3} where

  t 0 (Just x) = (0,   x, MoveRight)
  t 0 Nothing  = (1, 'E', MoveLeft)
  t 1 (Just x) = (1,   x, MoveLeft)
  t 1 Nothing  = (2, 'S', MoveRight)

main = print $ runMachine testMachine "10011"
~~~

What is the output of running this?

~~~
michi ~ $ runhaskell Turing.hs
10011
| q0

10011
 | q0

10011
  | q0

10011
   | q0

10011
    | q0

10011 
     | q0

10011E
    | q1

10011E
   | q1

10011E
  | q1

10011E
 | q1

10011E
| q1

 10011E
| q1

S10011E
 | q2
~~~


In the output, we see the different configurations of the Turing machine for the input word "10011". The '|' signifies the current position of the tape head, and the "qn" signifies the current state. In the last configuration, we see that the Turing machine has reached state q2, and because q2 is the accepting state, we know that the Turing machine has accepted the input word.


I hope that this article has been instructive. Have fun playing with [the code]($media$/Turing.hs), and if you want something more visual to get a feeling for Turing machines, I can warmly recommend you to look at [Manufactoria](http://pleasingfungus.com/Manufactoria/). It has certainly delayed the publication of this article by several hours. ;)
