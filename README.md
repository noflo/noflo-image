# noflo-image — Image processing for NoFlo

Image processing components for [NoFlo](https://noflojs.org): pixel adjustments and effects, dominant color extraction, histograms, computer-vision primitives (edge detection, feature corners, free-area finding), and image I/O.

Part of the NoFlo 2.x component library family. Requires Node.js >= 22, and runs on Deno and Bun as well.

## Isomorphic through the canvas engine

Most components operate on canvas objects from `@noflo/canvas` and its conditional-exports engine: native `OffscreenCanvas` in browsers, `pureimage` (pure JavaScript, no install scripts, no binaries) in Node.js. Components are single files that run unmodified in both environments.

## Usage

    npm install @noflo/image

Component identifiers in graphs are `image/<Component>`, for example `image/GetColors`. See `noflo.json` for the machine-readable component manifest.

## Components

- **I/O**: `image/UrlToBuffer` (fetch over HTTP(S)/data: URLs), `image/BufferToCanvas` (decode PNG/JPEG bytes), `image/CanvasToBuffer` (encode PNG bytes), `image/Measure` (dimensions from bytes), `image/GetGIFFrame` (GIF frame extraction with cumulative composition), `image/DetectAnimatedGif`, `image/ImageToCanvas`, `image/Crop`, `image/VideoToCanvas` (browser-only, guarded)
- **Adjustments**: `image/AdjustBrightness`, `image/AdjustContrast`, `image/AdjustSaturation`, `image/ApplyAdjustmentCurve` (with `image/GetPresetCurve` Instagram-style presets), `image/ApplyVignette` (browser engine; requires composite operations)
- **Analysis**: `image/GetHistogram` (RGBAY + HSCL), `image/GetColors`, `image/GetColorsFromRectangles`, `image/GetColorsFromCentroids`, `image/ExtractLightness`, `image/ExtractSaturation`, `image/CalculateAspectRatio`, `image/GetOrientation`
- **Computer vision** (vendored jsfeat subset): `image/GetCannyEdges`, `image/GetFeaturesYAPE`, `image/FindFeatureFreeAreas`, `image/FindFreeRectangles`, `image/GetBorderlessBox` — the rectangle/coverage logic these feed is what site-builder layout consumes

Components accept one canvas per activation; collections flow as streams or consistently-typed arrays.

## Dependencies

Pure JavaScript only: `culori` (color math), `file-type` (format sniffing), `image-size` (dimensions), `gifuct-js` (GIF decoding), `image-q` (color quantization), and the vendored jsfeat subset under `lib/vendor/` (MIT, upstream unmaintained). None require compilation, install scripts, or binaries. The GraphicsMagick external binary the 1.x library needed is gone.

## Development

    npm test

The test suite runs TypeScript checks, Biome lint, fbp-spec cases from `spec/`, and `node:test` suites from `test/` — including pixel-level regressions against the 1.x reference images in `test/fixtures/`.

## License

MIT
