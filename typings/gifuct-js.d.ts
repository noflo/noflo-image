/** Minimal typing for gifuct-js, which ships without declarations. */
declare module "gifuct-js" {
  export interface ParsedGIF {
    header: { signature: string; version: string };
    lsd: { width: number; height: number };
    frames: unknown[];
  }
  export interface DecodedFrame {
    dims: { top: number; left: number; width: number; height: number };
    patch: Uint8ClampedArray;
    colorTable: number[][];
    delay: number;
    disposalType: number;
  }
  export function parseGIF(buffer: Uint8Array | ArrayBuffer): ParsedGIF;
  export function decompressFrames(
    gif: ParsedGIF,
    buildImagePatches: boolean,
  ): DecodedFrame[];
}
