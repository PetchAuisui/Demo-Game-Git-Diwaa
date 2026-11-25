import { fit, hex, mix, clamp, lerp, rng, cycle, TAU } from "../../core/index.js";
import { Grid, shift, shadow, spring } from "./_lib.js";

export const meta = {
  name: "Door golem",
  desc: "A living stone archway breathes on squat legs: runes pulse in its dark doorway, its eye-slits glare under a stone brow, and two stone fists hover on threads of violet force.",
  tags: ["critter", "golem", "stone", "boss", "door", "monster", "arcane", "loop"],
  size: [136, 120],
  origin: [68, 112],
  duration: 2.4,
  loop: true,
  fps: 30,
  bg: "ground",
  options: {
    palette: ["#0e0d14", "#1c1a26", "#2c2938", "#3f3b4f", "#585266", "#757086", "#9d97ad", "#cfc9da"],
    rune: ["#140a26", "#3a1670", "#6b2cc0", "#a560f0", "#dcb0ff", "#ffffff"],
    seed: 1,
  },
};

const D = meta.duration;
const BODY = new Grid(-30, -86, 60, 88);
const FIST = new Grid(-13, -12, 27, 25);
const HW = 22, ARCH_Y = -58; // half width of the body, centre of its round top
const DW = 9, DOOR_Y = -38, DOOR_BOT = -12; // the doorway: half width, centre of its arch, sill

// is (x, y) inside the archway silhouette (body) / the doorway recess
const inBody = (x, y) => y <= -8 && y >= ARCH_Y - HW && Math.abs(x) <= HW && (y >= ARCH_Y || Math.hypot(x, y - ARCH_Y) <= HW);
const inDoor = (x, y) => y <= DOOR_BOT && Math.abs(x) <= DW && (y >= DOOR_Y || Math.hypot(x, y - DOOR_Y) <= DW);

// the breath: the body sinks and swells a pixel, the fists lag behind it
const breath = (t) => Math.sin((t / D) * TAU);

function stones(g, C, seed) {
  const R = rng(seed, 5);
  // running bond: rows of blocks, each lit from the top-left, mortar between, a few chips and cracks
  const rows = [];
  for (let y = -8, row = 0; y > ARCH_Y - HW - 2; row++) {
    const h = row % 3 === 1 ? 9 : 10;
    rows.push([y - h, y, row]);
    y -= h;
  }
  for (const [y0, y1, row] of rows) {
    let x = -HW - (row % 2 ? 6 : 0);
    while (x < HW) {
      const w = 13 + Math.floor(R.next() * 8), x0 = x, x1 = x + w;
      const tone = R.next() < 0.3 ? 3 : R.next() < 0.2 ? 5 : 4, chip = R.next(), cx = lerp(x0, x1, R.next());
      g.shade(x0, y0, x1 - 1, y1 - 1, (px, py) => {
        if (!inBody(px, py) || inDoor(px, py)) return 0;
        const top = py - y0 < 1, left = px - x0 < 1, bot = y1 - py < 1, right = x1 - px < 1;
        if (bot || right) return C[1]; // mortar
        if (top) return C[6];
        if (left) return C[5];
        if (py - y0 < 2 && px - x0 < 4) return C[6];
        // a chip off the lower-right corner of some blocks
        if (chip < 0.35 && y1 - py < 3 && x1 - px < 4 && (y1 - py) + (x1 - px) < 5) return C[2];
        // a crack running down some blocks
        if (chip > 0.8 && Math.abs(px - (cx + (py - y0) * 0.4)) < 0.6) return C[2];
        // a round body lit from the top-left: bright on the left, falling off to the right and at the base,
        // with a thin violet rim of back light from the runes on the far edge
        if (px > HW - 2.2 || (py < ARCH_Y && Math.hypot(px, py - ARCH_Y) > HW - 1.6 && px > 4)) return mix(C[3], hex("#6b2cc0"), 0.3);
        let k = tone + (px < -HW * 0.45 ? 1 : 0) - (px > HW * 0.35 ? 1 : 0) - (px > HW * 0.72 ? 1 : 0) - (py > -18 ? 1 : 0);
        return C[clamp(k, 1, 6)];
      });
      x = x1;
    }
  }
  // the keystone: a taller wedge at the crown with the eye slits under it
  g.shade(-5, ARCH_Y - HW - 1, 5, ARCH_Y - HW + 10, (px, py) => {
    const k = py - (ARCH_Y - HW - 1);
    if (Math.abs(px) > 3 + k * 0.25 || !inBody(px, py + 1)) return 0;
    if (Math.abs(px) > 2.4 + k * 0.25) return C[1];
    return px < -1 ? C[6] : C[5];
  });
}

