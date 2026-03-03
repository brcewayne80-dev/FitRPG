'use client';

interface StatCardProps {
  label: string;
  value: number | null;    // null = still loading (shows skeleton)
  subtitle?: string;
  valueColor?: string;     // Tailwind text color class, e.g. "text-accent"
}

export default function StatCard({
  label,
  value,
  subtitle,
  valueColor = 'text-white',
}: StatCardProps) {
  return (
    <div className="bg-card rounded-2xl px-5 py-6 flex flex-col gap-1.5">
      <span className="text-muted text-xs font-semibold uppercase tracking-widest">
        {label}
      </span>

      {value === null ? (
        <div className="h-10 w-24 bg-border rounded animate-pulse" />
      ) : (
        <span className={`text-4xl font-extrabold tabular-nums ${valueColor}`}>
          {value.toLocaleString()}
        </span>
      )}

      {subtitle && (
        <span className="text-subtle text-sm">{subtitle}</span>
      )}
    </div>
  );
}
