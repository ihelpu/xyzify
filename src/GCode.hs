{-# LANGUAGE OverloadedStrings #-}

module GCode (makeXYZ) where

import Prelude hiding (lines, unlines, length, head)
import Data.ByteString.Lazy.Char8 (ByteString, lines, unlines, length, head)
import Data.ByteString.Base64.Lazy (encode)
import Data.Either.Combinators (mapBoth)
    
makeXYZ :: ByteString -> Either String ByteString
makeXYZ = mapBoth id (encode . unlines) . fixHalves . break (== "; --- END SECTION ---") . lines

fixHalves :: ([ByteString], [ByteString]) -> Either String [ByteString]
fixHalves (prefix, codes) | null codes  = Left "Did not find END SECTION marker."
                          | otherwise   = case fixPrefix prefix of
                                              Right fixed -> Right $ fixed ++ tail codes
                                              x           -> x
                        
fixPrefix :: [ByteString] -> Either String [ByteString]
fixPrefix = swapParts . break (== "; --- MOVE THIS SECTION TO THE TOP AND DELETE THIS LINE ---")

swapParts :: ([ByteString], [ByteString]) -> Either String [ByteString]
swapParts (header, xyzStuff) | null xyzStuff  = Left "Did not find SECTION marker."
                             | otherwise      = Right $ tail xyzStuff ++ filter isCommand header

isCommand :: ByteString -> Bool
isCommand line = length line /= 0 && head line /= ';'