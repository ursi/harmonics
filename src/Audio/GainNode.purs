module Audio.GainNode
  ( GainNode
  , Volume
  , create
  , setVolume
  )
  where

import MasonPrelude
import Audio.AudioContext (AudioContext)

data GainNode
type Gain = Number
type Volume = Number

foreign import create_ :: AudioContext -> Effect GainNode
foreign import connect :: AudioContext -> GainNode -> Effect Unit
foreign import setGain :: Gain -> GainNode -> Effect Unit

toGain :: Volume -> Gain
toGain vol = vol / 1000.0

create :: Volume -> AudioContext -> Effect GainNode
create volume ac = do
  gn <- create_ ac
  setGain (toGain volume) gn
  connect ac gn
  pure gn

setVolume :: Volume -> GainNode -> Effect Unit
setVolume volume = setGain (toGain volume)
