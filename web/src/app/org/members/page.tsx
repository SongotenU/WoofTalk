'use client';

import { useState, useEffect, useCallback } from 'react';

interface Member {
  id: string;
  user_id: string;
  role: string;
  status: string;
  joined_at: string;
  email?: string;
}

export default function MembersPage() {
  const [members, setMembers] = useState<Member[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const fetchMembers = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/org/members');
      if (!res.ok) throw new Error('Failed to fetch members');
      const data = await res.json();
      setMembers(data.members || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchMembers();
  }, [fetchMembers]);

  const handleRemoveMember = async (userId: string) => {
    setActionLoading(userId);
    try {
      const res = await fetch(`/api/org/members`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: userId }),
      });
      if (!res.ok) throw new Error('Failed to remove member');
      await fetchMembers();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setActionLoading(null);
    }
  };

  const handleChangeRole = async (userId: string, newRole: string) => {
    setActionLoading(userId);
    try {
      const res = await fetch(`/api/org/members`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: userId, role: newRole }),
      });
      if (!res.ok) throw new Error('Failed to update role');
      await fetchMembers();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setActionLoading(null);
    }
  };

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Members</h2>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md text-sm">{error}</div>
      )}

      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Email</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Role</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Status</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Joined</th>
              <th className="text-right px-4 py-3 text-sm font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {members.map((member) => (
              <tr key={member.user_id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm font-mono text-gray-900">
                  {member.email || member.user_id.slice(0, 8)}
                </td>
                <td className="px-4 py-3 text-sm">
                  {actionLoading === member.user_id ? (
                    <span className="text-gray-400 text-xs">Updating...</span>
                  ) : (
                    <select
                      value={member.role}
                      onChange={(e) => handleChangeRole(member.user_id, e.target.value)}
                      className="px-2 py-0.5 border border-gray-300 rounded text-xs"
                      disabled={member.role === 'owner'}
                    >
                      <option value="owner">Owner</option>
                      <option value="admin">Admin</option>
                      <option value="member">Member</option>
                      <option value="viewer">Viewer</option>
                    </select>
                  )}
                </td>
                <td className="px-4 py-3 text-sm">
                  <span
                    className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                      member.status === 'active'
                        ? 'bg-green-100 text-green-800'
                        : member.status === 'invited'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-red-100 text-red-800'
                    }`}
                  >
                    {member.status}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {new Date(member.joined_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-sm text-right">
                  {member.role !== 'owner' && (
                    <button
                      onClick={() => handleRemoveMember(member.user_id)}
                      disabled={actionLoading === member.user_id}
                      className="text-red-600 hover:text-red-800 font-medium disabled:opacity-50"
                    >
                      Remove
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {members.length === 0 && !loading && (
          <div className="text-center py-12 text-gray-500">No members found</div>
        )}
        {loading && (
          <div className="text-center py-12 text-gray-500">Loading members...</div>
        )}
      </div>
    </div>
  );
}
