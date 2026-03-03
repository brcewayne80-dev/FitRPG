import Phaser from 'phaser';
import { CATAPULT_POS, CATAPULT_MUZZLE, CATAPULT_REARM_MS } from '../constants';

export class Catapult {
  sprite: Phaser.GameObjects.Sprite;
  alive = false;

  readonly muzzle = CATAPULT_MUZZLE;

  private armed = true;
  private scene: Phaser.Scene;
  onFired?: () => void;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;

    this.sprite = scene.add.sprite(CATAPULT_POS.x, CATAPULT_POS.y, 'catapult1');
    // 512×512 source image, Godot uses scale 0.293961 → ~150px displayed
    this.sprite.setOrigin(0.5, 0.5).setScale(0.293961).setVisible(false);

    if (!scene.anims.exists('catapult_fire')) {
      scene.anims.create({
        key: 'catapult_fire',
        frames: [
          { key: 'catapult1' },
          { key: 'catapult2' },
          { key: 'catapult3' },
          { key: 'catapult4' },
          { key: 'catapult1' }, // frame 4 = fire point
        ],
        frameRate: 5,
        repeat: 0,
      });
    }
  }

  show(): void {
    this.alive = true;
    this.armed = true;
    this.sprite.setVisible(true);
  }

  hide(): void {
    this.alive = false;
    this.sprite.setVisible(false);
  }

  fire(): void {
    if (!this.alive || !this.armed) return;
    this.armed = false;
    this.sprite.play('catapult_fire');

    // Spawn rock at the frame-4 moment (4/5 through animation @ 5fps = 800ms)
    this.scene.time.delayedCall(CATAPULT_REARM_MS, () => {
      this.onFired?.();
    });

    // Rearm after animation finishes (5 frames @ 5fps = 1s)
    this.scene.time.delayedCall(1000, () => {
      this.armed = true;
    });
  }

  destroy(): void {
    this.sprite.destroy();
  }
}
