'use client';

import { useState, useEffect } from 'react';

interface CohortData {
  cohorts: Array<{
    signup_month: string;
    cohort_size: number;
    retention: number[];
  }>;
  months: string[];
}

export default function CohortsPage() {
  const [data, setData] = useState<CohortData | null>(null);
  const [loading, setLoading] = useState(true);
  const [months, setMonths] = useState(6);

  const fetchData = async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/admin/cohorts?months=${months}`);
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

  const maxRetention = data ? Math.max(...data.cohorts.flatMap(c => c.retention), 1) : 1;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Cohort Analysis</h2>
        <div className="flex gap-2">
          {[3, 6, 12].map((m) => (
            <button key={m} onClick={() => setMonths(m)}
              className={`px-3 py-1.5 text-sm rounded-md ${months === m ? 'bg-gray-900 text-white' : 'bg-white text-gray-600 border border-gray-300'}`}>
              {m}m
            </button>
          ))}
          <button onClick={fetchData} className="px-3 py-1.5 text-sm bg-gray-900 text-white rounded-md">Refresh</button>
        </div>
      </div>

      {!loading && data && (
        <>
          <p className="text-sm text-gray-600 mb-4">User retention by signup month. Each row shows the percentage of users from a cohort who were still active in subsequent months.</p>

          {/* Cohort Table */}
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase">
                  <th className="px-4 py-3">Signup Month</th>
                  <th className="px-4 py-3">Cohort Size</th>
                  {data.months.map((m, i) => (
                    <th key={m} className="px-4 py-3 text-center">Month {i + 1}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {data.cohorts.map((cohort) => (
                  <tr key={cohort.signup_month} className="hover:bg-gray-50">
                    <td className="px-4 py-3 font-medium text-gray-900">{cohort.signup_month}</td>
                    <td className="px-4 py-3 text-gray-600">{cohort.cohort_size}</td>
                    {cohort.retention.map((r, i) => (
                      <td key={i} className="px-4 py-3 text-center">
                        <div className="flex items-center justify-center gap-2">
                          <div className="w-16 bg-gray-200 rounded-full h-2">
                            <div className="bg-blue-600 h-2 rounded-full" style={{ width: `${Math.max((r / maxRetention) * 100, 2)}%` }} />
                          </div>
                          <span className="text-xs text-gray-600 w-10 text-right">{r}</span>
                        </div>
                      </td>
                    ))}
                  </tr>
                ))}
                {data.cohorts.length === 0 && (
                  <tr><td colSpan={data.months.length + 2} className="px-4 py-8 text-center text-gray-400">No cohort data available</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}
