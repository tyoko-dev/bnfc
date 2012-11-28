{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module PrintBNF where

-- pretty-printer generated by the BNF converter

import AbsBNF
import Data.Char


-- the top-level printing method
printTree :: Print a => a -> String
printTree = render . prt 0

type Doc = [ShowS] -> [ShowS]

doc :: ShowS -> Doc
doc = (:)

render :: Doc -> String
render d = rend 0 (map ($ "") $ d []) "" where
  rend i ss = case ss of
    "["      :ts -> showChar '[' . rend i ts
    "("      :ts -> showChar '(' . rend i ts
    "{"      :ts -> showChar '{' . new (i+1) . rend (i+1) ts
    "}" : ";":ts -> new (i-1) . space "}" . showChar ';' . new (i-1) . rend (i-1) ts
    "}"      :ts -> new (i-1) . showChar '}' . new (i-1) . rend (i-1) ts
    ";"      :ts -> showChar ';' . new i . rend i ts
    t  : "," :ts -> showString t . space "," . rend i ts
    t  : ")" :ts -> showString t . showChar ')' . rend i ts
    t  : "]" :ts -> showString t . showChar ']' . rend i ts
    t        :ts -> space t . rend i ts
    _            -> id
  new i   = showChar '\n' . replicateS (2*i) (showChar ' ') . dropWhile isSpace
  space t = showString t . (\s -> if null s then "" else (' ':s))

parenth :: Doc -> Doc
parenth ss = doc (showChar '(') . ss . doc (showChar ')')

concatS :: [ShowS] -> ShowS
concatS = foldr (.) id

concatD :: [Doc] -> Doc
concatD = foldr (.) id

replicateS :: Int -> ShowS -> ShowS
replicateS n f = concatS (replicate n f)

-- the printer class does the job
class Print a where
  prt :: Int -> a -> Doc
  prtList :: [a] -> Doc
  prtList = concatD . map (prt 0)

instance Print a => Print [a] where
  prt _ = prtList

instance Print Char where
  prt _ s = doc (showChar '\'' . mkEsc '\'' s . showChar '\'')
  prtList s = doc (showChar '"' . concatS (map (mkEsc '"') s) . showChar '"')

mkEsc :: Char -> Char -> ShowS
mkEsc q s = case s of
  _ | s == q -> showChar '\\' . showChar s
  '\\'-> showString "\\\\"
  '\n' -> showString "\\n"
  '\t' -> showString "\\t"
  _ -> showChar s

prPrec :: Int -> Int -> Doc -> Doc
prPrec i j = if j<i then parenth else id


instance Print Integer where
  prt _ x = doc (shows x)
  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])


instance Print Double where
  prt _ x = doc (shows x)


instance Print Ident where
  prt _ (Ident i) = doc (showString ( i))
  prtList es = case es of
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])



instance Print LGrammar where
  prt i e = case e of
   LGr ldefs -> prPrec i 0 (concatD [prt 0 ldefs])


instance Print LDef where
  prt i e = case e of
   DefAll def -> prPrec i 0 (concatD [prt 0 def])
   DefSome ids def -> prPrec i 0 (concatD [prt 0 ids , doc (showString ":") , prt 0 def])
   LDefView ids -> prPrec i 0 (concatD [doc (showString "views") , prt 0 ids])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])

instance Print Grammar where
  prt i e = case e of
   Grammar defs -> prPrec i 0 (concatD [prt 0 defs])


instance Print Def where
  prt i e = case e of
   Rule label cat items -> prPrec i 0 (concatD [prt 0 label , doc (showString ".") , prt 0 cat , doc (showString "::=") , prt 0 items])
   Comment str -> prPrec i 0 (concatD [doc (showString "comment") , prt 0 str])
   Comments str0 str -> prPrec i 0 (concatD [doc (showString "comment") , prt 0 str0 , prt 0 str])
   Internal label cat items -> prPrec i 0 (concatD [doc (showString "internal") , prt 0 label , doc (showString ".") , prt 0 cat , doc (showString "::=") , prt 0 items])
   Token id reg -> prPrec i 0 (concatD [doc (showString "token") , prt 0 id , prt 0 reg])
   PosToken id reg -> prPrec i 0 (concatD [doc (showString "position") , doc (showString "token") , prt 0 id , prt 0 reg])
   Entryp ids -> prPrec i 0 (concatD [doc (showString "entrypoints") , prt 0 ids])
   Separator minimumsize cat str -> prPrec i 0 (concatD [doc (showString "separator") , prt 0 minimumsize , prt 0 cat , prt 0 str])
   Terminator minimumsize cat str -> prPrec i 0 (concatD [doc (showString "terminator") , prt 0 minimumsize , prt 0 cat , prt 0 str])
   Delimiters cat str0 str separation -> prPrec i 0 (concatD [doc (showString "delimiters") , prt 0 cat , prt 0 str0 , prt 0 str , prt 0 separation])
   Coercions id n -> prPrec i 0 (concatD [doc (showString "coercions") , prt 0 id , prt 0 n])
   Rules id rhss -> prPrec i 0 (concatD [doc (showString "rules") , prt 0 id , doc (showString "::=") , prt 0 rhss])
   Function id args exp -> prPrec i 0 (concatD [doc (showString "define") , prt 0 id , prt 0 args , doc (showString "=") , prt 0 exp])
   Layout strs -> prPrec i 0 (concatD [doc (showString "layout") , prt 0 strs])
   LayoutStop strs -> prPrec i 0 (concatD [doc (showString "layout") , doc (showString "stop") , prt 0 strs])
   LayoutTop  -> prPrec i 0 (concatD [doc (showString "layout") , doc (showString "toplevel")])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ";") , prt 0 xs])

