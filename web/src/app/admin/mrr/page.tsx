'use client';

import { useState, useEffect } from 'react';

interface MrrData {
  mrrTrend: Array<{
    month: string;
    mrr: number;
    activeSubscriptions: number;
    trials: number;
    cancelled: number;
    churnRate: number;
  }>;
  current: {
    mrr: number;
    activeSubscriptions: number;
    trials: number;
    totalSubscribers: number;
    trialSubscribers: number;
    premiumSubscribers: number;
  };
}

export default function AdminMrrPage() {
  const [data, setData] = useState<MrrData | null>(null);
  const [loading, setLoading] = useState(true);
  const [months, setMonths] = useState(12);

  const fetchData = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/admin/mrr?months=${months}`);
      if (!res.ok) throw new Error('Failed');
      const json = await res.json();
      setData(json);
    } catch {
      setData(null);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, [months]);

  const maxMrr = data ? Math.max(...data.mrrTrend.map((m) => m.mrr), 1) : 1;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Revenue & MRR Dashboard</h2>
        <div className="flex gap-2">
          {[3, 6, 12].map((m) => (
            <button key={m} onClick={() => setMonths(m)}
              className={`px-3 py-1.5 text-sm rounded-md ${
                months === m ? 'bg-gray-900 text-white' : 'bg-white text-gray-600 border border-gray-300'
              }`}>
              {m}m
            </button>
          ))}
          <button onClick={fetchData} className="px-3 py-1.5 text-sm bg-gray-900 text-white rounded-md">
            Refresh
          </button>
        </div>
      </div>

      {!loading && data && (
        <>
          {/* Current Metrics */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
            {[
              { label: 'MRR', value: `$${data.current.mrr.toFixed(2)}`, color: 'text-green-600' },
              { label: 'Active Subs', value: data.current.activeSubscriptions, color: 'text-blue-600' },
              { label: 'Trials', value: data.current.trials, color: 'text-purple-600' },
              { label: 'Premium Users', value: data.current.premiumSubscribers, color: 'text-orange-600' },
            ].map((card) => (
              <div key={card.label} className="bg-white p-4 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-500">{card.label}</p>
                <p className={`text-2xl font-bold ${card.color}`}>{card.value}</p>
              </div>
            ))}
          </div>

          {/* MRR Chart (simple bar) */}
          <div className="bg-white p-4 rounded-lg border border-gray-200 mb-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">MRR Trend</h3>
            <div className="flex items-end gap-1 h-48">
              {data.mrrTrend.map((m) => (
                <div key={m.month} className="flex-1 flex flex-col items-center gap-1">
                  <span className="text-xs text-gray-500">${m.mrr}</span>
                  <div
                    className="w-full bg-green-500 rounded-t"
                    style={{ height: `${(m.mrr / maxMrr) * 100}%`, minHeight: '4px' }}
                  />
                  <span className="text-xs text-gray-400 -rotate-45 origin-center">
                    {m.month.slice(5)}/{m.month.slice(2, 4)}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Churn Table */}
          <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
            <div className="px-4 py-3 border-b border-gray-200">
              <h3 className="text-lg font-semibold text-gray-900">Churn Analysis</h3>
            </div>
            <table className="w-full">
              <thead>
                <tr className="bg-gray-50 text-left text-xs text-gray-500 uppercase">
                  <th className="px-4 py-2">Month</th>
                  <th className="px-4 py-2">MRR</th>
                  <th className="px-4 py-2">Active</th>
                  <th className="px-4 py-2">Trials</th>
                  <th className="px-4 py-2">Cancelled</th>
                  <th className="px-4 py-2">Churn Rate</th>
                </tr>
              </thead>
              <tbody>
                {data.mrrTrend.map((m) => (
                  <tr key={m.month} className="border-t border-gray-100">
                    <td className="px-4 py-3 text-sm text-gray-900">{m.month}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">${m.mrr.toFixed(2)}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{m.activeSubscriptions}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{m.trials}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{m.cancelled}</td>
                    <td className="px-4 py-3 text-sm">
                      <span className={`px-2 py-0.5 rounded-full text-xs ${
                        m.churnRate > 10 ? 'bg-red-100 text-red-800' :
                        m.churnRate > 5 ? 'bg-yellow-100 text-yellow-800' :
                        'bg-green-100 text-green-800'
                      }`}>
                        {m.churnRate.toFixed(1)}%
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </>
      )}

      {loading && <div className="text-center py-8 text-gray-500">Loading...</div>}
    </div>
  );
}
