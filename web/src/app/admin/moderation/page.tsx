'use client';

import { useState, useEffect, useCallback } from 'react';

interface Phrase {
  id: string;
  text_content: string;
  language: string;
  author_id: string;
  status: 'pending' | 'approved' | 'rejected';
  flag_count: number;
  created_at: string;
}

export default function ModerationPage() {
  const [phrases, setPhrases] = useState<Phrase[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'pending' | 'approved' | 'rejected'>('pending');
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [bulkActionLoading, setBulkActionLoading] = useState(false);

  const fetchPhrases = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/moderation/phrases');
      if (!res.ok) throw new Error('Failed to fetch phrases');
      const data = await res.json();
      setPhrases(data.phrases || []);
    } catch {
      setPhrases([]);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchPhrases();
  }, [fetchPhrases]);

  const filtered =
    filter === 'all' ? phrases : phrases.filter((p) => p.status === filter);

  const toggleSelect = (id: string) => {
    const newSelected = new Set(selected);
    if (newSelected.has(id)) newSelected.delete(id);
    else newSelected.add(id);
    setSelected(newSelected);
  };

  const toggleSelectAll = () => {
    if (selected.size === filtered.length) {
      setSelected(new Set());
    } else {
      setSelected(new Set(filtered.map((p) => p.id)));
    }
  };

  const handleApprove = async (id: string) => {
    await updatePhraseStatus(id, 'approved');
  };

  const handleReject = async (id: string) => {
    await updatePhraseStatus(id, 'rejected');
  };

  const handleTakedown = async (id: string) => {
    await updatePhraseStatus(id, 'rejected');
  };

  const handleBulkAction = async (action: 'approve' | 'reject') => {
    if (selected.size === 0) return;
    setBulkActionLoading(true);
    try {
      const res = await fetch('/api/admin/moderation/bulk', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action,
          ids: Array.from(selected),
        }),
      });
      if (!res.ok) throw new Error('Bulk action failed');
      setSelected(new Set());
      await fetchPhrases();
    } catch (err: any) {
      console.error(err);
    } finally {
      setBulkActionLoading(false);
    }
  };

  const updatePhraseStatus = async (id: string, status: 'approved' | 'rejected') => {
    try {
      const res = await fetch('/api/admin/moderation/update', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, status }),
      });
      if (!res.ok) throw new Error('Failed to update phrase');
      await fetchPhrases();
    } catch (err: any) {
      console.error(err);
    }
  };

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Moderation</h2>

      {/* Filters */}
      <div className="flex gap-2 mb-4">
        {(['all', 'pending', 'approved', 'rejected'] as const).map((f) => (
          <button
            key={f}
            onClick={() => setFilter(f)}
            className={`px-3 py-1.5 text-sm rounded-md ${
              filter === f
                ? 'bg-gray-900 text-white'
                : 'bg-white text-gray-600 border border-gray-300 hover:bg-gray-50'
            }`}
          >
            {f.charAt(0).toUpperCase() + f.slice(1)}
            {f === 'pending' && (
              <span className="ml-1 bg-red-100 text-red-600 px-1.5 py-0.5 text-xs rounded-full">
                {phrases.filter((p) => p.status === 'pending').length}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Bulk Actions */}
      {selected.size > 0 && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded-md flex items-center justify-between">
          <span className="text-sm text-blue-700">{selected.size} selected</span>
          <div className="flex gap-2">
            <button
              onClick={() => handleBulkAction('approve')}
              disabled={bulkActionLoading}
              className="px-3 py-1 text-sm bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-50"
            >
              Approve Selected
            </button>
            <button
              onClick={() => handleBulkAction('reject')}
              disabled={bulkActionLoading}
              className="px-3 py-1 text-sm bg-red-600 text-white rounded-md hover:bg-red-700 disabled:opacity-50"
            >
              Reject Selected
            </button>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-4 py-3 w-10">
                <input
                  type="checkbox"
                  checked={selected.size === filtered.length && filtered.length > 0}
                  onChange={toggleSelectAll}
                />
              </th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Text</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Language</th>
              <th className="text-center px-4 py-3 text-sm font-medium text-gray-500">Flags</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Status</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Created</th>
              <th className="text-right px-4 py-3 text-sm font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map((phrase) => (
              <tr
                key={phrase.id}
                className={`hover:bg-gray-50 ${phrase.flag_count > 2 ? 'bg-red-50/50' : ''}`}
              >
                <td className="px-4 py-3">
                  <input
                    type="checkbox"
                    checked={selected.has(phrase.id)}
                    onChange={() => toggleSelect(phrase.id)}
                  />
                </td>
                <td className="px-4 py-3 text-sm text-gray-900 max-w-md truncate">
                  {phrase.text_content}
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">{phrase.language}</td>
                <td className="px-4 py-3 text-center text-sm">
                  {phrase.flag_count > 0 ? (
                    <span className="bg-red-100 text-red-700 px-2 py-0.5 rounded-full text-xs font-medium">
                      {phrase.flag_count}
                    </span>
                  ) : (
                    <span className="text-gray-400">0</span>
                  )}
                </td>
                <td className="px-4 py-3 text-sm">
                  <span
                    className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                      phrase.status === 'approved'
                        ? 'bg-green-100 text-green-800'
                        : phrase.status === 'rejected'
                          ? 'bg-red-100 text-red-800'
                          : 'bg-yellow-100 text-yellow-800'
                    }`}
                  >
                    {phrase.status}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {new Date(phrase.created_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-sm text-right">
                  <div className="flex gap-2 justify-end">
                    {phrase.status === 'pending' && (
                      <>
                        <button
                          onClick={() => handleApprove(phrase.id)}
                          className="text-green-600 hover:text-green-800 font-medium"
                        >
                          Approve
                        </button>
                        <button
                          onClick={() => handleReject(phrase.id)}
                          className="text-red-600 hover:text-red-800 font-medium"
                        >
                          Reject
                        </button>
                      </>
                    )}
                    {phrase.status === 'approved' && phrase.flag_count > 0 && (
                      <button
                        onClick={() => handleTakedown(phrase.id)}
                        className="text-red-600 hover:text-red-800 font-medium"
                      >
                        Takedown
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && !loading && (
          <div className="text-center py-12 text-gray-500">No phrases to moderate</div>
        )}
        {loading && (
          <div className="text-center py-12 text-gray-500">Loading phrases...</div>
        )}
      </div>
    </div>
  );
}
