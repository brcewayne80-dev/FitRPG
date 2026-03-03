'use client';

import { useEffect, useState, useCallback } from 'react';
import { useGamepad } from '../hooks/useGamepad';

interface GameOverlayProps {
  name: string;
  url: string | null; // null = native (Flare)
  onClose: () => void;
}

export default function GameOverlay({ name, url, onClose }: GameOverlayProps) {
  const [flareRunning, setFlareRunning] = useState(true);

  // Poll Flare status when it's a native game
  useEffect(() => {
    if (url !== null) return;

    const interval = setInterval(async () => {
      try {
        const res = await fetch('/api/launch-flare');
        const data = await res.json();
        if (!data.running) {
          setFlareRunning(false);
          clearInterval(interval);
        }
      } catch {
        // network error — keep polling
      }
    }, 2000);

    return () => clearInterval(interval);
  }, [url]);

  // Close on Escape key
  useEffect(() => {
    if (url === null) return; // can't close native game with keyboard
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [url, onClose]);

  const handleB = useCallback(() => {
    if (url !== null) onClose();
  }, [url, onClose]);

  useGamepad({ onB: handleB });

  return (
    <div className="fixed inset-0 z-50 bg-black flex flex-col">
      {url !== null ? (
        // Browser game — iframe
        <>
          <div className="flex items-center justify-between px-6 py-3 bg-black/80 border-b border-border">
            <span className="text-white font-bold text-lg">{name}</span>
            <button
              onClick={onClose}
              className="text-muted hover:text-white text-sm transition-colors"
            >
              B / Esc — Back to Dashboard
            </button>
          </div>
          <iframe
            src={url}
            className="flex-1 w-full border-0"
            allow="gamepad *"
            title={name}
          />
        </>
      ) : (
        // Native game (Flare)
        <div className="flex-1 flex flex-col items-center justify-center gap-8">
          {flareRunning ? (
            <>
              <div className="w-16 h-16 border-4 border-accent border-t-transparent rounded-full animate-spin" />
              <p className="text-white text-2xl font-bold">{name} is running…</p>
              <p className="text-muted text-lg">Close the game window to return here.</p>
            </>
          ) : (
            <>
              <p className="text-accent text-2xl font-bold">Session complete!</p>
              <button
                onClick={onClose}
                className="bg-accent hover:bg-green-600 text-white font-bold py-4 px-12 rounded-xl text-xl transition-colors"
              >
                Return to Dashboard
              </button>
            </>
          )}
        </div>
      )}
    </div>
  );
}
