#!/bin/bash
# agent_model="${AGENT_MODEL:-gpt-4o-mini-2024-07-18}"
agent_model=gemini-2.5-flash
attack_name="tool_knowledge"
# defense_name="ipiguard"
defense_name="repeat_user_prompt"
suite_name="workspace"
# mode="benign"
mode="under_attack"

output_dir="evaluation_results/$(echo $suite_name | tr '/' '_')/$(echo $agent_model | tr '/' '_')/$(echo $mode | tr '/' '_')_$(echo $attack_name | tr ' ' '_')_$(echo $defense_name | tr ' ' '_')_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$output_dir"

python3 run/eval.py \
    --suite_name "$suite_name" \
    --agent_model "$agent_model" \
    --attack_name "$attack_name" \
    --defense_name "$defense_name" \
    --output_dir "$output_dir" \
    --mode "$mode" \
    --uid 0 \
    --iid 0 \
