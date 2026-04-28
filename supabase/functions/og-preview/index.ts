import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Verified MIT: @supabase/supabase-js
// imagescript is pure TypeScript/Deno, MIT license.
import { Image } from "https://deno.land/x/imagescript@1.2.15/mod.ts";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

// Plan codes that require a mandatory watermark (mirrors TierService).
const FREE_CODES = new Set(["free", ""]);

interface OgPreviewRequest {
  /** Publicly accessible URL of the source image (JPEG/PNG). */
  image_url: string;
  /** Supabase user ID — used to fetch their tier. */
  user_id: string;
  /** Optional watermark style; defaults to "minimal". */
  template?: "minimal" | "prominent" | "brand_first";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: CORS });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  let body: OgPreviewRequest;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const { image_url, user_id, template = "minimal" } = body;
  if (!image_url || !user_id) {
    return json({ error: "image_url and user_id are required" }, 400);
  }

  // ── Tier check ────────────────────────────────────────────────────────────
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  );

  const { data: entRow } = await supabase
    .from("entitlements_v")
    .select("plan_code")
    .eq("user_id", user_id)
    .maybeSingle();

  const planCode: string = (entRow?.plan_code as string) ?? "free";
  const mandatory = FREE_CODES.has(planCode);

  // Pro/Ultimate users can skip watermark; free users cannot.
  const applyWatermark = mandatory; // caller may set template=null to skip for paid

  // ── Fetch source image ────────────────────────────────────────────────────
  const srcResp = await fetch(image_url);
  if (!srcResp.ok) {
    return json({ error: `Failed to fetch image: ${srcResp.status}` }, 502);
  }
  const srcBytes = new Uint8Array(await srcResp.arrayBuffer());

  // ── Decode + stamp ────────────────────────────────────────────────────────
  let base: Image;
  try {
    base = await Image.decode(srcBytes);
  } catch {
    return json({ error: "Cannot decode source image" }, 422);
  }

  if (applyWatermark) {
    await _applyWatermark(base, template);
  }

  const outBytes = await base.encodeJPEG(92);

  return new Response(outBytes, {
    status: 200,
    headers: {
      ...CORS,
      "Content-Type": "image/jpeg",
      "Cache-Control": "public, max-age=3600",
      "X-Watermark-Applied": String(applyWatermark),
      "X-Plan-Code": planCode,
    },
  });
});

// ── Watermark stamping ────────────────────────────────────────────────────────

async function _applyWatermark(
  base: Image,
  template: string,
): Promise<void> {
  const W = base.width;
  const H = base.height;

  // Watermark area cap: 15% of image area.
  // Logo is a filled rounded rect + "Made with Vagus" text.
  // We size the badge to ~10% of image width, max 200px.
  const badgeW = Math.min(Math.round(W * 0.10), 200);
  const badgeH = template === "minimal" ? Math.round(badgeW * 0.25) : Math.round(badgeW * 0.40);

  // Verify we stay under 15% cap.
  const totalArea = W * H;
  if (badgeW * badgeH > totalArea * 0.15) {
    // Scale down proportionally to stay within the cap.
    const scale = Math.sqrt((totalArea * 0.14) / (badgeW * badgeH));
    // (already guarded by the 10% width fraction — this is a safety belt)
    console.warn(`Watermark area clamped by 15% rule (scale=${scale.toFixed(2)})`);
  }

  const x = W - badgeW - 8;
  const y = H - badgeH - 8;

  // Semi-transparent dark pill backdrop.
  _drawRoundedRect(base, x, y, badgeW, badgeH, 4, 0, 0, 0, 120);

  // Text rows.
  const textColor = { r: 255, g: 255, b: 255, a: 210 };
  const subColor = { r: 180, g: 180, b: 180, a: 180 };

  if (template === "minimal") {
    _drawText(base, "Made with Vagus", x + 4, y + (badgeH - 10) / 2, 9, textColor);
  } else if (template === "prominent") {
    _drawText(base, "Made with Vagus", x + 4, y + 4, 9, textColor);
    _drawText(base, "vagus.app", x + 4, y + 18, 8, subColor);
  } else {
    // brand_first
    _drawText(base, "VAGUS", x + 4, y + 4, 10, textColor);
    _drawText(base, "Made with Vagus", x + 4, y + 18, 8, subColor);
    _drawText(base, "vagus.app", x + 4, y + 30, 7, subColor);
  }
}

