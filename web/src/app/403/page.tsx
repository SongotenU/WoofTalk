import Link from 'next/link';

export default function ForbiddenPage() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-4">403</h1>
        <h2 className="text-2xl font-medium text-gray-700 mb-2">Access Forbidden</h2>
        <p className="text-gray-500 max-w-md mb-8">
          You do not have permission to view this page. Only administrators can access the admin area.
        </p>
        <div className="flex gap-4 justify-center">
          <Link
            href="/"
            className="px-5 py-3 bg-indigo-600 text-white rounded-lg font-medium hover:bg-indigo-700"
          >
            Go Home
          </Link>
          <Link
            href="/auth/login"
            className="px-5 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50"
          >
            Sign in as admin
          </Link>
        </div>
      </div>
    </div>
  );
}
