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

The wrapper requires Python 3 and monitors an owned session, including nested
process groups. A guard trip exits 137.
Standard input is passed through to the command, including piped and file input.
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
    os_name=$(uname -s 2>/dev/null) || return 1

    if [ "$os_name" = "Darwin" ] \
            && command -v vm_stat >/dev/null 2>&1 \
            && command -v sysctl >/dev/null 2>&1; then
        if total_bytes=$(sysctl -n hw.memsize 2>/dev/null); then
            vm_stat 2>/dev/null | awk -v total="$total_bytes" '
                function counter_value(line, value) {
                    value = line
                    sub(/^[^:]*:[[:space:]]*/, "", value)
                    sub(/[[:space:]].*$/, "", value)
                    if (value !~ /^[0-9]+[.]?$/) {
                        return -1
                    }
                    sub(/[.]$/, "", value)
                    return value + 0
                }

                /page size of/ {
                    value = $0
                    sub(/^.*page size of[[:space:]]+/, "", value)
                    sub(/[[:space:]].*$/, "", value)
                    if (value ~ /^[0-9]+$/ && value > 0) {
                        page_size = value + 0
                        saw_page_size = 1
                    }
                }
                /^Pages active:/ {
                    active = counter_value($0)
                    saw_active = active >= 0
                }
                /^Pages inactive:/ {
                    inactive = counter_value($0)
                    saw_inactive = inactive >= 0
                }
                /^Pages speculative:/ {
                    speculative = counter_value($0)
                    saw_speculative = speculative >= 0
                }
                /^Pages wired down:/ {
                    wired = counter_value($0)
                    saw_wired = wired >= 0
                }
                /^Pages purgeable:/ {
                    purgeable = counter_value($0)
                    saw_purgeable = purgeable >= 0
                }
                /^File-backed pages:/ {
                    file_backed = counter_value($0)
                    saw_file_backed = file_backed >= 0
                }
                /^Pages occupied by compressor:/ {
                    compressed = counter_value($0)
                    saw_compressed = compressed >= 0
                }
                END {
                    if (total !~ /^[0-9]+$/ || total <= 0 ||
                            !saw_page_size || !saw_active || !saw_inactive ||
                            !saw_speculative || !saw_wired ||
                            !saw_purgeable || !saw_file_backed ||
                            !saw_compressed) {
                        exit 1
                    }

                    # Stats-compatible occupied capacity. File-backed and
                    # purgeable pages are reclaimable; compressed pages remain
                    # occupied physical capacity.
                    used_pages = active + inactive + speculative + wired \
                        + compressed - purgeable - file_backed
                    used = used_pages * page_size
                    if (used < 0) {
                        exit 1
                    }
                    if (used > total) {
                        used = total
                    }
                    printf "%.1f", (used * 100.0) / total
                }
            '
            return $?
        fi
    fi

    if [ "$os_name" = "Linux" ] && [ -r /proc/meminfo ]; then
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

# The launcher retains its session identity until all command members finish.
# Reparented children and nested groups keep the same session membership.
list_session_pids() {
    python3 -B "${SCRIPT_DIR}/ram_guard_session.py" members "$root_pid"
}

rss_kb_for_pid() {
    ps -o rss= -p "$1" 2>/dev/null | awk 'NF { print $1 + 0; exit }'
}

command_for_pid() {
    ps -o command= -p "$1" 2>/dev/null | sed -n '1p'
}

terminate_session() {
    echo "ram-guard: $1" >&2
    echo "ram-guard: terminating owned session: $root_pid" >&2
    if ! python3 -B "${SCRIPT_DIR}/ram_guard_session.py" terminate "$root_pid" "$grace_seconds"; then
        echo "ram-guard: owned session cleanup is incomplete" >&2
        return 1
    fi
    wait "$root_pid" 2>/dev/null || true
}

ps -axo pid=,pgid=,stat= >/dev/null 2>&1 \
    || die "session inspection is unavailable; rerun outside the sandbox or with process-inspection approval"
ps -o rss= -p "$$" >/dev/null 2>&1 \
    || die "process RSS inspection is unavailable; rerun outside the sandbox or with process-inspection approval"
command -v python3 >/dev/null 2>&1 || die "Python 3 is required for owned session supervision"
initial_host_pct=$(host_memory_pct) \
    || die "host memory inspection is unavailable; use an equivalent active monitor before running heavyweight commands"
