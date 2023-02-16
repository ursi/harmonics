module Main (main) where

import Lude

import Audio.AudioContext as AudioContext
import Audio.GainNode (Volume)
import Audio.GainNode as GainNode
import Audio.Oscillator (Frequency)
import Config (AppM)
import Component.NumberInput as NumberInput
import Component.SoundButton as SoundButton
import Data.Array ((..), (:))
import Data.Array as Array
-- import Debug as Debug
import Data.Set (Set)
import Data.Set as Set
import Halogen as Hal
import Halogen.Aff as HA
import Halogen.HTML as H
import Halogen.HTML.Events as E
import Halogen.HTML.Properties as P
import Note (AccDisplay, Note (..), Spn)
import Note as Note

type State =
  { frequency :: NoteFreq
  , bounds :: Frequency /\ Frequency
  , volume :: Number
  , accDisplay :: AccDisplay
  , freqMode :: FreqMode
  , excluded :: Set Int
  }

data Action
  = SetVolume Number
  | SetFrequency Number
  | SetLower Number
  | SetUpper Number
  | SetFreqMode String
  | SetNote String
  | SetOctave Int
  | SetAccDisplay String
  | ExcludeHarmonic Int
  | UnexcludeHarmonic Int

data FreqMode
  = Manual
  | Notes

type NoteFreq = Either Frequency Spn

type Html = ComponentHTML Action Slots AppM

nf2f :: NoteFreq -> Frequency
nf2f =
  case _ of
    Left f -> f
    Right n -> Note.toFreq n

main :: Effect Unit
main = do
  let initialVolume = 50.0
  audioContext <- AudioContext.create
  gainNode <- GainNode.create initialVolume audioContext
  HA.runHalogenAff do
    body <- HA.awaitBody
    runUI
      (Hal.hoist (runReaderT ~$ { audioContext, gainNode })
       $ parent initialVolume
      )
      unit body

type Slots =
  ( noiseMaker :: SoundButton.Slot
  , numberInput :: NumberInput.Slot
  )

parent :: ∀ q i. Volume -> Component q i Void AppM
parent volume =
  Hal.mkComponent
    { initialState: const
        { bounds: 466.0 /\ 3000.0
        , frequency: Right $ G /\ 2
        , freqMode: Notes
        , volume
        , accDisplay: Note.Sharp
        , excluded: mempty
        }
    , render
    , eval: Hal.mkEval $ Hal.defaultEval { handleAction = handleAction }
    }

handleAction :: ∀ o. Action -> HalogenM State Action Slots o AppM Unit
handleAction action = do
  state <- Hal.get
  case action of
    SetVolume n -> do
      { gainNode } <- ask
      liftEffect $ GainNode.setVolume n gainNode
      Hal.modify_ _ { volume = n }

    SetFrequency f -> Hal.modify_ _ { frequency = Left f }
    SetLower f -> Hal.modify_ _ { bounds = f /\ snd state.bounds }
    SetUpper f -> Hal.modify_ _ { bounds = fst state.bounds /\ f }
    SetFreqMode value ->
      case value of
        "Notes" ->
          Hal.modify_
            _ { freqMode = Notes
              , frequency = Right $ getNote state /\ getOctave state
              }
        "Manual" -> Hal.modify_ _ { freqMode = Manual }
        _ -> pure unit
    SetNote str ->
      case Note.fromString str of
        Just n ->
          case state.frequency of
            Left _ ->
              Hal.modify_ _ { frequency = Right $ n /\ getOctave state}
            Right (_ /\ octave) ->
              Hal.modify_ _ { frequency = Right $ n /\ octave }
        Nothing -> pure unit
    SetOctave n -> Hal.modify_ _ { frequency = Right $ getNote state /\ n}
    SetAccDisplay str ->
      case str of
        "Sharps" -> Hal.modify_ _ { accDisplay = Note.Sharp }
        "Flats" -> Hal.modify_ _ { accDisplay = Note.Flat }
        "Both" -> Hal.modify_ _ { accDisplay = Note.Both }
        _ -> pure unit
    ExcludeHarmonic i -> Hal.modify_ _ { excluded = Set.insert i state.excluded }
    UnexcludeHarmonic i -> Hal.modify_ _ { excluded = Set.delete i state.excluded }

