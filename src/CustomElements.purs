module CustomElements where

import MasonPrelude
import Effect.Aff (Aff)
import Data.Nullable (Nullable)
import Data.Nullable as Nullable
import Data.Number as Number
import Debug as Debug
import Halogen (AttrName(..), Component, ComponentHTML, ElemName(..), HalogenM)
import Halogen as Hal
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import Halogen.HTML (Leaf, HTML)
import Halogen.HTML as H
import Halogen.HTML.Events as E
import Halogen.HTML.Properties (IProp)
import Halogen.HTML.Properties as P
import Halogen.Subscription as Sub
import Control.Monad.Reader (class MonadAsk, ReaderT, runReaderT, ask)
import Control.Monad.Trans.Class (lift)
import Web.Event.Event as Event
import Web.Event.Event (Event)
import Web.DOM.Element as Element
import Web.HTML.HTMLElement (HTMLElement)
import Web.HTML.HTMLElement as HTMLElement
import Web.HTML.HTMLInputElement (HTMLInputElement)
import Web.HTML.HTMLInputElement as Input

type AttrChanged =
  { attr :: String
  , old :: Maybe String
  , new :: String
  , namespace :: Maybe String
  }

type Properties =
  { attributeChangedCallback :: AttrChanged -> Effect Unit
  , name :: String
  , observedAttributes :: Array String
  }
foreign import defineImpl ::
  (Nullable String -> Maybe String)
  -> Properties
  -> (HTMLElement -> HTMLElement -> Effect Unit)
  -> Effect Unit

type CustoM = ReaderT HTMLElement Aff

define :: Properties -> (HTMLElement -> HTMLElement -> Effect Unit) -> Effect Unit
define = defineImpl Nullable.toMaybe

add :: Effect Unit
add = do
  { emitter, listener } <- Sub.create

  let
    custom :: ∀ q i o. Component q i o CustoM
    custom =
      Hal.mkComponent
        { initialState
        , render
        , eval:
            Hal.mkEval
            $ Hal.defaultEval
                { initialize = Just Init
                , handleAction = handleAction
                }
        }

    initialState :: ∀ i. i -> State
    initialState _ =
      { label: Nothing
      , max: Nothing
      , min: Nothing
      , value: Nothing
      , valueString: ""
      }

    handleAction :: ∀ o. Action -> HalogenM State Action () o CustoM Unit
    handleAction action = do
      state <- Hal.get
      case action of
        Init -> do
          _ <- Hal.subscribe emitter
          this <- lift ask
          let attr a = liftEffect $ getAttribute a this
          label' <- attr "label"
          max <- attr "max"
          min <- attr "min"
          value <- attr "value"
          Hal.modify_
            _ { label = label'
              , max = Number.fromString =<< max
              , min = Number.fromString =<< min
              , value = Number.fromString =<< value
              }

        AttrChanged { attr, new } ->
          case attr of
            "label" -> Hal.modify_ _ { label = Just new }
            "max" -> Hal.modify_ _ { max = Number.fromString new }
            "min" -> Hal.modify_ _ { min = Number.fromString new }
            "value" -> Hal.modify_ _ { value = Number.fromString new }
            _ -> pure unit

        Input e -> do
          liftEffect $ Event.stopPropagation e
          let
            minput :: Maybe HTMLInputElement
            minput = Event.target e >>= Input.fromEventTarget
          case minput of
            Just input -> do
              value <- liftEffect $ Input.value input
              Hal.modify_ _ { valueString = Debug.log value }
              case Number.fromString value of
                Just n | between (fromMaybe bottom state.min) (fromMaybe top state.max) n
                         -> Hal.modify_ _ { value = Just n }
                _ -> pure unit

            Nothing -> pure unit

  define
    { name: "custom-element"
    , observedAttributes: [ "label", "max", "min" ]
    , attributeChangedCallback: Sub.notify listener <. AttrChanged
    }
    \this shadow -> do
      HA.runHalogenAff do
        runUI
          (Hal.hoist (runReaderT ~$ this) custom)
          unit
          shadow

data Action
  = Init
  | AttrChanged AttrChanged
  | Input Event

type State =
  { label :: Maybe String
  , max :: Maybe Number
  , min :: Maybe Number
  , value :: Maybe Number
  , valueString :: String
  }

customElement :: ∀ r w i. Leaf r w i
customElement = H.element (ElemName "custom-element") ~$ []

-- customElement' = H.div [ P.attr (AttrName "is") "custom-element" ] []


render :: ∀ m. State -> ComponentHTML Action () m
render state =
  H.label_
    [ H.text $ maybe "" (\l -> l <> ": ") state.label
    , H.input [ E.onInput Input, P.value state.valueString ]
    ]

-- slot :: String -> Array

slotE :: ∀ w i. String -> Array (HTML w i) -> HTML w i
slotE name = H.element (ElemName "slot") [ P.name name ]

slotA :: ∀ r i. String -> IProp r i
slotA = P.attr (AttrName "slot")

label :: ∀ r i. String -> IProp r i
label = P.attr (AttrName "label")

getAttribute :: String -> HTMLElement -> Effect (Maybe String)
getAttribute = Element.getAttribute <~. HTMLElement.toElement

setAttribute :: String -> String -> HTMLElement -> Effect Unit
setAttribute = Element.setAttribute <~~. HTMLElement.toElement
