'use client';

import { useState, useEffect, useCallback } from 'react';
import { supabase, subscribeToTranslations, subscribeToCommunityPhrases, subscribeToActivity } from '@/lib/supabase';

type SyncStatus = 'connected' | 'disconnected' | 'syncing';

interface SyncStatusResult {
  status: SyncStatus;
  lastSync: Date | null;
  isConnected: boolean;
}

export function useSyncStatus(): SyncStatusResult {
  const [status, setStatus] = useState<SyncStatus>('disconnected');
  const [lastSync, setLastSync] = useState<Date | null>(null);

  const updateLastSync = useCallback(() => {
    setLastSync(new Date());
  }, []);

  useEffect(() => {
    const channels = [
      subscribeToTranslations(() => updateLastSync()),
      subscribeToCommunityPhrases(() => updateLastSync()),
      subscribeToActivity(() => updateLastSync()),
    ];

    setStatus('connected');
    setLastSync(new Date());

    return () => {
      channels.forEach((channel) => {
        supabase.removeChannel(channel);
      });
      setStatus('disconnected');
    };
  }, [updateLastSync]);

  return {
    status,
    lastSync,
    isConnected: status === 'connected',
  };
}
