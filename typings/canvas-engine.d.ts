/**
 * Contract typings for the `@noflo/canvas` engine, mirroring
 * `@noflo/canvas/lib/engines/types.js`. Declared locally instead of
 * importing the engine sources: strict tsconfigs in dependent packages
 * would otherwise type-check the whole engine implementation under this
 * package's flags (the workspace strict-tsconfig trap).
 */
declare module "@noflo/canvas/engine" {
  /** The Web Canvas 2D method subset the drawing components rely on. */
  export interface EngineContext {
    fillStyle: string;
    strokeStyle: string;
    lineWidth: number;
    beginPath(): void;
    closePath(): void;
    moveTo(x: number, y: number): void;
    lineTo(x: number, y: number): void;
    bezierCurveTo(
      control1x: number,
      control1y: number,
      control2x: number,
      control2y: number,
      endx: number,
      endy: number,
    ): void;
    arc(
      x: number,
      y: number,
      radius: number,
      startAngle: number,
      endAngle: number,
      counterclockwise?: boolean,
    ): void;
    fill(): void;
    stroke(): void;
    fillRect(x: number, y: number, width: number, height: number): void;
    strokeRect(x: number, y: number, width: number, height: number): void;
    clearRect(x: number, y: number, width: number, height: number): void;
    drawImage(image: CanvasLike, ...rest: number[]): void;
    translate(x: number, y: number): void;
    rotate(angle: number): void;
    scale(x: number, y: number): void;
    save(): void;
    restore(): void;
    createRadialGradient(
      x0: number,
      y0: number,
      r0: number,
      x1: number,
      y1: number,
      r1: number,
    ): { addColorStop(offset: number, color: string): void };
    getImageData(
      x: number,
      y: number,
      width: number,
      height: number,
    ): { data: Uint8ClampedArray; width: number; height: number };
    putImageData(
      imageData: { data: Uint8ClampedArray; width: number; height: number },
      dx: number,
      dy: number,
    ): void;
  }

  /** A canvas object: dimensions plus a 2D context. */
  export interface CanvasLike {
    width: number;
    height: number;
    getContext(mode: "2d"): EngineContext;
  }

  export function createCanvas(width: number, height: number): CanvasLike;
  export function canvasToPng(canvas: CanvasLike): Promise<Uint8Array>;
  export function canvasToJpeg(canvas: CanvasLike): Promise<Uint8Array>;
  export function decodeImage(bytes: Uint8Array): Promise<CanvasLike>;
}
