import Data.Maybe
import Text.HTML.TagSoup
import Text.HTML.TagSoup.Tree

main =
  (renderTags . withTree transform . parseTags) <$> readFile "chronik.html"
  >>= putStrLn

emptyTag (TagText t) = all (\ x -> x `elem` " \n\t") t
emptyTag _ = False

pruneTags = filter (not . emptyTag)

formatTags delta = go 0 where
  go off (t : ts) = let (pre, post) = d off t in
    TagText (replicate pre ' ') : t : TagText "\n" : go post ts
  go off [] = []

  d off (TagOpen _ _) = (off, off + delta)
  d off (TagClose _ ) = (off - delta, off - delta)
  d off _ = (off, off)

withTree f = formatTags 2 . flattenTree . f . tagTree . pruneTags

transform =
  transformTree makeHeaders .
  transformTree splitYears .
  transformTree flattenTd

breakIter f (x:xs) = let (pre, post) = break f xs in (x : pre) : breakIter f post
breakIter f [] = []


getTrYear (TagBranch "tr" _ (TagBranch "td" _ [TagLeaf (TagText s)] : _)) =
  if length s == 4 then Just s else Nothing
getTrYear _ = Nothing

makeHeaders (TagBranch "yr" _ trs) =
  [ TagBranch "h2" [] [TagLeaf $ TagText $ fromJust $ getTrYear $ head trs]
  , TagBranch "ul" [] $
      map (\ (TagBranch "tr" _ [_, TagBranch "td" _ td]) -> TagBranch "li" [] td) trs
  ]
makeHeaders x = [x]

splitYears (TagBranch "tbody" atts inner) =
  map (TagBranch "yr" []) $ reverse $ breakIter (isJust . getTrYear) inner
splitYears x = [x]

flattenTd (TagBranch "td" _ [TagBranch "p" _ s]) = [TagBranch "td" [] s]
flattenTd x = [x]