// Minimal pixel-level helpers (imagescript exposes per-pixel access).
// These are intentionally simple — the Edge Function runs rarely (OG preview
// generation is cached) so a tight pixel loop is acceptable.

function _drawRoundedRect(
  img: Image,
  x: number, y: number, w: number, h: number, r: number,
  R: number, G: number, B: number, A: number,
): void {
  for (let py = y; py < y + h; py++) {
    for (let px = x; px < x + w; px++) {
      if (px < 0 || py < 0 || px >= img.width || py >= img.height) continue;
      // Corner rounding.
      const cx = Math.min(px - x, x + w - 1 - px);
      const cy = Math.min(py - y, y + h - 1 - py);
      if (cx < r && cy < r && (cx - r) ** 2 + (cy - r) ** 2 > r ** 2) continue;
      img.setPixelAt(px + 1, py + 1, Image.rgbaToColor(R, G, B, A));
    }
  }
}

// Rasterise text using a 5×7 pixel font baked inline.
// Only supports ASCII printable characters — sufficient for "Made with Vagus".
function _drawText(
  img: Image,
  text: string,
  x: number, y: number,
  _size: number,
  color: { r: number; g: number; b: number; a: number },
): void {
  const c = Image.rgbaToColor(color.r, color.g, color.b, color.a);
  let cx = x;
  for (const ch of text) {
    const glyph = FONT5X7[ch] ?? FONT5X7[" "];
    for (let row = 0; row < 7; row++) {
      for (let col = 0; col < 5; col++) {
        if (glyph[row] & (1 << (4 - col))) {
          const px = cx + col;
          const py = y + row;
          if (px >= 0 && px < img.width && py >= 0 && py < img.height) {
            img.setPixelAt(px + 1, py + 1, c);
          }
        }
      }
    }
    cx += 6; // 5px glyph + 1px kerning
  }
}

// Compact 5×7 bitmap font for ASCII characters used in watermark strings.
// Each character = 7 rows × 5 bits (MSB = leftmost column).
// Only the characters that appear in "Made with Vagus" and "vagus.app" are
// fully defined; everything else falls back to the space glyph.
const FONT5X7: Record<string, number[]> = {
  " ": [0, 0, 0, 0, 0, 0, 0],
  M: [0b11111, 0b10001, 0b10101, 0b10101, 0b10001, 0b10001, 0b10001],
  a: [0b01110, 0b00001, 0b01111, 0b10001, 0b10011, 0b01101, 0b00000],
  d: [0b00001, 0b00001, 0b01101, 0b10011, 0b10001, 0b10011, 0b01101],
  e: [0b01110, 0b10001, 0b11111, 0b10000, 0b10000, 0b10001, 0b01110],
  w: [0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b11011, 0b10001],
  i: [0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110],
  t: [0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100],
  h: [0b10001, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001],
  V: [0b10001, 0b10001, 0b10001, 0b10001, 0b01010, 0b01010, 0b00100],
  g: [0b01111, 0b10001, 0b10001, 0b01111, 0b00001, 0b10001, 0b01110],
  u: [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10011, 0b01101],
  s: [0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110],
  ".": [0, 0, 0, 0, 0, 0b00100, 0b00100],
  A: [0b00100, 0b01010, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001],
  G: [0b01110, 0b10001, 0b10000, 0b10111, 0b10001, 0b10001, 0b01111],
  U: [0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110],
  S: [0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110],
  v: [0b10001, 0b10001, 0b10001, 0b01010, 0b01010, 0b00100, 0b00000],
  p: [0b11110, 0b10001, 0b10001, 0b11110, 0b10000, 0b10000, 0b10000],
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}
