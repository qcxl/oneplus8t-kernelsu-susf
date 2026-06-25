#!/usr/bin/env python3
import sys
import re

def fix_makefile(makefile_path, patterns):
    with open(makefile_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    skip_next = False
    for i, line in enumerate(lines):
        if skip_next:
            skip_next = False
            continue

        # Check if this line matches any of the patterns
        matched = False
        for pattern in patterns:
            if re.search(pattern, line):
                matched = True
                break

        if matched:
            # Check if the next line is a recipe line (starts with tab)
            if i + 1 < len(lines) and lines[i + 1].startswith('\t'):
                skip_next = True
            continue

        new_lines.append(line)

    with open(makefile_path, 'w') as f:
        f.writelines(new_lines)

if __name__ == '__main__':
    makefile = sys.argv[1]
    patterns = sys.argv[2:]
    fix_makefile(makefile, patterns)
