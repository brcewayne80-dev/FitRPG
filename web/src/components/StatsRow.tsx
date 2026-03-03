'use client';

import { useEffect, useState } from 'react';
import { getTotalXP, getTodayXP } from '@/lib/storage';

export default function StatsRow() {
  const [totalXP, setTotalXP] = useState<number | null>(null);
  const [todayXP, setTodayXP] = useState<number | null>(null);

  useEffect(() => {
    getTotalXP().then(setTotalXP);
    getTodayXP().then(setTodayXP);
  }, []);

  return (
    <div className="flex gap-8 items-baseline">
      <div className="flex items-baseline gap-2">
        <span className="text-muted text-sm uppercase tracking-wider">Total XP</span>
        {totalXP === null ? (
          <div className="h-7 w-20 bg-border rounded animate-pulse inline-block" />
        ) : (
          <span className="text-accent text-2xl font-extrabold tabular-nums">
            {totalXP.toLocaleString()}
          </span>
        )}
      </div>

      <div className="flex items-baseline gap-2">
        <span className="text-muted text-sm uppercase tracking-wider">Today</span>
        {todayXP === null ? (
          <div className="h-7 w-16 bg-border rounded animate-pulse inline-block" />
        ) : (
          <span className="text-white text-2xl font-extrabold tabular-nums">
            +{todayXP.toLocaleString()}
          </span>
        )}
      </div>
    </div>
  );
}
