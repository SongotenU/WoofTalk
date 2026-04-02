"use client";

import { useState } from "react";

// ======================== MOCK DATA ========================

const mockMetrics = {
  totalTranslations: 12847,
  totalUsers: 3421,
  activeApiKeys: 28,
  apiCallsToday: 1563,
};

const mockTranslationsByDay = [
  { day: "Mon", count: 240 },
  { day: "Tue", count: 312 },
  { day: "Wed", count: 198 },
  { day: "Thu", count: 421 },
  { day: "Fri", count: 387 },
  { day: "Sat", count: 156 },
  { day: "Sun", count: 134 },
];

const mockUsers = [
  { id: "1a2b3c", email: "alice@acme.com", org: "Acme Corp", role: "owner", status: "active", joined: "2026-01-15" },
  { id: "2c3d4e", email: "bob@acme.com", org: "Acme Corp", role: "admin", status: "active", joined: "2026-02-01" },
  { id: "3e4f5a", email: "carol@woofco.io", org: "WoofCo", role: "owner", status: "active", joined: "2026-01-20" },
  { id: "4a5b6c", email: "dave@woofco.io", org: "WoofCo", role: "member", status: "invited", joined: "2026-03-10" },
  { id: "5b6c7d", email: "eve@barknet.com", org: "BarkNet", role: "viewer", status: "suspended", joined: "2026-02-28" },
  { id: "6c7d8e", email: "frank@acme.com", org: "Acme Corp", role: "member", status: "active", joined: "2026-03-05" },
];

const mockPhrases = [
  { id: "p1", text: "Good boy!", language: "Dog", status: "approved", flags: 0, created: "2026-03-01" },
  { id: "p2", text: "Sit down now", language: "Dog", status: "pending", flags: 3, created: "2026-03-28" },
  { id: "p3", text: "Let's go for a walk", language: "Dog", status: "approved", flags: 0, created: "2026-03-15" },
  { id: "p4", text: "I love you puppy", language: "Dog", status: "pending", flags: 0, created: "2026-03-30" },
  { id: "p5", text: "No barking at night", language: "Dog", status: "rejected", flags: 7, created: "2026-03-20" },
];

const mockApiKeys = [
  { id: "k1", name: "Acme Production", scope: "translate:full" as const, rateLimit: 100, calls: 8234, revoked: false, created: "2026-01-20" },
  { id: "k2", name: "ACME Staging", scope: "translate:write" as const, rateLimit: 30, calls: 412, revoked: false, created: "2026-02-15" },
  { id: "k3", name: "WoofCo Translator", scope: "translate:read" as const, rateLimit: 60, calls: 3102, revoked: false, created: "2026-02-01" },
  { id: "k4", name: "Revoked Test Key", scope: "translate:full" as const, rateLimit: 60, calls: 89, revoked: true, created: "2026-03-01" },
];

const mockAuditLog = [
  { id: "a1", admin: "a1b2c3", action: "USER_SUSPEND", targetType: "user", target: "eve@barknet.com", details: "Spam detection", time: "2026-04-01 14:32", ip: "192.168.1.42" },
  { id: "a2", admin: "a1b2c3", action: "CONTENT_APPROVE", targetType: "phrase", target: "p1 Good boy!", details: "Clean content", time: "2026-04-01 12:15", ip: "192.168.1.42" },
  { id: "a3", admin: "d4e5f6", action: "API_KEY_REVOKE", targetType: "api_key", target: "k4", details: "Compromised key", time: "2026-04-01 09:00", ip: "10.0.0.5" },
  { id: "a4", admin: "a1b2c3", action: "BULK_APPROVE", targetType: "phrase", target: "12 phrases", details: "Batch moderation", time: "2026-03-31 16:45", ip: "192.168.1.42" },
  { id: "a5", admin: "d4e5f6", action: "ORG_CREATE", targetType: "org", target: "BarkNet", details: "New org", time: "2026-03-30 11:00", ip: "10.0.0.5" },
];

