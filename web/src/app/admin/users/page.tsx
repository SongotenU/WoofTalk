'use client';

import { useState, useEffect } from 'react';

interface OrgMember {
  user_id: string;
  org_id: string;
  role: string;
  status: string;
  joined_at: string;
  organizations?: { name: string; slug: string };
  users?: { email: string; raw_user_meta_data: any };
}

export default function UsersPage() {
  const [members, setMembers] = useState<OrgMember[]>([]);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [page, setPage] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const PAGE_SIZE = 20;

  const [actionTarget, setActionTarget] = useState<{ userId: string; orgId: string } | null>(null);
  const [actionType, setActionType] = useState<'suspend' | 'reactivate' | 'change_role' | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  const handleAction = async (type: string, userId: string, orgId: string) => {
    setActionTarget({ userId, orgId });
    setActionType(type as any);

    if (type === 'suspend' || type === 'reactivate') {
      setActionLoading(true);
      try {
        const res = await fetch('/api/admin/users/role', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            action: type,
            user_id: userId,
            org_id: orgId,
          }),
        });

        if (!res.ok) throw new Error('Failed to update user status');

        // Refresh list
        await fetchMembers();
      } catch (err: any) {
        setError(err.message);
      } finally {
        setActionLoading(false);
      }
      setActionTarget(null);
      setActionType(null);
    }
  };

  const filtered = members.filter((member) => {
    const matchesSearch =
      !search ||
      member.users?.email?.toLowerCase().includes(search.toLowerCase()) ||
      member.organizations?.name?.toLowerCase().includes(search.toLowerCase());
    const matchesRole = roleFilter === 'all' || member.role === roleFilter;
    const matchesStatus = statusFilter === 'all' || member.status === statusFilter;
    return matchesSearch && matchesRole && matchesStatus;
  });

  const totalPages = Math.ceil(filtered.length / PAGE_SIZE);
  const paginated = filtered.slice(page * PAGE_SIZE, (page + 1) * PAGE_SIZE);

  const fetchMembers = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/admin/users/list');
      if (!res.ok) throw new Error('Failed to fetch users');
      const data = await res.json();
      setMembers(data.members || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchMembers();
  }, []);

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Users</h2>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md border border-red-200">
          {error}
        </div>
      )}

      {actionLoading && (
        <div className="mb-4 p-3 bg-blue-50 text-blue-700 rounded-md border border-blue-200">
          Updating user...
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-3 mb-4">
        <input
          type="text"
          placeholder="Search by email or org..."
          value={search}
          onChange={(e) => {
            setSearch(e.target.value);
            setPage(0);
          }}
          className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm placeholder:text-gray-400"
        />
        <select
          value={roleFilter}
          onChange={(e) => {
            setRoleFilter(e.target.value);
            setPage(0);
          }}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm"
        >
          <option value="all">All Roles</option>
          <option value="owner">Owner</option>
          <option value="admin">Admin</option>
          <option value="member">Member</option>
          <option value="viewer">Viewer</option>
        </select>
        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            setPage(0);
          }}
          className="px-3 py-2 border border-gray-300 rounded-md text-sm"
        >
          <option value="all">All Statuses</option>
          <option value="active">Active</option>
          <option value="invited">Invited</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Email</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Organization</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Role</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Status</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Joined</th>
              <th className="text-left px-4 py-3 text-sm font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {paginated.map((member) => (
              <tr key={`${member.user_id}-${member.org_id}`} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-sm text-gray-900 font-mono">
                  {member.users?.email || member.user_id.slice(0, 8)}
                </td>
                <td className="px-4 py-3 text-sm text-gray-600">
                  {member.organizations?.name || '—'}
                </td>
                <td className="px-4 py-3 text-sm">
                  <RoleBadge role={member.role} />
                </td>
                <td className="px-4 py-3 text-sm">
                  <StatusBadge status={member.status} />
                </td>
                <td className="px-4 py-3 text-sm text-gray-500">
                  {new Date(member.joined_at).toLocaleDateString()}
                </td>
                <td className="px-4 py-3 text-sm">
                  <div className="flex gap-2">
                    {member.status === 'active' && (
                      <button
                        onClick={() => handleAction('suspend', member.user_id, member.org_id)}
                        className="text-red-600 hover:text-red-800 text-xs font-medium"
                      >
                        Suspend
                      </button>
                    )}
                    {member.status === 'suspended' && (
                      <button
                        onClick={() => handleAction('reactivate', member.user_id, member.org_id)}
                        className="text-green-600 hover:text-green-800 text-xs font-medium"
                      >
                        Reactivate
                      </button>
                    )}
                    <button
                      onClick={() => handleAction('change_role', member.user_id, member.org_id)}
                      className="text-blue-600 hover:text-blue-800 text-xs font-medium"
                    >
                      Change Role
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {paginated.length === 0 && (
          <div className="text-center py-8 text-gray-500 text-sm">
            No users found
          </div>
        )}
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between mt-4">
          <p className="text-sm text-gray-500">
            Showing {page * PAGE_SIZE + 1}–{Math.min((page + 1) * PAGE_SIZE, filtered.length)} of {filtered.length}
          </p>
          <div className="flex gap-2">
            <button
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              disabled={page === 0}
              className="px-3 py-1 text-sm border border-gray-300 rounded-md disabled:opacity-50 hover:bg-gray-50"
            >
              Previous
            </button>
            <button
              onClick={() => setPage((p) => Math.min(totalPages - 1, p + 1))}
              disabled={page >= totalPages - 1}
              className="px-3 py-1 text-sm border border-gray-300 rounded-md disabled:opacity-50 hover:bg-gray-50"
            >
              Next
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function RoleBadge({ role }: { role: string }) {
  const colors: Record<string, string> = {
    owner: 'bg-purple-100 text-purple-800',
    admin: 'bg-blue-100 text-blue-800',
    member: 'bg-gray-100 text-gray-800',
    viewer: 'bg-gray-100 text-gray-500',
  };
  return (
    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${colors[role] || colors.member}`}>
      {role}
    </span>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    active: 'bg-green-100 text-green-800',
    invited: 'bg-yellow-100 text-yellow-800',
    suspended: 'bg-red-100 text-red-800',
  };
  return (
    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${colors[status] || colors.active}`}>
      {status}
    </span>
  );
}