// shoulder boulders where the threads of force come out, and an angry brow over the eyes
function shoulders(g, C) {
  for (const s of [-1, 1]) {
    const cx = s * (HW + 1), cy = ARCH_Y + 9;
    g.shade(cx - 8, cy - 7, cx + 8, cy + 7, (px, py) => {
      const nx = (px - cx) / 7.5, ny = (py - cy) / 6.5;
      if (nx * nx + ny * ny > 1) return 0;
      const l = -nx * 0.6 - ny * 0.8; // lit from the top-left
      if (ny > 0.55) return C[2];
      return l > 0.45 ? C[6] : l > 0 ? C[5] : l > -0.5 ? C[4] : C[3];
    });
    g.line(cx - 5, cy + 1, cx + 3, cy - 2, C[2]);
  }
}

function brow(g, C) {
  const ey = ARCH_Y - 8;
  for (const s of [-1, 1])
    for (let x = 2; x <= 12; x++) {
      const y = Math.round(ey - 1 - (x - 2) * 0.32);
      g.set(s * x, y, C[0]), g.set(s * x, y - 1, C[1]), g.set(s * x, y - 2, s < 0 ? C[6] : C[5]);
    }
}

// cracks that leak the violet light, pulsing
function cracks(g, Ru, t) {
  const glow = 0.5 + 0.5 * Math.sin((t / D) * TAU * 2 + 1.2);
  const lines = [
    [[-HW + 1, -44], [-15, -41], [-13, -36], [-10, -33]],
    [[HW - 1, -26], [17, -28], [14, -24], [11, -25]],
    [[-6, ARCH_Y - HW + 3], [-8, ARCH_Y - HW + 7], [-6, ARCH_Y - HW + 10]],
  ];
  for (const pts of lines)
    for (let k = 1; k < pts.length; k++) g.line(pts[k - 1][0], pts[k - 1][1], pts[k][0], pts[k][1], glow > 0.55 ? Ru[4] : Ru[3], 1);
  return { lines, glow };
}

function door(g, C, Ru, t) {
  const pulse = 0.5 + 0.5 * Math.sin((t / D) * TAU * 2);
  // the recess: deep shadow, its inner rim lit from below by the runes
  g.shade(-DW - 1, DOOR_Y - DW - 1, DW + 1, DOOR_BOT, (px, py) => {
    if (!inDoor(px, py)) return 0;
    const edge = !inDoor(px - 1.2, py) || !inDoor(px + 1.2, py) || !inDoor(px, py - 1.2);
    if (edge) return py > DOOR_Y ? Ru[1] : C[0];
    return py > DOOR_BOT - 3 ? Ru[1] : C[0];
  });
  // a column of runes climbing the doorway, each one lighting as the pulse passes it
  const GLYPHS = [
    ["x.x", "x.x", ".x.", ".x.", ".x."],
    [".x.", "x.x", ".x.", ".x.", "x.x"],
    ["x..", "xx.", "x.x", "..x", "..x"],
    [".x.", ".xx", ".x.", "xx.", ".x."],
  ];
  for (let i = 0; i < 4; i++) {
    const gy = DOOR_BOT - 8 - i * 7, phase = clamp(1 - Math.abs(((t / D) * 2 + i * 0.25) % 1 - 0.5) * 3);
    const c = phase > 0.6 ? Ru[5] : phase > 0.25 ? Ru[4] : Ru[3];
    GLYPHS[i].forEach((row, ry) => [...row].forEach((ch, rx) => ch === "x" && g.set(rx - 1, gy + ry - 2, c, 1, 7)));
  }
  return pulse;
}

function eyes(g, Ru, t) {
  // two slits under the keystone, narrowing to a squint now and then
  const squint = t > 1.6 && t < 1.78 ? 1 : 0;
  for (const s of [-1, 1]) {
    const cx = s * 7, cy = ARCH_Y - 8;
    for (let x = -3; x <= 3; x++) {
      const tilt = Math.round(-s * x * 0.35);
      g.set(cx + x, cy + tilt, Math.abs(x) < 2 ? Ru[5] : Ru[4], 1, 8);
      if (!squint && Math.abs(x) < 3) g.set(cx + x, cy + tilt + 1, Ru[3], 1, 8);
    }
    g.set(cx - s * 4, cy - 1 + Math.round(s * 4 * 0.35 * s), Ru[2], 1, 8);
  }
}

function fist(g, C, side) {
  g.clear();
  // a squared stone fist: four knuckle blocks on top, a thumb block, lit from the top-left
  g.shade(-11, -9, 11, 11, (px, py) => {
    const nx = Math.abs(px) / 11, ny = Math.abs(py - 1) / 9.5;
    if (nx ** 4 + ny ** 4 > 1) return 0;
    if (py < -3) {
      // four knuckle blocks, each with its own lit top
      if ((px + 11) % 5.5 < 0.9) return C[1];
      return py < -7 ? C[7] : (px + 11) % 5.5 < 2.2 ? C[6] : C[5];
    }
    if (Math.abs(py + 2.5) < 0.6) return C[1];
    if (side * px > 4 && py < 5) return (side * px > 9 ? C[2] : side > 0 ? C[3] : C[5]); // the thumb, towards the body
    if (py > 7) return C[2];
    return px < -7 ? C[5] : px > 7 ? C[3] : C[4];
  });
  g.line(-4, 4, 2, 6, C[2]); // a crack across the back of the hand
  g.outline(C[0]);
}

