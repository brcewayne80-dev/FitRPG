'use client';

import { useEffect, useState, useCallback } from 'react';
import { getDTVSave, type DTVSave } from '@/lib/storage';
import { createClient } from '@/lib/supabase/client';
import GameCard from './GameCard';
import GameOverlay from './GameOverlay';
import { useGamepad } from '../hooks/useGamepad';

const DTV_BASE_URL = process.env.NEXT_PUBLIC_DTV_URL ?? 'http://localhost:5173';
const KAETRAM_BASE_URL = process.env.NEXT_PUBLIC_KAETRAM_URL ?? 'http://localhost:9200';

const GAME_COUNT = 3;

export default function GamesGrid() {
  const [dtvSave, setDtvSave] = useState<DTVSave | null | undefined>(undefined);
  const [dtvUrl, setDtvUrl] = useState(DTV_BASE_URL);
  const [kaetramUrl, setKaetramUrl] = useState(KAETRAM_BASE_URL);
  const [token, setToken] = useState<string | null>(null);
  const [focusedIndex, setFocusedIndex] = useState(0);
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  useEffect(() => {
    getDTVSave().then(setDtvSave);

    createClient().auth.getSession().then(({ data: { session } }) => {
      if (session?.access_token) {
        const t = session.access_token;
        setToken(t);
        const encoded = encodeURIComponent(t);
        setDtvUrl(`${DTV_BASE_URL}?token=${encoded}`);
        setKaetramUrl(`${KAETRAM_BASE_URL}?token=${encoded}`);
      }
    });
  }, []);

  const dtvStat =
    dtvSave === undefined
      ? undefined
      : dtvSave === null
      ? 'No save yet'
      : `Best Wave: ${dtvSave.highest_wave_reached}`;

  // url=null means native (Flare)
  const games = [
    {
      name: 'Defend the Valley',
      description: 'Tower defense — hold the line against waves of enemies.',
      stat: dtvStat,
      url: dtvUrl,
    },
    {
      name: 'Kaetram',
      description: '2D MMORPG — explore, fight, and spend your XP in the shop.',
      stat: 'Multiplayer RPG',
      url: kaetramUrl,
    },
    {
      name: 'Flare',
      description: 'Action RPG — battle through a dark fantasy world. XP is your gold.',
      stat: 'Native Game',
      url: null as string | null,
    },
  ];

  const openGame = useCallback(
    async (index: number) => {
      if (games[index].url === null) {
        // Launch Flare via API (fire and forget — overlay handles status polling)
        try {
          await fetch('/api/launch-flare', {
            method: 'POST',
            headers: token ? { Authorization: `Bearer ${token}` } : {},
          });
        } catch {
          // API unavailable on dev Windows — overlay still shown
        }
      }
      setActiveIndex(index);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [dtvUrl, kaetramUrl, token]
  );

  const closeOverlay = useCallback(() => setActiveIndex(null), []);

  // Gamepad navigation
  const onLeft = useCallback(() => setFocusedIndex((i) => Math.max(0, i - 1)), []);
  const onRight = useCallback(() => setFocusedIndex((i) => Math.min(GAME_COUNT - 1, i + 1)), []);
  const onA = useCallback(() => openGame(focusedIndex), [openGame, focusedIndex]);
  useGamepad({ onLeft, onRight, onA });

  // Keyboard fallback for development on Windows
  useEffect(() => {
    function handleKey(e: KeyboardEvent) {
      if (activeIndex !== null) return;
      if (e.key === 'ArrowLeft') setFocusedIndex((i) => Math.max(0, i - 1));
      else if (e.key === 'ArrowRight') setFocusedIndex((i) => Math.min(GAME_COUNT - 1, i + 1));
      else if (e.key === 'Enter') openGame(focusedIndex);
    }
    window.addEventListener('keydown', handleKey);
    return () => window.removeEventListener('keydown', handleKey);
  }, [activeIndex, focusedIndex, openGame]);

  const activeGame = activeIndex !== null ? games[activeIndex] : null;

  return (
    <>
      <div className="flex gap-6 w-full h-full">
        {games.map((game, i) => (
          <div key={game.name} className="flex-1">
            <GameCard
              name={game.name}
              description={game.description}
              stat={game.stat}
              focused={focusedIndex === i}
              onPlay={() => openGame(i)}
            />
          </div>
        ))}
      </div>

      {activeGame && (
        <GameOverlay
          name={activeGame.name}
          url={activeGame.url}
          onClose={closeOverlay}
        />
      )}
    </>
  );
}
