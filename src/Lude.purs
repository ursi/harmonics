module Lude
  ( module Exports
  , attr
  , class'
  , element
  , log_
  , modToEnum
  , numberToString
  , stringToNumber
  , vCenter
  )
  where


import MasonPrelude as Exports
import Data.Nullable (Nullable) as Exports
import Data.Enum
  (class Enum
  , class BoundedEnum
  , cardinality
  , enumFromTo
  , fromEnum
  , toEnum
  )
  as Exports
import Effect.Aff (Aff, forkAff, runAff) as Exports
import Effect.Aff.Class (class MonadAff, liftAff) as Exports
import Halogen (Component, ComponentHTML, HalogenM, SubscriptionId) as Exports
import Halogen.VDom.Driver (runUI) as Exports
import Halogen.HTML (HTML) as Exports
import Halogen.HTML.Properties (IProp) as Exports
import Safe.Coerce (coerce) as Exports

import MasonPrelude
import Data.Enum (class BoundedEnum, Cardinality(..), cardinality, toEnum)
import Data.Maybe (fromJust)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Number as Number
import Halogen (AttrName(..), ClassName(..), ComponentHTML,  ElemName(..))
import Halogen.HTML (HTML)
import Halogen.HTML as H
import Halogen.HTML.Properties (IProp)
import Halogen.HTML.Properties as P
import Partial.Unsafe (unsafePartial)
import Safe.Coerce (coerce)

foreign import numberToString :: Number -> String
foreign import stringToNumberImpl :: String -> Nullable Number

stringToNumber :: String -> Maybe Number
stringToNumber = Nullable.toMaybe <. stringToNumberImpl

element :: ∀ r w i. String -> Array (IProp r i) -> Array (HTML w i) -> HTML w i
element = H.element <. ElemName

attr :: ∀ r i. String -> String -> IProp r i
attr = P.attr <. AttrName

class' :: ∀ r i. String -> IProp ( class :: String | r ) i
class' = P.class_ <. ClassName

log_ :: Number -> Number -> Number
log_ base n = Number.log n / Number.log base

modToEnum :: ∀ a. BoundedEnum a => Int -> a
modToEnum i = unsafePartial $ fromJust $ toEnum $ mod i $ coerce (cardinality :: _ a)

vCenter :: ∀ a s m. ComponentHTML a s m -> ComponentHTML a s m
vCenter child =
  H.div [ class' "center" ] [ child ]
