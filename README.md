# Templates component

Greentic templating node powered by Handlebars. The only exposed operation is `text`.

- Implicit lookup: `{{name}}` resolves to `state.input.name` when not found at root.
- Debug strings: `{{state}}` / `{{payload}}` render compact JSON (use `{{{state}}}` for unescaped).
- Strict scoping: context is built only from the current tenant/team/user/session state and payload; rendering fails if scope identifiers are missing.

## Requirements

- Rust 1.89+
- `wasm32-wasip2` target (`rustup target add wasm32-wasip2`)

## Usage

Node authoring shape:

```yaml
nodes:
  my_template:
    templates:
      text: "My name is {{name}}"
      routing: out   # optional, defaults to out
```

Context model:
- `state`: in-flow execution snapshot injected by the runner when the input is an object. `state.input` is the original node input mapping; `state.nodes.<id>.payload` is a prior node output.
- `payload`: current input payload
- `node_id`: optional input field; when set, `node` and `node_payload` are resolved from `state.nodes.<node_id>`
- `{{state}}` / `{{payload}}`: compact JSON strings for debugging (triple-stash to avoid HTML escaping)

Examples:
- `My name is {{name}}` → pulls `state.input.name`
- `Payload: {{payload.name}}` → pulls from payload
- `Previous: {{node_payload.answer}}` → uses `node_id` to resolve `state.nodes.<node_id>.payload`
- `Debug: {{{state}}}` → raw JSON of state
- Control flow helpers work as usual: `{{#if state.active}}Hi{{/if}}`, `{{#each payload.items}}{{this}}{{/each}}`

## Develop

```bash
cargo build --target wasm32-wasip2
cargo test
greentic-component build --manifest ./component.manifest.json --no-flow --no-write-schema
```
