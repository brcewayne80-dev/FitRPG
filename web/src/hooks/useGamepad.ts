'use client';

import { useEffect } from 'react';

const BTN_A = 0;
const BTN_B = 1;
const DPAD_UP = 12;
const DPAD_DOWN = 13;
const DPAD_LEFT = 14;
const DPAD_RIGHT = 15;

interface GamepadOptions {
  onLeft?: () => void;
  onRight?: () => void;
  onUp?: () => void;
  onDown?: () => void;
  onA?: () => void;
  onB?: () => void;
}

export function useGamepad(options: GamepadOptions) {
  useEffect(() => {
    const pressed = new Set<number>();
    let rafId: number;

    const checks: { btn: number; handler?: () => void }[] = [
      { btn: BTN_A, handler: options.onA },
      { btn: BTN_B, handler: options.onB },
      { btn: DPAD_LEFT, handler: options.onLeft },
      { btn: DPAD_RIGHT, handler: options.onRight },
      { btn: DPAD_UP, handler: options.onUp },
      { btn: DPAD_DOWN, handler: options.onDown },
    ];

    function poll() {
      const gamepads = navigator.getGamepads();
      for (const gp of gamepads) {
        if (!gp) continue;
        for (const { btn, handler } of checks) {
          const isPressed = gp.buttons[btn]?.pressed ?? false;
          if (isPressed && !pressed.has(btn)) {
            pressed.add(btn);
            handler?.();
          } else if (!isPressed) {
            pressed.delete(btn);
          }
        }
      }
      rafId = requestAnimationFrame(poll);
    }

    rafId = requestAnimationFrame(poll);
    return () => cancelAnimationFrame(rafId);
  }, [options.onA, options.onB, options.onLeft, options.onRight, options.onUp, options.onDown]);
}
