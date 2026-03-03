import Phaser from 'phaser';
import {
  CANVAS_W,
  CANVAS_H,
  FLOOR_Y,
  FLOOR_JITTER_PX,
  WAVE_COUNTDOWN_SEC,
  SPAWN_X_OFFSET,
  SPAWN_INTERVAL_MS,
  ARCHER_DAMAGE_BASE,
  ARCHER_FIRE_RATE_BASE,
  ARROW_X_NUDGE,
  ARCHER_JITTER_DEG,
  TOWER_HP_BASE,
  OUTPOST_HP_BASE,
  CATAPULT_DAMAGE_BASE,
  CATAPULT_FIRE_RATE_BASE,
  CATAPULT_AOE_BASE,
  CATAPULT_GRAVITY,
  CATAPULT_SPEED_MULT,
  CATAPULT_MIN_TARGET_DIST,
  OUTPOST_FIRE_RATE_BASE,
  OUTPOST_DAMAGE_SCALE_BASE,
  OUTPOST_WAVE_HP_SCALE,
  OUTPOST_WAVE_DAMAGE_SCALE,
  PROJECTILE_GRAVITY,
  SPEED_HINT,
  LARGE_ENEMY_START_WAVE,
  LARGE_ENEMY_SPAWN_CHANCE,
  LARGE_ENEMY_SCALE,
  LARGE_ENEMY_HP_MULT,
  SPEED_UP_SCALE,
  DAMAGE_UPGRADE_STEP,
  SPEED_UPGRADE_STEP,
  TOWER_HP_UPGRADE_STEP,
  OUTPOST_HP_UPGRADE_STEP,
  OUTPOST_DAMAGE_UPGRADE_STEP,
  CATAPULT_DAMAGE_UPGRADE_STEP,
  CATAPULT_SPEED_UPGRADE_STEP,
  CATAPULT_AOE_UPGRADE_STEP,
  TOWER_CONTACT,
  OUTPOST_CONTACT,
  ARCHER_MUZZLES,
  OUTPOST_MUZZLES,
  CATAPULT_MUZZLE,
  ballisticVelocity,
  spendXPAsync,
} from '../constants';
import { Enemy } from '../objects/Enemy';
import { Projectile } from '../objects/Projectile';
import { CatapultRock } from '../objects/CatapultRock';
import { Tower } from '../objects/Tower';
import { Outpost } from '../objects/Outpost';
import { Catapult } from '../objects/Catapult';
import { HUD } from '../ui/HUD';
import { UpgradePanel } from '../ui/UpgradePanel';
import {
  loadSave, writeSave, writeUpgrades, setHighestWaveIfGreater,
  type SaveData,
} from '../systems/SaveManager';
import { waveEnemyCount, hpScale, speedScale, dmgScale } from '../systems/WaveManager';

export class GameScene extends Phaser.Scene {
  constructor() { super('GameScene'); }

  // ── Runtime state ──
  private wave = 1;
  private gameOver = false;
  private inUpgradeBreak = false;
  private waitingForNextWave = false;
  private speedUpEnabled = false;

  // ── Spawning ──
  private pendingSpawns = 0;
  private aliveEnemies = 0;
  private spawning = false;
  private spawnTimer?: Phaser.Time.TimerEvent;
  private waveCountdownTimer?: Phaser.Time.TimerEvent;

  // ── Runtime stats (upgradeable) ──
  private archerDamage = ARCHER_DAMAGE_BASE;
  private archerFireRate = ARCHER_FIRE_RATE_BASE;
  private towerMaxHp = TOWER_HP_BASE;
  private towerArcherCount = 1;
  private catapultDamage = CATAPULT_DAMAGE_BASE;
  private catapultFireRate = CATAPULT_FIRE_RATE_BASE;
  private catapultAoe = CATAPULT_AOE_BASE;
  private catapultUnlocked = false;
  private outpostUnlocked = false;
  private outpostArcherCount = 1;
  private outpostDamageScale = OUTPOST_DAMAGE_SCALE_BASE;
  private outpostFireRate = OUTPOST_FIRE_RATE_BASE;
  private outpostMaxHp = OUTPOST_HP_BASE;
  private outpostRuntimeMaxHp = OUTPOST_HP_BASE;
  private outpostRuntimeDmgScale = OUTPOST_DAMAGE_SCALE_BASE;

