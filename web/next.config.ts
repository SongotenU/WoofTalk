import type { NextConfig } from "next";
import withPWA from "next-pwa";
import { withSentryConfig } from "@sentry/nextjs";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  outputFileTracingRoot: process.cwd(),
};
export default withSentryConfig(
  withPWA({
    dest: "public",
    register: true,
    skipWaiting: true,
    disable: process.env.NODE_ENV === "development",
    runtimeCaching: [
      {
        urlPattern: /^https:\/\/.*\.supabase\.co\/.*/i,
        handler: "NetworkFirst",
        options: { cacheName: "supabase-cache", expiration: { maxEntries: 50, maxAgeSeconds: 60 * 60 } },
      },
    ],
    // Custom SW code is appended via postbuild script
  })(nextConfig),
  {
    // For all available options, see:
    // https://github.com/getsentry/sentry-webpack-plugin#options
    org: "wooftalk",
    project: "wooftalk-web",
    // Only print logs for the Sentry CLI when `--debug` is passed
    silent: !process.argv.includes("--debug"),
    // Upload a larger set of source maps for prettier stack traces (increases build time)
    widenClientFileUpload: true,
    // Hides source maps from generated client bundles
    // sourcemaps: true,
    // Automatically tree-shake Sentry logger statements to reduce bundle size
    disableLogger: true,
    // Disable tunnel route for self-hosted Sentry
    tunnelRoute: undefined,
  }
);
