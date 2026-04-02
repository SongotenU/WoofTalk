import Link from 'next/link';

const navItems = [
  { href: '/org', label: 'Overview' },
  { href: '/org/members', label: 'Members' },
  { href: '/org/teams', label: 'Teams' },
];

export default function OrgLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b border-gray-200 px-6 py-4">
        <div className="flex items-center justify-between max-w-7xl mx-auto">
          <h1 className="text-xl font-bold text-gray-900">Organization</h1>
          <Link href="/" className="text-sm text-gray-500 hover:text-gray-700">
            ← Back to app
          </Link>
        </div>
      </header>
      <div className="flex max-w-7xl mx-auto">
        <nav className="w-48 min-h-[calc(100vh-64px)] bg-white border-r border-gray-200 p-4">
          <ul className="space-y-1">
            {navItems.map((item) => (
              <li key={item.href}>
                <Link
                  href={item.href}
                  className="block px-3 py-2 text-sm text-gray-600 hover:bg-gray-100 rounded-md"
                >
                  {item.label}
                </Link>
              </li>
            ))}
          </ul>
        </nav>
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  );
}
