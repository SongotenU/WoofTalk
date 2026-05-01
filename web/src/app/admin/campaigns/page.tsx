'use client';

import { useState, useEffect } from 'react';

interface Campaign {
  id: string;
  name: string;
  title: string;
  body: string;
  segment_id: string | null;
  status: string;
  sent_at: string | null;
  recipient_count: number;
  success_count: number;
  failure_count: number;
  user_segments?: { name: string };
  created_at: string;
}

interface Segment {
  id: string;
  name: string;
}

export default function AdminCampaignsPage() {
  const [campaigns, setCampaigns] = useState<Campaign[]>([]);
  const [segments, setSegments] = useState<Segment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    name: '',
    title: '',
    body: '',
    segment_id: '',
    status: 'draft',
  });

  const fetchData = async () => {
    setLoading(true);
    try {
      const [campRes, segRes] = await Promise.all([
        fetch('/api/admin/campaigns'),
        fetch('/api/admin/segments'),
      ]);
      if (campRes.ok) {
        const data = await campRes.json();
        setCampaigns(data.campaigns || []);
      }
      if (segRes.ok) {
        const data = await segRes.json();
        setSegments(data.segments || []);
      }
    } catch { /* ignore */ }
    finally { setLoading(false); }
  };

  useEffect(() => { fetchData(); }, []);

  const handleSave = async () => {
    try {
      const res = await fetch('/api/admin/campaigns', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...form,
          segment_id: form.segment_id || null,
        }),
      });
      if (!res.ok) throw new Error('Failed to save');
      setShowForm(false);
      setForm({ name: '', title: '', body: '', segment_id: '', status: 'draft' });
      fetchData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleSend = async (id: string) => {
    if (!confirm('Send this campaign now?')) return;
    try {
      const res = await fetch('/api/admin/campaigns/send', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ campaign_id: id }),
      });
      if (!res.ok) throw new Error('Failed to send');
      alert('Campaign send triggered!');
      fetchData();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const statusColors: Record<string, string> = {
    draft: 'bg-gray-100 text-gray-600',
    scheduled: 'bg-blue-100 text-blue-800',
    sending: 'bg-yellow-100 text-yellow-800',
    sent: 'bg-green-100 text-green-800',
    cancelled: 'bg-red-100 text-red-800',
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">Push Campaigns</h2>
        <button onClick={() => { setForm({ name: '', title: '', body: '', segment_id: '', status: 'draft' }); setShowForm(true); }}
          className="px-4 py-2 text-sm bg-gray-900 text-white rounded-md hover:bg-gray-800">
          + New Campaign
        </button>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold mb-4">New Campaign</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Name</label>
                <input type="text" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Notification Title</label>
                <input type="text" value={form.title} onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Notification Body</label>
                <textarea value={form.body} onChange={(e) => setForm({ ...form, body: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md text-sm" rows={3} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Target Segment (optional)</label>
                <select value={form.segment_id} onChange={(e) => setForm({ ...form, segment_id: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md text-sm">
                  <option value="">All Users</option>
                  {segments.map((s) => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                  ))}
                </select>
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <button onClick={() => setShowForm(false)} className="px-4 py-2 text-sm border border-gray-300 rounded-md">Cancel</button>
              <button onClick={handleSave} className="px-4 py-2 text-sm bg-gray-900 text-white rounded-md">Create</button>
            </div>
          </div>
        </div>
      )}

      {/* Campaigns List */}
      {loading ? (
        <div className="text-center py-8 text-gray-500">Loading...</div>
      ) : (
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-left text-xs text-gray-500 uppercase">
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Message</th>
                <th className="px-4 py-3">Segment</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Results</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {campaigns.map((c) => (
                <tr key={c.id} className="border-t border-gray-100">
                  <td className="px-4 py-3">
                    <p className="text-sm font-medium text-gray-900">{c.name}</p>
                    <p className="text-xs text-gray-400">{c.title}</p>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600 max-w-xs truncate">{c.body}</td>
                  <td className="px-4 py-3 text-sm text-gray-600">
                    {c.user_segments?.name || 'All Users'}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 text-xs rounded-full ${statusColors[c.status] || 'bg-gray-100'}`}>
                      {c.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-500">
                    {c.status === 'sent' && (
                      <span>{c.success_count} sent, {c.failure_count} failed</span>
                    )}
                  </td>
                  <td className="px-4 py-3">
                    {c.status === 'draft' && (
                      <button onClick={() => handleSend(c.id)} className="text-sm text-blue-600">Send</button>
                    )}
                  </td>
                </tr>
              ))}
              {campaigns.length === 0 && (
                <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">No campaigns yet</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
