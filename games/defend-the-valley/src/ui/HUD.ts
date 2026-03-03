import Phaser from 'phaser';

export interface HUDCallbacks {
  onSendWave: () => void;
  onSpeedToggle: () => void;
  onUpgrade: () => void;
}

export class HUD {
  private scene: Phaser.Scene;
  private waveText!: Phaser.GameObjects.Text;
  private statusText!: Phaser.GameObjects.Text;
  private hpText!: Phaser.GameObjects.Text;
  private sendBtn!: Phaser.GameObjects.Text;
  private speedBtn!: Phaser.GameObjects.Text;
  private upgradeBtn!: Phaser.GameObjects.Text;

  private cb: HUDCallbacks;
  private speedUp = false;
  private interwave = false;
  private countdown = 0;
  private countdownTimer?: Phaser.Time.TimerEvent;

  constructor(scene: Phaser.Scene, cb: HUDCallbacks) {
    this.scene = scene;
    this.cb = cb;
    this.build();
  }

  private build(): void {
    const depth = 100;
    const style = (size = 16): Phaser.Types.GameObjects.Text.TextStyle => ({
      fontFamily: 'monospace',
      fontSize: `${size}px`,
      color: '#ffffff',
      stroke: '#000000',
      strokeThickness: 3,
    });

    // Top-left: wave info
    this.waveText = this.scene.add.text(16, 12, 'Wave: 1', style(20)).setDepth(depth);
    this.hpText   = this.scene.add.text(16, 38, 'Tower: 250/250', style(14)).setDepth(depth);
    this.statusText = this.scene.add.text(16, 58, '', style(13))
      .setDepth(depth).setColor('#aaffaa');

    // Top-right buttons
    const bStyle = (size = 15): Phaser.Types.GameObjects.Text.TextStyle => ({
      fontFamily: 'monospace',
      fontSize: `${size}px`,
      color: '#ffffff',
      backgroundColor: '#333344',
      stroke: '#000000',
      strokeThickness: 2,
      padding: { x: 10, y: 6 },
    });

    const W = 1280;
    this.speedBtn = this.makeBtn(W - 170, 12, 'Speed 2x: OFF', bStyle(), () => {
      this.cb.onSpeedToggle();
    }).setDepth(depth);

    this.sendBtn = this.makeBtn(W - 340, 12, 'Send Wave (10s)', bStyle(), () => {
      if (this.interwave) this.cb.onSendWave();
    }).setDepth(depth);

    this.upgradeBtn = this.makeBtn(W - 510, 12, 'Upgrades', bStyle(), () => {
      if (this.interwave) this.cb.onUpgrade();
    }).setDepth(depth);
  }

  private makeBtn(
    x: number, y: number, label: string,
    style: Phaser.Types.GameObjects.Text.TextStyle,
    cb: () => void,
  ): Phaser.GameObjects.Text {
    const t = this.scene.add.text(x, y, label, style)
      .setInteractive({ useHandCursor: true })
      .on('pointerdown', cb)
      .on('pointerover', () => t.setColor('#ffff88'))
      .on('pointerout',  () => t.setColor('#ffffff'));
    return t;
  }

  setWave(wave: number): void {
    this.waveText.setText(`Wave: ${wave}`);
  }

  setHpText(text: string): void {
    this.hpText.setText(text);
  }

  setStatus(text: string): void {
    this.statusText.setText(text);
  }

  setInterwave(active: boolean, countdown: number): void {
    this.interwave = active;
    this.countdown = countdown;
    this.sendBtn.setAlpha(active ? 1 : 0.5);
    this.upgradeBtn.setAlpha(active ? 1 : 0.5);

    if (active) {
      this.countdownTimer?.destroy();
      let remaining = countdown;
      this.updateSendBtnLabel(remaining);
      this.countdownTimer = this.scene.time.addEvent({
        delay: 1000,
        callback: () => {
          remaining = Math.max(0, remaining - 1);
          this.updateSendBtnLabel(remaining);
        },
        repeat: countdown - 1,
      });
    } else {
      this.countdownTimer?.destroy();
      this.sendBtn.setText('Send Wave');
    }
  }

  private updateSendBtnLabel(remaining: number): void {
    this.sendBtn.setText(`Send Wave (${remaining}s)`);
  }

  setSpeedUp(enabled: boolean): void {
    this.speedUp = enabled;
    this.speedBtn.setText(`Speed 2x: ${enabled ? 'ON' : 'OFF'}`);
    this.speedBtn.setColor(enabled ? '#aaffaa' : '#ffffff');
  }

  destroy(): void {
    this.countdownTimer?.destroy();
    [this.waveText, this.hpText, this.statusText, this.sendBtn, this.speedBtn, this.upgradeBtn]
      .forEach(o => o.destroy());
  }
}
