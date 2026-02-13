#!/bin/bash
set -euo pipefail

PROJECT_ROOT=${PROJECT_ROOT_OVERRIDE:-/dcs/pg25/u5728153/Projects/BFTGraphGuard}

cd "$PROJECT_ROOT"

export PYTHONPATH="$PROJECT_ROOT"
export OLLAMA_MODELS="${OLLAMA_MODELS_OVERRIDE:-/dcs/large/u5728153/ollama/models}"

# IMPORTANT: point to your GPU-enabled ollama binary (NOT the conda one)
OLLAMA_BIN="${OLLAMA_BIN_OVERRIDE:-/dcs/pg25/u5728153/ollama/bin/ollama}"

# Bind Ollama to a dedicated local port for this job
export OLLAMA_HOST="${OLLAMA_HOST_OVERRIDE:-127.0.0.1:11438}"
export OLLAMA_BASE_URL="http://$OLLAMA_HOST/v1"

# If you want to force a specific GPU, set CUDA_VISIBLE_DEVICES_OVERRIDE
export CUDA_VISIBLE_DEVICES=0

OLLAMA_LOG="${OLLAMA_LOG_OVERRIDE:-ollama_server.log}"

AGENT_MODEL=llama3.3:70b
ATTACK_NAME=tool_knowledge
DEFENSE_NAME=repeat_user_prompt
SUITE_NAME=workspace
MODE=under_attack

OUTPUT_ROOT=/dcs/large/u5728153/dataset/bft_graph_guard/evaluation_results
OUTPUT_DIR="$OUTPUT_ROOT/$(echo "$SUITE_NAME" | tr '/' '_')/$(echo "$AGENT_MODEL" | tr '/' '_')/$(echo "$MODE" | tr '/' '_')_$(echo "$ATTACK_NAME" | tr ' ' '_')_$(echo "$DEFENSE_NAME" | tr ' ' '_')_$(date +%Y%m%d_%H%M%S)"


mkdir -p "$OUTPUT_DIR"

# Start server
"$OLLAMA_BIN" serve >"$OLLAMA_LOG" 2>&1 &
OLLAMA_PID=$!

cleanup() {
  # Kill server + any runners it spawned
  if kill -0 "$OLLAMA_PID" 2>/dev/null; then
    kill "$OLLAMA_PID" || true
    wait "$OLLAMA_PID" || true
  fi
  pkill -P "$OLLAMA_PID" 2>/dev/null || true
}
trap cleanup EXIT

# Wait until the server is actually ready
for i in {1..60}; do
  if curl -fsS "http://$OLLAMA_HOST/api/version" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "=== GPU status ==="
nvidia-smi || true

echo "=== Ollama status ==="
"$OLLAMA_BIN" ps || true
"$OLLAMA_BIN" list || true

PYTHON_BIN=/dcs/pg25/u5728153/.conda/envs/phong/bin/python3.11

"$PYTHON_BIN" run/eval.py \
  --suite_name "$SUITE_NAME" \
  --agent_model "$AGENT_MODEL" \
  --attack_name "$ATTACK_NAME" \
  --defense_name "$DEFENSE_NAME" \
  --output_dir "$OUTPUT_DIR" \
  --mode "$MODE" \
  --uid 0 \
  --iid 0
