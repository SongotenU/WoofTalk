"use client";

import { useEffect, useState } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

export default function InviteAcceptPage() {
  const searchParams = useSearchParams();
  const token = searchParams.get("token");
  const [status, setStatus] = useState<"loading" | "success" | "error" | "expired">("loading");
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (!token) {
      setStatus("error");
      setMessage("Invalid invite link — no token found");
      return;
    }

    const acceptInvite = async () => {
      try {
        // Check if token exists and is valid
        const { data: member, error } = await supabase
          .from("organization_members")
          .select("org_id, invite_expires_at, status, organizations(name)")
          .eq("invite_token", token)
          .single();

        if (error || !member) {
          setStatus("error");
          setMessage("Invalid invite token. It may have already been used.");
          return;
        }

        if (member.status !== "invited") {
          setStatus("error");
          setMessage("This invite has already been accepted or was revoked.");
          return;
        }

        if (member.invite_expires_at && new Date(member.invite_expires_at) < new Date()) {
          setStatus("expired");
          setMessage("This invitation has expired. Ask an admin to resend the invite.");
          return;
        }

        // Accept invite: update status to active
        const { error: updateError } = await supabase
          .from("organization_members")
          .update({
            status: "active",
            joined_at: new Date().toISOString(),
            invite_token: null,
            invite_expires_at: null,
          })
          .eq("invite_token", token);

        if (updateError) {
          setStatus("error");
          setMessage("Failed to accept invite. Please try again or contact support.");
          return;
        }

        setStatus("success");
        setMessage(`Welcome to ${member.organizations?.name || "the organization"}!`);
      } catch {
        setStatus("error");
        setMessage("Something went wrong. Please try again.");
      }
    };

    acceptInvite();
  }, [token]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
      <div className="bg-white rounded-xl border border-gray-200 p-8 max-w-md w-full text-center">
        {status === "loading" && (
          <>
            <div className="inline-block w-8 h-8 border-4 border-emerald-200 border-t-emerald-600 rounded-full animate-spin mb-4" />
            <p className="text-gray-600">Accepting your invitation...</p>
          </>
        )}

        {status === "success" && (
          <>
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">Welcome!</h2>
            <p className="text-gray-600 mb-6">{message}</p>
            <Link href="/org" className="inline-block px-6 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
              Go to your organization
            </Link>
          </>
        )}

        {(status === "error" || status === "expired") && (
          <>
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </div>
            <h2 className="text-xl font-bold text-gray-900 mb-2">
              {status === "expired" ? "Invitation Expired" : "Invalid Invitation"}
            </h2>
            <p className="text-gray-600 mb-6">{message}</p>
            <Link href="/" className="inline-block px-6 py-2 bg-emerald-600 text-white rounded-lg hover:bg-emerald-700">
              Go home
            </Link>
          </>
        )}
      </div>
    </div>
  );
}
