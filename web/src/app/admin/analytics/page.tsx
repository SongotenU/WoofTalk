'use client';

import { useState, useEffect } from 'react';

interface AnalyticsData {
  translations_by_day: { date: string; count: number }[];
  active_users_by_day: { date: string; count: number }[];
  api_calls_by_day: { date: string; count: number }[];
  top_endpoints: { endpoint: string; count: number }[];
  total_translations: number;
  total_api_calls: number;
  total_users: number;
}

export default function AnalyticsPage() {
  const [data, setData] = useState<AnalyticsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [period, setPeriod] = useState<'7d' | '30d' | '90d'>('30d');

  useEffect(() => {
    const fetchData = async () => {
      setLoading(true);
      try {
        const res = await fetch(`/api/admin/analytics?period=${period}`);
        if (!res.ok) throw new Error('Failed to fetch analytics');
        const json = await res.json();
        setData(json);
      } catch {
        setData(null);
      } finally {
        setLoading(false);
      }
    };
    fetchData();
  }, [period]);

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Analytics</h2>
        <div className="flex gap-2">
          {(['7d', '30d', '90d'] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`px-3 py-1.5 text-sm rounded-md ${
                period === p
                  ? 'bg-gray-900 text-white'
                  : 'bg-white text-gray-600 border border-gray-300 hover:bg-gray-50'
              }`}
            >
              {p}
            </button>
          ))}
        </div>
      </div>

      {!loading && data && (
        <>
          {/* Summary Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
            <MetricCard label="Total Translations" value={data.total_translations} />
            <MetricCard label="Total API Calls" value={data.total_api_calls} />
            <MetricCard label="Total Users" value={data.total_users} />
          </div>

          {/* Charts */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
            <ChartCard title="Translations per Day" data={data.translations_by_day} />
            <ChartCard title="Active Users per Day" data={data.active_users_by_day} />
            <ChartCard title="API Calls per Day" data={data.api_calls_by_day} />
            <TopEndpoints endpoints={data.top_endpoints} />
          </div>
        </>
      )}

      {loading && (
        <div className="text-center py-12 text-gray-500">Loading analytics...</div>
      )}
    </div>
  );
}

function MetricCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-3xl font-bold text-gray-900 mt-1">{value.toLocaleString()}</p>
    </div>
  );
}

function ChartCard({
  title,
  data,
}: {
  title: string;
  data: { date: string; count: number }[];
}) {
  const maxCount = Math.max(...data.map((d) => d.count), 1);

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4">
      <h3 className="text-sm font-medium text-gray-700 mb-4">{title}</h3>
      <div className="flex items-end gap-1 h-40">
        {data.map((d) => (
          <div
            key={d.date}
            className="flex-1 bg-green-500 rounded-t hover:bg-green-600 transition-colors relative group"
            style={{ height: `${(d.count / maxCount) * 100}%`, minHeight: d.count > 0 ? '4px' : '0' }}
            title={`${d.date}: ${d.count}`}
          >
            {d.count > 0 && (
              <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-1 px-2 py-1 bg-gray-900 text-white text-xs rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
                {d.count}
              </div>
            )}
          </div>
        ))}
      </div>
      <div className="flex justify-between mt-2 text-xs text-gray-400">
        <span>{data[0]?.date}</span>
        <span>{data[data.length - 1]?.date}</span>
      </div>
    </div>
  );
}

function TopEndpoints({
  endpoints,
}: {
  endpoints: { endpoint: string; count: number }[];
}) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4">
      <h3 className="text-sm font-medium text-gray-700 mb-4">Top API Endpoints</h3>
      {endpoints.map((ep) => (
        <div key={ep.endpoint} className="flex items-center justify-between py-2">
          <code className="text-sm text-gray-600 bg-gray-100 px-2 py-0.5 rounded">
            {ep.endpoint}
          </code>
          <span className="text-sm font-medium text-gray-900">{ep.count.toLocaleString()}</span>
        </div>
      ))}
      {endpoints.length === 0 && (
        <p className="text-sm text-gray-400">No API data yet</p>
      )}
    </div>
  );
}
