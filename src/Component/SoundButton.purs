module Component.SoundButton (Slot, soundButton) where

import Lude hiding (round)

import Audio.Oscillator (Frequency, Oscillator)
import Audio.Oscillator as Oscillator
import Config (Config)
import Data.Number as Number
import Halogen as Hal
import Halogen.HTML as H
import Halogen.HTML.Properties as P
import Halogen.HTML.Events as E
import Note (AccDisplay)
import Note as Note
import Record as Record
import Web.UIEvent.MouseEvent as MouseEvent

type Slot = ∀ q o. Hal.Slot q o Number

type InputRow =
  ( freq :: Frequency
  , harmonic :: Int
  , accDisplay :: AccDisplay
  )

type Input = { | InputRow }

soundButton :: ∀ q o m. MonadAsk Config m => MonadEffect m => Component q Input o m
soundButton =
  Hal.mkComponent
    { initialState: Record.merge { oscillator: Nothing }
    , render
    , eval:
        Hal.mkEval
        $ Hal.defaultEval
            { handleAction = handleAction
            , receive = Just <. UpdateAccDisplay <. _.accDisplay
            }
    }

type State =
  { oscillator :: Maybe Oscillator
  | InputRow
  }

data Action
  = Start
  | Stop
  | UpdateAccDisplay AccDisplay

handleAction :: ∀ o m.
  MonadAsk Config m =>
  MonadEffect m
  => Action
  -> HalogenM State Action () o m Unit
handleAction action = do
  config <- ask
  state <- Hal.get
  case action of
    Start -> do
      osc <-
        liftEffect
        $ Oscillator.start
            state.freq
            config.gainNode
            config.audioContext
      Hal.modify_ \s -> s { oscillator = Just osc }

    Stop ->
      case state.oscillator of
        Just osc -> liftEffect $ Oscillator.stop osc
        Nothing -> pure unit

    UpdateAccDisplay ad -> Hal.modify_ _ { accDisplay = ad }

render :: ∀ m. State -> ComponentHTML Action () m
render state =
  H.div
    [ class' "c2c"
    , E.onMouseDown \_ -> Start
    , E.onTouchStart \_ -> Start
    , E.onMouseEnter \e -> if MouseEvent.buttons e == 1 then Start else Stop
    , E.onMouseUp \_ -> Stop
    , E.onTouchEnd \_ -> Stop
    , E.onMouseLeave \_ -> Stop
    ]
    [ vCenter
      $ H.div_
          [ H.div [ P.style "font-size: 1.7em;" ] [ H.text $ show state.harmonic ]
          , H.text
            $ Note.freqAsSpnStr state.accDisplay state.freq <> "\n"
              <> numberToString (Number.round state.freq)
          ]
    ]

-- round :: Int -> Number -> Number
-- round places n = Number.round (10.0 ^ toNumber places * n) / 10.0 ^ toNumber places
