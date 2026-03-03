import Phaser from 'phaser';
import { loadSave } from '../systems/SaveManager';

export class MenuScene extends Phaser.Scene {
  constructor() { super('MenuScene'); }

  create(): void {
    const { width: W, height: H } = this.scale;
    const save = loadSave();

    // Background — cover-scale to fill 1280×720 canvas (928×793 source).
    if (this.textures.exists('bg')) {
      const bgScale = Math.max(W / 928, H / 793);
      this.add.image(W / 2, H / 2, 'bg').setScale(bgScale);
    } else {
      this.add.rectangle(0, 0, W, H, 0x0a0a14).setOrigin(0);
    }

    // Dark overlay
    this.add.rectangle(W / 2, H / 2, W, H, 0x000000, 0.5);

    // Title
    this.add.text(W / 2, H / 2 - 140, 'DEFEND THE VALLEY', {
      fontFamily: 'monospace',
      fontSize: '48px',
      color: '#ffffcc',
      stroke: '#000000',
      strokeThickness: 6,
    }).setOrigin(0.5);

    // Subtitle / tagline
    this.add.text(W / 2, H / 2 - 88, 'Tower Defense', {
      fontFamily: 'monospace',
      fontSize: '20px',
      color: '#aaaacc',
    }).setOrigin(0.5);

    // Best wave
    this.add.text(W / 2, H / 2 - 30, `Best Wave: ${save.highest_wave_reached}`, {
      fontFamily: 'monospace',
      fontSize: '18px',
      color: '#88ffaa',
    }).setOrigin(0.5);

    // Start button
    const startBtn = this.add.text(W / 2, H / 2 + 60, '▶  PLAY', {
      fontFamily: 'monospace',
      fontSize: '28px',
      color: '#ffffff',
      backgroundColor: '#224488',
      padding: { x: 30, y: 14 },
      stroke: '#000000',
      strokeThickness: 3,
    }).setOrigin(0.5).setInteractive({ useHandCursor: true });

    startBtn
      .on('pointerover', () => startBtn.setColor('#ffff88'))
      .on('pointerout',  () => startBtn.setColor('#ffffff'))
      .on('pointerdown', () => this.scene.start('GameScene'));

    // Controls hint
    this.add.text(W / 2, H - 40, 'Click Send Wave to begin • Upgrades available between waves', {
      fontFamily: 'monospace',
      fontSize: '13px',
      color: '#666688',
    }).setOrigin(0.5);
  }
}
