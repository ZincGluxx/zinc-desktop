#!/usr/bin/env bash
# Collect a low-overhead snapshot of Zinc Desktop runtime resource use.
# Usage: scripts/perf-report.sh [sample_seconds] [output_file]
set -euo pipefail

seconds="${1:-5}"
out="${2:-zinc-perf-$(date +%Y%m%d-%H%M%S).log}"
python3 - "$seconds" <<'PY' | tee "$out"
import glob
import os
import re
import sys
import time
from pathlib import Path

seconds = float(sys.argv[1])
matcher = re.compile(r"cosmic|zinc|pop-launcher|xdg-desktop-portal", re.I)

def proc_snapshot():
    procs = []
    for path in glob.glob('/proc/[0-9]*'):
        try:
            comm = Path(path, 'comm').read_text().strip()
            status = Path(path, 'status').read_text()
            pid = int(path.rsplit('/', 1)[1])
            ppid = int(re.search(r'^PPid:\s+(\d+)', status, re.M).group(1))
            rss = 0
            pss = 0
            smaps = Path(path, 'smaps_rollup').read_text()
            for line in smaps.splitlines():
                if line.startswith('Rss:'):
                    rss = int(line.split()[1])
                elif line.startswith('Pss:'):
                    pss = int(line.split()[1])
            threads = int(re.search(r'^Threads:\s+(\d+)', status, re.M).group(1))
            fds = len(glob.glob(path + '/fd/*'))
            stat = Path(path, 'stat').read_text().split()
            ticks = int(stat[13]) + int(stat[14])
            if matcher.search(comm) or matcher.search(' '.join(Path(path, 'cmdline').read_bytes().split(b'\0')[0:2]).decode(errors='ignore')):
                procs.append({
                    'pid': pid, 'ppid': ppid, 'comm': comm, 'rss': rss,
                    'pss': pss, 'threads': threads, 'fds': fds, 'ticks': ticks,
                })
        except (FileNotFoundError, PermissionError, ProcessLookupError, AttributeError, ValueError):
            continue
    return procs

def total_cpu_ticks():
    line = Path('/proc/stat').read_text().splitlines()[0]
    return sum(map(int, line.split()[1:]))

before = proc_snapshot()
t1 = total_cpu_ticks()
time.sleep(seconds)
after = proc_snapshot()
t2 = total_cpu_ticks()
cores = os.cpu_count() or 1
by_pid = {p['pid']: p for p in after}
print(f'# Zinc runtime performance report')
print(f'sample_seconds={seconds}')
print(f'processes={len(after)}')
print(f'sum_rss_mib={sum(p["rss"] for p in after)/1024:.1f}')
print(f'sum_pss_mib={sum(p["pss"] for p in after)/1024:.1f}')
print(f'threads={sum(p["threads"] for p in after)}')
print(f'fds={sum(p["fds"] for p in after)}')
print()
print('pid\tcomm\tpss_mib\tthreads\tfds\tcpu_pct_one_core')
for p in sorted(after, key=lambda p: -p['pss']):
    d = p['ticks'] - next((q['ticks'] for q in before if q['pid'] == p['pid']), p['ticks'])
    pct = d / max(t2 - t1, 1) * 100 * cores
    print(f'{p["pid"]}\t{p["comm"]}\t{p["pss"]/1024:.1f}\t{p["threads"]}\t{p["fds"]}\t{pct:.2f}')
print()
print('## cosmic-comp threads')
for tid_path in glob.glob('/proc/[0-9]*/task/[0-9]*'):
    pid = int(tid_path.split('/')[2])
    if by_pid.get(pid, {}).get('comm') != 'cosmic-comp':
        continue
    try:
        tid = int(tid_path.rsplit('/', 1)[1])
        comm = Path(tid_path, 'comm').read_text().strip()
        ticks = sum(map(int, Path(tid_path, 'stat').read_text().split()[13:15]))
        print(f'{tid}\t{comm}\t{ticks}')
    except (FileNotFoundError, PermissionError, ProcessLookupError, ValueError):
        continue
PY
