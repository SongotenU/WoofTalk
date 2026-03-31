'use client';

interface SearchFilterBarProps {
  search: string;
  language?: string;
  sort: 'upvotes' | 'newest' | 'trending';
  onSearch: (value: string) => void;
  onFilter: (language?: string) => void;
  onSort: (sort: 'upvotes' | 'newest' | 'trending') => void;
}

export function SearchFilterBar({
  search,
  language,
  sort,
  onSearch,
  onFilter,
  onSort,
}: SearchFilterBarProps) {
  return (
    <div className="flex flex-col sm:flex-row gap-3">
      <div className="flex-1">
        <input
          type="text"
          value={search}
          onChange={(e) => onSearch(e.target.value)}
          placeholder="Search phrases..."
          className="w-full px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-primary"
        />
      </div>

      <div className="flex gap-2">
        {([undefined, 'dog', 'cat', 'bird'] as const).map((lang) => (
          <button
            key={lang || 'all'}
            onClick={() => onFilter(lang)}
            className={`px-3 py-2 rounded-full text-sm capitalize transition-colors ${
              language === lang
                ? 'bg-primary text-primary-foreground'
                : 'bg-secondary text-secondary-foreground hover:bg-secondary/80'
            }`}
          >
            {lang || 'All'}
          </button>
        ))}
      </div>

      <select
        value={sort}
        onChange={(e) => onSort(e.target.value as 'upvotes' | 'newest' | 'trending')}
        className="px-3 py-2 border rounded-lg bg-background focus:outline-none focus:ring-2 focus:ring-primary"
      >
        <option value="upvotes">Most Upvoted</option>
        <option value="newest">Newest</option>
        <option value="trending">Trending</option>
      </select>
    </div>
  );
}
