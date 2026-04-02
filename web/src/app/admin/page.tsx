import { getAdminClient } from '@/lib/supabase/server-admin';

export default async function AdminDashboard() {
  const supabase = getAdminClient();

  // Fetch key metrics
  const [{ count: translationCount }, { count: userCount }, { count: phraseCount }] =
    await Promise.all([
      supabase.from('translations').select('*', { count: 'exact', head: true }),
      supabase.from('organization_members').select('*', { count: 'exact', head: true }),
      supabase.from('community_phrases').select('*', { count: 'exact', head: true }),
    ]);

  // API usage in last 24h
  const { count: apiCount } = await supabase
    .from('api_key_usage')
    .select('*', { count: 'exact', head: true })
    .gte('created_at', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString());

  return (
    <div>
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Dashboard</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <MetricCard label="Total Translations" value={translationCount ?? 0} />
        <MetricCard label="Org Members" value={userCount ?? 0} />
        <MetricCard label="Community Phrases" value={phraseCount ?? 0} />
        <MetricCard label="API Calls (24h)" value={apiCount ?? 0} />
      </div>

      <div className="bg-white rounded-lg border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h3>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          <QuickAction href="/admin/users" label="Manage Users" description="Search, filter, ban users" />
          <QuickAction href="/admin/moderation" label="Moderate Content" description="Review flagged phrases" />
          <QuickAction href="/admin/analytics" label="View Analytics" description="Usage trends and charts" />
          <QuickAction href="/admin/audit" label="Audit Log" description="Track all admin actions" />
        </div>
      </div>
    </div>
  );
}

function MetricCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="bg-white rounded-lg border border-gray-200 p-4">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-3xl font-bold text-gray-900 mt-1">{value}</p>
    </div>
  );
}

function QuickAction({ href, label, description }: { href: string; label: string; description: string }) {
  return (
    <a
      href={href}
      className="block p-4 border border-gray-200 rounded-lg hover:border-gray-400 transition-colors"
    >
      <p className="font-medium text-gray-900">{label}</p>
      <p className="text-sm text-gray-500 mt-1">{description}</p>
    </a>
  );
}
