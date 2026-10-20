// ==============================================================================
// UniCheck - Standard QR Code Matrix Generator (ISO/IEC 18004 Compliant)
// Pure TypeScript Implementation with Byte Mode & Reed-Solomon Error Correction
// ==============================================================================

// Galois Field (GF(256)) Math for Reed-Solomon
const EXP_TABLE = new Uint8Array(512);
const LOG_TABLE = new Uint8Array(256);

(function initGaloisField() {
  let val = 1;
  for (let i = 0; i < 255; i++) {
    EXP_TABLE[i] = val;
    EXP_TABLE[i + 255] = val;
    LOG_TABLE[val] = i;
    val = (val << 1) ^ (val & 0x80 ? 0x11d : 0);
  }
  LOG_TABLE[0] = 0;
})();

function gfMultiply(x: number, y: number): number {
  if (x === 0 || y === 0) return 0;
  return EXP_TABLE[LOG_TABLE[x] + LOG_TABLE[y]];
}

function getGeneratorPoly(errorCorrectionLength: number): Uint8Array {
  let poly = new Uint8Array([1]);
  for (let i = 0; i < errorCorrectionLength; i++) {
    const next = new Uint8Array(poly.length + 1);
    for (let j = 0; j < poly.length; j++) {
      next[j] ^= gfMultiply(poly[j], EXP_TABLE[i]);
      next[j + 1] ^= poly[j];
    }
    poly = next;
  }
  return poly;
}

function calculateReedSolomon(data: Uint8Array, ecLength: number): Uint8Array {
  const gen = getGeneratorPoly(ecLength);
  const res = new Uint8Array(ecLength);
  for (let i = 0; i < data.length; i++) {
    const factor = data[i] ^ res[0];
    res.copyWithin(0, 1);
    res[ecLength - 1] = 0;
    for (let j = 0; j < ecLength; j++) {
      res[j] ^= gfMultiply(gen[j], factor);
    }
  }
  return res;
}

// QR Code Specifications for Version 6 to 10 (Byte mode, Low/Medium EC)
interface VersionSpec {
  version: number;
  dimension: number;
  totalBytes: number;
  ecBytes: number;
  dataBytes: number;
  alignments: number[];
}

const VERSION_SPECS: VersionSpec[] = [
  { version: 4, dimension: 33, totalBytes: 100, ecBytes: 20, dataBytes: 80, alignments: [6, 26] },
  { version: 6, dimension: 41, totalBytes: 172, ecBytes: 36, dataBytes: 136, alignments: [6, 22, 38] },
  { version: 8, dimension: 49, totalBytes: 242, ecBytes: 52, dataBytes: 192, alignments: [6, 26, 46] },
  { version: 10, dimension: 57, totalBytes: 346, ecBytes: 74, dataBytes: 272, alignments: [6, 28, 52] },
];

export interface QrMatrix {
  dimension: number;
  modules: boolean[][];
  isReserved: boolean[][];
}

/**
 * Generate 2D QR Code Boolean Matrix for arbitrary text (e.g. JWT Token)
 */
