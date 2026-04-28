import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const APPLE_VERIFY_PROD = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_VERIFY_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt';

// Shared secret from App Store Connect → My Apps → [Vagus] → Subscriptions
const APPLE_SHARED_SECRET = Deno.env.get('APPLE_SHARED_SECRET') ?? '';

const PRODUCT_TIERS: Record<string, string> = {
  vagus_pro_monthly: 'pro',
  vagus_ultimate_monthly: 'ultimate',
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

interface LatestReceiptInfo {
  product_id: string;
  original_transaction_id: string;
  expires_date_ms: string;
  is_trial_period: string;
  is_in_intro_offer_period: string;
  purchase_date_ms: string;
}

interface AppleVerifyResponse {
  status: number;
  latest_receipt_info?: LatestReceiptInfo[];
  latest_receipt?: string;
  receipt?: { in_app: LatestReceiptInfo[] };
}

async function callApple(
  receiptData: string,
  sandbox: boolean,
): Promise<AppleVerifyResponse> {
  const url = sandbox ? APPLE_VERIFY_SANDBOX : APPLE_VERIFY_PROD;
  const body = JSON.stringify({
    'receipt-data': receiptData,
    password: APPLE_SHARED_SECRET,
    'exclude-old-transactions': true,
  });

  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body,
  });
  return res.json() as Promise<AppleVerifyResponse>;
}

async function verifyReceipt(
  receiptData: string,
): Promise<{ tier: string; expiresAt: Date; originalTxId: string; isTrial: boolean }> {
  // Try production first; status 21007 means the receipt is from sandbox.
  let appleResp = await callApple(receiptData, false);

  if (appleResp.status === 21007) {
    appleResp = await callApple(receiptData, true);
  }

  if (appleResp.status !== 0) {
    throw new Error(`Apple verifyReceipt status ${appleResp.status}`);
  }

  const infos = appleResp.latest_receipt_info ?? [];
  if (infos.length === 0) {
    throw new Error('No receipt info returned by Apple');
  }

  // Pick the most recent non-expired transaction.
  const now = Date.now();
  const active = infos
    .filter((i) => parseInt(i.expires_date_ms) > now)
    .sort((a, b) => parseInt(b.expires_date_ms) - parseInt(a.expires_date_ms));

  const latest = active[0] ?? infos.sort(
    (a, b) => parseInt(b.expires_date_ms) - parseInt(a.expires_date_ms),
  )[0];

  const tier = PRODUCT_TIERS[latest.product_id] ?? 'free';
  const expiresAt = new Date(parseInt(latest.expires_date_ms));
  const isTrial =
    latest.is_trial_period === 'true' ||
    latest.is_in_intro_offer_period === 'true';

  return {
    tier,
    expiresAt,
    originalTxId: latest.original_transaction_id,
    isTrial,
  };
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // Require authenticated caller — the JWT is the user's Supabase token.
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing authorization' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser();

    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const receiptData: string | undefined = body.receipt_data;

    if (!receiptData) {
      return new Response(
        JSON.stringify({ error: 'receipt_data is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    // Server-side validation with Apple — this is the authority check.
    const { tier, expiresAt, originalTxId, isTrial } =
      await verifyReceipt(receiptData);

    const status = expiresAt > new Date() ? (isTrial ? 'trialing' : 'active') : 'expired';

    // Use service-role client to write subscription data (user cannot write this themselves).
    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    // Write using TRIAL-compatible column names (plan_code, period_end).
    const { error: upsertError } = await serviceClient
      .from('subscriptions')
      .upsert(
        {
          user_id: user.id,
          plan_code: tier,           // 'pro' | 'ultimate'
          status,
          platform: 'apple',
          period_start: new Date().toISOString(),
          period_end: expiresAt.toISOString(),
          apple_original_transaction_id: originalTxId,
          apple_expires_at: expiresAt.toISOString(),
          is_trial: isTrial,
          cancel_at_period_end: false,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      );

    if (upsertError) {
      console.error('DB upsert error:', upsertError);
      return new Response(
        JSON.stringify({ error: 'Failed to update subscription' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    return new Response(
      JSON.stringify({ tier, status, expires_at: expiresAt.toISOString(), is_trial: isTrial }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  } catch (err) {
    console.error('validate-apple-receipt error:', err);
    return new Response(
      JSON.stringify({ error: (err as Error).message ?? 'Internal error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    );
  }
});
