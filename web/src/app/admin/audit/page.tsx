'use client';

import { useState, useEffect, useCallback } from 'react';

interface AuditEntry {
  id: string;
  admin_user_id: string;
  action: string;
  target_type: string | null;
  target_id: string | null;
  details: Record<string, unknown>;
  ip_address: string | null;
  created_at: string;
}

export default function AuditLogPage() {
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionFilter, setActionFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const PAGE_SIZE = 50;

  const fetchAuditLog = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ limit: String(PAGE_SIZE), offset: String(page * PAGE_SIZE) });
      if (actionFilter !== 'all') params.set('action', actionFilter);
      const res = await fetch(`/api/admin/audit?${params}`);
      if (!res.ok) throw new Error('Failed to fetch audit log');
      const data = await res.json();
      setEntries(data.entries || []);
    } catch {
      setEntries([]);
    } finally {
      setLoading(false);
    }
  }, [page, actionFilter]);

  useEffect(() => {
    fetchAuditLog();
  }, [fetchAuditLog]);

  const actions = [...new Set(entries.map((e) => e.action))];

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Audit Log</h2>

      {/* Filter */}
      <div className="mb-4">
        <select
          value={actionFilter}
          onChange={(e) => {
            setActionFilter(e.target.value);
            setPage(0);
          }}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm"
        >
          <option value="all">All Actions</option>
          {actions.map((action) => (
            <option key={action} value={action}>
              {action}
            </option>
          ))}
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Timestamp</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Admin</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Action</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Target</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Details</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">IP</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {entries.map((entry) => (
              <tr key={entry.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm text-gray-500 whitespace-nowrap">
                  {new Date(entry.created_at).toLocaleString()}
                </td>
                <td className="px-4 py-3 text-sm font-mono text-gray-600">
                  {entry.admin_user_id?.slice(0, 8) || '—'}
                </td>
                <td className="px-4 py-3 text-sm">
                  <span className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-xs font-medium">
                    {entry.action}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">
                  {entry.target_type ? (
                    <span className="font-mono text-xs">
                      {entry.target_type}#{entry.target_id?.slice(0, 8)}
                    </span>
                  ) : (
                    '—'
                  )}
                </td>
                <td className="px-4 py-3 text-sm text-gray-500 max-w-xs truncate">
                  {entry.details && Object.keys(entry.details).length > 0
                    ? JSON.stringify(entry.details)
                    : '—'}
                </td>
                <td className="px-4 py-3 text-sm font-mono text-gray-500">
                  {entry.ip_address || '—'}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {entries.length === 0 && !loading && (
          <div className="text-center py-12 text-gray-500">No audit entries</div>
        )}
        {loading && (
          <div className="text-center py-12 text-gray-500">Loading audit log...</div>
        )}
      </div>

      {/* Pagination */}
      <div className="flex justify-center mt-4 gap-2">
        <button
          onClick={() => setPage((p) => Math.max(0, p - 1))}
          disabled={page === 0}
          className="px-4 py-2 text-sm border border-gray-300 rounded-md disabled:opacity-50 hover:bg-gray-50"
        >
          Previous
        </button>
        <button
          onClick={() => setPage((p) => p + 1)}
          disabled={entries.length < PAGE_SIZE}
          className="px-4 py-2 text-sm border border-gray-300 rounded-md disabled:opacity-50 hover:bg-gray-50"
        >
          Next
        </button>
      </div>
    </div>
  );
}
