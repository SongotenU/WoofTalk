'use client';

import { useState, useEffect } from 'react';

interface Team {
  id: string;
  name: string;
  org_id: string;
  created_at: string;
  member_count: number;
}

export default function TeamsPage() {
  const [teams, setTeams] = useState<Team[]>([]);
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);
  const [newTeamName, setNewTeamName] = useState('');
  const [error, setError] = useState<string | null>(null);

  const fetchTeams = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/org/teams');
      if (!res.ok) throw new Error('Failed to fetch teams');
      const data = await res.json();
      setTeams(data.teams || []);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTeams();
  }, []);

  const handleCreateTeam = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTeamName.trim()) return;
    setCreating(true);
    setError(null);
    try {
      const res = await fetch('/api/org/teams', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name: newTeamName }),
      });
      if (!res.ok) throw new Error('Failed to create team');
      setNewTeamName('');
      await fetchTeams();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setCreating(false);
    }
  };

  const handleDeleteTeam = async (id: string) => {
    try {
      const res = await fetch(`/api/org/teams/${id}`, {
        method: 'DELETE',
      });
      if (!res.ok) throw new Error('Failed to delete team');
      await fetchTeams();
    } catch (err: any) {
      setError(err.message);
    }
  };

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Teams</h2>

      {error && (
        <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-md text-sm">{error}</div>
      )}

      {/* Create Team */}
      <div className="bg-white rounded-lg border border-gray-200 p-6 mb-6">
        <form onSubmit={handleCreateTeam} className="flex gap-3">
          <input
            type="text"
            value={newTeamName}
            onChange={(e) => setNewTeamName(e.target.value)}
            placeholder="Team name"
            className="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm"
          />
          <button
            type="submit"
            disabled={creating}
            className="px-4 py-2 bg-green-600 text-white rounded-md text-sm font-medium hover:bg-green-700 disabled:opacity-50"
          >
            {creating ? 'Creating...' : 'Create Team'}
          </button>
        </form>
      </div>

      {/* Team List */}
      <div className="space-y-3">
        {teams.map((team) => (
          <div
            key={team.id}
            className="bg-white rounded-lg border border-gray-200 p-4 flex items-center justify-between"
          >
            <div>
              <p className="font-medium text-gray-900">{team.name}</p>
              <p className="text-sm text-gray-500">{team.member_count ?? 0} members</p>
            </div>
            <button
              onClick={() => handleDeleteTeam(team.id)}
              className="text-sm text-red-600 hover:text-red-800"
            >
              Delete
            </button>
          </div>
        ))}
      </div>

      {teams.length === 0 && !loading && (
        <div className="text-center py-12 text-gray-500">No teams yet. Create one above.</div>
      )}
      {loading && (
        <div className="text-center py-12 text-gray-500">Loading teams...</div>
      )}
    </div>
  );
}
