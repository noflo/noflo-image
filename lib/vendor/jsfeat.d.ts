/** Typings for the vendored jsfeat build, covering the subset the CV
 * components use. */
export interface Matrix {
  cols: number;
  rows: number;
  data: Uint8Array | Int32Array | Float32Array | Float64Array;
  buffer: ArrayBuffer;
  resize(w: number, h: number, new_type?: number): void;
  new_data(w: number, h: number, type: number): void;
}
export interface Keypoint {
  x: number;
  y: number;
  score: number;
  level: number;
  angle: number;
}
export interface Yape06 {
  laplacian_threshold: number;
  min_eigen_value_threshold: number;
  detect(img: Matrix, points: Keypoint[]): number;
}
export interface ImgProc {
  grayscale(
    src: Uint8ClampedArray,
    w: number,
    h: number,
    dst: Matrix,
    code?: number,
  ): void;
  gaussian_blur(src: Matrix, dst: Matrix, radius: number, sigma: number): void;
  box_blur_gray(
    src: Matrix,
    dst: Matrix,
    radius: number,
    options: number,
  ): void;
  canny(src: Matrix, dst: Matrix, low: number, high: number): void;
}
export interface MatrixConstructor {
  new (
    cols: number,
    rows: number,
    type?: number,
    data_buffer?: Uint8Array | null,
  ): Matrix;
}
export interface KeypointConstructor {
  new (
    x: number,
    y: number,
    score: number,
    level?: number,
    angle?: number,
  ): Keypoint;
}

export default class JSFeat {
  static REVISION: string;
  static U8_t: number;
  static S32_t: number;
  static F32_t: number;
  static F64_t: number;
  static C1_t: number;
  static C2_t: number;
  static C3_t: number;
  static C4_t: number;
  static COLOR_RGBA2GRAY: number;
  static COLOR_RGB2GRAY: number;
  static matrix_t: MatrixConstructor;
  static keypoint_t: KeypointConstructor;
  static imgproc: ImgProc;
  static yape06: Yape06;
}
