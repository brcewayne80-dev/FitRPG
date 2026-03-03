'use client';

interface GameCardProps {
  name: string;
  description: string;
  stat?: string; // undefined = loading skeleton
  focused: boolean;
  onPlay: () => void;
}

export default function GameCard({ name, description, stat, focused, onPlay }: GameCardProps) {
  return (
    <div
      className={[
        'bg-card rounded-2xl p-8 flex flex-col gap-6 border transition-all duration-150 cursor-pointer h-full',
        focused
          ? 'border-accent ring-4 ring-accent ring-offset-2 ring-offset-bg scale-[1.03]'
          : 'border-border',
      ].join(' ')}
      onClick={onPlay}
    >
      <div className="flex flex-col gap-3 flex-1">
        <h3 className="text-white font-extrabold text-3xl leading-tight">{name}</h3>
        <p className="text-muted text-lg leading-relaxed">{description}</p>
      </div>

      <div className="flex items-center min-h-[2rem]">
        {stat === undefined ? (
          <div className="h-6 w-36 bg-border rounded animate-pulse" />
        ) : stat === 'No save yet' ? (
          <span className="text-subtle text-xl">{stat}</span>
        ) : (
          <span className="text-accent text-xl font-semibold">{stat}</span>
        )}
      </div>

      <button
        onClick={(e) => { e.stopPropagation(); onPlay(); }}
        className={[
          'w-full font-bold text-xl py-4 rounded-xl transition-colors duration-150',
          focused
            ? 'bg-accent hover:bg-green-600 active:bg-green-700 text-white'
            : 'bg-border text-muted hover:bg-accent hover:text-white',
        ].join(' ')}
      >
        ▶ Play
      </button>
    </div>
  );
}
