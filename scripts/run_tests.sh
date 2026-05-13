#!/usr/bin/env sh
set -eu

project_root=$(cd "$(dirname "$0")/.." && pwd)

cd "$project_root"

for test_file in tests/*.mojo; do
	[ -e "$test_file" ] || continue
	echo "Running $test_file"
	mojo run -I src "$test_file"
done

