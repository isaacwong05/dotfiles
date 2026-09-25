#!/usr/bin/env python3
"""Conservative weekly Arch maintenance report and interactive apply mode."""

from __future__ import annotations

import argparse
import fcntl
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path


HOME = Path.home()
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state")) / "arch-maintenance"
LOG_FILE = STATE_DIR / "maintenance.log"
LOCK_FILE = STATE_DIR / "maintenance.lock"
KEEP_CACHE_VERSIONS = 3


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def run_command(args: list[str], *, timeout: int = 120) -> tuple[int, str]:
    """Run one command without a shell; return its exit status and combined output."""
    try:
        result = subprocess.run(
            args,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 127, str(exc)
    return result.returncode, result.stdout.strip()


def root_command(args: list[str]) -> list[str]:
    if os.geteuid() == 0:
        return args
    if command_exists("sudo"):
        return ["sudo", *args]
    if command_exists("doas"):
        return ["doas", *args]
    return args


def output_lines(output: str, limit: int = 20) -> list[str]:
    lines = [line for line in output.splitlines() if line.strip()]
    if len(lines) > limit:
        return [*lines[:limit], f"... ({len(lines) - limit} more)"]
    return lines


def write_snapshot(name: str, content: str) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    target = STATE_DIR / name
    temporary = target.with_suffix(target.suffix + ".tmp")
    temporary.write_text(content + ("\n" if content and not content.endswith("\n") else ""))
    temporary.replace(target)


def snapshot_packages() -> None:
    for name, args in (
        ("explicit-packages.txt", ["pacman", "-Qqe"]),
        ("foreign-packages.txt", ["pacman", "-Qqm"]),
    ):
        status, output = run_command(args)
        if status == 0:
            write_snapshot(name, output)


def append_log(lines: list[str]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a") as log:
        log.write(f"\n[{datetime.now().astimezone().isoformat(timespec='seconds')}]\n")
        log.write("\n".join(lines) + "\n")


def section(title: str, lines: list[str], report: list[str]) -> None:
    report.append(f"\n== {title} ==")
    report.extend(lines or ["none"])


def command_report(label: str, args: list[str], report: list[str], *, limit: int = 20) -> None:
    status, output = run_command(args)
    lines = output_lines(output, limit)
    if status != 0:
        lines.append(f"command exited {status}")
    section(label, lines, report)


def update_query_report(label: str, args: list[str], report: list[str]) -> None:
    status, output = run_command(args)
    lines = output_lines(output)
    if not lines and status in {1, 2}:
        lines = ["none"]
    elif status != 0:
        lines.append(f"command exited {status}")
    section(label, lines, report)


def directory_size(path: Path) -> int:
    total = 0
    if not path.exists():
        return total
    for child in path.rglob("*"):
        try:
            if child.is_file():
                total += child.stat().st_size
        except OSError:
            pass
    return total


def report() -> int:
    lines = [
        f"Arch maintenance report: {datetime.now().astimezone().isoformat(timespec='seconds')}",
        f"host: {os.uname().nodename} | kernel: {os.uname().release}",
    ]

    usage = shutil.disk_usage("/")
    cache_size = directory_size(Path("/var/cache/pacman/pkg"))
    section(
        "disk",
        [
            f"/: {usage.used / 2**30:.1f} GiB used / {usage.free / 2**30:.1f} GiB free ({usage.used / usage.total:.0%})",
            f"pacman cache: {cache_size / 2**30:.1f} GiB",
        ],
        lines,
    )

    if command_exists("checkupdates"):
        update_query_report("official updates (checkupdates)", ["checkupdates"], lines)
    else:
        section("official updates", ["not checked: install pacman-contrib for checkupdates"], lines)

    if command_exists("paru"):
        update_query_report("AUR updates (paru -Qua)", ["paru", "-Qua"], lines)
    else:
        section("AUR updates", ["not checked: paru is not installed"], lines)

    command_report("orphan packages (review before removing)", ["pacman", "-Qtdq"], lines)
    command_report("foreign/AUR packages", ["pacman", "-Qmq"], lines, limit=50)

    pacnew = sorted(
        str(path)
        for root in (Path("/etc"),)
        if root.exists()
        for path in root.rglob("*")
        if path.is_file() and path.name.endswith((".pacnew", ".pacsave", ".pacorig"))
    )
    section("pending package config files", pacnew, lines)

    command_report("failed system services", ["systemctl", "--failed", "--no-legend", "--no-pager"], lines)
    command_report(
        "failed user services",
        ["systemctl", "--user", "--failed", "--no-legend", "--no-pager"],
        lines,
    )
    command_report("journal errors this boot", ["journalctl", "-b", "-p", "3", "-n", "20", "--no-pager"], lines)
    command_report("journal disk usage", ["journalctl", "--disk-usage"], lines)

    if command_exists("paccache"):
        section("package cache cleanup", ["paccache available; apply mode keeps 3 versions"], lines)
    else:
        section("package cache cleanup", ["paccache missing: install pacman-contrib if desired"], lines)

    if command_exists("pacdiff"):
        section("pacnew helper", ["pacdiff available; apply mode can open it interactively"], lines)
    else:
        section("pacnew helper", ["pacdiff missing: install pacman-contrib if desired"], lines)

    for name, args in (
        ("fstrim timer", ["systemctl", "is-enabled", "fstrim.timer"]),
        ("reflector", ["reflector", "--version"]),
        ("firmware updater", ["fwupdmgr", "--version"]),
        ("flatpak", ["flatpak", "--version"]),
    ):
        if command_exists(args[0]):
            status, output = run_command(args)
            section(name, [output or ("enabled" if status == 0 else f"command exited {status}")], lines)
        else:
            section(name, [f"{args[0]} not installed"], lines)

    snapshot_packages()
    append_log(lines)
    print("\n".join(lines))
    return 0


def confirm(prompt: str) -> bool:
    answer = input(f"{prompt} [y/N] ").strip().lower()
    return answer in {"y", "yes"}


def apply(*, dry_run: bool = False) -> int:
    if not sys.stdin.isatty() and not dry_run:
        print("apply mode requires an interactive terminal; use --report from a timer", file=sys.stderr)
        return 2

    if dry_run:
        print("dry run: would perform a full official upgrade, then update AUR packages")
        print(f"dry run: would keep {KEEP_CACHE_VERSIONS} versions per package with paccache")
        print("dry run: would offer orphan removal and pacdiff interactively")
        return report()

    if not confirm("Run the weekly Arch maintenance actions now?"):
        print("cancelled")
        return 0

    actions: list[str] = []
    status, output = run_command(root_command(["pacman", "-Syu"]))
    actions.extend(["official package update:", output or f"command exited {status}"])
    if status != 0:
        append_log(actions)
        print("\n".join(actions), file=sys.stderr)
        return status

    if command_exists("paru") and confirm("Update AUR packages with paru -Sua?"):
        status, output = run_command(["paru", "-Sua"], timeout=900)
        actions.extend(["AUR package update:", output or f"command exited {status}"])
        if status != 0:
            print("AUR update failed; inspect the output before continuing", file=sys.stderr)

    if command_exists("paccache") and confirm(f"Clean package cache, keeping {KEEP_CACHE_VERSIONS} versions?"):
        status, output = run_command(root_command(["paccache", "-r", "-k", str(KEEP_CACHE_VERSIONS)]))
        actions.extend(["package cache:", output or f"command exited {status}"])
    elif not command_exists("paccache"):
        actions.append("package cache: skipped; paccache is not installed")

    status, orphan_output = run_command(["pacman", "-Qtdq"])
    orphans = orphan_output.splitlines() if status == 0 else []
    if orphans:
        print("\nOrphan packages:\n" + "\n".join(orphans))
        if confirm("Remove these orphan packages with pacman -Rns?"):
            status, output = run_command(root_command(["pacman", "-Rns", "--", *orphans]))
            actions.extend(["orphan removal:", output or f"command exited {status}"])
    else:
        actions.append("orphan removal: none")

    pacnew = sorted(
        str(path)
        for path in Path("/etc").rglob("*")
        if path.is_file() and path.name.endswith((".pacnew", ".pacsave", ".pacorig"))
    )
    if pacnew and command_exists("pacdiff") and confirm("Open pacdiff for pending package config files?"):
        status, output = run_command(["pacdiff", "--sudo"], timeout=900)
        actions.extend(["pacdiff:", output or f"command exited {status}"])
    elif pacnew:
        actions.append("pacnew/pacsave files remain: " + ", ".join(pacnew))

    snapshot_packages()
    append_log(actions)
    print("\n".join(actions))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--report", action="store_true", help="read-only report (default; timer mode)")
    mode.add_argument("--apply", action="store_true", help="interactive full upgrade and cleanup")
    parser.add_argument("--dry-run", action="store_true", help="show apply actions, then produce a report")
    args = parser.parse_args()

    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with LOCK_FILE.open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("another maintenance run is already active", file=sys.stderr)
            return 2
        return apply(dry_run=True) if args.dry_run else apply() if args.apply else report()


if __name__ == "__main__":
    raise SystemExit(main())