  // ── Cooldowns ──
  private archerCd = [0, 0, 0];       // seconds remaining per archer
  private outpostArcherCd = [0, 0, 0];
  private catapultCd = 0;

  // ── Game objects ──
  private enemies: Enemy[] = [];
  private projectiles: Projectile[] = [];
  private catapultRocks: CatapultRock[] = [];
  private tower!: Tower;
  private outpost!: Outpost;
  private catapult!: Catapult;
  private hud!: HUD;
  private upgradePanel!: UpgradePanel;

  // ── Save ──
  private save!: SaveData;

  // ─────────────────────────────────────────────────────────────────────────────
  create(): void {
    this.save = loadSave();
    this.resetRuntimeState();
    this.applyUpgradesFromSave();

    // Background — cover-scale to fill 1280×720 canvas (928×793 source).
    if (this.textures.exists('bg')) {
      const bgScale = Math.max(CANVAS_W / 928, CANVAS_H / 793);
      this.add.image(CANVAS_W / 2, CANVAS_H / 2, 'bg').setScale(bgScale);
    }

    // Register enemy animations
    Enemy.registerAnims(this);

    // Build structures
    this.tower   = new Tower(this, this.towerMaxHp);
    this.outpost = new Outpost(this, this.outpostMaxHp);
    this.catapult = new Catapult(this);
    this.catapult.onFired = () => this.fireCatapultRock();

    if (this.outpostUnlocked) {
      this.outpostRuntimeMaxHp = this.calcOutpostMaxHp(this.wave);
      this.outpostRuntimeDmgScale = this.calcOutpostDmgScale(this.wave);
      this.outpost.show(this.outpostRuntimeMaxHp);
    }
    if (this.catapultUnlocked) this.catapult.show();

    // HUD
    this.hud = new HUD(this, {
      onSendWave:   () => this.sendWaveNow(),
      onSpeedToggle: () => this.toggleSpeedUp(),
      onUpgrade:    () => this.openUpgradePanel(),
    });

    // Upgrade panel
    this.upgradePanel = new UpgradePanel(this, {
      onClose:           () => this.closeUpgradePanel(),
      onDamage:          () => this.upgradeAction('archer_power', () => { this.archerDamage += DAMAGE_UPGRADE_STEP; }),
      onSpeed:           () => this.upgradeAction('archer_speed', () => { this.archerFireRate += SPEED_UPGRADE_STEP; }),
      onTowerHp:         () => this.upgradeAction('tower_health', () => {
        this.towerMaxHp += TOWER_HP_UPGRADE_STEP;
        this.tower.maxHp = this.towerMaxHp;
        this.tower.healFrom(TOWER_HP_UPGRADE_STEP);
      }),
      onTowerArcher:     () => this.upgradeAction('tower_archers', () => {
        if (this.towerArcherCount < 3) this.towerArcherCount++;
      }),
      onCatapultUnlock:  () => this.upgradeAction('catapult_unlocked', () => {
        if (!this.catapultUnlocked) {
          this.catapultUnlocked = true;
          this.catapult.show();
        }
      }),
      onCatapultDamage:  () => this.upgradeAction('catapult_power', () => {
        if (this.catapultUnlocked) this.catapultDamage += CATAPULT_DAMAGE_UPGRADE_STEP;
      }),
      onCatapultSpeed:   () => this.upgradeAction('catapult_speed', () => {
        if (this.catapultUnlocked) this.catapultFireRate += CATAPULT_SPEED_UPGRADE_STEP;
      }),
      onCatapultAoe:     () => this.upgradeAction('catapult_aoe', () => {
        if (this.catapultUnlocked) this.catapultAoe += CATAPULT_AOE_UPGRADE_STEP;
      }),
      onOutpostUnlock:   () => this.upgradeAction('outpost_unlocked', () => {
        if (!this.outpost.alive) {
          this.outpostUnlocked = true;
          this.outpostRuntimeMaxHp = this.calcOutpostMaxHp(this.wave);
          this.outpostRuntimeDmgScale = this.calcOutpostDmgScale(this.wave);
          this.outpost.show(this.outpostRuntimeMaxHp);
          this.retargetEnemies(OUTPOST_CONTACT.x);
        }
      }),
      onOutpostArcher:   () => this.upgradeAction('outpost_archers', () => {
        if (this.outpostUnlocked && this.outpostArcherCount < 3) this.outpostArcherCount++;
      }),
      onOutpostDamage:   () => this.upgradeAction('outpost_power', () => {
        if (this.outpostUnlocked) {
          this.outpostDamageScale += OUTPOST_DAMAGE_UPGRADE_STEP;
          this.outpostRuntimeDmgScale = this.outpostDamageScale;
        }
      }),
      onOutpostSpeed:    () => this.upgradeAction('outpost_speed', () => {
        if (this.outpostUnlocked) this.outpostFireRate += SPEED_UPGRADE_STEP;
      }),
      onOutpostHp:       () => this.upgradeAction('outpost_strength', () => {
        if (this.outpostUnlocked) {
          this.outpostMaxHp += OUTPOST_HP_UPGRADE_STEP;
          this.outpostRuntimeMaxHp = this.outpostMaxHp;
          if (this.outpost.alive) {
            this.outpost.maxHp = this.outpostRuntimeMaxHp;
            this.outpost.healFrom(OUTPOST_HP_UPGRADE_STEP);
          }
        }
      }),
    });

    this.updateHpText();
    this.enterWaveSetupState();
  }

