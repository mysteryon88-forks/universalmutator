SHELL := /bin/bash
.ONESHELL:

PYTHON ?= python3
VENV ?= .venv
PIP := $(VENV)/bin/pip
MUTATE := $(VENV)/bin/mutate

TMP_DIR := tmp
TACT_OUT := /tmp/tact-out
TOLK_JSON := /tmp/tolk-out.json

# Tolk CLI via npx (TON)
TOLK_NPX := npx -y @ton/tolk-js
TOLK_CMD := $(TOLK_NPX) --output-json $(TOLK_JSON) MUTANT

.PHONY: help doctor venv install-um tolk-install tolk-check tact-check \
        mutate-tact mutate-tolk mutate-tact-only mutate-tolk-only clean

help:
	@echo "Targets:"
	@echo "  make doctor            - show toolchain availability"
	@echo "  make venv              - create venv"
	@echo "  make install-um         - install universalmutator into venv (editable)"
	@echo "  make tolk-install       - install Tolk CLI wrapper (@ton/tolk-js) globally"
	@echo "  make tolk-check         - compile examples/foo.tolk via npx"
	@echo "  make tact-check         - compile examples/foo.tact via tact"
	@echo "  make mutate-tact        - mutate Tact with compilation check"
	@echo "  make mutate-tolk        - mutate Tolk with compilation check (via npx)"
	@echo "  make mutate-*-only      - use only <lang>.rules (no universal/c_like)"
	@echo "  make clean              - remove tmp mutants"

doctor:
	@echo "python: $$($(PYTHON) --version 2>/dev/null || true)"
	@echo "venv: $(VENV)"
	@echo "node: $$(node --version 2>/dev/null || echo 'NOT FOUND')"
	@echo "npm:  $$(npm --version 2>/dev/null || echo 'NOT FOUND')"
	@echo "tact: $$(command -v tact >/dev/null && tact --version 2>/dev/null || echo 'NOT FOUND')"
	@echo "npx @ton/tolk-js: $$( $(TOLK_NPX) --help >/dev/null 2>&1 && echo 'OK' || echo 'NOT FOUND (run make tolk-install or use npx with internet)' )"
	@echo "mutate: $$(test -x $(MUTATE) && echo 'OK' || echo 'NOT FOUND (run make install-um)')"

venv:
	$(PYTHON) -m venv $(VENV)
	$(PIP) install -U pip

# Editable install. If you're offline, this may still work because it's local,
# but build isolation may try to pull setuptools; use --no-build-isolation.
install-um: venv
	$(PIP) install -e . --no-build-isolation --no-deps || true
	@echo "If 'mutate' is still missing, run: source $(VENV)/bin/activate && python -m universalmutator.genmutants --help"

# Optional: global install of tolk-js (still runs via npx)
tolk-install:
	npm i -g @ton/tolk-js

tolk-check:
	$(TOLK_NPX) --output-json $(TOLK_JSON) examples/foo.tolk
	@echo "OK: wrote $(TOLK_JSON)"

tact-check:
	tact examples/foo.tact --output $(TACT_OUT)
	@echo "OK: wrote $(TACT_OUT)"

mutate-tact:
	mkdir -p $(TMP_DIR)/mutants_tact
	$(MUTATE) examples/foo.tact tact \
		--cmd "tact MUTANT --output $(TACT_OUT)" \
		--mutantDir $(TMP_DIR)/mutants_tact

mutate-tact-only:
	mkdir -p $(TMP_DIR)/mutants_tact_only
	$(MUTATE) examples/foo.tact tact \
		--only tact.rules --noCheck \
		--mutantDir $(TMP_DIR)/mutants_tact_only

mutate-tolk:
	mkdir -p tmp/mutants_tolk
	mutate examples/foo.tolk tolk \
  	--cmd "npx -y @ton/tolk-js --output-json /tmp/tolk-out.json examples/foo.tolk" \
  	--mutantDir tmp/mutants_tolk


