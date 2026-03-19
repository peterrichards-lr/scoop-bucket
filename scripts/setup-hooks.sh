#!/bin/bash

# Setup Git hooks
mkdir -p .git/hooks
ln -sf ../../scripts/lint.sh .git/hooks/pre-commit
chmod +x scripts/lint.sh
chmod +x .git/hooks/pre-commit

echo "Git hooks setup successfully!"
