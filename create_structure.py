#!/usr/bin/env python3
"""
create_structure.py
Reorganizes the PROJET_N8N_ULTIMATE repository into a clean, final structure.
Safe to run multiple times (idempotent).
"""

import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

TARGET_DIRS = [
    "workflows/raw",
    "workflows/fixed",
    "workflows/test-copies",
    "config",
    "datasets",
    "evaluations",
    "logs",
    "error-logs",
    "scripts",
]

WORKFLOW_PROD_FILES = {
    "orchestrator.json",
    "ingestion.json",
    "rag_graph.json",
    "rag_classic.json",
    "rag_tabular.json",
    "enrichment.json",
    "monitor.json",
}

LOG_FILES = {
    "import-log.json",
    "evaluation-log.json",
    "agent4-summary.csv",
}


def mkdirs():
    for d in TARGET_DIRS:
        path = ROOT / d
        path.mkdir(parents=True, exist_ok=True)


def move_file(src: Path, dst: Path):
    if not src.exists():
        return
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists():
        print(f"SKIP (exists): {dst}")
        return
    shutil.move(str(src), str(dst))
    print(f"MOVED: {src} -> {dst}")


def organize_workflows():
    workflows_dir = ROOT / "workflows"
    if not workflows_dir.exists():
        return

    for file in workflows_dir.iterdir():
        if not file.is_file():
            continue

        name = file.name

        if name.endswith("_TestCopy.json"):
            move_file(file, ROOT / "workflows/test-copies" / name)

        elif name in WORKFLOW_PROD_FILES:
            move_file(file, ROOT / "workflows/raw" / name)


def organize_scripts():
    scripts_dir = ROOT / "scripts"
    if not scripts_dir.exists():
        return

    for file in scripts_dir.iterdir():
        if file.name == "create_structure.py":
            continue
        move_file(file, ROOT / "scripts" / file.name)


def organize_configs():
    for name in ["postgres-schema.sql", "n8n-env-vars.yaml"]:
        move_file(ROOT / name, ROOT / "config" / name)


def organize_logs():
    for name in LOG_FILES:
        move_file(ROOT / name, ROOT / "logs" / name)


def main():
    print("=== Creating target directory structure ===")
    mkdirs()

    print("=== Organizing workflows ===")
    organize_workflows()

    print("=== Organizing scripts ===")
    organize_scripts()

    print("=== Organizing config files ===")
    organize_configs()

    print("=== Organizing logs ===")
    organize_logs()

    print("=== Done ===")


if __name__ == "__main__":
    main()
