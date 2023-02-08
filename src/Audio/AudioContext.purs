module Audio.AudioContext where

import MasonPrelude

data AudioContext

foreign import create :: Effect AudioContext
