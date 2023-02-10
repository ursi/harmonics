module Config where

import Lude
import Control.Monad.Reader (ReaderT)
import Audio.AudioContext (AudioContext)
import Audio.GainNode (GainNode)

type Config =
  { audioContext :: AudioContext
  , gainNode :: GainNode
  }


type AppM = ReaderT Config Aff
