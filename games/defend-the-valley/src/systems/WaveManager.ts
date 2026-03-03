import { ENEMIES_PER_WAVE_GROWTH } from '../constants';

export function waveEnemyCount(wave: number): number {
  if (wave <= 5) return wave;
  return Math.max(5, Math.round(5 * Math.pow(ENEMIES_PER_WAVE_GROWTH, wave - 5)));
}

export function hpScale(wave: number): number {
  const growthSteps = Math.max(0, wave - 5);
  return Math.pow(1.08, growthSteps) * 0.55;
}

export function speedScale(wave: number): number {
  const growthSteps = Math.max(0, wave - 5);
  return Math.pow(1.01, growthSteps);
}

export function dmgScale(wave: number): number {
  const growthSteps = Math.max(0, wave - 5);
  return Math.pow(1.03, growthSteps);
}
