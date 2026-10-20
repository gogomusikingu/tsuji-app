// The 辻 mark (Theme.swift TsujiMark): a thick open book of straight lines and circular arcs,
// with one vermilion line on the right page. Geometry on a 1024 grid.

const farY = 240, nearY = 570, dip = 34, rise = 22, block = 120, wf = 284, wn = 315;
const p = (dx, y) => [512 + dx, y];

/** Points along the circular arc from a through b to c (a itself excluded). */
function arc(a, b, c) {
  const d = 2 * (a[0] * (b[1] - c[1]) + b[0] * (c[1] - a[1]) + c[0] * (a[1] - b[1]));
  const a2 = a[0] ** 2 + a[1] ** 2, b2 = b[0] ** 2 + b[1] ** 2, c2 = c[0] ** 2 + c[1] ** 2;
  const o = [(a2 * (b[1] - c[1]) + b2 * (c[1] - a[1]) + c2 * (a[1] - b[1])) / d,
    (a2 * (c[0] - b[0]) + b2 * (a[0] - c[0]) + c2 * (b[0] - a[0])) / d];
  const r = Math.hypot(a[0] - o[0], a[1] - o[1]);
  const angle = (q) => Math.atan2(q[1] - o[1], q[0] - o[0]);
  const positive = (x) => ((x % (2 * Math.PI)) + 2 * Math.PI) % (2 * Math.PI);
  const start = angle(a);
  const sweepPos = positive(angle(c) - start);
  const sweep = positive(angle(b) - start) < sweepPos ? sweepPos : sweepPos - 2 * Math.PI;
  const pts = [];
  for (let i = 1; i <= 48; i++) {
    const t = start + (sweep * i) / 48;
    pts.push([o[0] + r * Math.cos(t), o[1] + r * Math.sin(t)]);
  }
  return pts;
}

const line = (pts) => pts.map(([x, y]) => `L${x.toFixed(1)} ${y.toFixed(1)}`).join("");
const move = ([x, y]) => `M${x} ${y}`;

export const OUTLINE = move(p(-wf, farY))
  + line(arc(p(-wf, farY), p(-wf / 2, farY - rise), p(0, farY + dip)))
  + line(arc(p(0, farY + dip), p(wf / 2, farY - rise), p(wf, farY)))
  + line([p(wn, nearY + block)])
  + line(arc(p(wn, nearY + block), p(wn / 2, nearY - rise + block), p(0, nearY + dip + block)))
  + line(arc(p(0, nearY + dip + block), p(-wn / 2, nearY - rise + block), p(-wn, nearY + block)))
  + "Z";

export const INNER = move(p(-wn, nearY))
  + line(arc(p(-wn, nearY), p(-wn / 2, nearY - rise), p(0, nearY + dip)))
  + line(arc(p(0, nearY + dip), p(wn / 2, nearY - rise), p(wn, nearY)))
  + move(p(0, farY + dip)) + line([p(0, nearY + dip + block)]);

export const VERSE = `M${512 + 70} 395L${512 + 240} 395`;

/** The tight crop drops the icon's margin so the book fills the box (TsujiMark tight: true). */
export const VIEWBOX = { full: "0 0 1024 1024", tight: `${512 - 512 / 1.45} ${472 - 512 / 1.45} ${1024 / 1.45} ${1024 / 1.45}` };

export function markSVG({ tight = false, verse = 1, cls = "" } = {}) {
  return `<svg class="mark ${cls}" viewBox="${tight ? VIEWBOX.tight : VIEWBOX.full}" aria-hidden="true">`
    + `<path d="${OUTLINE}" fill="none" stroke="var(--ink)" stroke-width="36" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<path d="${INNER}" fill="none" stroke="var(--ink)" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>`
    + `<path class="mark-verse" d="${VERSE}" stroke="var(--shu)" stroke-width="22" stroke-linecap="round" style="opacity:${verse}"/>`
    + `</svg>`;
}
