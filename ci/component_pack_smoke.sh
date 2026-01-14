#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
KEEP_TEMP="${KEEP_TEMP:-0}"
PACK_DIR="${TMP_DIR}/pack"
PACK_ID="ai.greentic.component-templates-test"
FLOW_ID="ai.greentic.component-templates.test"
NODE_ID="templates_step"
COMPONENT_ID="ai.greentic.component-templates"
FLOW_FILE="${PACK_DIR}/flows/templates.ygtc"
WASM_SRC="${ROOT_DIR}/target/wasm32-wasip2/release/component_templates.wasm"

cleanup() {
  if [[ "${KEEP_TEMP}" == "1" ]]; then
    return
  fi
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "Temp dir: ${TMP_DIR}"

make -C "${ROOT_DIR}" build

if [[ ! -f "${WASM_SRC}" ]]; then
  echo "Missing wasm artifact at ${WASM_SRC}" >&2
  exit 1
fi

greentic-pack new --dir "${PACK_DIR}" "${PACK_ID}"
mkdir -p "${PACK_DIR}/components"
cp "${WASM_SRC}" "${PACK_DIR}/components/${COMPONENT_ID}.wasm"

greentic-flow new \
  --flow "${FLOW_FILE}" \
  --id "${FLOW_ID}" \
  --type messaging \
  --name "Templates smoke" \
  --description "Smoke test for component-templates"

cat > "${TMP_DIR}/payload.json" <<'JSON'
{
  "config": {
    "templates": {
      "text": "helo: {{{state}}}",
      "output_path": "text",
      "wrap": true
    }
  },
  "msg": {
    "id": "msg-1",
    "tenant": {
      "env": "dev",
      "tenant": "tenant",
      "tenant_id": "tenant",
      "session_id": "session-1",
      "attempt": 1
    },
    "channel": "chat",
    "session_id": "session-1",
    "user_id": null,
    "text": "hello",
    "attachments": [],
    "metadata": {}
  },
  "payload": {
    "seed": "input"
  }
}
JSON

greentic-flow add-step \
  --flow "${FLOW_FILE}" \
  --node-id "${NODE_ID}" \
  --operation text \
  --payload "$(cat "${TMP_DIR}/payload.json")" \
  --local-wasm "${PACK_DIR}/components/${COMPONENT_ID}.wasm" \
  --routing-out

greentic-pack update --in "${PACK_DIR}"
greentic-pack build --in "${PACK_DIR}"

PACK_ARCHIVE="${PACK_DIR}/dist/$(basename "${PACK_DIR}").gtpack"
RUN_OUTPUT="$(greentic-runner-cli --pack "${PACK_ARCHIVE}" --flow "${FLOW_ID}" --input '{}' --json | tail -n 1)"

ARTIFACTS_DIR="$(echo "${RUN_OUTPUT}" | rg -o '"artifacts_dir":"[^"]+"' | head -n1 | sed 's/.*"artifacts_dir":"//;s/"$//')"
if [[ -z "${ARTIFACTS_DIR}" ]]; then
  echo "Could not locate artifacts_dir in runner output." >&2
  echo "${RUN_OUTPUT}" >&2
  exit 1
fi

ARTIFACTS_PATH="${ROOT_DIR}/${ARTIFACTS_DIR#./}"
TRANSCRIPT="${ARTIFACTS_PATH}/transcript.jsonl"
if [[ ! -f "${TRANSCRIPT}" ]]; then
  echo "Missing transcript at ${TRANSCRIPT}" >&2
  exit 1
fi

OUTPUT_LINE="$(rg '"phase":"end"' "${TRANSCRIPT}" | tail -n 1)"
if command -v jq >/dev/null 2>&1; then
  RENDERED="$(echo "${OUTPUT_LINE}" | jq -r '.. | strings | select(test("helo:"))' | head -n 1)"
  if [[ -z "${RENDERED}" ]]; then
    echo "Did not find rendered template output in transcript." >&2
    echo "${OUTPUT_LINE}" >&2
    exit 1
  fi
  echo "${RENDERED}" | rg -q 'input' || {
    echo "Rendered output did not include injected state." >&2
    echo "${RENDERED}" >&2
    exit 1
  }
else
  echo "${OUTPUT_LINE}" | rg -q 'helo:' || {
    echo "Did not find rendered template output in transcript." >&2
    echo "${OUTPUT_LINE}" >&2
    exit 1
  }
  echo "${OUTPUT_LINE}" | rg -q 'input' || {
    echo "Rendered output did not include injected state." >&2
    echo "${OUTPUT_LINE}" >&2
    exit 1
  }
fi

echo "Smoke test passed."
