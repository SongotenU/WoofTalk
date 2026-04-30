-- Fix CHECK constraint on subscription_snapshots table
-- The original constraint used 'cancelled' (British English) but the code uses 'canceled' (American English)
-- Also adding 'paused' status which was missing

-- Drop the existing CHECK constraint
ALTER TABLE public.subscription_snapshots 
  DROP CONSTRAINT IF EXISTS subscription_snapshots_status_check;

-- Add the corrected CHECK constraint with proper spelling and all statuses
ALTER TABLE public.subscription_snapshots 
  ADD CONSTRAINT subscription_snapshots_status_check 
  CHECK (status IN ('trial', 'active', 'canceled', 'expired', 'past_due', 'paused'));

-- Add comment explaining the statuses
COMMENT ON COLUMN public.subscription_snapshots.status IS 
  'Subscription status: trial, active, canceled, expired, past_due, or paused';
