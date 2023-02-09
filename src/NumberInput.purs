module NumberInput where

import Lude
import Effect.Aff as Aff
import Data.Time.Duration (Milliseconds(..))
import Halogen as Hal
import Halogen.HTML as H
import Halogen.HTML.Events as E
import Halogen.HTML.Properties as P
import Halogen.Subscription (Emitter)
import Halogen.Subscription as Sub
import Record as Record

type Output = Number

type InputRow =
  ( label :: String
  , max :: Maybe Number
  , min :: Maybe Number
  , value :: Number
  )

type Input = { | InputRow }

data Action
  = Init
  | Update Input
  | Input String
  | Revert

type State =
  { sid :: Maybe SubscriptionId
  , valueString :: String
  | InputRow
  }

type Slot = ∀ q. Hal.Slot q Output String

numberInput :: ∀ q m. MonadAff m => Component q Input Output m
numberInput =
  Hal.mkComponent
    { initialState: Record.merge { valueString: "", sid: Nothing }
    , render
    , eval:
        Hal.mkEval
        $ Hal.defaultEval
            { initialize = Just Init
            , receive = Just <. Update
            , handleAction = handleAction
            }
    }

handleAction :: ∀ m. MonadAff m => Action -> HalogenM State Action () Output m Unit
handleAction action = do
  state <- Hal.get
  case action of
    Init ->
      if stringToNumber state.valueString == Just state.value
      then pure unit
      else Hal.modify_ _ { valueString = numberToString state.value }
    Update input -> do
      Hal.put $ Record.merge input state
      handleAction Init
    Input value -> do
      maybe (pure unit) Hal.unsubscribe state.sid
      Hal.modify_ _ { sid = Nothing, valueString = value }
      case stringToNumber value of
        Just n | between' state.min state.max n
                 -> do
                   Hal.modify_ _ { value = n }
                   Hal.raise n
        _ | value == "" -> pure unit
          | otherwise -> do
              sid <- Hal.subscribe =<< setTimer 1500.0 Revert
              Hal.modify_ _ { sid = Just sid }
    Revert ->
      Hal.modify_
        _ { sid = Nothing
          , valueString = numberToString state.value
          }

render :: ∀ m. State -> ComponentHTML Action () m
render state =
  H.label_
    [ H.text $ if state.label == "" then "" else state.label <> ": "
    , H.input
        [ class' "c3c"
        , P.style
            case stringToNumber state.valueString of
              Just n | between' state.min state.max n -> ""
              _ | state.valueString == ""
                  || state.valueString == "-"
                  || state.valueString == "."
                  || state.valueString == "-."
                  -> ""
                | otherwise -> "color: #a80000;"
        , E.onValueInput Input
        , P.value state.valueString
        , P.placeholder $ numberToString state.value
        ]
    ]

between' :: ∀ a. Bounded a => Maybe a -> Maybe a -> a -> Boolean
between' lower upper = between (fromMaybe bottom lower) (fromMaybe top upper)

setTimer :: ∀ m a. MonadAff m => Number -> a -> m (Emitter a)
setTimer ms action = do
  { emitter, listener } <- liftEffect Sub.create
  _ <- liftAff $ forkAff do
    Aff.delay $ Milliseconds ms
    liftEffect $ Sub.notify listener action
  pure emitter
