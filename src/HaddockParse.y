{
module HaddockParse (parseParas, parseString) where

import HaddockLex
import HaddockTypes
}

%tokentype { Token }

%token 	SQUO	{ TokSpecial '\'' }
	DQUO 	{ TokSpecial '\"' }
	'/'	{ TokSpecial '/' }
	'['	{ TokSpecial '[' }
	']'	{ TokSpecial ']' }
	URL	{ TokURL $$ }
	'*'	{ TokBullet }
	'(n)'	{ TokNumber }
	'>'	{ TokBirdTrack }
	PARA    { TokPara }
	STRING	{ TokString $$ }

%monad { Either String }

%name parseParas  doc
%name parseString seq

%%

doc	:: { ParsedDoc }
	: apara PARA doc	{ docAppend $1 $3 }
	| PARA doc 		{ $2 }
	| apara			{ $1 }
	| {- empty -}		{ DocEmpty }

apara	:: { ParsedDoc }
	: ulpara		{ DocUnorderedList [$1] }
	| olpara		{ DocOrderedList [$1] }
	| para			{ $1 }

ulpara  :: { ParsedDoc }
	: '*' para		{ $2 }

olpara  :: { ParsedDoc } 
	: '(n)' para		{ $2 }

para    :: { ParsedDoc }
	: seq			{ docParagraph $1 }
	| codepara		{ DocCodeBlock $1 }

codepara :: { ParsedDoc }
	: '>' seq codepara	{ docAppend $2 $3 }
	| '>' seq		{ $2 }

seq	:: { ParsedDoc }
	: elem seq		{ docAppend $1 $2 }
	| elem			{ $1 }

elem	:: { ParsedDoc }
	: STRING		{ DocString $1 }
	| '/' STRING '/'	{ DocEmphasis (DocString $2) }
	| URL			{ DocURL $1 }
	| SQUO STRING SQUO	{ DocIdentifier $2 }
	| DQUO STRING DQUO	{ DocModule $2 }
	| '[' seq ']'		{ DocMonospaced $2 }

{
happyError :: [Token] -> Either String a
happyError toks = 
  Left ("parse error in doc string: "  ++ show (take 3 toks))

-- Either monad (we can't use MonadError because GHC < 5.00 has
-- an older incompatible version).
instance Monad (Either String) where
	return        = Right
	Left  l >>= _ = Left l
	Right r >>= k = k r
	fail msg      = Left msg
}
