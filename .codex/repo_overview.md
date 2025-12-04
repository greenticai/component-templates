# Repository Overview

## 1. High-Level Purpose
- Rust/WASI-P2 Greentic component that renders Handlebars templates using invocation envelopes containing config, message, payload, and state.
- Targets the Greentic node world (`greentic:component/component@0.4.0`), producing formatted payloads without mutating state or performing routing.

## 2. Main Components and Functionality
- **Path:** src/lib.rs  
  **Role:** Component implementation and wasm exports.  
  **Key functionality:** Parses invocation JSON into `{config, msg: ChannelMessageEnvelope, payload, state}`; builds a Handlebars context `{msg, payload, state}`; renders templates with optional `output_path` (dotted nesting) and `wrap` (default true → `{ "text": ... }`, false → raw string); returns `ComponentResult` JSON with payload, empty `state_updates`, optional `TemplateError` (includes message and optional line/column details); exposes Greentic node exports for wasm invoke/stream/lifecycle.  
  **Key dependencies / integration points:** `handlebars`, `serde`/`serde_json`; `greentic-types` for message/context types; `greentic-interfaces-guest` for wasm exports when targeting wasm.
- **Path:** schemas/component.schema.json  
  **Role:** JSON Schema for component configuration.  
  **Key functionality:** Requires `template` string; optional `output_path` (default `text`) and `wrap` (default `true`).
- **Path:** schemas/io/input.schema.json  
  **Role:** JSON Schema for invocation input.  
  **Key functionality:** Documents invocation envelope fields (`config`, `msg`, `payload`, `state`, optional `connections`).
- **Path:** schemas/io/output.schema.json  
  **Role:** JSON Schema for invocation output.  
  **Key functionality:** Default payload `{ "text": "<rendered>" }`; describes optional error/control objects.
- **Path:** component.manifest.json  
  **Role:** Greentic component manifest describing world/version, capabilities (messaging, telemetry, WASI opts), resource limits, artifact path/hash (blake3 updated after release build).
- **Path:** tests/conformance.rs  
  **Role:** Integration tests verifying manifest world value, template rendering, and TemplateError reporting.
- **Path:** ci/local_check.sh  
  **Role:** Local helper script running `cargo fmt`, `cargo clippy --all-targets -D warnings`, and `cargo test`.
- **Path:** Makefile  
  **Role:** Convenience targets for `build`/`check` (wasm32-wasip2), `lint`, and `test`.

## 3. Work In Progress, TODOs, and Stubs
- No explicit TODO/FIXME/stub markers found.

## 4. Broken, Failing, or Conflicting Areas
- No failing tests or known conflicts after `cargo test`.

## 5. Notes for Future Work
- Regenerate manifest hash after producing the wasm artifact once functionality stabilizes or if the wasm changes.
