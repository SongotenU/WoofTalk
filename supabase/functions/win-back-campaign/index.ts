import { serve } from "https://deno.land/x/supabase_aws@0.4.0/mod.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface Envelope {
  event: string;
  data: any;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { event, data } = await req.json() as Envelope;

    // Handle RevenueCat webhook cancellation event
    if (event === "CANCELLATION" || event === "EXPIRATION") {
      const userId = data?.app_user_id || data?.user_id;
      if (!userId) throw new Error("No user_id in webhook payload");

      // Fetch user email and cancellation info
      const { data: userData } = await supabaseClient.auth.admin.getUserById(userId);
      const email = userData?.user?.email;
      if (!email) return new Response("No email found", { status: 200 });

      // Get cancellation reason
      const { data: surveyData } = await supabaseClient
        .from("cancellation_surveys")
        .select("reason, feedback")
        .eq("user_id", userId)
        .order("created_at", { ascending: false })
        .limit(1)
        .single();

      // Update subscription_status
      await supabaseClient
        .from("subscription_status")
        .update({
          subscription_tier: "free",
          cancellation_reason: surveyData?.reason || "unknown",
          cancelled_at: new Date().toISOString(),
        })
        .eq("user_id", userId);

      // Generate win-back offer code
      const offerCode = `COMEBACK-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

      // Store offer in database (optional: create win_back_offers table)
      // For now, log it
      console.log(`Win-back offer for ${email}: ${offerCode}`);

      // Send win-back email via Supabase Auth (email template)
      const { error: emailError } = await supabaseClient.auth.admin.generateLink({
        type: "magiclink",
        email,
        options: {
          redirectTo: `${Deno.env.get("SITE_URL")}/subscribe?promo=${offerCode}`,
          data: {
            email_template: "win_back",
            offer_code: offerCode,
            offer_discount: "50% off first 3 months",
            cancellation_reason: surveyData?.reason || "unknown",
          },
        },
      });

      if (emailError) {
        console.error("Failed to send win-back email:", emailError);
      }

      return new Response(JSON.stringify({ success: true, offerCode }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ message: "Event not handled" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