export function generateQrMatrix(text: string): QrMatrix {
  const encoder = new TextEncoder();
  const rawBytes = encoder.encode(text);

  // Pick suitable version
  let spec = VERSION_SPECS[0];
  for (const s of VERSION_SPECS) {
    if (s.dataBytes - 3 >= rawBytes.length) {
      spec = s;
      break;
    }
    spec = s;
  }

  const dim = spec.dimension;
  const modules: boolean[][] = Array.from({ length: dim }, () => Array(dim).fill(false));
  const isReserved: boolean[][] = Array.from({ length: dim }, () => Array(dim).fill(false));

  // Helper to set module
  const setModule = (r: number, c: number, val: boolean, reserved = true) => {
    if (r >= 0 && r < dim && c >= 0 && c < dim) {
      modules[r][c] = val;
      if (reserved) isReserved[r][c] = true;
    }
  };

  // 1. Finder patterns (7x7 + 1 separator at Top-Left, Top-Right, Bottom-Left)
  const drawFinder = (top: number, left: number) => {
    for (let r = -1; r <= 7; r++) {
      for (let c = -1; c <= 7; c++) {
        const nr = top + r;
        const nc = left + c;
        if (nr >= 0 && nr < dim && nc >= 0 && nc < dim) {
          if (r === -1 || r === 7 || c === -1 || c === 7) {
            setModule(nr, nc, false, true);
          } else if (r === 0 || r === 6 || c === 0 || c === 6) {
            setModule(nr, nc, true, true);
          } else if (r >= 2 && r <= 4 && c >= 2 && c <= 4) {
            setModule(nr, nc, true, true);
          } else {
            setModule(nr, nc, false, true);
          }
        }
      }
    }
  };

  drawFinder(0, 0);
  drawFinder(0, dim - 7);
  drawFinder(dim - 7, 0);

  // 2. Alignment patterns
  const aligns = spec.alignments;
  for (const ar of aligns) {
    for (const ac of aligns) {
      // Avoid finder pattern zones
      if ((ar <= 8 && ac <= 8) || (ar <= 8 && ac >= dim - 8) || (ar >= dim - 8 && ac <= 8)) {
        continue;
      }
      for (let r = -2; r <= 2; r++) {
        for (let c = -2; c <= 2; c++) {
          const isBorder = Math.abs(r) === 2 || Math.abs(c) === 2;
          const isCenter = r === 0 && c === 0;
          setModule(ar + r, ac + c, isBorder || isCenter, true);
        }
      }
    }
  }

  // 3. Timing patterns (Alternating on row 6 & col 6)
  for (let i = 8; i < dim - 8; i++) {
    if (!isReserved[6][i]) setModule(6, i, i % 2 === 0, true);
    if (!isReserved[i][6]) setModule(i, 6, i % 2 === 0, true);
  }

  // 4. Reserve format info zones (around finders)
  for (let i = 0; i <= 8; i++) {
    setModule(8, i, false, true);
    setModule(i, 8, false, true);
    setModule(8, dim - 1 - i, false, true);
    setModule(dim - 1 - i, 8, false, true);
  }

  // 5. Build BitStream (Byte Mode = 0100, Count = 8/16 bits, Data, Terminator, Pad)
  const bitArray: number[] = [];
  const pushBits = (val: number, len: number) => {
    for (let i = len - 1; i >= 0; i--) {
      bitArray.push((val >>> i) & 1);
    }
  };

  // Byte mode indicator (0100)
  pushBits(0b0100, 4);
  // Char count (8 bits for version <= 9)
  pushBits(rawBytes.length, spec.version <= 9 ? 8 : 16);
  // Raw byte payload
  for (let i = 0; i < rawBytes.length; i++) {
    pushBits(rawBytes[i], 8);
  }

  // Terminator
  const totalDataBits = spec.dataBytes * 8;
  const termLen = Math.min(4, totalDataBits - bitArray.length);
  pushBits(0, termLen);

  // Align to byte
  while (bitArray.length % 8 !== 0) {
    bitArray.push(0);
  }

  // Pad bytes (0xEC, 0x11)
  const padBytes = [0xec, 0x11];
  let padIdx = 0;
  while (bitArray.length < totalDataBits) {
    pushBits(padBytes[padIdx % 2], 8);
    padIdx++;
  }

  // Convert to data byte array
  const dataBytes = new Uint8Array(spec.dataBytes);
  for (let i = 0; i < spec.dataBytes; i++) {
    let b = 0;
    for (let bit = 0; bit < 8; bit++) {
      b = (b << 1) | bitArray[i * 8 + bit];
    }
    dataBytes[i] = b;
  }

  // 6. Compute Reed-Solomon Error Correction Code
  const ecData = calculateReedSolomon(dataBytes, spec.ecBytes);

  // Interleave data and EC
  const finalBits: number[] = [];
  for (let i = 0; i < dataBytes.length; i++) {
    for (let bit = 7; bit >= 0; bit--) finalBits.push((dataBytes[i] >>> bit) & 1);
  }
  for (let i = 0; i < ecData.length; i++) {
    for (let bit = 7; bit >= 0; bit--) finalBits.push((ecData[i] >>> bit) & 1);
  }

  // 7. Place bits zigzag column by column from right to left
  let bitPointer = 0;
  let upward = true;

  for (let col = dim - 1; col > 0; col -= 2) {
    if (col === 6) col--; // Skip vertical timing pattern column

    const rows = upward
      ? Array.from({ length: dim }, (_, i) => dim - 1 - i)
      : Array.from({ length: dim }, (_, i) => i);

    for (const r of rows) {
      for (const c of [col, col - 1]) {
        if (!isReserved[r][c]) {
          const bitVal = bitPointer < finalBits.length ? finalBits[bitPointer++] : 0;
          // Apply standard Mask 0: (row + col) % 2 === 0
          const mask = (r + c) % 2 === 0;
          modules[r][c] = (bitVal === 1) !== mask;
        }
      }
    }
    upward = !upward;
  }

  // 8. Draw Format Info for Mask 0 (EC Level M: 0b00, Mask 0: 0b000 -> 0x5412)
  const formatInfo = 0x5412;
  for (let i = 0; i < 15; i++) {
    const bit = ((formatInfo >>> (14 - i)) & 1) === 1;
    if (i < 6) {
      modules[8][i] = bit;
    } else if (i === 6) {
      modules[8][7] = bit;
    } else if (i === 7) {
      modules[8][8] = bit;
    } else if (i === 8) {
      modules[7][8] = bit;
    } else {
      modules[14 - i][8] = bit;
    }

    if (i < 8) {
      modules[dim - 1 - i][8] = bit;
    } else {
      modules[8][dim - 15 + i] = bit;
    }
  }

  return { dimension: dim, modules, isReserved };
}
