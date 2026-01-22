#!/usr/bin/env python3
"""
N8N MCP ULTIMATE - Environment & Connection Verification Script
================================================================
Generated: 2026-01-22
Session: claude/setup-db-env-config-lLxYQ

This script verifies:
1. PostgreSQL (Supabase) connection
2. Redis (Upstash) connection
3. Environment variables
4. Executes database initialization SQL
"""

import os
import sys
import json
import subprocess
from datetime import datetime
from pathlib import Path

# Try to import required packages
try:
    import urllib.request
    import urllib.error
except ImportError:
    pass

# ============================================
# Configuration
# ============================================

SCRIPT_DIR = Path(__file__).parent
PROJECT_DIR = SCRIPT_DIR.parent
ERROR_LOG = PROJECT_DIR / "error-logs" / "agent1-error.txt"
SQL_FILE = SCRIPT_DIR / "init-db.sql"
ENV_FILE = PROJECT_DIR / ".env"

# Database credentials (Supabase PostgreSQL)
PG_CONFIG = {
    "host": "db.ayqviqmxifzmhphiqfmj.supabase.co",
    "port": "5432",
    "database": "postgres",
    "user": "postgres",
    "password": "LxtBJKljhhBassDS",
}

# Redis credentials (Upstash)
REDIS_CONFIG = {
    "url": "https://dynamic-frog-47846.upstash.io",
    "token": "AbrmAAIncDFlYjliNTA0MzRhNmQ0YjlkYjIzZGM1Y2I2NGJlNDRmMnAxNDc4NDY",
}


# ============================================
# Logging
# ============================================