  // ─────────────────────────────────────────────────────────────────────────────
  update(_time: number, delta: number): void {
    if (this.gameOver) return;
    if (this.tower.hp <= 0) return;

    const dt = delta / 1000; // seconds

    // Tick archers
    this.tickArchers(dt);
    this.tickCatapult(dt);
    this.tickOutpostArchers(dt);

    // Update all enemies
    for (let i = this.enemies.length - 1; i >= 0; i--) {
      const e = this.enemies[i];
      if (!e.active) { this.enemies.splice(i, 1); continue; }
      e.update(delta);
    }

    // Update projectiles
    for (let i = this.projectiles.length - 1; i >= 0; i--) {
      const p = this.projectiles[i];
      if (!p.active) { this.projectiles.splice(i, 1); continue; }
      p.update(delta);
    }

    // Update catapult rocks
    for (let i = this.catapultRocks.length - 1; i >= 0; i--) {
      const r = this.catapultRocks[i];
      if (!r.active) { this.catapultRocks.splice(i, 1); continue; }
      r.update(delta);
    }

    // Draw HP bars
    this.tower.drawHpBar();
    this.outpost.drawHpBar();

    this.tryAdvanceWave();
    this.updateHpText();
  }

  // ─── Wave management ─────────────────────────────────────────────────────────
  private enterWaveSetupState(statusPrefix = ''): void {
    this.spawning = false;
    this.waitingForNextWave = true;
    this.inUpgradeBreak = true;

    const prefix = statusPrefix || `Prepare for Wave ${this.wave}`;
    this.hud.setStatus(prefix);
    this.hud.setInterwave(true, WAVE_COUNTDOWN_SEC);

    this.waveCountdownTimer?.destroy();
    this.waveCountdownTimer = this.time.delayedCall(
      WAVE_COUNTDOWN_SEC * 1000,
      () => { if (!this.gameOver) this.sendWaveNow(); },
    );
  }

  private sendWaveNow(): void {
    if (!this.inUpgradeBreak || !this.waitingForNextWave || this.gameOver) return;
    this.waitingForNextWave = false;
    this.inUpgradeBreak = false;
    this.closeUpgradePanel();
    this.hud.setInterwave(false, 0);
    this.waveCountdownTimer?.destroy();
    this.startWave();
  }

  private startWave(): void {
    if (this.tower.hp <= 0) return;
    this.aliveEnemies = 0;
    this.hud.setStatus(`Wave ${this.wave}`);
    this.hud.setWave(this.wave);

    this.pendingSpawns = waveEnemyCount(this.wave);
    this.spawning = true;

    this.spawnTimer?.destroy();
    this.spawnTimer = this.time.addEvent({
      delay: SPAWN_INTERVAL_MS,
      callback: this.onSpawnTick,
      callbackScope: this,
      repeat: this.pendingSpawns - 1,
    });
    this.onSpawnTick(); // spawn first immediately
  }

