import Control.Arrow ((&&&))
import Control.Monad (guard, replicateM)
import Data.List ((\\), sort, nub)

solutions l r nl nr
  | length l <= nl = return [l]
  | otherwise = do
    (ltr, l' , r' ) <- move nl l  r
    (rtl, r'', l'') <- move nr r' l'
  
    rest <- solutions l'' r'' nl nr
    return $ ltr : rtl : rest
  
move n from to = do
  xs <- replicateM n from
  guard (nub xs == xs)
  return (xs, from \\ xs, to ++ xs)


solutions1 l r | length l <= 2 = return [l]
               | otherwise = do
  l1 <- l
  l2 <- l
  guard (l1 /= l2)
  let l' = l \\ [l1, l2]
  let r' = r ++ [l1, l2]

  r1 <- r'
  let l'' = l' ++ [r1]
  let r'' = r' \\ [r1]

  rest <- solutions1 l'' r''
  return $ [l1, l2] : [r1] : rest
  


time = sum . map maximum

evaluate = sort . map (time &&& id)

main = print $ head $ evaluate $ solutions [5, 10, 20, 25] [] 2 1
