#!/usr/bin/env bash
# Non-mutating local readiness audit. No server access and no downloads.
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

bash -n scripts/fetch-upstream.sh
python3 - <<'PY'
from pathlib import Path
import re
import json
paths = [
    'HISTORY.md', 'README.md', 'config/upstream.lock', 'config/telegram-public.json',
    'db/migrations/001_capacity_guard.sql',
    'tests/test_capacity.py', 'docs/ADR-001-commerce-stack.md',
    'docs/ADR-002-persian-first.md', 'docs/ADR-003-shahpanel-selection.md',
    'docs/shahpanel-staging-runbook.md',
    'docs/architecture.md',
    'docs/n8n-automation.md', 'docs/security-and-release.md',
]
missing = [p for p in paths if not Path(p).is_file()]
if missing:
    raise SystemExit('Missing tracked preparation files: ' + ', '.join(missing))
rows = [
    ln.split('\t') for ln in Path('config/upstream.lock').read_text().splitlines()
    if ln.strip() and not ln.startswith('#')
]
assert len(rows) == 3, 'Expected 3 pinned selected upstreams'
assert all(len(r) == 3 and re.fullmatch(r'[0-9a-f]{40}', r[2]) for r in rows)
assert {r[0] for r in rows} == {'shahpanel', 'remnawave-backend', 'remnawave-node'}
assert all('bedolaga' not in r[1].lower() and 'minishop' not in r[1].lower() for r in rows)
assert any(r[0] == 'shahpanel' and r[2] == 'e898e84999779fd105a3e948a95ced3f44db9df1' for r in rows)
bot = json.loads(Path('config/telegram-public.json').read_text())
assert bot['telegram']['username'] == 'RavixNetBot'
assert bot['telegram']['public_url'] == 'https://t.me/RavixNetBot'
assert bot['telegram']['telegram_api_verified'] is False
assert bot['telegram']['status'] == 'awaiting_private_credentials_and_https_host'
assert set(bot['telegram']) == {'username', 'public_url', 'integration', 'status', 'source', 'telegram_api_verified'}
assert 'hard_max = 500' in Path('db/migrations/001_capacity_guard.sql').read_text()
print('PASS: offline preflight, pinned source manifest, files and SQL cap')
PY
python3 -m py_compile tests/test_capacity.py
echo "Offline checks finished. No production resources touched."