if number_ge "$initial_host_pct" "$host_max_pct"; then
    echo "ram-guard: host ${initial_host_pct}%; host cutoff ${host_max_pct}%; descendant RSS cutoff ${process_max_rss_mb} MiB" >&2
    echo "ram-guard: host memory ${initial_host_pct}% reached cutoff ${host_max_pct}% before command launch" >&2
    exit 137
fi

# Child workflows may record the effective active safety envelope without
# re-parsing this launcher's command line or inventing a second guard state.
export FSMGEN_RAM_GUARD_ACTIVE=1
export FSMGEN_RAM_GUARD_EFFECTIVE_HOST_MAX_PCT="$host_max_pct"
export FSMGEN_RAM_GUARD_EFFECTIVE_PROCESS_MAX_RSS_MB="$process_max_rss_mb"

guard_directory=$(mktemp -d "${FSMGEN_TMP_ROOT}/ram-guard.XXXXXXXX") \
    || die "cannot create repository-local launcher handoff"
root_pid=""
session_ready=0
cleanup_guard() {
    saved_status=$?
    trap - EXIT HUP INT TERM
    if [ -n "$root_pid" ]; then
        if [ "$session_ready" -eq 1 ]; then
            terminate_session "monitor exiting before owned session completion"
        else
            kill -KILL "$root_pid" 2>/dev/null || true
            wait "$root_pid" 2>/dev/null || true
        fi
    fi
    rm -f -- "$guard_directory/ready" "$guard_directory/go" \
        "$guard_directory/status" "$guard_directory/finish" "$guard_directory/"*.tmp
    rmdir -- "$guard_directory" 2>/dev/null || true
    exit "$saved_status"
}
trap cleanup_guard EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

# The helper passes every inherited descriptor unchanged. The file handshake
# avoids reserving a descriptor which may already belong to the caller.
# Explicit stdin redirection prevents Bash's asynchronous /dev/null fallback.
python3 -B "${SCRIPT_DIR}/ram_guard_session.py" launch "$guard_directory" "$$" "$@" <&0 &
root_pid=$!
attempt=0
until [ -f "$guard_directory/ready" ]; do
    kill -0 "$root_pid" 2>/dev/null || die "owned session launcher failed before readiness"
    attempt=$((attempt + 1))
    [ "$attempt" -le 1000 ] || die "owned session launcher readiness timed out"
    sleep 0.01
done
read -r ready_pid < "$guard_directory/ready"
[ "$ready_pid" = "$root_pid" ] || die "owned session launcher identity mismatch"
group_id=$(ps -o pgid= -p "$root_pid" | awk 'NF { print $1; exit }')
[ "$group_id" = "$root_pid" ] || die "owned session launcher did not establish its group"
session_ready=1
initial_members=$(list_session_pids) || die "owned session inspection failed before command launch"
[ "$initial_members" = "$root_pid" ] || die "owned session identity mismatch before command launch"
: > "$guard_directory/go"
echo "ram-guard: PID $root_pid; host ${initial_host_pct}%; host cutoff ${host_max_pct}%; descendant RSS cutoff ${process_max_rss_mb} MiB; poll ${poll_seconds}s" >&2

while :; do
    if ! kill -0 "$root_pid" 2>/dev/null; then
        terminate_session "owned session supervisor exited before completion"
        root_pid=""
        exit 137
    fi
    pids=$(list_session_pids) || {
        terminate_session "session inspection became unavailable"
        root_pid=""
        exit 137
    }
    if [ -f "$guard_directory/status" ] && [ "$pids" = "$root_pid" ]; then
        : > "$guard_directory/finish"
        wait "$root_pid"
        command_status=$?
        root_pid=""
        exit "$command_status"
    fi
    if host_pct=$(host_memory_pct); then
        if number_ge "$host_pct" "$host_max_pct"; then
            terminate_session "host memory ${host_pct}% reached cutoff ${host_max_pct}%"
            root_pid=""
            exit 137
        fi
    else
        terminate_session "host memory usage became unavailable while command was running"
        root_pid=""
        exit 137
    fi
    for pid in $pids; do
        rss_kb=$(rss_kb_for_pid "$pid")
        [ -n "$rss_kb" ] || continue
        if [ "$rss_kb" -ge "$process_max_rss_kb" ]; then
            rss_mb=$(awk -v kb="$rss_kb" 'BEGIN { printf "%.1f", kb / 1024.0 }')
            command_text=$(command_for_pid "$pid")
            terminate_session "PID $pid RSS ${rss_mb} MiB reached cutoff ${process_max_rss_mb} MiB: ${command_text}"
            root_pid=""
            exit 137
        fi
    done
    sleep "$poll_seconds"
done
