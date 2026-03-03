import GamesGrid from '@/components/GamesGrid';
import StatsRow from '@/components/StatsRow';

export default function DashboardPage() {
  return (
    <main className="h-screen flex flex-col overflow-hidden bg-bg">
      <header className="flex items-center justify-between px-12 py-6 border-b border-border shrink-0">
        <h1 className="text-white text-3xl font-black tracking-tight">FitRPG</h1>
        <StatsRow />
      </header>

      <div className="flex-1 flex items-stretch px-12 py-8 min-h-0">
        <GamesGrid />
      </div>

      <footer className="text-center text-muted text-sm pb-5 shrink-0">
        ← → Navigate &nbsp;•&nbsp; <span className="text-accent font-bold">A</span> Play &nbsp;•&nbsp; <span className="text-accent font-bold">B</span> Back
      </footer>
    </main>
  );
}