const mockOrgs = [
  { id: "o1", name: "Acme Corp", slug: "acme-corp", plan: "pro", members: 3, apiKeys: 2 },
  { id: "o2", name: "WoofCo", slug: "woofco-io", plan: "free", members: 2, apiKeys: 1 },
  { id: "o3", name: "BarkNet", slug: "barknet", plan: "enterprise", members: 1, apiKeys: 0 },
];

const translationsSample = [
  { direction: "Dog", human: "Woof! Woof woof!", meaning: "I want treats now!" },
  { direction: "Human", dog: "I'm going outside for a bit", dogMeaning: "*tail wagging* *sniff sniff* *zoomies*" },
  { direction: "Dog", human: "rrrrrfff awooooo", meaning: "Stranger at the door!" },
];

// ======================== COMPONENTS ========================

function Card({ children, className }: { children: React.ReactNode; className?: string }) {
  return <div className={`bg-white rounded-xl border border-gray-200 p-6 shadow-sm ${className}`}>{children}</div>;
}

function Badge({ text, color }: { text: string; color: string }) {
  const colors: Record<string, string> = {
    green: "bg-green-100 text-green-700",
    red: "bg-red-100 text-red-700",
    yellow: "bg-yellow-100 text-yellow-700",
    blue: "bg-blue-100 text-blue-700",
    purple: "bg-purple-100 text-purple-700",
    gray: "bg-gray-100 text-gray-700",
  };
  return <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${colors[color] || colors.gray}`}>{text}</span>;
}

function Metric({ label, value, accent }: { label: string; value: string | number; accent: string }) {
  return (
    <Card className="text-center">
      <p className="text-4xl font-bold text-gray-900">{typeof value === "number" ? value.toLocaleString() : value}</p>
      <p className="text-sm text-gray-500 mt-1">{label}</p>
    </Card>
  );
}

// ======================== TAB PANELS ========================

function DashboardTab() {
  const maxCount = Math.max(...mockTranslationsByDay.map((d) => d.count));
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Metric label="Total Translations" value={mockMetrics.totalTranslations} accent="green" />
        <Metric label="Active Users" value={mockMetrics.totalUsers} accent="blue" />
        <Metric label="Active API Keys" value={mockMetrics.activeApiKeys} accent="purple" />
        <Metric label="API Calls Today" value={mockMetrics.apiCallsToday} accent="yellow" />
      </div>

      <Card>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Translations This Week</h3>
        <div className="flex items-end gap-3 h-48">
          {mockTranslationsByDay.map((d) => (
            <div
              key={d.day}
              className="flex-1 bg-emerald-400 rounded-t-lg hover:bg-emerald-500 transition-colors relative group cursor-pointer"
              style={{ height: `${(d.count / maxCount) * 100}%` }}
              title={`${d.count} translations`}
            >
              <div className="absolute -top-8 left-1/2 -translate-x-1/2 bg-gray-900 text-white text-xs rounded px-2 py-1 opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
                {d.count}
              </div>
            </div>
          ))}
        </div>
        <div className="flex justify-between mt-2">
          {mockTranslationsByDay.map((d) => (
            <span key={d.day} className="text-xs text-gray-400 w-full text-center">
              {d.day}
            </span>
          ))}
        </div>
      </Card>

      <Card>
        <h3 className="text-lg font-semibold text-gray-900 mb-3">Quick Translate Demo</h3>
        <div className="space-y-3">
          {translationsSample.map((t, i) => (
            <div key={i} className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
              <span className="text-xs font-bold text-emerald-600 bg-emerald-100 px-2 py-0.5 rounded shrink-0">{t.direction}</span>
              <div>
                <p className="text-sm font-medium text-gray-900">
                  {t.direction === "Dog" ? `🐕 "${t.human}"` : `🧑 "${t.dog}"`}
                </p>
                <p className="text-sm text-gray-500">
                  {t.direction === "Dog" ? `→ "${t.meaning}"` : `→ "${t.dogMeaning}"`}
                </p>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function UsersTab() {
  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">Organization Members</h3>
        <Badge text={`${mockUsers.length} users`} color="blue" />
      </div>
      <div className="overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-200 text-gray-500">
              <th className="text-left py-3 px-2">Email</th>
              <th className="text-left py-3 px-2">Organization</th>
              <th className="text-left py-3 px-2">Role</th>
              <th className="text-left py-3 px-2">Status</th>
              <th className="text-left py-3 px-2">Joined</th>
            </tr>
          </thead>
          <tbody>
            {mockUsers.map((u) => (
              <tr key={u.id} className="border-b border-gray-100 hover:bg-gray-50">
                <td className="py-2.5 px-2 font-mono text-xs">{u.email}</td>
                <td className="py-2.5 px-2 text-gray-600">{u.org}</td>
                <td className="py-2.5 px-2">
                  <Badge
                    text={u.role}
                    color={u.role === "owner" ? "purple" : u.role === "admin" ? "blue" : u.role === "member" ? "gray" : "gray"}
                  />
                </td>
                <td className="py-2.5 px-2">
                  <Badge
                    text={u.status}
                    color={u.status === "active" ? "green" : u.status === "invited" ? "yellow" : "red"}
                  />
                </td>
                <td className="py-2.5 px-2 text-gray-500">{u.joined}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </Card>
  );
}

function ModerationTab() {
  return (
    <Card>
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">Content Moderation Queue</h3>
        <Badge text={`${mockPhrases.filter((p) => p.status === "pending").length} pending`} color="yellow" />
      </div>
      <div className="space-y-3">
        {mockPhrases.map((p) => (
          <div key={p.id} className={`p-3 rounded-lg border ${p.flags > 3 ? "bg-red-50 border-red-200" : "bg-gray-50 border-gray-200"}`}>
            <div className="flex items-start justify-between">
              <div>
                <p className="font-medium text-gray-900">{p.text}</p>
                <p className="text-xs text-gray-500 mt-1">{p.language} · {p.created}</p>
              </div>
              <div className="flex items-center gap-2">
                {p.flags > 0 && <Badge text={`${p.flags} flags`} color={p.flags > 3 ? "red" : "yellow"} />}
                <Badge
                  text={p.status}
                  color={p.status === "approved" ? "green" : p.status === "pending" ? "yellow" : "red"}
                />
              </div>
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}

function ApiTab() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Metric label="Active Keys" value={mockApiKeys.filter((k) => !k.revoked).length} accent="green" />
        <Metric label="Total API Calls" value={mockApiKeys.reduce((s, k) => s + k.calls, 0)} accent="blue" />
        <Metric label="Revoked Keys" value={mockApiKeys.filter((k) => k.revoked).length} accent="red" />
      </div>

      <Card>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">API Keys</h3>
        <div className="space-y-3">
          {mockApiKeys.map((k) => (
            <div key={k.id} className={`p-3 rounded-lg border ${k.revoked ? "bg-red-50 border-red-200 opacity-60" : "bg-gray-50 border-gray-200"}`}>
              <div className="flex items-center justify-between">
                <div>
                  <p className="font-medium text-gray-900">{k.name}</p>
                  <div className="flex items-center gap-3 mt-1">
                    <code className="text-xs text-gray-400">
                      wt_live_{k.id}xxxxxxxxxxxxxxxx
                    </code>
                    <Badge text={k.scope} color="blue" />
                    <span className="text-xs text-gray-500">{k.rateLimit} req/min</span>
                  </div>
                </div>
                <div className="text-right">
                  <p className="text-2xl font-bold text-gray-900">{k.calls.toLocaleString()}</p>
                  <p className="text-xs text-gray-500">calls</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </Card>

      <Card>
        <h3 className="text-lg font-semibold text-gray-900 mb-3">API Response Example</h3>
        <pre className="bg-gray-900 text-green-400 text-sm p-4 rounded-lg overflow-x-auto">
{`POST https://wooftalk.supabase.co/functions/v1/api-gateway/v1/translate
Authorization: Bearer wt_live_abc1234567890def

Request:
{
  "source_language": "human",
  "target_language": "dog",
  "text": "Good boy, sit down!"
}

Response (200):
{
  "data": {
    "human_text": "Good boy, sit down!",
    "animal_text": "woof woof ruff!",
    "source_language": "human",
    "target_language": "dog",
    "confidence": 0.87,
    "created_at": "2026-04-02T10:30:00.000Z"
  }
}`}
        </pre>
      </Card>
    </div>
  );
}

function AuditTab() {
  return (
    <Card>
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Admin Audit Log</h3>
      <div className="space-y-2">
        {mockAuditLog.map((entry) => (
          <div key={entry.id} className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg text-sm">
            <div className="w-2 h-2 rounded-full bg-emerald-400 mt-1.5 shrink-0" />
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <Badge text={entry.action} color="blue" />
                <span className="text-gray-900 font-medium">{entry.targetType} · {entry.target}</span>
              </div>
              <p className="text-gray-500 text-xs mt-1">
                {entry.time} · {entry.ip} · {entry.details}
              </p>
            </div>
          </div>
        ))}
      </div>
    </Card>
  );
}

function OrgsTab() {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Metric label="Organizations" value={mockOrgs.length} accent="blue" />
        <Metric label="Total Members" value={mockOrgs.reduce((s, o) => s + o.members, 0)} accent="green" />
        <Metric label="API Keys" value={mockOrgs.reduce((s, o) => s + o.apiKeys, 0)} accent="purple" />
      </div>

      <div className="space-y-3">
        {mockOrgs.map((o) => (
          <Card key={o.id}>
            <div className="flex items-start justify-between">
              <div>
                <h4 className="text-lg font-semibold text-gray-900">{o.name}</h4>
                <code className="text-sm text-gray-500">/{o.slug}</code>
                <div className="flex items-center gap-3 mt-2">
                  <Badge
                    text={o.plan}
                    color={o.plan === "enterprise" ? "purple" : o.plan === "pro" ? "blue" : "gray"}
                  />
                  <span className="text-sm text-gray-500">{o.members} members</span>
                  <span className="text-sm text-gray-500">{o.apiKeys} API keys</span>
                </div>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ======================== MAIN PAGE ========================

const tabs = [
  { id: "dashboard", label: "Dashboard" },
  { id: "users", label: "Users" },
  { id: "moderation", label: "Moderation" },
  { id: "api", label: "API Keys" },
  { id: "audit", label: "Audit Log" },
  { id: "orgs", label: "Organizations" },
];

export default function DemoPage() {
  const [activeTab, setActiveTab] = useState("dashboard");

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top Banner */}
      <div className="bg-gradient-to-r from-emerald-600 to-teal-600 text-white px-6 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="flex items-center gap-3 mb-2">
            <h1 className="text-2xl font-bold">WoofTalk v4.0 Enterprise Demo</h1>
            <span className="bg-white/20 text-white text-xs px-2 py-0.5 rounded-full">MOCK DATA</span>
          </div>
          <p className="text-emerald-100 text-sm">
            Interactive preview of the admin dashboard, API gateway, and org management — all data is simulated.
          </p>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="bg-white border-b border-gray-200 sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-6">
          <div className="flex gap-1 overflow-x-auto scrollbar-hide -mb-px">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-4 py-3 text-sm font-medium border-b-2 whitespace-nowrap transition-colors ${
                  activeTab === tab.id
                    ? "border-emerald-500 text-emerald-600"
                    : "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-6xl mx-auto px-6 py-6">
        {activeTab === "dashboard" && <DashboardTab />}
        {activeTab === "users" && <UsersTab />}
        {activeTab === "moderation" && <ModerationTab />}
        {activeTab === "api" && <ApiTab />}
        {activeTab === "audit" && <AuditTab />}
        {activeTab === "orgs" && <OrgsTab />}
      </div>
    </div>
  );
}
