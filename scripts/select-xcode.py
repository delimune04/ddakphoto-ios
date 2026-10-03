#!/usr/bin/env python3
"""Select the newest installed non-beta Xcode supported by App Store uploads."""
import glob
import os
import re
import subprocess

candidates = []
paths = glob.glob('/Applications/Xcode*.app/Contents/Developer')
current = subprocess.check_output(['xcode-select', '-p'], text=True).strip()
if current not in paths:
    paths.append(current)
for path in paths:
    if 'beta' in path.lower():
        continue
    environment = dict(os.environ, DEVELOPER_DIR=path)
    try:
        output = subprocess.check_output(['xcodebuild', '-version'], env=environment,
            text=True, stderr=subprocess.DEVNULL)
    except (subprocess.CalledProcessError, OSError):
        continue
    match = re.search(r'Xcode (\d+)(?:\.(\d+))?(?:\.(\d+))?', output)
    if match:
        version = tuple(int(value or 0) for value in match.groups())
        if version[0] >= 26:
            candidates.append((version, path))
if not candidates:
    raise SystemExit('This runner has no non-beta Xcode 26 or newer. A newer macOS runner is required.')
version, path = max(candidates)
print('Selected Xcode ' + '.'.join(map(str, version)) + ': ' + path)
if os.environ.get('GITHUB_ENV'):
    with open(os.environ['GITHUB_ENV'], 'a') as handle:
        handle.write('DEVELOPER_DIR=' + path + '\n')
