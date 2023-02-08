module Audio (Slot, noiseMaker) where

import MasonPrelude

import Audio.AudioContext (AudioContext)
import Audio.GainNode (GainNode)
import Audio.Oscillator (Frequency, Oscillator)
import Audio.Oscillator as Oscillator
import Halogen (Component, ComponentHTML, HalogenM)
import Halogen as Hal
import Halogen.HTML as H
import Halogen.HTML.Events as E
import Record as Record
import Web.UIEvent.MouseEvent as MouseEvent

type Slot = ∀ q o. Hal.Slot q o Number

type InputRow =
  ( ac :: AudioContext
  , freq :: Frequency
  , gn :: GainNode
  , harmonic :: Int
  )

type Input = { | InputRow }

noiseMaker :: ∀ q o m. MonadEffect m => Component q Input o m
noiseMaker =
  Hal.mkComponent
    { initialState: Record.merge { oscillator: Nothing }
    , render
    , eval: Hal.mkEval $ Hal.defaultEval { handleAction = handleAction }
    }

type State =
  { oscillator :: Maybe Oscillator
  | InputRow
  }

data Action
  = Start
  | Stop

handleAction :: ∀ o m. MonadEffect m => Action -> HalogenM State Action () o m Unit
handleAction action = do
  state <- Hal.get
  case action of
    Start -> do
      osc <- liftEffect $ Oscillator.start state.freq state.gn state.ac
      Hal.modify_ \s -> s { oscillator = Just osc }

    Stop ->
      case state.oscillator of
        Just osc -> liftEffect $ Oscillator.stop osc
        Nothing -> pure unit

render :: ∀ m. State -> ComponentHTML Action () m
render { freq, harmonic } =
  H.button
    [ E.onMouseDown \_ -> Start
    , E.onTouchStart \_ -> Start
    , E.onMouseEnter \e -> if MouseEvent.buttons e == 1 then Start else Stop
    , E.onMouseUp \_ -> Stop
    , E.onTouchEnd \_ -> Stop
    , E.onMouseLeave \_ -> Stop
    ]
    [ H.text $ show harmonic <> " " <> show freq ]
