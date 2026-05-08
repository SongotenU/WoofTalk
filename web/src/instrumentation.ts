import * as Sentry from "@sentry/nextjs";
import { onCLS, onINP, onLCP, onFCP, onTTFB } from "web-vitals";

export function register() {
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN || "",
    tracesSampleRate: 0.1,
    environment: process.env.NODE_ENV || "development",
    integrations: [
      Sentry.replayIntegration({
        maskAllText: true,
        blockAllMedia: true,
      }),
    ],
  });

  // Web Vitals reporting to Sentry
  function reportWebVital(metric: { name: string; value: number; id: string; rating: string; delta: number }) {
    Sentry.captureMessage(`web_vital_${metric.name}`, {
      level: metric.rating === "poor" ? "warning" : "info",
      contexts: {
        web_vital: {
          name: metric.name,
          value: Math.round(metric.name === "CLS" ? metric.value * 1000 : metric.value),
          rating: metric.rating,
          id: metric.id,
          delta: Math.round(metric.name === "CLS" ? metric.delta * 1000 : metric.delta),
        },
      },
    });
  }

  onCLS(reportWebVital);
  onINP(reportWebVital);
  onLCP(reportWebVital);
  onFCP(reportWebVital);
  onTTFB(reportWebVital);
}
