'use client';

import { useState, useEffect } from 'react';

interface ErrorLog {
  id: string;
  platform: string;
  error_type: string;
  message: string;
  stack_trace?: string;
  user_id?: string;
  endpoint?: string;
  status_code?: number;
  metadata: any;
  created_at: string;
}

export default function AdminErrorsPage() {
  const [errors, setErrors] = useState<ErrorLog[]>([]);
  const [summary, setSummary] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [days, setDays] = useState(7);
  const [platform, setPlatform] = useState<string>('');
  const [expandedError, setExpandedError] = useState<string | null>(null);

  const fetchErrors = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ days: days.toString() });
      if (platform) params.set('platform', platform);
      const res = await fetch(`/api/admin/errors?${params}`);
      if (!res.ok) throw new Error('Failed to fetch');
      const data = await res.json();
      setErrors(data.errors || []);
      setSummary(data.summary || null);
    } catch {
      setErrors([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchErrors(); }, [days, platform]);

  const platformColors: Record<string, string> = {
    ios: 'bg-blue-100 text-blue-800',
    android: 'bg-green-100 text-green-800',
    web: 'bg-purple-100 text-purple-800',
    edge_function: 'bg-orange-100 text-orange-800',
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Error Tracking</h2>
        <button onClick={fetchErrors} className="px-3 py-1.5 text-sm bg-gray-900 text-white rounded-md hover:bg-gray-800">
          Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="flex gap-4 mb-6">
        <select value={days} onChange={(e) => setDays(parseInt(e.target.value))}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm">
          <option value={7}>Last 7 days</option>
          <option value={30}>Last 30 days</option>
          <option value={90}>Last 90 days</option>
        </select>
        <select value={platform} onChange={(e) => setPlatform(e.target.value)}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm">
          <option value="">All Platforms</option>
          <option value="ios">iOS</option>
          <option value="android">Android</option>
          <option value="web">Web</option>
          <option value="edge_function">Edge Function</option>
        </select>
      </div>

      {/* Summary Cards */}
      {summary && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-sm text-gray-500">Total Errors</p>
            <p className="text-2xl font-bold text-gray-900">{summary.total}</p>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-sm text-gray-500">By Type</p>
            <div className="mt-1 space-y-1">
              {Object.entries(summary.byType || {}).map(([type, count]: [string, any]) => (
                <div key={type} className="flex justify-between text-sm">
                  <span className="text-gray-600">{type}</span>
                  <span className="font-medium">{count}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="bg-white p-4 rounded-lg border border-gray-200">
            <p className="text-sm text-gray-500">By Platform</p>
            <div className="mt-1 space-y-1">
              {summary.byDay?.[0] && Object.entries(summary.byDay[0].platforms || {}).map(([plat, count]: [string, any]) => (
                <div key={plat} className="flex justify-between text-sm">
                  <span className="text-gray-600">{plat}</span>
                  <span className="font-medium">{count}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Error List */}
      {loading ? (
        <div className="text-center py-8 text-gray-500">Loading...</div>
      ) : (
        <div className="bg-white border border-gray-200 rounded-lg overflow-hidden">
          <div className="max-h-96 overflow-y-auto">
            {errors.map((err) => (
              <div key={err.id} className="border-b border-gray-100 last:border-b-0">
                <div className="p-4 hover:bg-gray-50 cursor-pointer"
                  onClick={() => setExpandedError(expandedError === err.id ? null : err.id)}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className={`px-2 py-0.5 text-xs rounded-full ${platformColors[err.platform] || 'bg-gray-100'}`}>
                        {err.platform}
                      </span>
                      <span className="text-sm font-medium text-gray-900">{err.error_type}</span>
                      <span className="text-sm text-gray-600 truncate max-w-md">{err.message}</span>
                    </div>
                    <span className="text-xs text-gray-400">
                      {new Date(err.created_at).toLocaleDateString()}
                    </span>
                  </div>
                  {err.status_code && (
                    <span className="text-xs text-gray-400 ml-16">Status: {err.status_code}</span>
                  )}
                </div>
                {expandedError === err.id && (
                  <div className="px-4 pb-4 ml-16">
                    {err.endpoint && <p className="text-sm text-gray-500">Endpoint: {err.endpoint}</p>}
                    {err.stack_trace && (
                      <pre className="mt-2 p-2 bg-gray-50 rounded text-xs overflow-x-auto text-gray-700">
                        {err.stack_trace}
                      </pre>
                    )}
                    {err.metadata && Object.keys(err.metadata).length > 0 && (
                      <pre className="mt-2 p-2 bg-gray-50 rounded text-xs overflow-x-auto text-gray-700">
                        {JSON.stringify(err.metadata, null, 2)}
                      </pre>
                    )}
                  </div>
                )}
              </div>
            ))}
            {errors.length === 0 && (
              <p className="text-center py-8 text-gray-400">No errors found</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