render :: State -> Html
render state =
  let
    bottomHarmonic :: Int
    bottomHarmonic =
      max 1 $ ceil $ fst state.bounds / nf2f state.frequency

    topHarmonic :: Int
    topHarmonic =
      max 1 $ floor $ snd state.bounds / nf2f state.frequency
  in
  H.div [ class' "c5c" ]
    [ sidebar { state, bottomHarmonic, topHarmonic }
    , harmonicsPanel { state, bottomHarmonic, topHarmonic }
    ]

harmonicsPanel ::
  { state :: State
  , bottomHarmonic :: Int
  , topHarmonic :: Int
  }
  -> Html
harmonicsPanel { state, bottomHarmonic, topHarmonic } =
  H.div [ class' "c1c" ]
    $ bottomHarmonic .. topHarmonic
      # Array.filter (not <. Set.member ~$ state.excluded)
      <#> (\harmonic ->
             noiseMaker harmonic (toNumber harmonic * nf2f state.frequency)
          )
  where
    noiseMaker :: Int -> Frequency -> Html
    noiseMaker harmonic freq =
      H.div [ onRightMouseDown \_ -> ExcludeHarmonic harmonic ]
        [ H.slot_
            (Proxy :: _ "noiseMaker")
            freq
            SoundButton.soundButton
            { accDisplay: state.accDisplay, freq, harmonic }
        ]

sidebar :: { state :: State, bottomHarmonic :: Int, topHarmonic :: Int } -> Html
sidebar { state, bottomHarmonic, topHarmonic } =
  H.div [ class' "c4c" ]
  $ [ volume
    , accidentalDisplay
    ]
    <> frequencyType
    <> bounds
    <>
    [ excludedHarmonics ]
  where
    volume :: Html
    volume =
      numberInput4
        { label: "Volume"
        , min: Just 0.0
        , max: Just 1000.0
        , value: state.volume
        }
        SetVolume

    accidentalDisplay :: Html
    accidentalDisplay =
      H.select [ E.onValueInput SetAccDisplay, P.style "width: fit-content;" ]
        [ H.option [ P.selected $ state.accDisplay == Note.Sharp ]
            [ H.text "Sharps" ]
        , H.option [ P.selected $ state.accDisplay == Note.Flat ]
            [ H.text "Flats" ]
        , H.option [ P.selected $ state.accDisplay == Note.Both ]
            [ H.text "Both" ]
        ]

    frequencyType :: Array Html
    frequencyType =
      [ H.div_
          [ H.label [ P.for "freq-type" ] [ H.text "Frequency Type: " ]
          , H.select [ P.id "freq-type", E.onValueInput SetFreqMode ]
              [ H.option_ [ H.text "Notes" ]
              , H.option_ [ H.text "Manual" ]
              ]
          ]
      , case state.freqMode of
          Manual ->
            numberInput
              { label: "Base Frequency"
              , min: Just 10.0
              , max: Nothing
              , value: nf2f state.frequency
              }
              SetFrequency
          Notes ->
            H.div_
              [ H.select [ P.id "note-picker", E.onValueInput SetNote ]
                $ enumFromTo Note.C Note.B
                  <#> \n ->
                        H.option
                          [ P.value $ show n
                          , P.selected $ n == getNote state
                          ]
                          [ H.text $ Note.display state.accDisplay n ]
              , H.text " "
              , numberInput' "c9c"
                  { label: ""
                  , min: Just 0.0
                  , max: Nothing
                  , value: toNumber $ getOctave state
                  }
                  (SetOctave <. round)
                  "octave"
              ]
      ]

    bounds :: Array Html
    bounds =
      [ numberInput4
          { label: "Lower Bound"
          , min: Just 0.0
          , max: Nothing
          , value: fst state.bounds
          }
          SetLower
      , numberInput4
          { label: "Upper Bound"
          , min: Just 0.0
          , max: Nothing
          , value: snd state.bounds
          }
          SetUpper
      ]

    excludedHarmonics :: Html
    excludedHarmonics =
      H.div [ class' "c6c" ]
      $ foldr
          (\harmonic acc ->
             if between bottomHarmonic topHarmonic harmonic then
               H.div
                 [ class' "c7c"
                 , E.onClick \_-> UnexcludeHarmonic harmonic
                 ]
                 [ H.text $ show harmonic ] : acc
             else
               acc
          )
          []
          state.excluded

    numberInput :: NumberInput.Input -> (NumberInput.Output -> Action) -> Html
    numberInput input handle = numberInput' "" input handle input.label

    numberInput4 :: NumberInput.Input -> (NumberInput.Output -> Action) -> Html
    numberInput4 input handle = numberInput' "c8c" input handle input.label

    numberInput' ::
      String
      -> NumberInput.Input
      -> (NumberInput.Output -> Action)
      -> String
      -> Html
    numberInput' class'' input handle id =
      H.span [ class' class'' ]
        [ H.slot
            (Proxy :: _ "numberInput")
            id
            NumberInput.numberInput
            input
            handle
        ]

getNote :: State -> Note
getNote state =
  case state.frequency of
    Left f -> fst $ Note.closestHalfStep f
    Right (n /\ _) -> n

getOctave :: State -> Int
getOctave state =
  case state.frequency of
    Left f -> snd $ Note.closestHalfStep f
    Right (_ /\ octave) -> octave
