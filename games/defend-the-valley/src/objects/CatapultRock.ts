import Phaser from 'phaser';
import { FLOOR_Y } from '../constants';
import type { Enemy } from './Enemy';

export class CatapultRock extends Phaser.GameObjects.Sprite {
  private vx = 0;
  private vy = 0;
  private gravity = 1200;
  private life = 0;
  private floorY = FLOOR_Y;
  private aoeRadius = 110;
  private aoeDamage = 30;
  private exploded = false;
  private enemies: Enemy[] = [];
  private explosion!: Phaser.GameObjects.Sprite;

  constructor(scene: Phaser.Scene) {
    super(scene, 0, 0, 'boulder');
    scene.add.existing(this);
    // 16×16 boulder, Godot uses scale 1.0
    this.setScale(1.0);

    this.explosion = scene.add.sprite(0, 0, 'explosion');
    // 256×256 explosion, Godot uses scale 1.0
    this.explosion.setVisible(false).setScale(1.0);

    if (!scene.anims.exists('explosion_play')) {
      scene.anims.create({
        key: 'explosion_play',
        frames: Array.from({ length: 10 }, (_, i) => ({ key: `explosion${i + 1}` })),
        frameRate: 10,
        repeat: 0,
      });
    }
    this.explosion.on(Phaser.Animations.Events.ANIMATION_COMPLETE, () => {
      this.explosion.destroy();
      this.destroy();
    });
  }

  launch(
    x: number, y: number,
    vx: number, vy: number,
    gravity: number,
    floorY: number,
    damage: number,
    radius: number,
    enemies: Enemy[],
  ): void {
    this.setPosition(x, y);
    this.explosion.setPosition(x, y);
    this.vx = vx;
    this.vy = vy;
    this.gravity = gravity;
    this.floorY = floorY;
    this.aoeDamage = damage;
    this.aoeRadius = radius;
    this.enemies = enemies;
    this.life = 0;
    this.exploded = false;
    this.setActive(true).setVisible(true);
    this.setRotation(Math.atan2(vy, vx));
  }

  update(delta: number): void {
    if (this.exploded) return;

    const dt = delta / 1000;
    this.life += dt;
    if (this.life >= 6) { this.explode(); return; }

    this.vy += this.gravity * dt;
    this.x += this.vx * dt;
    this.y += this.vy * dt;
    this.explosion.setPosition(this.x, this.y);
    this.setRotation(Math.atan2(this.vy, this.vx));

    if (this.y >= this.floorY - 2) {
      this.y = this.floorY;
      this.explode();
    }
  }

  private explode(): void {
    if (this.exploded) return;
    this.exploded = true;
    this.setVisible(false);

    this.explosion.setPosition(this.x, this.y);
    this.explosion.setVisible(true).setRotation(0);
    this.explosion.play('explosion_play');

    // AoE damage
    for (const e of this.enemies) {
      if (!e.active) continue;
      const dist = Phaser.Math.Distance.Between(this.x, this.y, e.x, e.y);
      if (dist <= this.aoeRadius) {
        e.takeDamage(this.aoeDamage);
      }
    }
  }
}
