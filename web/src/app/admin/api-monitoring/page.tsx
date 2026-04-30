'use client';

import { useState, useEffect } from 'react';

interface ApiKeyUsage {
  id: string;
  api_key_id: string;
  endpoint: string;
  status_code: number;
  created_at: string;
  api_keys: { name: string; user_id: string; rate_limit: number; is_revoked: boolean };
}

interface MonitoringData {
  usage: ApiKeyUsage[];
  summary: {
    total_calls: number;
    by_endpoint: Record<string, number>;
    by_status: Record<string, number>;
    top_users: Record<string, number>;
  };
}

export default function ApiMonitoringPage() {
  const [data, setData] = useState<MonitoringData | null>(null);
  const [loading, setLoading] = useState(true);
  const [days, setDays] = useState(7);

  const fetchData = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/admin/api-monitoring?days=${days}`);
      if (!res.ok) throw new Error('Failed');
      const json = await res.json();
      setData(json);
    } catch {
      setData(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, [days]);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">API Monitoring</h2>
        <div className="flex gap-2">
          {[1, 7, 30].map((d) => (
            <button key={d} onClick={() => setDays(d)}
              className={`px-3 py-1.5 text-sm rounded-md ${days === d ? 'bg-gray-900 text-white' : 'bg-white text-gray-600 border border-gray-300'}`}>
              {d}d
            </button>
          ))}
          <button onClick={fetchData} className="px-3 py-1.5 text-sm bg-gray-900 text-white rounded-md">Refresh</button>
        </div>
      </div>

      {!loading && data && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-4 gap-4 mb-6">
            <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">Total Calls</p>
              <p className="text-2xl font-bold text-gray-900">{data.summary.total_calls}</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">Endpoints</p>
              <p className="text-2xl font-bold text-gray-900">{Object.keys(data.summary.by_endpoint).length}</p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">Error Rate</p>
              <p className="text-2xl font-bold text-gray-900">
                {data.summary.total_calls > 0
                  ? Math.round((data.summary.by_status['4'] || 0) / data.summary.total_calls * 100)
                  : 0}%
              </p>
            </div>
            <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200">
              <p className="text-sm text-gray-500">Active Keys</p>
              <p className="text-2xl font-bold text-gray-900">{Object.keys(data.summary.top_users).length}</p>
            </div>
          </div>

          {/* By Endpoint */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 mb-6">
            <div className="px-4 py-3 border-b border-gray-200"><h3 className="font-semibold text-gray-900">Calls by Endpoint</h3></div>
            <div className="p-4 space-y-2">
              {Object.entries(data.summary.by_endpoint).sort((a, b) => b[1] - a[1]).map(([endpoint, count]) => (
                <div key={endpoint} className="flex items-center justify-between text-sm">
                  <span className="text-gray-600 font-mono">{endpoint}</span>
                  <span className="font-semibold text-gray-900">{count as number}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Recent Calls */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200">
            <div className="px-4 py-3 border-b border-gray-200"><h3 className="font-semibold text-gray-900">Recent API Calls</h3></div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase">
                    <th className="px-4 py-3">Time</th>
                    <th className="px-4 py-3">API Key</th>
                    <th className="px-4 py-3">Endpoint</th>
                    <th className="px-4 py-3">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-200">
                  {data.usage.map((u) => (
                    <tr key={u.id} className="hover:bg-gray-50">
                      <td className="px-4 py-3 text-gray-600">{new Date(u.created_at).toLocaleString()}</td>
                      <td className="px-4 py-3 text-gray-900">{u.api_keys?.name || u.api_key_id.slice(0, 8)}</td>
                      <td className="px-4 py-3 font-mono text-xs">{u.endpoint}</td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex px-2 py-1 text-xs rounded-full ${u.status_code < 400 ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>
                          {u.status_code}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
