import Phaser from 'phaser';

export interface UpgradeState {
  archerDamage: number;
  archerFireRate: number;
  towerMaxHp: number;
  towerArcherCount: number;
  catapultUnlocked: boolean;
  catapultDamage: number;
  catapultFireRate: number;
  catapultAoe: number;
  outpostUnlocked: boolean;
  outpostAlive: boolean;
  outpostArcherCount: number;
  outpostDamageScale: number;
  outpostFireRate: number;
  outpostMaxHp: number;
}

export interface UpgradeCallbacks {
  onClose:              () => void;
  onDamage:             () => void;
  onSpeed:              () => void;
  onTowerHp:            () => void;
  onTowerArcher:        () => void;
  onCatapultUnlock:     () => void;
  onCatapultDamage:     () => void;
  onCatapultSpeed:      () => void;
  onCatapultAoe:        () => void;
  onOutpostUnlock:      () => void;
  onOutpostArcher:      () => void;
  onOutpostDamage:      () => void;
  onOutpostSpeed:       () => void;
  onOutpostHp:          () => void;
}

export class UpgradePanel {
  private scene: Phaser.Scene;
  private bg!: Phaser.GameObjects.Rectangle;
  private container!: Phaser.GameObjects.Container;
  private buttons: Phaser.GameObjects.Text[] = [];
  private cb: UpgradeCallbacks;
  visible = false;

  constructor(scene: Phaser.Scene, cb: UpgradeCallbacks) {
    this.scene = scene;
    this.cb = cb;
    this.build();
    this.setVisible(false);
  }

  private build(): void {
    const CX = 1280 / 2, CY = 720 / 2;
    const PW = 480, PH = 440;
    const depth = 200;

    // Dim overlay
    this.bg = this.scene.add.rectangle(CX, CY, 1280, 720, 0x000000, 0.55)
      .setDepth(depth).setInteractive();

    const panelBg = this.scene.add.rectangle(CX, CY, PW, PH, 0x1a1a2e, 0.98)
      .setDepth(depth + 1).setStrokeStyle(2, 0x4466aa);

    const items: [string, () => void, () => boolean][] = [
      ['+ Projectile Damage',    this.cb.onDamage,          () => false],
      ['+ Fire Rate',            this.cb.onSpeed,           () => false],
      ['+ Tower HP',             this.cb.onTowerHp,         () => false],
      ['+ Tower Archer (x/3)',   this.cb.onTowerArcher,     () => false],
      ['— Catapult —',           () => {},                   () => true],
      ['Add / Rebuild Catapult', this.cb.onCatapultUnlock,  () => false],
      ['+ Catapult Damage',      this.cb.onCatapultDamage,  () => false],
      ['+ Catapult Fire Rate',   this.cb.onCatapultSpeed,   () => false],
      ['+ Catapult Blast Radius',this.cb.onCatapultAoe,     () => false],
      ['— Outpost —',            () => {},                   () => true],
      ['Add / Rebuild Outpost',  this.cb.onOutpostUnlock,   () => false],
      ['+ Outpost Archer (x/3)',  this.cb.onOutpostArcher,  () => false],
      ['+ Outpost Damage',       this.cb.onOutpostDamage,   () => false],
      ['+ Outpost Fire Rate',    this.cb.onOutpostSpeed,    () => false],
      ['+ Outpost HP',           this.cb.onOutpostHp,       () => false],
      ['▶ Close',                this.cb.onClose,           () => false],
    ];

    const startY = CY - PH / 2 + 28;
    const rowH = 26;

    const titleStyle: Phaser.Types.GameObjects.Text.TextStyle = {
      fontFamily: 'monospace', fontSize: '18px', color: '#ddddff',
    };
    this.scene.add.text(CX, startY - 12, 'Upgrades', titleStyle)
      .setOrigin(0.5).setDepth(depth + 2);

    const btnStyle: Phaser.Types.GameObjects.Text.TextStyle = {
      fontFamily: 'monospace', fontSize: '13px', color: '#ffffff',
      backgroundColor: '#252540', padding: { x: 8, y: 4 },
    };
    const headerStyle: Phaser.Types.GameObjects.Text.TextStyle = {
      fontFamily: 'monospace', fontSize: '12px', color: '#aaaacc',
    };

    items.forEach(([label, action, isHeader], i) => {
      const y = startY + 18 + i * rowH;
      if (isHeader()){
        this.scene.add.text(CX, y, label, headerStyle).setOrigin(0.5).setDepth(depth + 2);
        return;
      }
      const t = this.scene.add.text(CX, y, label, btnStyle)
        .setOrigin(0.5)
        .setDepth(depth + 2)
        .setInteractive({ useHandCursor: true })
        .on('pointerdown', action)
        .on('pointerover', () => t.setColor('#ffff88'))
        .on('pointerout',  () => t.setColor('#ffffff'));
      this.buttons.push(t);
    });

    // Depth order fix
    panelBg.setDepth(depth + 1);
  }

  setVisible(v: boolean): void {
    this.visible = v;
    this.bg.setVisible(v);
    this.buttons.forEach(b => b.setVisible(v));
    // Also show/hide the panel bg and title (rebuilt each call — simpler to track via depth)
    this.scene.children.each(child => {
      const d = (child as Phaser.GameObjects.GameObject & { depth?: number }).depth ?? 0;
      if (d === 201 || d === 202) {
        (child as Phaser.GameObjects.Text).setVisible(v);
      }
    });
  }

  refresh(_state: UpgradeState): void {
    // Button text/disabled state could be updated here per state
    // For now buttons are always enabled (Phase 1 = free upgrades)
  }

  destroy(): void {
    this.bg.destroy();
    this.buttons.forEach(b => b.destroy());
  }
}
