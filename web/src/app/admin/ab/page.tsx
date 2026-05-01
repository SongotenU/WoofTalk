'use client';

import { useState, useEffect } from 'react';

interface Experiment {
  id: string;
  name: string;
  description: string;
  is_active: boolean;
  variants: Array<{ name: string; weight: number; value?: any }>;
  start_date: string;
  end_date: string;
  created_at: string;
  experiment_assignments: Array<{ count: number }>;
}

export default function AdminABPage() {
  const [experiments, setExperiments] = useState<Experiment[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Experiment | null>(null);
  const [form, setForm] = useState({
    name: '',
    description: '',
    is_active: false,
    variants: [{ name: 'Control', weight: 50 }, { name: 'Variant A', weight: 50 }],
    start_date: '',
    end_date: '',
  });

  const fetchExperiments = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/admin/ab');
      if (!res.ok) throw new Error('Failed');
      const data = await res.json();
      setExperiments(data.experiments || []);
    } catch {
      setExperiments([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchExperiments(); }, []);

  const openCreate = () => {
    setEditing(null);
    setForm({ name: '', description: '', is_active: false, variants: [{ name: 'Control', weight: 50 }, { name: 'Variant A', weight: 50 }], start_date: '', end_date: '' });
    setShowForm(true);
  };

  const openEdit = (exp: Experiment) => {
    setEditing(exp);
    setForm({
      name: exp.name,
      description: exp.description || '',
      is_active: exp.is_active,
      variants: exp.variants || [{ name: 'Control', weight: 50 }, { name: 'Variant A', weight: 50 }],
      start_date: exp.start_date ? exp.start_date.slice(0, 10) : '',
      end_date: exp.end_date ? exp.end_date.slice(0, 10) : '',
    });
    setShowForm(true);
  };

  const handleSave = async () => {
    try {
      const payload: any = { ...form };
      if (form.start_date) payload.start_date = new Date(form.start_date).toISOString();
      if (form.end_date) payload.end_date = new Date(form.end_date).toISOString();

      const res = await fetch('/api/admin/ab', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(editing ? { id: editing.id, ...payload } : payload),
      });
      if (!res.ok) throw new Error('Failed to save');
      setShowForm(false);
      fetchExperiments();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Delete this experiment?')) return;
    try {
      const res = await fetch(`/api/admin/ab?id=${id}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Failed');
      fetchExperiments();
    } catch (err: any) {
      alert(err.message);
    }
  };

  const addVariant = () => {
    setForm({ ...form, variants: [...form.variants, { name: '', weight: 0 }] });
  };

  const updateVariant = (i: number, field: string, value: any) => {
    const v = [...form.variants];
    (v[i] as any)[field] = value;
    setForm({ ...form, variants: v });
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-2xl font-bold text-gray-900">A/B Testing</h2>
        <button onClick={openCreate} className="px-4 py-2 text-sm bg-gray-900 text-white rounded-md hover:bg-gray-800">
          + New Experiment
        </button>
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-lg max-h-[80vh] overflow-y-auto">
            <h3 className="text-lg font-semibold mb-4">{editing ? 'Edit' : 'New'} Experiment</h3>
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
              <div className="flex items-center gap-2">
                <input type="checkbox" checked={form.is_active} onChange={(e) => setForm({ ...form, is_active: e.target.checked })} />
                <label className="text-sm text-gray-700">Active</label>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">Variants</label>
                {form.variants.map((v, i) => (
                  <div key={i} className="flex gap-2 mb-2">
                    <input type="text" placeholder="Name" value={v.name}
                      onChange={(e) => updateVariant(i, 'name', e.target.value)}
                      className="flex-1 px-2 py-1 border border-gray-300 rounded text-sm" />
                    <input type="number" placeholder="Weight" value={v.weight}
                      onChange={(e) => updateVariant(i, 'weight', parseInt(e.target.value) || 0)}
                      className="w-20 px-2 py-1 border border-gray-300 rounded text-sm" />
                    {form.variants.length > 2 && (
                      <button onClick={() => setForm({ ...form, variants: form.variants.filter((_, j) => j !== i) })}
                        className="text-red-500 text-sm">Remove</button>
                    )}
                  </div>
                ))}
                <button onClick={addVariant} className="text-sm text-blue-600">+ Add Variant</button>
              </div>
              <div className="flex gap-2">
                <label className="text-sm text-gray-700">Start Date</label>
                <input type="date" value={form.start_date} onChange={(e) => setForm({ ...form, start_date: e.target.value })}
                  className="px-2 py-1 border border-gray-300 rounded text-sm" />
                <label className="text-sm text-gray-700">End Date</label>
                <input type="date" value={form.end_date} onChange={(e) => setForm({ ...form, end_date: e.target.value })}
                  className="px-2 py-1 border border-gray-300 rounded text-sm" />
              </div>
            </div>
            <div className="flex justify-end gap-2 mt-6">
              <button onClick={() => setShowForm(false)} className="px-4 py-2 text-sm border border-gray-300 rounded-md">Cancel</button>
              <button onClick={handleSave} className="px-4 py-2 text-sm bg-gray-900 text-white rounded-md">Save</button>
            </div>
          </div>
        </div>
      )}

      {/* Experiments List */}
      {loading ? (
        <div className="text-center py-8 text-gray-500">Loading...</div>
      ) : (
        <div className="bg-white rounded-lg border border-gray-200 overflow-hidden">
          <table className="w-full">
            <thead>
              <tr className="bg-gray-50 text-left text-xs text-gray-500 uppercase">
                <th className="px-4 py-3">Name</th>
                <th className="px-4 py-3">Status</th>
                <th className="px-4 py-3">Variants</th>
                <th className="px-4 py-3">Assignments</th>
                <th className="px-4 py-3">Actions</th>
              </tr>
            </thead>
            <tbody>
              {experiments.map((exp) => (
                <tr key={exp.id} className="border-t border-gray-100">
                  <td className="px-4 py-3">
                    <p className="text-sm font-medium text-gray-900">{exp.name}</p>
                    {exp.description && <p className="text-xs text-gray-500">{exp.description}</p>}
                  </td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 text-xs rounded-full ${
                      exp.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'
                    }`}>
                      {exp.is_active ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600">
                    {exp.variants?.map((v) => `${v.name}(${v.weight})`).join(', ')}
                  </td>
                  <td className="px-4 py-3 text-sm text-gray-600">
                    {exp.experiment_assignments?.[0]?.count || 0}
                  </td>
                  <td className="px-4 py-3">
                    <button onClick={() => openEdit(exp)} className="text-sm text-blue-600 mr-3">Edit</button>
                    <button onClick={() => handleDelete(exp.id)} className="text-sm text-red-600">Delete</button>
                  </td>
                </tr>
              ))}
              {experiments.length === 0 && (
                <tr><td colSpan={5} className="px-4 py-8 text-center text-gray-400">No experiments yet</td></tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
