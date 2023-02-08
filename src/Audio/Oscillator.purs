module Audio.Oscillator
  ( Oscillator
  , Frequency
  , start
  , stop
  )
  where

import MasonPrelude
import Audio.AudioContext (AudioContext)
import Audio.GainNode (GainNode)

type Frequency = Number

data Oscillator

foreign import create :: AudioContext -> Effect Oscillator
foreign import setFreq :: Frequency -> Oscillator -> Effect Unit
foreign import connect :: GainNode -> Oscillator -> Effect Unit
foreign import disconnect :: Oscillator -> Effect Unit
foreign import start_ :: Oscillator -> Effect Unit
foreign import stop_ :: Oscillator -> Effect Unit

start :: Frequency -> GainNode -> AudioContext -> Effect Oscillator
start freq gn ac = do
  osc <- create ac
  setFreq freq osc
  connect gn osc
  start_ osc
  pure osc

stop :: Oscillator -> Effect Unit
stop osc = do
  stop_ osc
  disconnect osc
