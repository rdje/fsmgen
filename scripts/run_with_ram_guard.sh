#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=project_data_locality_env.sh
source "${SCRIPT_DIR}/project_data_locality_env.sh"

host_max_pct="${FSMGEN_RAM_GUARD_HOST_MAX_PCT:-88}"
process_max_rss_mb="${FSMGEN_RAM_GUARD_PROCESS_MAX_RSS_MB:-4096}"
poll_seconds="${FSMGEN_RAM_GUARD_POLL_SECONDS:-2}"
grace_seconds="${FSMGEN_RAM_GUARD_GRACE_SECONDS:-5}"

usage() {
    cat <<'USAGE'
Usage:
  scripts/run_with_ram_guard.sh [options] -- command [args...]

Options:
  --host-max-pct N          Stop when host memory usage is >= N percent.
                            Default: FSMGEN_RAM_GUARD_HOST_MAX_PCT or 88.
  --process-max-rss-mb N    Stop when any descendant RSS is >= N MiB.
                            Default: FSMGEN_RAM_GUARD_PROCESS_MAX_RSS_MB or 4096.
  --poll-seconds N          Monitor interval in seconds.
                            Default: FSMGEN_RAM_GUARD_POLL_SECONDS or 2.
  --grace-seconds N         Seconds between TERM and KILL after a trip.
                            Default: FSMGEN_RAM_GUARD_GRACE_SECONDS or 5.
  -h, --help                Show this help.

Examples:
  scripts/run_with_ram_guard.sh -- prove -Iperl t/248-regression-corpus-accounting.t
  scripts/run_with_ram_guard.sh --process-max-rss-mb 3072 -- ./bin/fsmgen --check-json ppif/axi_aw_valid_ready.ppif

The wrapper monitors the command and all descendants. A guard trip exits 137.
USAGE
}

die() {
    echo "ram-guard: $*" >&2
    exit 2
}

is_number() {
    awk -v n="$1" 'BEGIN { exit !(n ~ /^[0-9]+([.][0-9]+)?$/) }'
}

number_ge() {
    awk -v a="$1" -v b="$2" 'BEGIN { exit !(a >= b) }'
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --host-max-pct)
            [ "$#" -ge 2 ] || die "--host-max-pct requires a value"
            host_max_pct="$2"
            shift 2
            ;;
        --process-max-rss-mb)
            [ "$#" -ge 2 ] || die "--process-max-rss-mb requires a value"
            process_max_rss_mb="$2"
            shift 2
            ;;
        --poll-seconds)
            [ "$#" -ge 2 ] || die "--poll-seconds requires a value"
            poll_seconds="$2"
            shift 2
            ;;
        --grace-seconds)
            [ "$#" -ge 2 ] || die "--grace-seconds requires a value"
            grace_seconds="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            die "unknown option: $1"
            ;;
        *)
            break
            ;;
    esac
done

[ "$#" -gt 0 ] || die "missing command; use -- before the command"

is_number "$host_max_pct" || die "host cutoff must be numeric"
is_number "$process_max_rss_mb" || die "process RSS cutoff must be numeric"
is_number "$poll_seconds" || die "poll interval must be numeric"
is_number "$grace_seconds" || die "grace interval must be numeric"

process_max_rss_kb=$(awk -v mb="$process_max_rss_mb" 'BEGIN { printf "%d", mb * 1024 }')

host_memory_pct() {
    if command -v vm_stat >/dev/null 2>&1 && command -v sysctl >/dev/null 2>&1; then
        if total_bytes=$(sysctl -n hw.memsize 2>/dev/null); then
            vm_stat 2>/dev/null | awk -v total="$total_bytes" '
                /page size of/ { page_size = $8 + 0 }
                /^Pages free:/ {
                    value = $3
                    gsub(/[^0-9]/, "", value)
                    free_pages = value + 0
                }
                /^Pages speculative:/ {
                    value = $3
                    gsub(/[^0-9]/, "", value)
                    speculative_pages = value + 0
                }
                END {
                    if (total <= 0 || page_size <= 0) {
                        exit 1
                    }
                    available = (free_pages + speculative_pages) * page_size
                    used = total - available
                    if (used < 0) {
                        used = 0
                    }
                    printf "%.1f", (used * 100.0) / total
                }
            '
            return $?
        fi
    fi

    if command -v memory_pressure >/dev/null 2>&1; then
        memory_pressure 2>/dev/null | awk '
            /^The system has/ {
                total = $4 + 0
                for (i = 1; i <= NF; i++) {
                    if ($i == "of" && (i + 1) <= NF) {
                        value = $(i + 1)
                        gsub(/[^0-9]/, "", value)
                        page_size = value + 0
                    }
                }
            }
            /^Pages free:/ { free_pages = $3 + 0 }
            /^Pages speculative:/ { speculative_pages = $3 + 0 }
            END {
                if (total <= 0 || page_size <= 0) {
                    exit 1
                }
                available = (free_pages + speculative_pages) * page_size
                used = total - available
                if (used < 0) {
                    used = 0
                }
                printf "%.1f", (used * 100.0) / total
            }
        '
        return $?
    fi

    if [ -r /proc/meminfo ]; then
        awk '
            /^MemTotal:/ { total = $2 }
            /^MemAvailable:/ { available = $2 }
            END {
                if (total <= 0 || available <= 0) {
                    exit 1
                }
                printf "%.1f", ((total - available) * 100.0) / total
            }
        ' /proc/meminfo
        return $?
    fi

    return 1
}

