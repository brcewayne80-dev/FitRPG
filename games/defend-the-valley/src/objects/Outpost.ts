import Phaser from 'phaser';
import { OUTPOST_POS, OUTPOST_CONTACT, OUTPOST_MUZZLES, OUTPOST_HP_BASE } from '../constants';

export class Outpost {
  sprite: Phaser.GameObjects.Sprite;
  maxHp: number;
  hp: number;
  alive = false;

  readonly contactX = OUTPOST_CONTACT.x;
  readonly muzzles = OUTPOST_MUZZLES;

  private hpBar: Phaser.GameObjects.Graphics;

  constructor(scene: Phaser.Scene, maxHp = OUTPOST_HP_BASE) {
    this.maxHp = maxHp;
    this.hp = maxHp;

    this.sprite = scene.add.sprite(OUTPOST_POS.x, OUTPOST_POS.y, 'tower2');
    // 128×128 source image, Godot uses scale 2.42188 → ~310px displayed
    this.sprite.setScale(2.42188).setOrigin(0.5, 0.5).setVisible(false);

    this.hpBar = scene.add.graphics();
  }

  show(maxHp: number): void {
    this.maxHp = maxHp;
    this.hp = maxHp;
    this.alive = true;
    this.sprite.setVisible(true);
  }

  hide(): void {
    this.alive = false;
    this.sprite.setVisible(false);
    this.hpBar.clear();
  }

  takeDamage(amount: number): boolean {
    if (!this.alive) return false;
    this.hp = Math.max(0, this.hp - amount);
    return this.hp <= 0;
  }

  healFrom(amount: number): void {
    this.hp = Math.min(this.maxHp, this.hp + amount);
  }

  drawHpBar(): void {
    if (!this.alive) { this.hpBar.clear(); return; }
    const W = 80, H = 8;
    const bx = OUTPOST_CONTACT.x - W / 2;
    const by = OUTPOST_CONTACT.y + 15;
    const pct = Math.max(0, Math.min(1, this.hp / this.maxHp));

    this.hpBar.clear();
    this.hpBar.fillStyle(0x0d0d0d, 0.8);
    this.hpBar.fillRect(bx, by, W, H);
    this.hpBar.fillStyle(0x59a6f8, 0.95);
    this.hpBar.fillRect(bx + 1, by + 1, (W - 2) * pct, H - 2);
    this.hpBar.lineStyle(1, 0xf0f0f0, 0.9);
    this.hpBar.strokeRect(bx, by, W, H);
  }

  destroy(): void {
    this.sprite.destroy();
    this.hpBar.destroy();
  }
}
