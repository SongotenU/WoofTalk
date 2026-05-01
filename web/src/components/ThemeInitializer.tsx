"use client";

import { useEffect } from "react";
import { useTheme } from "@/lib/theme-provider";

export default function ThemeInitializer() {
  const { theme } = useTheme();

  useEffect(() => {
    const savedContrast = localStorage.getItem('highContrast');
    if (savedContrast === 'true') {
      document.documentElement.setAttribute('data-contrast', 'high');
    } else {
      document.documentElement.removeAttribute('data-contrast');
    }
  }, []);

  useEffect(() => {
    const savedContrast = localStorage.getItem('highContrast');
    if (savedContrast === 'true') {
      document.documentElement.setAttribute('data-contrast', 'high');
    }
  }, [theme]);

  return null;
}