class Colors:
    RED = "\033[0;31m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    NC = "\033[0m"


def log_info(msg):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")


def log_warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")


def init_error_log():
    """Initialize the error log file."""
    ERROR_LOG.parent.mkdir(parents=True, exist_ok=True)
    with open(ERROR_LOG, "w") as f:
        f.write("# ============================================\n")
        f.write("# Agent 1 - Setup Log\n")
        f.write(f"# Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write("# Session: claude/setup-db-env-config-lLxYQ\n")
        f.write("# ============================================\n\n")


def append_to_log(msg):
    """Append message to error log."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(ERROR_LOG, "a") as f:
        f.write(f"[{timestamp}] {msg}\n")


# ============================================
# PostgreSQL Functions
# ============================================

def test_postgres_connection():
    """Test PostgreSQL connection using psql."""
    log_info(f"Testing PostgreSQL connection to {PG_CONFIG['host']}...")

    try:
        env = os.environ.copy()
        env["PGPASSWORD"] = PG_CONFIG["password"]

        result = subprocess.run(
            [
                "psql",
                "-h", PG_CONFIG["host"],
                "-p", PG_CONFIG["port"],
                "-U", PG_CONFIG["user"],
                "-d", PG_CONFIG["database"],
                "-c", "SELECT 1 as test;",
            ],
            env=env,
            capture_output=True,
            text=True,
            timeout=30,
        )

        if result.returncode == 0:
            log_info("PostgreSQL connection successful!")
            append_to_log("PostgreSQL connection: SUCCESS")
            return True
        else:
            log_error(f"PostgreSQL connection failed: {result.stderr}")
            append_to_log(f"PostgreSQL connection: FAILED - {result.stderr}")
            return False

    except FileNotFoundError:
        log_error("psql command not found. Please install PostgreSQL client.")
        append_to_log("PostgreSQL connection: FAILED - psql not installed")
        return False
    except subprocess.TimeoutExpired:
        log_error("PostgreSQL connection timed out")
        append_to_log("PostgreSQL connection: FAILED - timeout")
        return False
    except Exception as e:
        log_error(f"PostgreSQL connection error: {e}")
        append_to_log(f"PostgreSQL connection: FAILED - {e}")
        return False


def execute_sql_file():
    """Execute the init-db.sql file."""
    log_info(f"Executing SQL from {SQL_FILE}...")

    if not SQL_FILE.exists():
        log_error(f"SQL file not found: {SQL_FILE}")
        append_to_log(f"SQL execution: FAILED - file not found")
        return False

    try:
        env = os.environ.copy()
        env["PGPASSWORD"] = PG_CONFIG["password"]

        result = subprocess.run(
            [
                "psql",
                "-h", PG_CONFIG["host"],
                "-p", PG_CONFIG["port"],
                "-U", PG_CONFIG["user"],
                "-d", PG_CONFIG["database"],
                "-f", str(SQL_FILE),
            ],
            env=env,
            capture_output=True,
            text=True,
            timeout=60,
        )

        if result.returncode == 0:
            log_info("SQL executed successfully!")
            append_to_log("SQL execution: SUCCESS")
            print(result.stdout)
            return True
        else:
            log_error(f"SQL execution failed: {result.stderr}")
            append_to_log(f"SQL execution: FAILED - {result.stderr}")
            return False

    except Exception as e:
        log_error(f"SQL execution error: {e}")
        append_to_log(f"SQL execution: FAILED - {e}")
        return False


def test_postgres_with_python():
    """Test PostgreSQL using psycopg2 if available."""
    try:
        import psycopg2

        log_info("Testing PostgreSQL with psycopg2...")
        conn = psycopg2.connect(
            host=PG_CONFIG["host"],
            port=PG_CONFIG["port"],
            database=PG_CONFIG["database"],
            user=PG_CONFIG["user"],
            password=PG_CONFIG["password"],
            sslmode="require",
        )
        cur = conn.cursor()
        cur.execute("SELECT 1;")
        cur.close()
        conn.close()
        log_info("PostgreSQL (psycopg2) connection successful!")
        append_to_log("PostgreSQL (psycopg2) connection: SUCCESS")
        return True
    except ImportError:
        log_warn("psycopg2 not installed, skipping Python test")
        return None
    except Exception as e:
        log_error(f"PostgreSQL (psycopg2) failed: {e}")
        append_to_log(f"PostgreSQL (psycopg2) connection: FAILED - {e}")
        return False


# ============================================
# Redis Functions
# ============================================

def test_redis_connection():
    """Test Redis (Upstash) connection using REST API."""
    log_info(f"Testing Redis (Upstash) connection to {REDIS_CONFIG['url']}...")

    try:
        # Upstash REST API format: POST with command as JSON array
        url = REDIS_CONFIG["url"]
        data = json.dumps(["PING"]).encode("utf-8")

        req = urllib.request.Request(
            url,
            data=data,
            headers={
                "Authorization": f"Bearer {REDIS_CONFIG['token']}",
                "Content-Type": "application/json",
            },
            method="POST",
        )

        with urllib.request.urlopen(req, timeout=10) as response:
            result = response.read().decode("utf-8")
            result_json = json.loads(result)

            if result_json.get("result") == "PONG":
                log_info("Redis (Upstash) connection successful!")
                append_to_log("Redis connection: SUCCESS")
                return True
            else:
                log_error(f"Unexpected Redis response: {result}")
                append_to_log(f"Redis connection: FAILED - unexpected response: {result}")
                return False

    except urllib.error.HTTPError as e:
        log_error(f"Redis HTTP error: {e.code} - {e.reason}")
        append_to_log(f"Redis connection: FAILED - HTTP {e.code}")
        return False
    except urllib.error.URLError as e:
        log_error(f"Redis URL error: {e.reason}")
        append_to_log(f"Redis connection: FAILED - {e.reason}")
        return False
    except Exception as e:
        log_error(f"Redis connection error: {e}")
        append_to_log(f"Redis connection: FAILED - {e}")
        return False


def test_redis_with_library():
    """Test Redis using redis-py with Upstash if available."""
    try:
        import redis

        log_info("Testing Redis with redis-py...")
        r = redis.Redis(
            host="dynamic-frog-47846.upstash.io",
            port=6379,
            password=REDIS_CONFIG["token"],
            ssl=True,
        )
        result = r.ping()
        if result:
            log_info("Redis (redis-py) connection successful!")
            append_to_log("Redis (redis-py) connection: SUCCESS")
            return True
        return False
    except ImportError:
        log_warn("redis-py not installed, skipping library test")
        return None
    except Exception as e:
        log_error(f"Redis (redis-py) failed: {e}")
        append_to_log(f"Redis (redis-py) connection: FAILED - {e}")
        return False


# ============================================
# Environment Verification
# ============================================

def verify_env_file():
    """Verify that .env file exists and has required variables."""
    log_info("Verifying environment file...")

    if not ENV_FILE.exists():
        log_error(f".env file not found at {ENV_FILE}")
        append_to_log("Environment file: NOT FOUND")
        return False

    required_vars = [
        "POSTGRES_URL",
        "POSTGRES_HOST",
        "POSTGRES_PASSWORD",
        "REDIS_URL",
        "OPENAI_API_KEY",
        "COHERE_API_KEY",
        "PINECONE_API_KEY",
        "NEO4J_URL",
    ]

    with open(ENV_FILE) as f:
        content = f.read()

    missing = []
    for var in required_vars:
        if var not in content:
            missing.append(var)
        else:
            # Check if it has a value
            for line in content.split("\n"):
                if line.startswith(var + "="):
                    value = line.split("=", 1)[1].strip()
                    if not value or value.startswith("<") or value == "your-":
                        missing.append(f"{var} (empty/placeholder)")

    if missing:
        log_warn(f"Missing or placeholder environment variables: {missing}")
        append_to_log(f"Environment file: INCOMPLETE - missing {missing}")
        return False

    log_info("Environment file verified!")
    append_to_log("Environment file: OK")
    return True


# ============================================
# Main
# ============================================

def main():
    print()
    print("=" * 50)
    print(" N8N MCP ULTIMATE - Setup Verification")
    print("=" * 50)
    print()

    init_error_log()
    results = {}

    # Step 1: Verify environment file
    results["env_file"] = verify_env_file()

    # Step 2: Test PostgreSQL connection
    results["postgres_psql"] = test_postgres_connection()

    # Alternative: Test with psycopg2
    pg_python = test_postgres_with_python()
    if pg_python is not None:
        results["postgres_python"] = pg_python

    # Step 3: Execute SQL if PostgreSQL is connected
    if results.get("postgres_psql") or results.get("postgres_python"):
        results["sql_execution"] = execute_sql_file()

    # Step 4: Test Redis connection
    results["redis_rest"] = test_redis_connection()

    # Alternative: Test with redis-py
    redis_python = test_redis_with_library()
    if redis_python is not None:
        results["redis_python"] = redis_python

    # Summary
    print()
    print("=" * 50)

    all_ok = all(v for v in results.values() if v is not None)

    if all_ok:
        print(f"{Colors.GREEN}Setup OK{Colors.NC}")
        append_to_log("\n=== FINAL STATUS: Setup OK ===")
        return 0
    else:
        failed = [k for k, v in results.items() if v is False]
        print(f"{Colors.RED}Setup FAILED{Colors.NC}")
        print(f"Failed checks: {failed}")
        print(f"Check {ERROR_LOG} for details")
        append_to_log(f"\n=== FINAL STATUS: Setup FAILED - {failed} ===")
        return 1


if __name__ == "__main__":
    sys.exit(main())
