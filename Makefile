.PHONY: build test lint check flows wasm

BUILD_FLAGS ?=

default: build

build:
	greentic-component build --manifest ./component.manifest.json $(BUILD_FLAGS)

flows:
	greentic-component flow update

wasm:
	if cargo component --version >/dev/null 2>&1; then \
		cargo component build --release --target wasm32-wasip2; \
	else \
		cargo build --target wasm32-wasip2 --release; \
	fi

check:
	@WASM_PATH=$$(find target -type f -name component_templates.wasm ! -path '*/deps/*' | head -n1); \
	if [ -z "$$WASM_PATH" ]; then \
		echo "component_templates.wasm not found under target/"; \
		exit 1; \
	fi; \
	greentic-component doctor "$$WASM_PATH" --manifest ./component.manifest.json

lint:
	cargo fmt --all
	cargo clippy --workspace --all-targets -- -D warnings

test:
	cargo test --workspace --all-targets