mutate-tolk-only:
	mkdir -p tmp/mutants_tolk_only
	mutate examples/foo.tolk tolk \
  	--cmd "npx -y @ton/tolk-js --only tolk.rules --noCheck \
		--mutantDir --output-json /tmp/tolk-out.json examples/foo.tolk" \
  	--mutantDir tmp/mutants_tolk_only

clean:
	rm -rf $(TMP_DIR)/mutants_tact* $(TMP_DIR)/mutants_tolk*
	rm -f $(TOLK_JSON)



FILE ?=
LOG_DIR := tmp/compile_logs
TACT_OUT_DIR := /tmp/tact-out
TOLK_JSON := /tmp/tolk-out.json

TACT ?= tact
TOLK_NPX := npx -y @ton/tolk-js

.PHONY: tact-validate tolk-validate

tact-validate:
	@bash -euo pipefail -c '\
	FILE="$(FILE)"; \
	if [ -z "$$FILE" ]; then \
	  echo "Usage: make tact-validate FILE=path/to/file.tact"; exit 2; \
	fi; \
	mkdir -p "$(LOG_DIR)" "$(TACT_OUT_DIR)"; \
	name="$${FILE##*/}"; \
	LOG="$(LOG_DIR)/tact_$${name}.log"; \
	echo "Compiling Tact: $$FILE"; \
	if "$(TACT)" "$$FILE" --output "$(TACT_OUT_DIR)" >"$$LOG" 2>&1; then \
	  echo "OK. Output: $(TACT_OUT_DIR)"; \
	  echo "Log: $$LOG"; \
	else \
	  rc="$$?"; \
	  echo "FAILED (exit $$rc). Log: $$LOG"; \
	  echo "---- error context (best effort) ----"; \
	  awk "BEGIN{p=0} /Error:/{p=1} {if(p) print}" "$$LOG" | sed -n "1,160p" || true; \
	  echo "---- tail ----"; \
	  tail -n 80 "$$LOG" || true; \
	  exit "$$rc"; \
	fi'

tolk-validate:
	@bash -euo pipefail -c '\
	FILE="$(FILE)"; \
	if [ -z "$$FILE" ]; then \
	  echo "Usage: make tolk-validate FILE=path/to/file.tolk"; exit 2; \
	fi; \
	mkdir -p "$(LOG_DIR)"; \
	name="$${FILE##*/}"; \
	LOG="$(LOG_DIR)/tolk_$${name}.log"; \
	rm -f "$(TOLK_JSON)" >/dev/null 2>&1 || true; \
	echo "Compiling Tolk (via npx @ton/tolk-js): $$FILE"; \
	if npx -y @ton/tolk-js --output-json "$(TOLK_JSON)" "$$FILE" >"$$LOG" 2>&1; then \
	  echo "OK. JSON: $(TOLK_JSON)"; \
	  echo "Log: $$LOG"; \
	else \
	  rc="$$?"; \
	  echo "FAILED (exit $$rc). Log: $$LOG"; \
	  echo "---- error context (best effort) ----"; \
	  grep -nEi "error|failed|exception" "$$LOG" | head -n 60 || true; \
	  echo "---- tail ----"; \
	  tail -n 120 "$$LOG" || true; \
	  exit "$$rc"; \
	fi'


# -----------------------------
# FunC (func) toolchain targets
# -----------------------------

# FunC outputs
FUNC_FIF  := /tmp/func-out.fif
FUNC_CELL := /tmp/func-out.cell
FILE_DEFAULT_FUNC := examples/foo.fc

.PHONY: func-install func-check func-validate func-build

func-install:
	@bash -euo pipefail -c '\
	npm i -g ton-compiler; \
	echo "OK: ton-compiler installed. Try: ton-compiler --help"'

# ✅ default check = validate (Fift-only)
func-check:
	@$(MAKE) func-validate FILE=$(FILE_DEFAULT_FUNC)