list_tree_pids() {
    root_pid="$1"
    all_pids="$root_pid"
    changed=1

    while [ "$changed" -eq 1 ]; do
        changed=0
        ps_rows=$(ps -axo pid=,ppid= 2>/dev/null) || {
            printf '%s\n' "$root_pid"
            return 0
        }
        children=$(printf '%s\n' "$ps_rows" | awk -v roots="$all_pids" '
            BEGIN {
                count = split(roots, root_array, " ")
                for (i = 1; i <= count; i++) {
                    if (root_array[i] != "") {
                        root[root_array[i]] = 1
                    }
                }
            }
            {
                pid = $1
                ppid = $2
                if (root[ppid]) {
                    print pid
                }
            }
        ')
        for child_pid in $children; do
            case " $all_pids " in
                *" $child_pid "*) ;;
                *)
                    all_pids="$all_pids $child_pid"
                    changed=1
                    ;;
            esac
        done
    done

    printf '%s\n' $all_pids
}

rss_kb_for_pid() {
    ps -o rss= -p "$1" 2>/dev/null | awk 'NF { print $1 + 0; exit }'
}

command_for_pid() {
    ps -o command= -p "$1" 2>/dev/null | sed -n '1p'
}

terminate_tree() {
    reason="$1"
    pids=$(list_tree_pids "$root_pid")
    echo "ram-guard: $reason" >&2
    echo "ram-guard: terminating PID tree: $(printf '%s ' $pids)" >&2
    kill -TERM $pids 2>/dev/null || true
    sleep "$grace_seconds"
    pids=$(list_tree_pids "$root_pid")
    if [ -n "$pids" ]; then
        kill -KILL $pids 2>/dev/null || true
    fi
}

ps -axo pid=,ppid= >/dev/null 2>&1 \
    || die "process-tree inspection is unavailable; rerun outside the sandbox or with process-inspection approval"
ps -o rss= -p "$$" >/dev/null 2>&1 \
    || die "process RSS inspection is unavailable; rerun outside the sandbox or with process-inspection approval"
initial_host_pct=$(host_memory_pct) \
    || die "host memory inspection is unavailable; use an equivalent active monitor before running heavyweight commands"

"$@" &
root_pid=$!

echo "ram-guard: PID $root_pid; host ${initial_host_pct}%; host cutoff ${host_max_pct}%; descendant RSS cutoff ${process_max_rss_mb} MiB; poll ${poll_seconds}s" >&2

while kill -0 "$root_pid" 2>/dev/null; do
    if host_pct=$(host_memory_pct); then
        if number_ge "$host_pct" "$host_max_pct"; then
            terminate_tree "host memory ${host_pct}% reached cutoff ${host_max_pct}%"
            wait "$root_pid" 2>/dev/null || true
            exit 137
        fi
    else
        terminate_tree "host memory usage became unavailable while command was running"
        wait "$root_pid" 2>/dev/null || true
        exit 137
    fi

    for pid in $(list_tree_pids "$root_pid"); do
        rss_kb=$(rss_kb_for_pid "$pid")
        [ -n "$rss_kb" ] || continue
        if [ "$rss_kb" -ge "$process_max_rss_kb" ]; then
            rss_mb=$(awk -v kb="$rss_kb" 'BEGIN { printf "%.1f", kb / 1024.0 }')
            command_text=$(command_for_pid "$pid")
            terminate_tree "PID $pid RSS ${rss_mb} MiB reached cutoff ${process_max_rss_mb} MiB: ${command_text}"
            wait "$root_pid" 2>/dev/null || true
            exit 137
        fi
    done

    sleep "$poll_seconds"
done

wait "$root_pid"
exit $?
