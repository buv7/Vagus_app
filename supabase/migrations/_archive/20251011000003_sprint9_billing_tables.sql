-- Sprint 9: Monetization & Plan Gating
-- Enhance existing billing infrastructure (additive only)

-- 1. Add missing columns to subscriptions (if needed)
ALTER TABLE IF EXISTS public.subscriptions
  ADD COLUMN IF NOT EXISTS plan TEXT DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active',
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add constraints if they don't exist (wrapped in DO block for idempotency)
DO $$
BEGIN
  -- Add plan check constraint if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints
    WHERE constraint_name = 'subscriptions_plan_check'
  ) THEN
    ALTER TABLE public.subscriptions 
    ADD CONSTRAINT subscriptions_plan_check 
    CHECK (plan IN ('free', 'premium_client', 'premium_coach', 'admin_override'));
  END IF;
  
  -- Add status check constraint if not exists
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.check_constraints
    WHERE constraint_name = 'subscriptions_status_check'
  ) THEN
    ALTER TABLE public.subscriptions 
    ADD CONSTRAINT subscriptions_status_check 
    CHECK (status IN ('active', 'canceled', 'expired', 'past_due'));
  END IF;
END$$;

CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON public.subscriptions(status) WHERE status = 'active';

-- 2. Add missing columns to invoices
ALTER TABLE IF EXISTS public.invoices
  ADD COLUMN IF NOT EXISTS subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS paid_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS due_date DATE;

CREATE INDEX IF NOT EXISTS idx_invoices_user ON public.invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_subscription ON public.invoices(subscription_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON public.invoices(status);

-- 3. Add missing columns to coupons (reconcile naming differences)
ALTER TABLE IF EXISTS public.coupons
  ADD COLUMN IF NOT EXISTS valid_from TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS valid_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::JSONB,
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();

-- Make coupons.code unique if not already
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint 
    WHERE conname = 'coupons_code_key'
  ) THEN
    ALTER TABLE public.coupons ADD CONSTRAINT coupons_code_key UNIQUE (code);
  END IF;
END$$;

-- 4. Ensure coupon_redemptions table structure
CREATE TABLE IF NOT EXISTS public.coupon_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_code TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  redeemed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(coupon_code, user_id)
);

CREATE INDEX IF NOT EXISTS idx_coupon_redemptions_user ON public.coupon_redemptions(user_id);

-- 5. Enable RLS on all tables
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupon_redemptions ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies for subscriptions
DROP POLICY IF EXISTS "owner_read_subs" ON public.subscriptions;
CREATE POLICY "owner_read_subs" ON public.subscriptions
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "service_role_manage_subs" ON public.subscriptions;
CREATE POLICY "service_role_manage_subs" ON public.subscriptions
  FOR ALL 
  TO service_role
  USING (true) 
  WITH CHECK (true);

-- 7. RLS Policies for invoices
DROP POLICY IF EXISTS "owner_read_invoices" ON public.invoices;
CREATE POLICY "owner_read_invoices" ON public.invoices
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "service_role_manage_invoices" ON public.invoices;
CREATE POLICY "service_role_manage_invoices" ON public.invoices
  FOR ALL 
  TO service_role
  USING (true) 
  WITH CHECK (true);

-- 8. RLS Policies for coupons (read-only for authenticated users)
DROP POLICY IF EXISTS "public_read_coupons" ON public.coupons;
CREATE POLICY "public_read_coupons" ON public.coupons
  FOR SELECT 
  TO authenticated
  USING (is_active = TRUE OR TRUE); -- Allow reading coupons

DROP POLICY IF EXISTS "service_role_manage_coupons" ON public.coupons;
CREATE POLICY "service_role_manage_coupons" ON public.coupons
  FOR ALL 
  TO service_role
  USING (true) 
  WITH CHECK (true);

