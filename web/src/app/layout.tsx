import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { EntitlementProvider } from "@/providers/EntitlementProvider";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "WoofTalk — Translate Between Human & Animal Languages",
  description: "Translate between human and dog, cat, bird languages with voice input/output. Works offline as a PWA.",
  manifest: "/manifest.json",
  themeColor: "#4CAF50",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <EntitlementProvider>{children}</EntitlementProvider>
      </body>
    </html>
  );
}
