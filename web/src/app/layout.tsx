import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { EntitlementProvider } from "@/providers/EntitlementProvider";
import { ThemeProvider } from "@/lib/theme-provider";
import ThemeInitializer from "@/components/ThemeInitializer";
import PWAInstallPrompt from "@/components/PWAInstallPrompt";
import Script from "next/script";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "WoofTalk — Translate Between Human & Animal Languages",
  description: "Translate between human and dog, cat, bird languages with voice input/output. Works offline as a PWA.",
  manifest: "/manifest.json",
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#4CAF50" },
    { media: "(prefers-color-scheme: dark)", color: "#2E7D32" },
  ],
  openGraph: {
    title: "WoofTalk — Talk to Your Pets",
    description: "Translate between human and animal languages with AI-powered voice translation. Works offline.",
    url: "https://wooftalk.app",
    siteName: "WoofTalk",
    images: [
      {
        url: "https://wooftalk.app/og-image.png",
        width: 1200,
        height: 630,
        alt: "WoofTalk - Translate to Dog, Cat, and Bird languages",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "WoofTalk — Talk to Your Pets",
    description: "Translate between human and animal languages with AI-powered voice translation.",
    images: ["https://wooftalk.app/og-image.png"],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <Script id="theme-init" strategy="beforeInteractive">
          {`
            (function() {
              var theme = localStorage.getItem('wooftalk-theme') || 'system';
              if (theme === 'dark') {
                document.documentElement.classList.add('dark');
              } else if (theme === 'light') {
                document.documentElement.classList.remove('dark');
              } else {
                if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
                  document.documentElement.classList.add('dark');
                }
              }
            })();
          `}
        </Script>
      </head>
      <body className={inter.className}>
        <ThemeProvider>
          <ThemeInitializer />
          <EntitlementProvider>
            {children}
            <PWAInstallPrompt />
          </EntitlementProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
