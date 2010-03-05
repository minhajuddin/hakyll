-- | Internal module do some low-level rendering.
module Text.Hakyll.Internal.Render
    ( substitute
    , regularSubstitute
    , finalSubstitute
    , pureRenderWith
    , writePage
    ) where

import qualified Data.Map as M
import Control.Monad.Reader (liftIO)
import Data.Maybe (fromMaybe)

import Text.Hakyll.Context (Context, ContextManipulation)
import Text.Hakyll.File
import Text.Hakyll.Hakyll
import Text.Hakyll.RenderAction
import Text.Hakyll.Internal.Template

-- | A pure render function.
pureRenderWith :: ContextManipulation -- ^ Manipulation to apply on the context.
               -> Template -- ^ Template to use for rendering.
               -> Context -- ^ Renderable object to render with given template.
               -> Context -- ^ The body of the result will contain the render.
pureRenderWith manipulation template context =
    -- Ignore $root when substituting here. We will only replace that in the
    -- final render (just before writing).
    let contextIgnoringRoot = M.insert "root" "$root" (manipulation context)
        body = regularSubstitute template contextIgnoringRoot
    in M.insert "body" body context

-- | Write a page to the site destination. Final action after render
--   chains and such.
writePage :: RenderAction Context ()
writePage = createRenderAction $ \initialContext -> do
    additionalContext' <- askHakyll additionalContext
    let url = fromMaybe (error "No url defined at write time.")
                        (M.lookup "url" initialContext)
        body = fromMaybe "" (M.lookup "body" initialContext)
    let context = additionalContext' `M.union` M.singleton "root" (toRoot url)
    destination <- toDestination url
    makeDirectories destination
    -- Substitute $root here, just before writing.
    liftIO $ writeFile destination $ finalSubstitute (fromString body) context