-- 9. RLS Policies for coupon_redemptions
DROP POLICY IF EXISTS "owner_read_redemptions" ON public.coupon_redemptions;
CREATE POLICY "owner_read_redemptions" ON public.coupon_redemptions
  FOR SELECT 
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "service_role_manage_redemptions" ON public.coupon_redemptions;
CREATE POLICY "service_role_manage_redemptions" ON public.coupon_redemptions
  FOR ALL 
  TO service_role
  USING (true) 
  WITH CHECK (true);

-- 10. Function to get user's current plan
CREATE OR REPLACE FUNCTION public.get_user_plan(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_plan TEXT;
BEGIN
  SELECT plan INTO v_plan
  FROM public.subscriptions
  WHERE user_id = p_user_id
  AND status = 'active'
  ORDER BY created_at DESC
  LIMIT 1;
  
  RETURN COALESCE(v_plan, 'free');
END;
$$;

-- 11. Function to validate coupon (compatible with existing schema)
CREATE OR REPLACE FUNCTION public.validate_coupon_code(p_code TEXT)
RETURNS TABLE(
  is_valid BOOLEAN,
  percent_off INTEGER,
  amount_off_cents INTEGER,
  message TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_coupon RECORD;
BEGIN
  SELECT * INTO v_coupon
  FROM public.coupons
  WHERE code = p_code
  LIMIT 1;
  
  IF v_coupon IS NULL THEN
    RETURN QUERY SELECT FALSE, NULL::INTEGER, NULL::INTEGER, 'Coupon not found'::TEXT;
    RETURN;
  END IF;
  
  -- Check is_active column (existing schema uses is_active, not active)
  IF v_coupon.is_active = FALSE THEN
    RETURN QUERY SELECT FALSE, NULL::INTEGER, NULL::INTEGER, 'Coupon is not active'::TEXT;
    RETURN;
  END IF;
  
  -- Check redeem_by date (existing schema)
  IF v_coupon.redeem_by IS NOT NULL AND v_coupon.redeem_by < NOW() THEN
    RETURN QUERY SELECT FALSE, NULL::INTEGER, NULL::INTEGER, 'Coupon has expired'::TEXT;
    RETURN;
  END IF;
  
  -- Check max redemptions
  IF v_coupon.max_redemptions IS NOT NULL THEN
    DECLARE
      v_redemption_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO v_redemption_count
      FROM public.coupon_redemptions
      WHERE coupon_code = p_code;
      
      IF v_redemption_count >= v_coupon.max_redemptions THEN
        RETURN QUERY SELECT FALSE, NULL::INTEGER, NULL::INTEGER, 'Coupon has been fully redeemed'::TEXT;
        RETURN;
      END IF;
    END;
  END IF;
  
  RETURN QUERY SELECT 
    TRUE, 
    v_coupon.percent_off, 
    v_coupon.amount_off_cents, 
    'Coupon is valid'::TEXT;
END;
$$;

-- 12. Trigger to update subscriptions timestamp
CREATE OR REPLACE FUNCTION public.update_subscription_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_subscription_timestamp ON public.subscriptions;
CREATE TRIGGER trigger_update_subscription_timestamp
BEFORE UPDATE ON public.subscriptions
FOR EACH ROW
EXECUTE FUNCTION public.update_subscription_timestamp();

-- 13. Grant permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.subscriptions TO authenticated;
GRANT SELECT ON public.invoices TO authenticated;
GRANT SELECT ON public.coupons TO authenticated;
GRANT SELECT ON public.coupon_redemptions TO authenticated;

-- 14. Comments
COMMENT ON TABLE public.subscriptions IS 'User subscription plans and status';
COMMENT ON TABLE public.invoices IS 'Payment invoices for subscriptions';
COMMENT ON TABLE public.coupons IS 'Discount coupons for subscriptions';
COMMENT ON TABLE public.coupon_redemptions IS 'Tracking of coupon usage by users';
COMMENT ON FUNCTION public.get_user_plan IS 'Returns active plan for user, defaults to free';
COMMENT ON FUNCTION public.validate_coupon_code IS 'Validates coupon code and returns discount information';
