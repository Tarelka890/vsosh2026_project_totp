import sys, getpass, subprocess, time, sqlite3
from pathlib import Path
import pyotp

DB_PATH = Path('/var/lib/totp/secure_totp.db')
MAX_TRIES = 3
BLOCK_DURATION = 300

def init_db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS attempts (
            user TEXT NOT NULL,
            action TEXT NOT NULL,
            fail_count INTEGER NOT NULL,
            last_fail_ts INTEGER NOT NULL,
            PRIMARY KEY(user, action)
        )
    """)
    conn.commit()
    return conn

def get_attempt(conn, user, action):
    c = conn.cursor()
    c.execute("SELECT fail_count, last_fail_ts FROM attempts WHERE user=? and action=?", (user, action))
    row = c.fetchone()
    return (row[0], row[1]) if row else (0,0)

# def set_attempt(conn, user, action, fail, ts):
#     c = conn.cursor()
#     c.execute("""
#         INSERT INTO attempts(user, action, fail_count, last_fail_ts)
#         VALUES (?, ?, ?, ?)
#         ON CONFLICT(user, action) DO UPDATE SET
#             fail_count=excluded.fail_count,
#             last_fail_ts=excluded.last_fail_ts
#     """, (user, action, fail, ts))