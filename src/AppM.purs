module AppM where

-- import Audio.AudioContext (AudioContext)
-- import Control.Monad.Reader (ReaderT, runReaderT)
-- import Effect.Aff (Aff)
-- import Halogen (Component, ComponentHTML, HalogenM)

-- type AppM = ReaderT AudioContext Aff

-- runAppM :: forall q i o. Store.Store -> H.Component q i o AppM -> Aff (H.Component q i o Aff)
-- runAppM store = runStoreT store Store.reduce <<< coerce

-- runAppM :: ∀ q i o. AudioContext -> Component q i o AppM -> Aff (Component q i o Aff)
-- runAppM ac component = runReaderT
