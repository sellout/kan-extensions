{-# LANGUAGE CPP #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
#if __GLASGOW_HASKELL__ >= 702 && __GLASGOW_HASKELL__ < 710
{-# LANGUAGE Trustworthy #-}
#endif
-----------------------------------------------------------------------------
-- |
-- Module      :  Control.Comonad.Density
-- Copyright   :  (C) 2008-2011 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  non-portable (GADTs, MPTCs)
--
-- The 'Density' 'Comonad' for a 'Functor' (aka the 'Comonad generated by a 'Functor')
-- The 'Density' term dates back to Dubuc''s 1974 thesis. The term
-- 'Monad' genererated by a 'Functor' dates back to 1972 in Street''s
-- ''Formal Theory of Monads''.
--
-- The left Kan extension of a 'Functor' along itself (@'Lan' f f@) forms a 'Comonad'. This is
-- that 'Comonad'.
----------------------------------------------------------------------------
module Control.Comonad.Density
  ( Density(..)
  , liftDensity
  , densityToAdjunction, adjunctionToDensity
  , densityToLan, lanToDensity
  ) where

import Control.Applicative
import Control.Comonad
import Control.Comonad.Trans.Class
import Data.Functor.Apply
import Data.Functor.Adjunction
import Data.Functor.Extend
import Data.Functor.Kan.Lan

data Density k a where
  Density :: (k b -> a) -> k b -> Density k a

instance Functor (Density f) where
  fmap f (Density g h) = Density (f . g) h
  {-# INLINE fmap #-}

instance Extend (Density f) where
  duplicated (Density f ws) = Density (Density f) ws
  {-# INLINE duplicated #-}

instance Comonad (Density f) where
  duplicate (Density f ws) = Density (Density f) ws
  {-# INLINE duplicate #-}
  extract (Density f a) = f a
  {-# INLINE extract #-}

instance ComonadTrans Density where
  lower (Density f c) = extend f c
  {-# INLINE lower #-}

instance Apply f => Apply (Density f) where
  Density kxf x <.> Density kya y =
    Density (\k -> kxf (fmap fst k) (kya (fmap snd k))) ((,) <$> x <.> y)
  {-# INLINE (<.>) #-}

instance Applicative f => Applicative (Density f) where
  pure a = Density (const a) (pure ())
  {-# INLINE pure #-}
  Density kxf x <*> Density kya y =
    Density (\k -> kxf (fmap fst k) (kya (fmap snd k))) (liftA2 (,) x y)
  {-# INLINE (<*>) #-}

-- | The natural transformation from a @'Comonad' w@ to the 'Comonad' generated by @w@ (forwards).
--
-- This is merely a right-inverse (section) of 'lower', rather than a full inverse.
--
-- @
-- 'lower' . 'liftDensity' ≡ 'id'
-- @
liftDensity :: Comonad w => w a -> Density w a
liftDensity = Density extract
{-# INLINE liftDensity #-}

-- | The Density 'Comonad' of a left adjoint is isomorphic to the 'Comonad' formed by that 'Adjunction'.
--
-- This isomorphism is witnessed by 'densityToAdjunction' and 'adjunctionToDensity'.
--
-- @
-- 'densityToAdjunction' . 'adjunctionToDensity' ≡ 'id'
-- 'adjunctionToDensity' . 'densityToAdjunction' ≡ 'id'
-- @
densityToAdjunction :: Adjunction f g => Density f a -> f (g a)
densityToAdjunction (Density f v) = fmap (leftAdjunct f) v
{-# INLINE densityToAdjunction #-}

adjunctionToDensity :: Adjunction f g => f (g a) -> Density f a
adjunctionToDensity = Density counit
{-# INLINE adjunctionToDensity #-}

-- | The 'Density' 'Comonad' of a 'Functor' @f@ is obtained by taking the left Kan extension
-- ('Lan') of @f@ along itself. This isomorphism is witnessed by 'lanToDensity' and 'densityToLan'
--
-- @
-- 'lanToDensity' . 'densityToLan' ≡ 'id'
-- 'densityToLan' . 'lanToDensity' ≡ 'id'
-- @
lanToDensity :: Lan f f a -> Density f a
lanToDensity (Lan f v) = Density f v
{-# INLINE lanToDensity #-}

densityToLan :: Density f a -> Lan f f a
densityToLan (Density f v) = Lan f v
{-# INLINE densityToLan #-}

