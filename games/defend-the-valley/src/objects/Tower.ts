import Phaser from 'phaser';
import { ARCHER_MUZZLES, TOWER_CONTACT } from '../constants';

export class Tower {
  sprite: Phaser.GameObjects.Sprite;
  maxHp: number;
  hp: number;

  readonly contactX = TOWER_CONTACT.x;
  readonly muzzles = ARCHER_MUZZLES;

  private hpBar: Phaser.GameObjects.Graphics;
  private scene: Phaser.Scene;

  constructor(scene: Phaser.Scene, maxHp: number) {
    this.scene = scene;
    this.maxHp = maxHp;
    this.hp = maxHp;

    // Godot world (72, 398) + camera offset (+66, +31) = screen (138, 429)
    this.sprite = scene.add.sprite(138, 429, 'tower');
    // 128×128 source, Godot scale 3.54688 → ~454px displayed
    this.sprite.setScale(3.54688).setOrigin(0.5, 0.5);

    this.hpBar = scene.add.graphics();
  }

  takeDamage(amount: number): boolean {
    this.hp = Math.max(0, this.hp - amount);
    return this.hp <= 0;
  }

  healFrom(amount: number): void {
    this.hp = Math.min(this.maxHp, this.hp + amount);
  }

  drawHpBar(): void {
    const W = 100, H = 10;
    // Draw bar just above the tower sprite's top edge
    const topY = this.sprite.y - this.sprite.displayHeight / 2;
    const bx = this.sprite.x - W / 2;
    const by = topY - H - 4;
    const pct = Math.max(0, Math.min(1, this.hp / this.maxHp));

    this.hpBar.clear();
    this.hpBar.fillStyle(0x0d0d0d, 0.8);
    this.hpBar.fillRect(bx, by, W, H);
    this.hpBar.fillStyle(0x42c75a, 0.95);
    this.hpBar.fillRect(bx + 1, by + 1, (W - 2) * pct, H - 2);
    this.hpBar.lineStyle(1, 0xf0f0f0, 0.9);
    this.hpBar.strokeRect(bx, by, W, H);
  }

  destroy(): void {
    this.sprite.destroy();
    this.hpBar.destroy();
  }
}
