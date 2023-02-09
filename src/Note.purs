module Note where

import Lude

import Audio.Oscillator (Frequency)
import Data.Enum.Generic as EG

data Note
  = C
  | CD
  | D
  | DE
  | E
  | F
  | FG
  | G
  | GA
  | A
  | AB
  | B

type Spn = Note /\ Int

derive instance Eq Note
derive instance Ord Note
derive instance Generic Note _

instance Show Note where
  show = genericShow

instance Bounded Note where
  bottom = A
  top = GA

instance Enum Note where
  succ = EG.genericSucc
  pred = EG.genericPred

instance BoundedEnum Note where
  cardinality = EG.genericCardinality
  toEnum = EG.genericToEnum
  fromEnum = EG.genericFromEnum

fromString :: String -> Maybe Note
fromString =
  case _ of
    "C" -> Just C
    "CD" -> Just CD
    "D" -> Just D
    "DE" -> Just DE
    "E" -> Just E
    "F" -> Just F
    "FG" -> Just FG
    "G" -> Just G
    "GA" -> Just GA
    "A" -> Just A
    "AB" -> Just AB
    "B" -> Just B
    _ -> Nothing

data AccDisplay
  = Sharp
  | Flat
  | Both

derive instance Eq AccDisplay

display :: AccDisplay -> Note -> String
display dis note =
  case note of
    A -> show note
    AB -> helper "A" "B"
    B -> show note
    C -> show note
    CD -> helper "C" "D"
    D -> show note
    DE -> helper "D" "E"
    E -> show note
    F -> show note
    FG -> helper "F" "G"
    G -> show note
    GA -> helper "G" "A"
  where
    helper :: String -> String -> String
    helper lower higher =
      let
        sharp = lower <> "♯"
        flat = higher <> "♭"
      in
      case dis of
        Sharp -> sharp
        Flat -> flat
        Both -> sharp <> "/" <> flat

halfStep :: Number
halfStep = 2.0 ^ (1.0 / 12.0)

cent :: Number
cent = 2.0 ^ (1.0 / 1200.0)

toFreq :: Spn -> Frequency
toFreq (note /\ octave) =
  440.0
  * halfStep
    ^ (toNumber (fromEnum note - fromEnum A) + 12.0 * toNumber (octave - 4))

closestHalfStep :: Frequency -> Spn
closestHalfStep f =
  let halfSteps = round $ log_ halfStep (f / toFreq (C /\ 0)) in
  modToEnum halfSteps /\ (halfSteps / 12)

centsOff :: Frequency -> Int
centsOff f = round $ log_ cent (f / toFreq (closestHalfStep f))

freqAsSpnStr :: AccDisplay -> Frequency -> String
freqAsSpnStr ad f =
  let
    spn = closestHalfStep f
    cents = centsOff f
  in
  display ad (fst spn)
  <> show (snd spn)
  <> if cents == 0 then
       ""
     else
       " "
       <> (if cents > 0 then "+" else "")
       <> show cents
