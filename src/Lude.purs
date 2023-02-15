module Lude
  ( module Exports
  , attr
  , class'
  , element
  , handler
  , handler'
  , modToEnum
  , numberToString
  , onLeftMouseDown
  , onRightMouseDown
  , stringToNumber
  , vCenter
  )
  where


import MasonPrelude as Exports
import Control.Monad.Reader (class MonadAsk, ask, runReaderT) as Exports
import Data.Enum
  ( class Enum
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
import Web.Event.Event (preventDefault) as Exports
import Web.UIEvent.MouseEvent (MouseEvent) as Exports

import MasonPrelude
import Data.Enum (class BoundedEnum, Cardinality(..), cardinality, toEnum)
import Data.Maybe (fromJust)
import Data.Nullable as Nullable
import Halogen (AttrName(..), ClassName(..), ComponentHTML,  ElemName(..))
import Halogen.HTML (HTML)
import Halogen.HTML as H
import Halogen.HTML.Events as E
import Halogen.HTML.Properties (IProp)
import Halogen.HTML.Properties as P
import Partial.Unsafe (unsafePartial)
import Web.Event.Event (Event, EventType(..))
import Web.UIEvent.MouseEvent (MouseEvent)
import Web.UIEvent.MouseEvent as MouseEvent

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

modToEnum :: ∀ a. BoundedEnum a => Int -> a
modToEnum i = unsafePartial $ fromJust $ toEnum $ mod i $ coerce (cardinality :: _ a)

vCenter :: ∀ a s m. ComponentHTML a s m -> ComponentHTML a s m
vCenter child =
  H.div [ class' "center" ] [ child ]

handler :: ∀ r i. String -> (Event -> i) -> IProp r i
handler = E.handler <. EventType

handler' :: ∀ r i. String -> (Event -> Maybe i) -> IProp r i
handler' = E.handler' <. EventType

onLeftMouseDown :: ∀ r i. (MouseEvent -> i) -> IProp r i
onLeftMouseDown = customMouseDown 1

onRightMouseDown :: ∀ r i. (MouseEvent -> i) -> IProp r i
onRightMouseDown = customMouseDown 2

customMouseDown :: ∀ r i. Int -> (MouseEvent -> i) -> IProp r i
customMouseDown buttons f =
  handler'
    "mousedown"
    (\e -> do
       me <- MouseEvent.fromEvent e
       if MouseEvent.buttons me == buttons
       then pure $ f me
       else Nothing
    )
