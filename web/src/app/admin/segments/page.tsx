'use client';

import { useState, useEffect } from 'react';

interface Segment {
  id: string;
  name: string;
  description: string;
  filters: { breed?: string; location?: string; min_translations?: number };
  user_count: number;
  created_at: string;
}

export default function AdminSegmentsPage() {
  const [segments, setSegments] = useState<Segment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Segment | null>(null);
  const [form, setForm] = useState({
    name: '',
    description: '',
    filters: { breed: '', location: '', min_translations: '' },
  });

  const fetchSegments = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/segments');
      if (!res.ok) throw new Error('Failed');
      const data = await res.json();
      setSegments(data.segments || []);
    } catch {
      setSegments([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchSegments(); }, []);

  const openCreate = () => {
    setEditing(null);
    setForm({ name: '', description: '', filters: { breed: '', location: '', min_translations: '' } });
    setShowForm(true);
  };

  const openEdit = (seg: Segment) => {
    setEditing(seg);
    setForm({
      name: seg.name,
      description: seg.description || '',
      filters: {
        breed: seg.filters?.breed || '',
        location: seg.filters?.location || '',
        min_translations: seg.filters?.min_translations?.toString() || '',
      },
    });
    setShowForm(true);
  };

  const handleSave = async () => {
    try {
      const filters: any = {};
      if (form.filters.breed) filters.breed = form.filters.breed;
      if (form.filters.location) filters.location = form.filters.location;
      if (form.filters.min_translations) filters.min_translations = parseInt(form.filters.min_translations);

      const res = await fetch('/api/admin/segments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editing ? { id: editing.id, name: form.name, description: form.description, filters } :
          { name: form.name, description: form.description, filters }),
      });
      if (!res.ok) throw new Error('Failed to save');
      setShowForm(false);
      fetchSegments();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this segment?')) return;
    try {
      const res = await fetch(`/api/admin/segments?id=${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Failed');
      fetchSegments();
    } catch (err: any) {
      alert(err.message);
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">User Segmentation</h2>
        <button onClick={openCreate} className="px-4 py-2 text-sm bg-gray-900 text-white rounded-md hover:bg-gray-800">
          + New Segment
        </button>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <h3 className="text-lg font-semibold mb-4">{editing ? 'Edit' : 'New'} Segment</h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">Name</label>
                <input type="text" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">Description</label>
                <textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="mt-1 w-full px-3 py-2 border border-gray-300 rounded-md text-sm" rows={2} />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Filters</label>
                <input type="text" placeholder="Breed (e.g. Labrador)" value={form.filters.breed}
                  onChange={(e) => setForm({ ...form, filters: { ...form.filters, breed: e.target.value } })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm mb-2" />
                <input type="text" placeholder="Location (e.g. CA)" value={form.filters.location}
                  onChange={(e) => setForm({ ...form, filters: { ...form.filters, location: e.target.value } })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm mb-2" />
                <input type="number" placeholder="Min translations (last 30d)" value={form.filters.min_translations}
                  onChange={(e) => setForm({ ...form, filters: { ...form.filters, min_translations: e.target.value } })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md text-sm" />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <button onClick={() => setShowForm(false)} className="px-4 py-2 text-sm border border-gray-300 rounded-md">Cancel</button>
              <button onClick={handleSave} className="px-4 py-2 text-sm bg-gray-900 text-white rounded-md">Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Segments List */}
      {loading ? (
        <div className="text-center py-8 text-gray-500">Loading...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {segments.map((seg) => (
            <div key={seg.id} className="bg-white p-4 rounded-lg border border-gray-200">
              <div className="flex items-start justify-between">
                <div>
                  <h4 className="text-sm font-semibold text-gray-900">{seg.name}</h4>
                  {seg.description && <p className="text-xs text-gray-500 mt-1">{seg.description}</p>}
                </div>
                <div className="flex gap-2">
                  <button onClick={() => openEdit(seg)} className="text-xs text-blue-600">Edit</button>
                  <button onClick={() => handleDelete(seg.id)} className="text-xs text-red-600">Delete</button>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-gray-100">
                <p className="text-xs text-gray-500">Users: <span className="font-medium text-gray-900">{seg.user_count}</span></p>
                {seg.filters && (
                  <div className="mt-1 space-y-0.5">
                    {seg.filters.breed && <p className="text-xs text-gray-400">Breed: {seg.filters.breed}</p>}
                    {seg.filters.location && <p className="text-xs text-gray-400">Location: {seg.filters.location}</p>}
                    {seg.filters.min_translations && <p className="text-xs text-gray-400">Min transl: {seg.filters.min_translations}</p>}
                  </div>
                )}
              </div>
            </div>
          ))}
          {segments.length === 0 && (
            <p className="col-span-full text-center py-8 text-gray-400">No segments yet</p>
          )}
        </div>
      )}
    </div>
  );
}
