module Main where

import MasonPrelude


import Audio.AudioContext (AudioContext)
import Audio.AudioContext as AudioContext
import Audio.GainNode (GainNode)
import Audio.GainNode as GainNode
import Audio.Oscillator (Frequency)
import Audio as Audio
import NumberInput as NumberInput
import Data.Array ((..))
-- import Debug as Debug
import DOM.HTML.Indexed (HTMLinput)
import Effect.Aff.Class (class MonadAff)
import Halogen (Component, ComponentHTML, HalogenM)
import Halogen as Hal
import Halogen.Aff as HA
import Halogen.VDom.Driver (runUI)
import Halogen.HTML as H
import Halogen.HTML.Properties (IProp)


main :: Effect Unit
main = do
  let initialVolume = 50.0
  ac <- AudioContext.create
  gn <- GainNode.create initialVolume ac
  let
    parent :: ∀ q i m. MonadAff m => Component q i Void m
    parent =
      Hal.mkComponent
        { initialState: const
            { ac
            , bounds: 500.0 /\ 3000.0
            , gn
            , frequency: 97.99886
            , volume: initialVolume
            }
        , render
        , eval: Hal.mkEval $ Hal.defaultEval { handleAction = handleAction }
        }

  HA.runHalogenAff do
    body <- HA.awaitBody
    runUI parent unit body

type Slots =
  ( noiseMaker :: Audio.Slot
  , numberInput :: NumberInput.Slot
  )

type State =
  { ac :: AudioContext
  , gn :: GainNode
  , frequency :: Frequency
  , bounds :: Frequency /\ Frequency
  , volume :: Number
  }

data Action
  = SetVolume Number
  | SetFrequency Number
  | SetLower Number
  | SetUpper Number
  | NOP

handleAction :: ∀ o m. MonadAff m => Action -> HalogenM State Action Slots o m Unit
handleAction action = do
  state <- Hal.get
  case action of
    SetVolume n -> do
      liftEffect $ GainNode.setVolume n state.gn
      Hal.modify_ _ { volume = n }

    SetFrequency f -> Hal.modify_ _ { frequency = f }
    SetLower f -> Hal.modify_ _ { bounds = f /\ snd state.bounds }
    SetUpper f -> Hal.modify_ _ { bounds = fst state.bounds /\ f }
    NOP -> pure unit


render :: ∀ m. MonadAff m => State -> ComponentHTML Action Slots m
render state@{ ac, gn } =
  let
    lower :: Frequency
    lower = fst state.bounds

    upper :: Frequency
    upper = snd state.bounds
  in
  H.div_
    [ numberInput
        { label: "Volume"
        , min: Just 0.0
        , max: Just 1000.0
        , value: state.volume
        }
        SetVolume
    , H.br_
    , numberInput
        { label: "Base Frequency"
        , min: Just 10.0
        , max: Nothing
        , value: state.frequency
        }
        SetFrequency
    , H.br_
    , numberInput
        { label: "Lower Bound"
        , min: Just 0.0
        , max: Nothing
        , value: lower
        }
        SetLower
    , numberInput
        { label: "Upper Bound"
        , min: Just 0.0
        , max: Nothing
        , value: upper
        }
        SetUpper
    , H.div_
        $ (\harmonic -> noiseMaker harmonic (toNumber harmonic * state.frequency))
          <$> ceil (lower / state.frequency) .. floor (upper / state.frequency)
    ]
  where
    noiseMaker :: Int -> Frequency -> ComponentHTML Action Slots m
    noiseMaker harmonic freq =
      H.slot_
        (Proxy :: _ "noiseMaker")
        freq
        Audio.noiseMaker
        { ac, freq, gn, harmonic }

    numberInput ::
      NumberInput.Input
      -> (NumberInput.Output -> Action)
      -> ComponentHTML Action Slots m
    numberInput input handle =
      H.slot
        (Proxy :: _ "numberInput")
        input.label
        NumberInput.numberInput
        input
        handle

labledInput :: ∀ m.
  String ->
  Array (IProp HTMLinput Action) ->
  ComponentHTML Action Slots m
labledInput label props =
  H.label_ [ H.text $ label <> ": ", H.input props ]
