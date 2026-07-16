#!/usr/bin/env bash
# Automated stale-info checker for the pre-push gate.
# Uses `git grep` so it only searches tracked files.
set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly NC='\033[0m'

errors=0
pass() { echo -e "  ${GREEN}OK${NC}  $1"; }
fail() {
	echo -e "  ${RED}FAIL${NC} $1"
	((errors++))
}

# shellcheck disable=SC2059
check_no_match() {
	local pattern="$1" msg="$2" pathspec="$3"
	if git grep -nE "$pattern" -- $pathspec 2>/dev/null; then
		fail "$msg"
	else
		pass "$msg"
	fi
}

echo ""
echo "========== Stale Info Check =========="
echo ""

# Patterns that are never correct anywhere in tracked files
check_no_match '--concurrency=8' \
	'--concurrency=8 found (should be --concurrency=2)' \
	'*.md *.yaml *.yml *.sh'

check_no_match 'retention-days: 7' \
	'retention-days: 7 found (should be >= 90 for CI, or documented)' \
	'*.yml *.yaml'

check_no_match \
	'adServiceProvider|donationServiceProvider|firebaseServiceProvider|cloudBackupServiceProvider|backupStatusProvider|isProProvider|isAdFreeProvider' \
	'Non-existent provider referenced in docs' \
	'*.md *.yaml *.yml'

check_no_match 'quality_gate\.sh' \
	'quality_gate.sh referenced (script is deprecated)' \
	':!CHANGELOG.md :!AGENTS.md :!agents_docs/stale_info_checklist.md :!scripts/check_stale_info.sh'

check_no_match '\bCSV\b.*\b(import|export)\b|\b(import|export)\b.*\bCSV\b' \
	'CSV import/export mentioned (feature removed)' \
	':!CHANGELOG.md :!AGENTS.md :!agents_docs/stale_info_checklist.md :!lib/widgets/whats_new_sheet.dart :!scripts/check_stale_info.sh'

# Dep names — exclude files where historical references are valid
check_no_match '\bdio\b' \
	'\bdio\b found (should be http)' \
	':!pubspec.lock :!CHANGELOG.md :!AGENTS.md :!agents_docs/stale_info_checklist.md :!scripts/check_stale_info.sh'

check_no_match 'connectivity_plus' \
	'connectivity_plus found (should be internet_connection_checker)' \
	':!pubspec.lock :!CHANGELOG.md :!AGENTS.md :!agents_docs/stale_info_checklist.md :!scripts/check_stale_info.sh'

echo ""
echo "======================================"
echo ""

if [ $errors -eq 0 ]; then
	echo -e "${GREEN}All stale-info checks passed.${NC}"
	exit 0
else
	echo -e "${RED}$errors stale-info issue(s) found. Fix them before pushing.${NC}"
	echo "  (Use \`git push --no-verify\` to bypass this check.)"
	exit 1
fi
