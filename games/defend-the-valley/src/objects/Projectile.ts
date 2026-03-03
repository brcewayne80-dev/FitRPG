import Phaser from 'phaser';
import { PROJECTILE_GRAVITY, ARROW_STICK_LIFE, ARROW_MAX_LIFE, FLOOR_Y } from '../constants';
import type { Enemy } from './Enemy';

export class Projectile extends Phaser.GameObjects.Sprite {
  private vx = 0;
  private vy = 0;
  private damage = 0;
  private life = 0;
  private stuck = false;
  private stickTimeLeft = 0;
  private floorY = FLOOR_Y;
  private enemies: Enemy[] = [];

  constructor(scene: Phaser.Scene) {
    super(scene, 0, 0, 'arrow');
    scene.add.existing(this);
    this.setScale(0.7);
  }

  launch(
    x: number, y: number,
    vx: number, vy: number,
    damage: number,
    enemies: Enemy[],
    floorY = FLOOR_Y,
  ): void {
    this.setPosition(x, y);
    this.vx = vx;
    this.vy = vy;
    this.damage = damage;
    this.life = 0;
    this.stuck = false;
    this.stickTimeLeft = 0;
    this.floorY = floorY;
    this.enemies = enemies;
    this.setActive(true).setVisible(true);
    this.setRotation(Math.atan2(vy, vx));
  }

  update(delta: number): void {
    const dt = delta / 1000;

    if (this.stuck) {
      this.stickTimeLeft -= dt;
      if (this.stickTimeLeft <= 0) this.destroy();
      return;
    }

    this.life += dt;
    if (this.life >= ARROW_MAX_LIFE) { this.destroy(); return; }

    this.vy += PROJECTILE_GRAVITY * dt;
    this.x += this.vx * dt;
    this.y += this.vy * dt;
    this.setRotation(Math.atan2(this.vy, this.vx));

    // Check hit against enemies
    for (const e of this.enemies) {
      if (!e.active) continue;
      const dist = Phaser.Math.Distance.Between(this.x, this.y, e.x, e.y);
      if (dist < 40) {
        e.takeDamage(this.damage);
        this.destroy();
        return;
      }
    }

    // Stick in floor
    if (this.y >= this.floorY) {
      this.y = this.floorY;
      this.stuck = true;
      this.stickTimeLeft = ARROW_STICK_LIFE;
    }
  }
}
