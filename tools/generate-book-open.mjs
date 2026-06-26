/**
 * CHAPTER 온보딩용 book_open.riv 생성
 * 실행: node tools/generate-book-open.mjs
 */
import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { RiveFile, hex, PropertyKey } from '@stevysmith/rive-generator';

const __dirname = dirname(fileURLToPath(import.meta.url));
const outPath = join(__dirname, '../assets/animations/book_open.riv');

const riv = new RiveFile();
const W = 280;
const H = 210;
const PAGE_W = 120;
const PAGE_H = 172;
const SPINE_X = W / 2;
const SPINE_Y = H / 2;

const artboard = riv.addArtboard({ name: 'BookOpen', width: W, height: H });

const shadow = riv.addShape(artboard, { name: 'Shadow', x: SPINE_X, y: SPINE_Y + PAGE_H / 2 + 12 });
riv.addEllipse(shadow, { width: 160, height: 18 });
const shadowFill = riv.addFill(shadow);
riv.addSolidColor(shadowFill, hex('#E8E0D4'));

const spine = riv.addShape(artboard, { name: 'Spine', x: SPINE_X, y: SPINE_Y });
riv.addRectangle(spine, { width: 10, height: PAGE_H });
const spineFill = riv.addFill(spine);
riv.addSolidColor(spineFill, hex('#8B7355'));

function addPage(parentId, name, offsetX, coverColor) {
  const node = riv.addNode(parentId, { name: `${name}Node`, x: SPINE_X, y: SPINE_Y });

  const paper = riv.addShape(node, { name: `${name}Paper`, x: offsetX, y: 0 });
  riv.addRectangle(paper, { width: PAGE_W, height: PAGE_H });
  const paperFill = riv.addFill(paper);
  riv.addSolidColor(paperFill, hex('#FAF7F2'));

  for (let i = 0; i < 5; i++) {
    const line = riv.addShape(node, { name: `${name}Line${i}`, x: offsetX + 16, y: -58 + i * 16 });
    riv.addRectangle(line, { width: PAGE_W - 40 - i * 6, height: 2.5 });
    const lineFill = riv.addFill(line);
    riv.addSolidColor(lineFill, hex('#D8D0C4'));
  }

  const cover = riv.addShape(node, { name: `${name}Cover`, x: offsetX, y: 0 });
  riv.addRectangle(cover, { width: PAGE_W, height: PAGE_H });
  const coverFill = riv.addFill(cover);
  riv.addSolidColor(coverFill, hex(coverColor));

  return { node, cover };
}

const left = addPage(artboard, 'Left', -PAGE_W / 2, '#7A6A5C');
const right = addPage(artboard, 'Right', 2, '#6E5F52');

const anim = riv.addLinearAnimation(artboard, {
  name: 'openBook',
  fps: 60,
  duration: 150,
  loop: 'oneShot',
});

function animateOpen(animationId, nodeId, coverId, sign) {
  const keyed = riv.addKeyedObject(animationId, nodeId);
  const rot = riv.addKeyedProperty(keyed, PropertyKey.rotation);
  const end = sign * 1.08;
  riv.addKeyFrameDouble(rot, { frame: 0, value: 0, interpolation: 'cubic' });
  riv.addKeyFrameDouble(rot, { frame: 35, value: end * 0.12, interpolation: 'cubic' });
  riv.addKeyFrameDouble(rot, { frame: 115, value: end, interpolation: 'cubic' });
  riv.addKeyFrameDouble(rot, { frame: 150, value: end, interpolation: 'hold' });

  const coverKeyed = riv.addKeyedObject(animationId, coverId);
  const opacity = riv.addKeyedProperty(coverKeyed, PropertyKey.opacity);
  riv.addKeyFrameDouble(opacity, { frame: 0, value: 100, interpolation: 'linear' });
  riv.addKeyFrameDouble(opacity, { frame: 45, value: 100, interpolation: 'linear' });
  riv.addKeyFrameDouble(opacity, { frame: 75, value: 0, interpolation: 'cubic' });
  riv.addKeyFrameDouble(opacity, { frame: 150, value: 0, interpolation: 'hold' });
}

animateOpen(anim, left.node, left.cover, -1);
animateOpen(anim, right.node, right.cover, 1);

const bytes = riv.export();
writeFileSync(outPath, Buffer.from(bytes));
console.log(`Generated ${outPath} (${bytes.length} bytes)`);
