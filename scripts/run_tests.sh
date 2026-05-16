#!/usr/bin/env sh

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'   # no color

set -eu

project_root=$(cd "$(dirname "$0")/.." && pwd)

cd "$project_root"

failed=0

for test_file in tests/*.mojo; do
	[ -e "$test_file" ] || continue
	echo "Running $test_file"
	if ! mojo run -I src "$test_file"; then
		failed=1
	fi
done

if [ "$failed" -eq 0 ]; then
	printf "🚀 All tests ${GREEN}passed!${NC}"
fi

if [ "$failed" -eq 1 ]; then
	printf "💥 Some tests ${RED}failed!${NC}"
fi

exit "$failed"