# ✅ Single-file validate: FunC -> Fift (no main required)
func-validate:
	@bash -euo pipefail -c '\
	FILE="$(FILE)"; \
	if [ -z "$$FILE" ]; then echo "Usage: make func-validate FILE=path/to/file.fc"; exit 2; fi; \
	if [ ! -f "$$FILE" ]; then echo "File not found: $$FILE"; exit 2; fi; \
	mkdir -p tmp/compile_logs; \
	LOG="tmp/compile_logs/func_$${FILE##*/}.log"; \
	rm -f "$(FUNC_FIF)" >/dev/null 2>&1 || true; \
	echo "Compiling FunC -> Fift (validate): $$FILE"; \
	if command -v ton-compiler >/dev/null; then \
	  ton-compiler --input "$$FILE" --output-fift "$(FUNC_FIF)" >"$$LOG" 2>&1; \
	else \
	  npx -y ton-compiler --input "$$FILE" --output-fift "$(FUNC_FIF)" >"$$LOG" 2>&1; \
	fi; \
	RC="$$?"; \
	if [ "$$RC" -eq 0 ]; then \
	  echo "OK. FIF: $(FUNC_FIF)"; echo "Log: $$LOG"; \
	else \
	  echo "FAILED (exit $$RC). Log: $$LOG"; \
	  grep -nEi "error|fatal|failed|line|parse|undefined" "$$LOG" | head -n 120 || true; \
	  tail -n 160 "$$LOG" || true; \
	  exit "$$RC"; \
	fi'

# ✅ Full build: FunC -> cell (+fift). Requires main.
func-build:
	@bash -euo pipefail -c '\
	FILE="$(FILE)"; \
	if [ -z "$$FILE" ]; then echo "Usage: make func-build FILE=path/to/file.fc"; exit 2; fi; \
	if [ ! -f "$$FILE" ]; then echo "File not found: $$FILE"; exit 2; fi; \
	mkdir -p tmp/compile_logs; \
	LOG="tmp/compile_logs/func_build_$${FILE##*/}.log"; \
	rm -f "$(FUNC_CELL)" "$(FUNC_FIF)" >/dev/null 2>&1 || true; \
	echo "Compiling FunC -> Cell: $$FILE"; \
	if command -v ton-compiler >/dev/null; then \
	  ton-compiler --input "$$FILE" --output "$(FUNC_CELL)" --output-fift "$(FUNC_FIF)" >"$$LOG" 2>&1; \
	else \
	  npx -y ton-compiler --input "$$FILE" --output "$(FUNC_CELL)" --output-fift "$(FUNC_FIF)" >"$$LOG" 2>&1; \
	fi; \
	RC="$$?"; \
	if [ "$$RC" -eq 0 ]; then \
	  echo "OK. CELL: $(FUNC_CELL)"; echo "FIF: $(FUNC_FIF)"; echo "Log: $$LOG"; \
	else \
	  echo "FAILED (exit $$RC). Log: $$LOG"; \
	  grep -nEi "main|procedure|entry|error|fatal|failed" "$$LOG" | head -n 160 || true; \
	  tail -n 200 "$$LOG" || true; \
	  exit "$$RC"; \
	fi'

.PHONY: mutate-func

# Usage:
#   make mutate-func FILE=path/to/file.fc
# Mutants go to: tmp/mutants_func
mutate-func:
	@bash -euo pipefail -c '\
	FILE="$(FILE)"; \
	if [ -z "$$FILE" ]; then \
	  echo "Usage: make mutate-func FILE=path/to/file.fc"; exit 2; \
	fi; \
	if [ ! -f "$$FILE" ]; then \
	  echo "File not found: $$FILE"; exit 2; \
	fi; \
	mkdir -p tmp/mutants_func; \
	echo "Mutating FunC with compile-check (Fift-only): $$FILE"; \
	.venv/bin/mutate "$$FILE" func \
	  --cmd "bash -lc '\''rm -f $(FUNC_FIF) >/dev/null 2>&1 || true; \
	    if command -v ton-compiler >/dev/null; then \
	      ton-compiler --input \"$$FILE\" --output-fift $(FUNC_FIF); \
	    else \
	      npx -y ton-compiler --input \"$$FILE\" --output-fift $(FUNC_FIF); \
	    fi'\''" \
	  --mutantDir tmp/mutants_func'