export function draw(p, time, o) {
  const t = shift(time, D, o.seed), C = fit(o.palette, 8), Ru = fit(o.rune, 6), b = breath(t);
  const lift = Math.round(b * 1.2);
  // the body
  const g = BODY.clear();
  stones(g, C, o.seed);
  // legs: two squat blocks under the body
  for (const s of [-1, 1])
    g.shade(s * 12 - 7, -9, s * 12 + 6, 1, (px, py) => (py > -0.5 + 1 ? 0 : py < -8 ? C[6] : px < s * 12 - 5 ? C[5] : py > -2 ? C[2] : C[4]));
  shoulders(g, C);
  const pulse = door(g, C, Ru, t);
  const cr = cracks(g, Ru, t);
  brow(g, C);
  eyes(g, Ru, t);
  g.outline((x, y, nx, ny) => (ny > 0 || nx > 0 ? C[0] : C[1]));
  g.draw(p, 1, 0, lift > 0 ? 0 : lift);

  // light from the runes and the eyes
  p.glow(0, DOOR_Y + 8, 20, Ru[2], 0.35 + 0.25 * pulse);
  for (const pts of cr.lines) for (const [x, y] of pts) p.glow(x, y + lift, 4, Ru[3], 0.2 + 0.25 * cr.glow);
  p.glow(0, DOOR_BOT - 6, 8, Ru[3], 0.3 + 0.3 * pulse);
  for (const s of [-1, 1]) p.glow(s * 7, ARCH_Y - 8 + lift, 7, Ru[3], 0.55), p.glow(s * 7, ARCH_Y - 8 + lift, 2, Ru[4], 0.5);

  // the fists hover beside it, bobbing a beat behind the breath, tied on by threads of force
  const F = FIST;
  for (const s of [-1, 1]) {
    const lag = breath(t - 0.35 - (s > 0 ? 0.2 : 0));
    const fx = s * 43, fy = -32 + lag * 3;
    // a thread of force from the shoulder to the wrist, wavering
    const sx = s * (HW + 7), sy = ARCH_Y + 10 + lift;
    for (let k = 0; k <= 12; k++) {
      const u = k / 12, wob = Math.sin(u * 7 + (t / D) * TAU * 3 + s) * 1.6 * Math.sin(u * Math.PI);
      const x = lerp(sx, fx - s * 10, u), y = lerp(sy, fy - 4, u) + wob;
      p.dot(x, y, k % 3 === 0 ? Ru[4] : Ru[3], 0.8);
      p.glow(x, y, 3, Ru[2], 0.15);
    }
    fist(F, C, -s);
    F.draw(p, 1, fx, fy);
    // a ring of force round the wrist
    for (let a = 0; a < TAU; a += TAU / 18) {
      const z = Math.sin(a + (t / D) * TAU * 2), x = fx - s * 11 + Math.cos(a) * 1.5, y = fy + 1 + Math.sin(a + (t / D) * TAU * 2) * 7;
      if (z > -0.2) p.dot(x, y, z > 0.5 ? Ru[4] : Ru[3], 0.9);
    }
    p.glow(fx - s * 11, fy, 9, Ru[2], 0.25);
    // grit trickles off the knuckles and falls to the floor
    cycle(t, D, 3, o.seed * 13 + (s > 0 ? 1 : 2), 0.8, (age, L, r) => {
      const x0 = fx + r.range(-6, 6), y0 = fy + 7;
      const y = y0 + 0.5 * 160 * age * age;
      if (y < -1) p.px(x0, y, age < L * 0.5 ? C[5] : C[3]);
    });
  }

  // pebbles drift up round the body on the force, glinting
  cycle(t, D, 7, o.seed * 7 + 3, 1.6, (age, L, r) => {
    const x = r.range(-HW - 4, HW + 4) + Math.sin(age * 3 + r.next() * 6) * 2, y = -6 - age * 14 - r.range(0, 30);
    const fade = Math.sin((age / L) * Math.PI);
    p.dot(x, y, r.next() < 0.5 ? C[5] : C[6], fade);
    if (r.next() < 0.4) p.glow(x, y, 3, Ru[2], 0.3 * fade);
  });
}

export function drawBack(p, time, o) {
  const t = shift(time, D, o.seed), Ru = fit(o.rune, 6);
  shadow(p, 0, 0, 34, 3.5, hex("#08070c"), 0.7);
  // violet light on the floor in front of the doorway, breathing with the runes
  const pulse = 0.5 + 0.5 * Math.sin((t / D) * TAU * 2);
  for (let x = -24; x <= 24; x += 6) p.glow(x, 0, 14, Ru[2], (0.12 + 0.08 * pulse) * (1 - Math.abs(x) / 30));
}
