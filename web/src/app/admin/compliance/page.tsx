'use client';

import { useState, useEffect } from 'react';

interface ComplianceAction {
  id: string;
  action: string;
  target_type: string;
  target_id: string;
  details: any;
  created_at: string;
}

export default function AdminCompliancePage() {
  const [auditLog, setAuditLog] = useState<ComplianceAction[]>([]);
  const [loading, setLoading] = useState(true);
  const [exportUserId, setExportUserId] = useState('');
  const [deleteUserId, setDeleteUserId] = useState('');
  const [actionStatus, setActionStatus] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  const fetchAuditLog = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/compliance/audit');
      if (!res.ok) throw new Error('Failed');
      const data = await res.json();
      setAuditLog(data.actions || []);
    } catch {
      setAuditLog([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchAuditLog(); }, []);

  const handleExport = async () => {
    if (!exportUserId) return;
    setActionStatus(null);
    try {
      const res = await fetch('/api/admin/compliance/export', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: exportUserId }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Export failed');
      setActionStatus({ type: 'success', message: `Data exported for user ${exportUserId}` });
      setExportUserId('');
      fetchAuditLog();
    } catch (e: any) {
      setActionStatus({ type: 'error', message: e.message });
    }
  };

  const handleDelete = async () => {
    if (!deleteUserId) return;
    if (!confirm(`Are you sure you want to delete all data for user ${deleteUserId}? This cannot be undone.`)) return;
    setActionStatus(null);
    try {
      const res = await fetch('/api/admin/compliance/delete', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: deleteUserId }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Delete failed');
      setActionStatus({ type: 'success', message: `Data deleted for user ${deleteUserId}` });
      setDeleteUserId('');
      fetchAuditLog();
    } catch (e: any) {
      setActionStatus({ type: 'error', message: e.message });
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">GDPR / CCPA Compliance</h2>
        <button onClick={fetchAuditLog} className="px-3 py-1.5 text-sm bg-gray-900 text-white rounded-md">
          Refresh
        </button>
      </div>

      {actionStatus && (
        <div className={`mb-4 p-3 rounded-md text-sm ${actionStatus.type === 'success' ? 'bg-green-50 text-green-800' : 'bg-red-50 text-red-800'}`}>
          {actionStatus.message}
        </div>
      )}

      {/* Export Section */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-gray-200 mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-3">Data Export (Right to Access)</h3>
        <p className="text-sm text-gray-600 mb-3">Export all data for a specific user (organization members, translations, community phrases, API usage, subscriptions).</p>
        <div className="flex gap-2">
          <input
            type="text"
            value={exportUserId}
            onChange={(e) => setExportUserId(e.target.value)}
            placeholder="User ID (UUID)"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm"
          />
          <button onClick={handleExport} className="px-4 py-2 bg-blue-600 text-white text-sm rounded-md hover:bg-blue-700">
            Export Data
          </button>
        </div>
      </div>

      {/* Delete Section */}
      <div className="bg-white p-4 rounded-lg shadow-sm border border-red-200 mb-6">
        <h3 className="text-lg font-semibold text-red-900 mb-3">Data Deletion (Right to be Forgotten)</h3>
        <p className="text-sm text-gray-600 mb-3">Permanently delete all data for a user. This action cannot be undone.</p>
        <div className="flex gap-2">
          <input
            type="text"
            value={deleteUserId}
            onChange={(e) => setDeleteUserId(e.target.value)}
            placeholder="User ID (UUID)"
            className="flex-1 px-3 py-2 border border-red-300 rounded-md text-sm"
          />
          <button onClick={handleDelete} className="px-4 py-2 bg-red-600 text-white text-sm rounded-md hover:bg-red-700">
            Delete Data
          </button>
        </div>
      </div>

      {/* Audit Trail */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200">
        <div className="px-4 py-3 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">Compliance Audit Trail</h3>
        </div>
        {loading ? (
          <div className="p-8 text-center text-gray-500">Loading...</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-gray-50 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  <th className="px-4 py-3">Date</th>
                  <th className="px-4 py-3">Action</th>
                  <th className="px-4 py-3">Target ID</th>
                  <th className="px-4 py-3">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200">
                {auditLog.map((entry) => (
                  <tr key={entry.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-gray-600">{new Date(entry.created_at).toLocaleString()}</td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex px-2 py-1 text-xs rounded-full ${entry.action === 'COMPLIANCE_DELETE' ? 'bg-red-100 text-red-800' : 'bg-blue-100 text-blue-800'}`}>
                        {entry.action}
                      </span>
                    </td>
                    <td className="px-4 py-3 font-mono text-xs text-gray-600">{entry.target_id}</td>
                    <td className="px-4 py-3 text-gray-600 text-xs">{JSON.stringify(entry.details)}</td>
                  </tr>
                ))}
                {auditLog.length === 0 && (
                  <tr><td colSpan={4} className="px-4 py-8 text-center text-gray-400">No compliance actions recorded</td></tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