  private onSpawnTick(): void {
    if (!this.spawning || this.pendingSpawns <= 0) return;
    this.spawnEnemy(this.wave);
    this.pendingSpawns--;
    if (this.pendingSpawns <= 0) {
      this.spawning = false;
    }
  }

  private spawnEnemy(w: number): void {
    const contactX = this.getActiveContactX();
    const spawnX   = CANVAS_W + SPAWN_X_OFFSET;
    const jitter   = Phaser.Math.FloatBetween(-FLOOR_JITTER_PX, FLOOR_JITTER_PX);
    const fy       = FLOOR_Y + jitter;

    const hp  = hpScale(w);
    const spd = speedScale(w);
    const dmg = dmgScale(w);

    const enemy = new Enemy(this, spawnX, fy);
    const isLarge = w >= LARGE_ENEMY_START_WAVE && Math.random() <= LARGE_ENEMY_SPAWN_CHANCE;
    const finalHp = isLarge ? hp * LARGE_ENEMY_HP_MULT : hp;
    if (isLarge) enemy.setScale(LARGE_ENEMY_SCALE);

    enemy.configure(spawnX, fy, contactX, fy, finalHp, spd, dmg);
    enemy.onAttack = (e, damage) => this.onEnemyAttack(e, damage);
    enemy.onDied   = (e) => this.onEnemyDied(e);

    this.enemies.push(enemy);
    this.aliveEnemies++;
  }

  private tryAdvanceWave(): void {
    if (this.tower.hp <= 0) return;
    if (this.spawning) return;
    if (this.waitingForNextWave) return;
    if (this.inUpgradeBreak) return;
    if (this.aliveEnemies > 0) return;

    const cleared = this.wave;
    this.wave++;
    setHighestWaveIfGreater(this.save, this.wave);
    this.enterWaveSetupState(`Wave ${cleared} cleared!`);
  }

  // ─── Enemy events ─────────────────────────────────────────────────────────────
  private onEnemyAttack(_enemy: Enemy, damage: number): void {
    if (this.tower.hp <= 0) return;

    if (this.outpost.alive) {
      const destroyed = this.outpost.takeDamage(damage);
      if (destroyed) this.destroyOutpost();
    } else {
      const destroyed = this.tower.takeDamage(damage);
      if (destroyed) this.triggerGameOver();
    }
    this.updateHpText();
  }

  private onEnemyDied(enemy: Enemy): void {
    this.aliveEnemies = Math.max(0, this.aliveEnemies - 1);
    const idx = this.enemies.indexOf(enemy);
    if (idx >= 0) this.enemies.splice(idx, 1);
  }

  // ─── Archer shooting ─────────────────────────────────────────────────────────
  private tickArchers(dt: number): void {
    if (this.archerFireRate <= 0) return;
    const cdTime = 1 / Math.max(0.01, this.archerFireRate);
    const active = Math.min(this.towerArcherCount, 3);

    for (let i = 0; i < active; i++) {
      this.archerCd[i] -= dt;
      if (this.archerCd[i] <= 0) {
        this.archerCd[i] = cdTime;
        this.fireArcFromMuzzle(ARCHER_MUZZLES[i], i, this.archerDamage, 1.0, ARCHER_JITTER_DEG);
      }
    }
  }

  private tickOutpostArchers(dt: number): void {
    if (!this.outpostUnlocked || !this.outpost.alive) return;
    if (this.outpostFireRate <= 0) return;

    const cdTime = 1 / Math.max(0.01, this.outpostFireRate);
    const active = Math.min(this.outpostArcherCount, 3);

    for (let i = 0; i < active; i++) {
      this.outpostArcherCd[i] -= dt;
      if (this.outpostArcherCd[i] <= 0) {
        this.outpostArcherCd[i] = cdTime;
        const muzzle = OUTPOST_MUZZLES[i];
        const damage = this.archerDamage * this.outpostRuntimeDmgScale;
        this.fireArcFromMuzzle(muzzle, i, damage, 0.85, 2.0, true);
      }
    }
  }

