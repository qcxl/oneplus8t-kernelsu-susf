#!/usr/bin/env python3
import sys
import re

def fix_makefile(makefile_path, patterns):
    with open(makefile_path, 'r') as f:
        lines = f.readlines()

    new_lines = []
    skip_until_recipe = False
    for i, line in enumerate(lines):
        if skip_until_recipe:
            # Skip empty lines and recipe lines until we find a non-recipe line
            if line.startswith('\t') or line.strip() == '':
                continue
            else:
                skip_until_recipe = False
                new_lines.append(line)
            continue

        # Check if this line matches any of the patterns
        matched = False
        for pattern in patterns:
            if re.search(pattern, line):
                matched = True
                break

        if matched:
            # Start skipping: skip empty lines and recipe lines
            skip_until_recipe = True
            continue

        new_lines.append(line)

    with open(makefile_path, 'w') as f:
        f.writelines(new_lines)

if __name__ == '__main__':
    makefile = sys.argv[1]
    patterns = sys.argv[2:]
    fix_makefile(makefile, patterns)