instance Print Item where
  prt i e = case e of
   Terminal str -> prPrec i 0 (concatD [prt 0 str])
   NTerminal cat -> prPrec i 0 (concatD [prt 0 cat])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print Cat where
  prt i e = case e of
   ListCat cat -> prPrec i 0 (concatD [doc (showString "[") , prt 0 cat , doc (showString "]")])
   IdCat id -> prPrec i 0 (concatD [prt 0 id])


instance Print Label where
  prt i e = case e of
   LabNoP labelid -> prPrec i 0 (concatD [prt 0 labelid])
   LabP labelid profitems -> prPrec i 0 (concatD [prt 0 labelid , prt 0 profitems])
   LabPF labelid0 labelid profitems -> prPrec i 0 (concatD [prt 0 labelid0 , prt 0 labelid , prt 0 profitems])
   LabF labelid0 labelid -> prPrec i 0 (concatD [prt 0 labelid0 , prt 0 labelid])


instance Print LabelId where
  prt i e = case e of
   Id id -> prPrec i 0 (concatD [prt 0 id])
   Wild  -> prPrec i 0 (concatD [doc (showString "_")])
   ListE  -> prPrec i 0 (concatD [doc (showString "[") , doc (showString "]")])
   ListCons  -> prPrec i 0 (concatD [doc (showString "(") , doc (showString ":") , doc (showString ")")])
   ListOne  -> prPrec i 0 (concatD [doc (showString "(") , doc (showString ":") , doc (showString "[") , doc (showString "]") , doc (showString ")")])


instance Print ProfItem where
  prt i e = case e of
   ProfIt intlists ns -> prPrec i 0 (concatD [doc (showString "(") , doc (showString "[") , prt 0 intlists , doc (showString "]") , doc (showString ",") , doc (showString "[") , prt 0 ns , doc (showString "]") , doc (showString ")")])

  prtList es = case es of
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print IntList where
  prt i e = case e of
   Ints ns -> prPrec i 0 (concatD [doc (showString "[") , prt 0 ns , doc (showString "]")])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print Separation where
  prt i e = case e of
   SepNone  -> prPrec i 0 (concatD [])
   SepTerm str -> prPrec i 0 (concatD [doc (showString "terminator") , prt 0 str])
   SepSepar str -> prPrec i 0 (concatD [doc (showString "separator") , prt 0 str])


instance Print Arg where
  prt i e = case e of
   Arg id -> prPrec i 0 (concatD [prt 0 id])

  prtList es = case es of
   [] -> (concatD [])
   x:xs -> (concatD [prt 0 x , prt 0 xs])

instance Print Exp where
  prt i e = case e of
   Cons exp0 exp -> prPrec i 0 (concatD [prt 1 exp0 , doc (showString ":") , prt 0 exp])
   App id exps -> prPrec i 1 (concatD [prt 0 id , prt 2 exps])
   Var id -> prPrec i 2 (concatD [prt 0 id])
   LitInt n -> prPrec i 2 (concatD [prt 0 n])
   LitChar c -> prPrec i 2 (concatD [prt 0 c])
   LitString str -> prPrec i 2 (concatD [prt 0 str])
   LitDouble d -> prPrec i 2 (concatD [prt 0 d])
   List exps -> prPrec i 2 (concatD [doc (showString "[") , prt 0 exps , doc (showString "]")])

  prtList es = case es of
   [] -> (concatD [])
   [x] -> (concatD [prt 2 x])
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 2 x , prt 2 xs])
   x:xs -> (concatD [prt 0 x , doc (showString ",") , prt 0 xs])

instance Print RHS where
  prt i e = case e of
   RHS items -> prPrec i 0 (concatD [prt 0 items])

  prtList es = case es of
   [x] -> (concatD [prt 0 x])
   x:xs -> (concatD [prt 0 x , doc (showString "|") , prt 0 xs])

instance Print MinimumSize where
  prt i e = case e of
   MNonempty  -> prPrec i 0 (concatD [doc (showString "nonempty")])
   MEmpty  -> prPrec i 0 (concatD [])


instance Print Reg where
  prt i e = case e of
   RSeq reg0 reg -> prPrec i 2 (concatD [prt 2 reg0 , prt 3 reg])
   RAlt reg0 reg -> prPrec i 1 (concatD [prt 1 reg0 , doc (showString "|") , prt 2 reg])
   RMinus reg0 reg -> prPrec i 1 (concatD [prt 2 reg0 , doc (showString "-") , prt 2 reg])
   RStar reg -> prPrec i 3 (concatD [prt 3 reg , doc (showString "*")])
   RPlus reg -> prPrec i 3 (concatD [prt 3 reg , doc (showString "+")])
   ROpt reg -> prPrec i 3 (concatD [prt 3 reg , doc (showString "?")])
   REps  -> prPrec i 3 (concatD [doc (showString "eps")])
   RChar c -> prPrec i 3 (concatD [prt 0 c])
   RAlts str -> prPrec i 3 (concatD [doc (showString "[") , prt 0 str , doc (showString "]")])
   RSeqs str -> prPrec i 3 (concatD [doc (showString "{") , prt 0 str , doc (showString "}")])
   RDigit  -> prPrec i 3 (concatD [doc (showString "digit")])
   RLetter  -> prPrec i 3 (concatD [doc (showString "letter")])
   RUpper  -> prPrec i 3 (concatD [doc (showString "upper")])
   RLower  -> prPrec i 3 (concatD [doc (showString "lower")])
   RAny  -> prPrec i 3 (concatD [doc (showString "char")])



