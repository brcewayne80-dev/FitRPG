import Phaser from 'phaser';
import {
  FLOOR_Y,
  ENEMY_BASE_SPEED,
  ENEMY_BASE_HP,
  ENEMY_BASE_DAMAGE,
  ENEMY_ATTACK_INTERVAL_SEC,
  ORC_WALK_FRAMES,
  ORC_ATTACK_FRAMES,
  ORC_DIE_FRAMES,
  ORC_ANIM_FPS,
} from '../constants';

export const enum EnemyState { WALK, ATTACK, DIE }

export class Enemy extends Phaser.GameObjects.Sprite {
  state: EnemyState = EnemyState.WALK;
  contactX = 0;
  floorY = FLOOR_Y;
  moveSpeed = 0;
  maxHp = 0;
  hp = 0;
  attackDamage = 0;
  attackTimer = 0;

  private hpBar!: Phaser.GameObjects.Graphics;
  private dead = false;

  // Callbacks set by GameScene
  onAttack?: (enemy: Enemy, damage: number) => void;
  onDied?: (enemy: Enemy) => void;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y, 'orc');
    scene.add.existing(this);

    this.hpBar = scene.add.graphics();
    this.setFlipX(true); // orc faces left (sprite faces right natively)
  }

  configure(
    spawnX: number,
    spawnY: number,
    contactX: number,
    floorYIn: number,
    hpScaleVal: number,
    speedScaleVal: number,
    dmgScaleVal: number,
  ): void {
    this.setPosition(spawnX, spawnY);
    this.contactX = contactX;
    this.floorY = floorYIn;

    this.moveSpeed = ENEMY_BASE_SPEED * speedScaleVal;
    this.maxHp = ENEMY_BASE_HP * hpScaleVal;
    this.hp = this.maxHp;
    this.attackDamage = ENEMY_BASE_DAMAGE * dmgScaleVal;

    this.state = EnemyState.WALK;
    this.attackTimer = 0;
    this.dead = false;
    this.setActive(true).setVisible(true);
    this.hpBar.setVisible(true);

    this.playAnim('orc_walk');
  }

  retargetContact(newContactX: number): void {
    this.contactX = newContactX;
    if (this.state === EnemyState.ATTACK && !this.dead) {
      this.state = EnemyState.WALK;
      this.attackTimer = 0;
      this.playAnim('orc_walk');
    }
  }

  takeDamage(amount: number): void {
    if (this.state === EnemyState.DIE || this.dead) return;
    this.hp -= amount;
    if (this.hp <= 0) this.die();
  }

  update(delta: number): void {
    if (this.dead) return;

    // Keep on floor
    this.y = this.floorY;

    switch (this.state) {
      case EnemyState.WALK:
        this.x -= this.moveSpeed * (delta / 1000);
        if (this.x <= this.contactX) {
          this.state = EnemyState.ATTACK;
          this.attackTimer = 0.15;
          this.playAnim('orc_attack');
        }
        break;

      case EnemyState.ATTACK:
        this.attackTimer -= delta / 1000;
        if (this.attackTimer <= 0) {
          this.attackTimer = ENEMY_ATTACK_INTERVAL_SEC;
          this.onAttack?.(this, this.attackDamage);
        }
        break;

      case EnemyState.DIE:
        break;
    }

    this.drawHpBar();
  }

  private die(): void {
    if (this.dead) return;
    this.dead = true;
    this.state = EnemyState.DIE;
    this.playAnim('orc_die');
    this.onDied?.(this);

    // Remove after die animation completes (4 frames @ 5fps ≈ 800ms + buffer)
    this.scene.time.delayedCall(900, () => {
      this.hpBar.destroy();
      this.destroy();
    });
  }

  private playAnim(key: string): void {
    if (this.anims.currentAnim?.key !== key) {
      this.play(key, true);
    }
  }

  private drawHpBar(): void {
    if (this.dead || this.state === EnemyState.DIE) {
      this.hpBar.clear();
      return;
    }
    const W = 40, H = 6;
    const bx = this.x - W / 2;
    const by = this.y - this.displayHeight * 0.5 - 8;
    const pct = Math.max(0, Math.min(1, this.hp / this.maxHp));

    this.hpBar.clear();
    this.hpBar.fillStyle(0x0d0d0d, 0.8);
    this.hpBar.fillRect(bx, by, W, H);
    this.hpBar.fillStyle(0xe02e2e, 0.95);
    this.hpBar.fillRect(bx + 1, by + 1, (W - 2) * pct, H - 2);
    this.hpBar.strokeRect(bx, by, W, H);
    this.hpBar.lineStyle(1, 0xf0f0f0, 0.9);
    this.hpBar.strokeRect(bx, by, W, H);
  }

  /** Register animations once per scene (call from PreloadScene or GameScene.create) */
  static registerAnims(scene: Phaser.Scene): void {
    if (scene.anims.exists('orc_walk')) return;

    scene.anims.create({
      key: 'orc_walk',
      frames: ORC_WALK_FRAMES.map(f => ({ key: 'orc', frame: f })),
      frameRate: ORC_ANIM_FPS,
      repeat: -1,
    });
    scene.anims.create({
      key: 'orc_attack',
      frames: ORC_ATTACK_FRAMES.map(f => ({ key: 'orc', frame: f })),
      frameRate: ORC_ANIM_FPS,
      repeat: -1,
    });
    scene.anims.create({
      key: 'orc_die',
      frames: ORC_DIE_FRAMES.map(f => ({ key: 'orc', frame: f })),
      frameRate: ORC_ANIM_FPS,
      repeat: 0,
    });
  }
}
