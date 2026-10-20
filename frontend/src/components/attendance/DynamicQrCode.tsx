// ==============================================================================
// UniCheck - Dynamic QR Code Renderer (Stitch Screen 5c0df9af4d2545919e8f774c1159e7da)
// High-Contrast SVG QR Matrix with UniCheck Center Seal & Corner Accents
// ==============================================================================

import React, { useMemo } from 'react';
import { generateQrMatrix } from '../../utils/qr-generator';

interface DynamicQrCodeProps {
  value: string;
  size?: number;
  className?: string;
  showScanningBeam?: boolean;
}

export const DynamicQrCode: React.FC<DynamicQrCodeProps> = ({
  value,
  size = 384,
  className = '',
  showScanningBeam = true,
}) => {
  // Generate QR matrix from token
  const qrMatrix = useMemo(() => {
    if (!value || !value.trim()) return null;
    try {
      return generateQrMatrix(value.trim());
    } catch (e) {
      console.error('Failed to generate QR matrix:', e);
      return null;
    }
  }, [value]);

  // Center logo zone boundary in normalized 240x240 coordinates
  // Logo is at (95, 95) with size 50x50
  const isInsideCenterSeal = (x: number, y: number, cellSize: number) => {
    const sealLeft = 90;
    const sealRight = 150;
    const sealTop = 90;
    const sealBottom = 150;
    return (
      x + cellSize >= sealLeft &&
      x <= sealRight &&
      y + cellSize >= sealTop &&
      y <= sealBottom
    );
  };

  // Convert matrix modules to SVG rect elements
  const dataCells = useMemo(() => {
    if (!qrMatrix) return [];
    const { dimension, modules, isReserved } = qrMatrix;
    const viewBoxSize = 240;
    const margin = 12;
    const availableSize = viewBoxSize - margin * 2;
    const cellSize = availableSize / dimension;

    const cells: React.ReactNode[] = [];

    for (let r = 0; r < dimension; r++) {
      for (let c = 0; c < dimension; c++) {
        // Skip reserved finder pattern regions (first 8x8 in 3 corners)
        if (
          (r < 8 && c < 8) ||
          (r < 8 && c >= dimension - 8) ||
          (r >= dimension - 8 && c < 8)
        ) {
          continue;
        }

        const x = margin + c * cellSize;
        const y = margin + r * cellSize;

        // Skip cells overlapping the center UniCheck badge seal
        if (isInsideCenterSeal(x, y, cellSize)) {
          continue;
        }

        if (modules[r][c]) {
          cells.push(
            <rect
              key={`cell-${r}-${c}`}
              x={x}
              y={y}
              width={Math.max(1.2, cellSize * 0.94)}
              height={Math.max(1.2, cellSize * 0.94)}
              rx={cellSize > 3 ? 0.75 : 0.3}
              fill="#131b2e"
            />
          );
        }
      }
    }

    return cells;
  }, [qrMatrix]);

  return (
    <div
      className={`relative p-space-lg rounded-2xl bg-white shadow-xl flex items-center justify-center transition-all duration-300 ${className}`}
      id="qrContainerWrapper"
      style={{ maxWidth: '100%' }}
    >
      {/* 1. Animated Cyber Scanning Laser Line */}
      {showScanningBeam && (
        <div
          className="absolute left-6 right-6 h-0.5 bg-[#006b5f] shadow-[0_0_12px_#006b5f] opacity-80 pointer-events-none z-10 animate-pulse"
          id="scanningBeam"
          style={{
            animation: 'scanLine 3s ease-in-out infinite alternate',
          }}
        />
      )}

      {/* 2. Corner Security Accents */}
      <div className="absolute top-2 left-2 w-4 h-4 border-t-2 border-l-2 border-primary pointer-events-none rounded-tl-sm" />
      <div className="absolute top-2 right-2 w-4 h-4 border-t-2 border-r-2 border-primary pointer-events-none rounded-tr-sm" />
      <div className="absolute bottom-2 left-2 w-4 h-4 border-b-2 border-l-2 border-primary pointer-events-none rounded-bl-sm" />
      <div className="absolute bottom-2 right-2 w-4 h-4 border-b-2 border-r-2 border-primary pointer-events-none rounded-br-sm" />

      {/* 3. SVG High-Precision Matrix Canvas */}
      <div
        className="flex items-center justify-center select-none"
        style={{ width: size, height: size, maxWidth: '100%' }}
        id="qrCodeTarget"
      >
        <svg
          className="w-full h-full text-on-surface transition-opacity duration-300"
          fill="currentColor"
          id="mainQrSvg"
          viewBox="0 0 240 240"
        >
          {/* Finder pattern: Top-Left */}
          <rect x="10" y="10" width="60" height="60" rx="8" fill="#131b2e" />
          <rect x="18" y="18" width="44" height="44" rx="4" fill="#ffffff" />
          <rect x="26" y="26" width="28" height="28" rx="2" fill="#131b2e" />

          {/* Finder pattern: Top-Right */}
          <rect x="170" y="10" width="60" height="60" rx="8" fill="#131b2e" />
          <rect x="178" y="18" width="44" height="44" rx="4" fill="#ffffff" />
          <rect x="186" y="26" width="28" height="28" rx="2" fill="#131b2e" />

          {/* Finder pattern: Bottom-Left */}
          <rect x="10" y="170" width="60" height="60" rx="8" fill="#131b2e" />
          <rect x="18" y="178" width="44" height="44" rx="4" fill="#ffffff" />
          <rect x="26" y="186" width="28" height="28" rx="2" fill="#131b2e" />

          {/* Dynamic Matrix Cells */}
          {dataCells}

          {/* Central UniCheck Brand Seal (Stitch 5c0df9af4d2545919e8f774c1159e7da lines 175-178) */}
          <rect x="95" y="95" width="50" height="50" rx="10" fill="#ffffff" />
          <rect x="100" y="100" width="40" height="40" rx="8" fill="#0037b0" />
          <path
            d="M112 120 L118 126 L128 114"
            fill="none"
            stroke="#ffffff"
            strokeWidth="4"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </div>

      <style>{`
        @keyframes scanLine {
          0% { top: 1.5rem; }
          100% { top: calc(100% - 1.5rem); }
        }
      `}</style>
    </div>
  );
};