  private fireArcFromMuzzle(
    muzzle: { x: number; y: number },
    rank: number,
    damage: number,
    speedMult: number,
    jitterDeg: number,
    fromOutpost = false,
  ): void {
    const start = { x: muzzle.x + ARROW_X_NUDGE, y: muzzle.y };
    const fromX = fromOutpost ? OUTPOST_CONTACT.x : TOWER_CONTACT.x;
    const target = this.findRankedEnemy(fromX, rank);
    if (!target) return;

    let { vx, vy } = ballisticVelocity(start, { x: target.x, y: target.y }, SPEED_HINT * speedMult, PROJECTILE_GRAVITY);

    if (jitterDeg > 0) {
      const jitter = Phaser.Math.DegToRad(Phaser.Math.FloatBetween(-jitterDeg, jitterDeg));
      const cos = Math.cos(jitter), sin = Math.sin(jitter);
      const nvx = vx * cos - vy * sin;
      const nvy = vx * sin + vy * cos;
      vx = nvx; vy = nvy;
    }

    const p = new Projectile(this);
    p.launch(start.x, start.y, vx, vy, damage, this.enemies, FLOOR_Y);
    this.projectiles.push(p);
  }

  private findRankedEnemy(fromX: number, rank: number): Enemy | null {
    const active = this.enemies.filter(e => e.active && e.x >= fromX);
    // Sort by distance from muzzle (ascending)
    active.sort((a, b) => (a.x - fromX) - (b.x - fromX));
    return active[rank] ?? active[0] ?? null;
  }

  // ─── Catapult ─────────────────────────────────────────────────────────────────
  private tickCatapult(dt: number): void {
    if (!this.catapultUnlocked || !this.catapult.alive) return;
    if (this.catapultFireRate <= 0) return;
    if (this.enemies.length === 0) return;

    this.catapultCd -= dt;
    if (this.catapultCd <= 0) {
      this.catapultCd = 1 / Math.max(0.01, this.catapultFireRate);
      this.catapult.fire();
    }
  }

  private fireCatapultRock(): void {
    const muzzle = CATAPULT_MUZZLE;
    const target = this.findCatapultTarget(muzzle.x);
    if (!target) return;

    const aim = { x: target.x, y: FLOOR_Y };
    const { vx, vy } = ballisticVelocity(muzzle, aim, SPEED_HINT * CATAPULT_SPEED_MULT, CATAPULT_GRAVITY);

    const rock = new CatapultRock(this);
    rock.launch(muzzle.x, muzzle.y, vx, vy, CATAPULT_GRAVITY, FLOOR_Y, this.catapultDamage, this.catapultAoe, this.enemies);
    this.catapultRocks.push(rock);
  }

  private findCatapultTarget(fromX: number): Enemy | null {
    const minX = TOWER_CONTACT.x + CATAPULT_MIN_TARGET_DIST;
    const eligible = this.enemies.filter(e => e.active && e.x >= minX && e.x >= fromX);
    if (eligible.length === 0) return null;
    eligible.sort((a, b) => (a.x - fromX) - (b.x - fromX));
    return eligible[0];
  }

  // ─── Outpost / game-over ─────────────────────────────────────────────────────
  private destroyOutpost(): void {
    this.outpost.hide();
    this.retargetEnemies(TOWER_CONTACT.x);
    this.hud.setStatus('Outpost destroyed!');
  }

  private retargetEnemies(newContactX: number): void {
    for (const e of this.enemies) {
      if (e.active) e.retargetContact(newContactX);
    }
  }

  private getActiveContactX(): number {
    if (this.outpost.alive) return OUTPOST_CONTACT.x;
    return TOWER_CONTACT.x;
  }

  private triggerGameOver(): void {
    if (this.gameOver) return;
    this.gameOver = true;
    this.spawning = false;
    this.spawnTimer?.destroy();
    this.waveCountdownTimer?.destroy();

    setHighestWaveIfGreater(this.save, this.wave);
    this.saveUpgrades();

    const { width: W, height: H } = this.scale;

    this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0.65).setDepth(500);

    this.add.text(W / 2, H / 2 - 70, 'GAME OVER', {
      fontFamily: 'monospace', fontSize: '64px', color: '#ff4444',
      stroke: '#000000', strokeThickness: 6,
    }).setOrigin(0.5).setDepth(501);

