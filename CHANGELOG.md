# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- Package renamed to `@noflo/image`; the version resets to the 2.x generation (2.0.0-alpha.1) for the fresh package name. Component addressing is unchanged — library IDs derive identically from the scoped name, so component and graph names stay the same. The old `noflo-image` will be deprecated with a pointer once 2.x reaches stable
- Migrated to NoFlo 2.x: components now depend on `@noflo/noflo` ^2.0.0 instead of the unscoped `noflo` 1.x package; components export a named `getComponent`
- Package is now plain ESM with no build step; supported runtime is Node.js >= 22 (components also run under Deno and Bun); indentation normalized to spaces per the repository EditorConfig
- Removed the GraphicsMagick (`gm`) external-binary dependency: `image/GetGIFFrame` decodes GIFs with `gifuct-js` and composes frames cumulatively onto a canvas. Frames using the restore-to-previous disposal method render slightly differently than in a full animation player
- Replaced deprecated/unmaintained dependencies: `request`/`superagent` → global `fetch`, `read-chunk` → `file-type` v21 direct buffer input, `animated-gif-detector` → a direct GIF NETSCAPE2.0 extension check, `rgbquant` → `image-q`, `d3-color` → `culori`, `tmp`/`graceful-logger`/`urijs` dropped entirely. `chroma-js` was already unused
- `jsfeat` 0.0.8 is vendored wholesale under `lib/vendor/` (MIT, upstream unmaintained) instead of being depended on
- Components now operate on canvases from `@noflo/canvas`'s conditional-exports engine, keeping every component isomorphic; the 1.x `-node`/browser component pairs are merged into single files
- `image/UrlToBuffer` and `image/Measure` handle HTTP(S) and data: URLs via `fetch`; local file paths are out of scope — read files with `@noflo/filesystem` and feed the bytes. `image/UrlToTempFile` and `image/CreateImage` are removed in favor of byte-flow composition (`UrlToBuffer` → `BufferToCanvas`)
- `image/CanvasToBuffer` emits PNG image bytes (`Uint8Array`) instead of the node-canvas buffer
- `image/Fill`-style addressable collection semantics follow the 2.x per-activation contract
- `image/VideoToCanvas` draws one frame per activation instead of installing an animation loop; it fails explicitly outside a browser environment instead of crashing on the missing DOM
- `image/GetColors` drops the `method` port: rgbquant's histogram methods have no image-q equivalent
- `image/ApplyVignette` fails explicitly on canvas engines without composite operations instead of silently rendering a wrong-looking result
- Removed the 1.x `UrlToCanvas` example graph; the 1.x spec fixtures moved to `test/fixtures/`

### Fixed

- `image/FindFreeRectangles` kept its validity grid in module-level state, corrupting concurrent activations; the grid is now local to each activation
- `image/ToFullscale`'s wikimedia converter computed a replacement URL but never assigned it, so it always returned the original
- `image/GetCannyEdges` called jsfeat's `grayscale` with two arguments instead of four and read its thresholds from undefined class properties, so it never produced correct edges
- `image/GetPresetCurve` passed an Error to `output.done` instead of reporting on an error port
- Unparseable images and failed fetches are reported on `error` ports with `output.error()` instead of throwing inside the process function

### Added

- `test/` suites covering every component group, plus pixel-level regressions against the 1.x reference fixture images (brightness, contrast, saturation, color curve)
- A generated minimal 2-frame animated GIF fixture for GIF tests
- `spec/` fbp-spec cases for the data-in/data-out components
- Publish-time `noflo.json` component manifest
