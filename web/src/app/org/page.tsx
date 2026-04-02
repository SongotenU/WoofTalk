'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';

interface Org {
  id: string;
  name: string;
  slug: string;
  plan_type: string;
}

interface Invites {
  id: string;
  email: string;
  role: string;
  status: string;
  created_at: string;
  expires_at: string;
}

export default function OrgOverview() {
  const [org, setOrg] = useState<Org | null>(null);
  const [invites, setInvites] = useState<Invites[]>([]);
  const [creating, setCreating] = useState(false);
  const [inviteLoading, setInviteLoading] = useState(false);
  const [inviteEmail, setInviteEmail] = useState('');
  const [inviteRole, setInviteRole] = useState('member');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [form, setForm] = useState({ name: '', slug: '', plan: 'free' });
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    fetchOrg();
    fetchInvites();
  }, []);

  const fetchOrg = async () => {
    try {
      const res = await fetch('/api/org/me');
      if (res.ok) {
        const data = await res.json();
        setOrg(data.org);
        return;
      }
    } catch {
      //
    }
    setOrg(null);
  };

  const fetchInvites = async () => {
    try {
      const res = await fetch('/api/org/invites');
      if (res.ok) {
        const data = await res.json();
        setInvites(data.invites || []);
      }
    } catch {
      //
    }
  };

  const handleCreateOrg = async (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (!form.name || !form.slug) {
      setFormError('Name and slug are required');
      return;
    }
    setCreating(true);
    try {
      const res = await fetch('/api/org/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      if (!res.ok) throw new Error('Failed to create organization');
      await fetchOrg();
      setForm({ name: '', slug: '', plan: 'free' });
    } catch (err: any) {
      setFormError(err.message);
    } finally {
      setCreating(false);
    }
  };

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setInviteLoading(true);
    setError(null);
    setSuccess(null);
    try {
      const res = await fetch('/api/org/invite', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: inviteEmail, role: inviteRole }),
      });
      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'Failed to send invite');
      }
      setSuccess('Invite sent successfully');
      setInviteEmail('');
      fetchInvites();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setInviteLoading(false);
    }
  };

  if (!org) {
    return (
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-6">Create Organization</h2>
        <div className="bg-white rounded-lg border border-gray-200 p-6 max-w-md">
          {formError && (
            <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md text-sm">{formError}</div>
          )}
          <form onSubmit={handleCreateOrg} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Organization Name*
              </label>
              <input
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="Acme Corp"
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Slug*
              </label>
              <input
                type="text"
                value={form.slug}
                onChange={(e) =>
                  setForm({ ...form, slug: e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, '') })
                }
                placeholder="acme-corp"
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
              />
              <p className="text-xs text-gray-500 mt-1">
                Used in URLs. Only lowercase letters, numbers, and dashes.
              </p>
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Plan Type
              </label>
              <select
                value={form.plan}
                onChange={(e) => setForm({ ...form, plan: e.target.value })}
                className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm"
              >
                <option value="free">Free</option>
                <option value="pro">Pro</option>
                <option value="enterprise">Enterprise</option>
              </select>
            </div>
            <button
              type="submit"
              disabled={creating}
              className="w-full py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 disabled:opacity-50"
            >
              {creating ? 'Creating...' : 'Create Organization'}
            </button>
          </form>
        </div>
      </div>
    );
  }

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">{org.name}</h2>

      {/* Org Card */}
      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <p className="text-sm text-gray-500">Plan</p>
            <p className="text-lg font-semibold text-gray-900 capitalize">{org.plan_type}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Slug</p>
            <p className="text-lg font-mono text-gray-600">{org.slug}</p>
          </div>
          <div>
            <p className="text-sm text-gray-500">Quick Links</p>
            <div className="flex gap-3 mt-1">
              <Link href="/org/members" className="text-sm text-green-600 hover:underline">
                Manage Members
              </Link>
              <Link href="/org/teams" className="text-sm text-green-600 hover:underline">
                Teams
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Invite Members */}
      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Invite Members</h3>
        {error && (
          <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md text-sm">{error}</div>
        )}
        {success && (
          <div className="mb-4 p-3 bg-green-50 text-green-700 rounded-md text-sm">{success}</div>
        )}
        <form onSubmit={handleInvite} className="flex gap-3">
          <input
            type="email"
            value={inviteEmail}
            onChange={(e) => setInviteEmail(e.target.value)}
            placeholder="colleague@company.com"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm"
            required
          />
          <select
            value={inviteRole}
            onChange={(e) => setInviteRole(e.target.value)}
            className="px-3 py-2 border border-gray-300 rounded-md text-sm"
          >
            <option value="admin">Admin</option>
            <option value="member">Member</option>
            <option value="viewer">Viewer</option>
          </select>
          <button
            type="submit"
            disabled={inviteLoading}
            className="px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 disabled:opacity-50"
          >
            {inviteLoading ? 'Sending...' : 'Invite'}
          </button>
        </form>
      </div>

      {/* Pending Invites */}
      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Pending Invites</h3>
        {invites.length === 0 ? (
          <p className="text-sm text-gray-500">No pending invites</p>
        ) : (
          <div className="space-y-2">
            {invites.map((invite) => (
              <div
                key={invite.id}
                className="flex items-center justify-between py-2 px-3 bg-gray-50 rounded-md"
              >
                <div>
                  <p className="text-sm font-medium text-gray-900">{invite.email}</p>
                  <p className="text-xs text-gray-500">Role: {invite.role}</p>
                </div>
                <span
                  className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                    invite.status === 'pending'
                      ? 'bg-yellow-100 text-yellow-800'
                      : invite.status === 'accepted'
                        ? 'bg-green-100 text-green-800'
                        : 'bg-gray-100 text-gray-800'
                  }`}
                >
                  {invite.status}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
