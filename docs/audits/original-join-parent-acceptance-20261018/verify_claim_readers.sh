#!/usr/bin/env bash
# Preserve the claim fact card's complete saved-reader reverify sequence.
set -euo pipefail

cd -- "$(git -C "$(dirname -- "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
task_reader_audit=docs/audits/original-join-parent-acceptance-20261018
task_reader_list=false
case "${1:-}" in
    '') ;;
    --list) task_reader_list=true ;;
    *) printf 'Usage: bash %s [--list]\n' "$0" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || exit 2

run_saved_reader() {
    if "$task_reader_list"; then
        printf '%q ' "$@"
        printf '\n'
    else
        "$@"
    fi
}

run_saved_reader scripts/check_claim_verification.pl
run_saved_reader prove -Iperl t/1636-claim-verification-doctrine.t
for task_reader in verify_{failed,corrected_failed,snapshot_failed} selected_intake epoch_constraints verify_{selected_failed,runtime_cache} default_dispatch qualify_{fixed_module_gap,caller_modules} operand_inventory ast_model_inputs preparation_correction compile_only_inputs operand_allocation qualify_operand_allocation payload_closure rollover_source_card canonical_contracts check_canonical_progress qualify_selected_intake_roles qualify_runtime_cache_roles qualify_default_dispatch_roles qualify_fixed_gap_roles qualify_caller_roles qualify_operand_roles qualify_ast_input_roles; do
    run_saved_reader python3 -B "$task_reader_audit/$task_reader.py"
done
run_saved_reader python3 -B "$task_reader_audit/live_operand_route.py" --current