    this.add.text(W / 2, H / 2 + 0, `Wave Reached: ${this.wave}`, {
      fontFamily: 'monospace', fontSize: '24px', color: '#ffffff',
      stroke: '#000000', strokeThickness: 3,
    }).setOrigin(0.5).setDepth(501);

    const retryBtn = this.add.text(W / 2, H / 2 + 80, '↩  RETRY', {
      fontFamily: 'monospace', fontSize: '28px', color: '#ffffff',
      backgroundColor: '#442222', padding: { x: 28, y: 12 },
      stroke: '#000000', strokeThickness: 3,
    }).setOrigin(0.5).setDepth(501).setInteractive({ useHandCursor: true });

    retryBtn
      .on('pointerover', () => retryBtn.setColor('#ffaaaa'))
      .on('pointerout',  () => retryBtn.setColor('#ffffff'))
      .on('pointerdown', () => this.scene.restart());

    const menuBtn = this.add.text(W / 2, H / 2 + 150, 'Main Menu', {
      fontFamily: 'monospace', fontSize: '18px', color: '#aaaacc',
    }).setOrigin(0.5).setDepth(501).setInteractive({ useHandCursor: true });

    menuBtn
      .on('pointerdown', () => this.scene.start('MenuScene'));
  }

  // ─── Upgrade panel ───────────────────────────────────────────────────────────
  private openUpgradePanel(): void {
    if (!this.inUpgradeBreak || !this.waitingForNextWave || this.gameOver) return;
    this.upgradePanel.setVisible(true);
  }

  private closeUpgradePanel(): void {
    this.upgradePanel.setVisible(false);
  }

  private async upgradeAction(key: string, fn: () => void): Promise<void> {
    const allowed = await spendXPAsync(key);
    if (!allowed) {
      this.hud.setStatus('Not enough XP!');
      this.time.delayedCall(1800, () => this.hud.setStatus(''));
      return;
    }
    fn();
    this.saveUpgrades();
    this.closeUpgradePanel();
  }

  // ─── Speed toggle ─────────────────────────────────────────────────────────────
  private toggleSpeedUp(): void {
    this.speedUpEnabled = !this.speedUpEnabled;
    this.time.timeScale  = this.speedUpEnabled ? SPEED_UP_SCALE : 1;
    this.physics.world.timeScale = 1 / (this.speedUpEnabled ? SPEED_UP_SCALE : 1);
    this.hud.setSpeedUp(this.speedUpEnabled);
  }

  // ─── Outpost scaling ─────────────────────────────────────────────────────────
  private calcOutpostMaxHp(purchaseWave: number): number {
    const w = Math.max(1, purchaseWave);
    const growth = Math.pow(Math.max(1, 1.03), w - 1);
    const mult   = Math.max(1, growth * Math.max(0.1, OUTPOST_WAVE_HP_SCALE));
    return this.outpostMaxHp * mult;
  }

  private calcOutpostDmgScale(purchaseWave: number): number {
    const w = Math.max(1, purchaseWave);
    const growth = Math.pow(Math.max(1, 1.08), w - 1);
    const mult   = Math.max(1, growth * Math.max(0.1, OUTPOST_WAVE_DAMAGE_SCALE));
    return this.outpostDamageScale * mult;
  }

  // ─── HUD helpers ─────────────────────────────────────────────────────────────
  private updateHpText(): void {
    let txt = `Tower: ${Math.ceil(this.tower.hp)}/${this.tower.maxHp}`;
    if (this.outpostUnlocked) {
      if (this.outpost.alive) {
        txt += ` | Outpost: ${Math.ceil(this.outpost.hp)}/${Math.ceil(this.outpost.maxHp)}`;
      } else {
        txt += ' | Outpost: Destroyed';
      }
    }
    this.hud.setHpText(txt);
  }

  // ─── Save helpers ─────────────────────────────────────────────────────────────
  private resetRuntimeState(): void {
    this.wave = 1;
    this.gameOver = false;
    this.inUpgradeBreak = false;
    this.waitingForNextWave = false;
    this.speedUpEnabled = false;
    this.enemies = [];
    this.projectiles = [];
    this.catapultRocks = [];
    this.archerCd = [0, 0, 0];
    this.outpostArcherCd = [0, 0, 0];
    this.catapultCd = 0;
    this.aliveEnemies = 0;
    this.pendingSpawns = 0;
    this.spawning = false;
  }

  private applyUpgradesFromSave(): void {
    const up = this.save.upgrades;
    this.archerDamage       = ARCHER_DAMAGE_BASE    + DAMAGE_UPGRADE_STEP      * up.archer_power;
    this.archerFireRate     = ARCHER_FIRE_RATE_BASE + SPEED_UPGRADE_STEP       * up.archer_speed;
    this.towerMaxHp         = TOWER_HP_BASE         + TOWER_HP_UPGRADE_STEP    * up.tower_health;
    this.towerArcherCount   = Math.min(3, 1 + up.tower_archers);
    this.catapultUnlocked   = up.catapult_unlocked > 0;
    this.catapultDamage     = CATAPULT_DAMAGE_BASE  + CATAPULT_DAMAGE_UPGRADE_STEP * up.catapult_power;
    this.catapultFireRate   = CATAPULT_FIRE_RATE_BASE + CATAPULT_SPEED_UPGRADE_STEP * up.catapult_speed;
    this.catapultAoe        = CATAPULT_AOE_BASE     + CATAPULT_AOE_UPGRADE_STEP    * up.catapult_aoe;
    this.outpostUnlocked    = up.outpost_unlocked > 0;
    this.outpostArcherCount = Math.min(3, 1 + up.outpost_archers);
    this.outpostDamageScale = OUTPOST_DAMAGE_SCALE_BASE + OUTPOST_DAMAGE_UPGRADE_STEP * up.outpost_power;
    this.outpostFireRate    = OUTPOST_FIRE_RATE_BASE    + SPEED_UPGRADE_STEP          * up.outpost_speed;
    this.outpostMaxHp       = OUTPOST_HP_BASE           + OUTPOST_HP_UPGRADE_STEP     * up.outpost_strength;
    this.outpostRuntimeDmgScale = this.outpostDamageScale;
    this.outpostRuntimeMaxHp    = this.outpostMaxHp;
  }

  private upgradeLevel(current: number, base: number, step: number): number {
    if (step <= 0) return 0;
    return Math.max(0, Math.round((current - base) / step));
  }

  private saveUpgrades(): void {
    writeUpgrades(this.save, {
      archer_power:      this.upgradeLevel(this.archerDamage,    ARCHER_DAMAGE_BASE,    DAMAGE_UPGRADE_STEP),
      archer_speed:      this.upgradeLevel(this.archerFireRate,   ARCHER_FIRE_RATE_BASE, SPEED_UPGRADE_STEP),
      tower_health:      this.upgradeLevel(this.towerMaxHp,       TOWER_HP_BASE,         TOWER_HP_UPGRADE_STEP),
      tower_archers:     Math.max(0, this.towerArcherCount - 1),
      catapult_unlocked: this.catapultUnlocked ? 1 : 0,
      catapult_power:    this.upgradeLevel(this.catapultDamage,   CATAPULT_DAMAGE_BASE,  CATAPULT_DAMAGE_UPGRADE_STEP),
      catapult_speed:    this.upgradeLevel(this.catapultFireRate,  CATAPULT_FIRE_RATE_BASE, CATAPULT_SPEED_UPGRADE_STEP),
      catapult_aoe:      this.upgradeLevel(this.catapultAoe,      CATAPULT_AOE_BASE,     CATAPULT_AOE_UPGRADE_STEP),
      outpost_unlocked:  this.outpostUnlocked ? 1 : 0,
      outpost_archers:   Math.max(0, this.outpostArcherCount - 1),
      outpost_power:     this.upgradeLevel(this.outpostDamageScale, OUTPOST_DAMAGE_SCALE_BASE, OUTPOST_DAMAGE_UPGRADE_STEP),
      outpost_speed:     this.upgradeLevel(this.outpostFireRate,   OUTPOST_FIRE_RATE_BASE,   SPEED_UPGRADE_STEP),
      outpost_strength:  this.upgradeLevel(this.outpostMaxHp,      OUTPOST_HP_BASE,          OUTPOST_HP_UPGRADE_STEP),
    });
  }

  // Suppress unused import warnings
  private _unusedRef = { writeSave, CANVAS_W };
}
