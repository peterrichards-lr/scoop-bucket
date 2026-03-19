#!/bin/bash

# Exit on any failure
set -e

# Define the bucket directory
BUCKET_DIR="bucket"

# Check all .json files in bucket/
FAILED=0

shopt -s nullglob
for file in "$BUCKET_DIR"/*.json; do
    if [ ! -f "$file" ]; then continue; fi
    
    echo "Linting $file..."
    
    # 1. Validate JSON format
    if ! jq . "$file" > /dev/null; then
        echo "Error: $file is not valid JSON."
        FAILED=1
        continue
    fi
    
    # 2. Check for required Scoop manifest fields
    if ! jq -e '.version and .description and .homepage' "$file" > /dev/null; then
        echo "Error: $file is missing required manifest fields (version, description, or homepage)."
        FAILED=1
        continue
    fi
done

if [ $FAILED -ne 0 ]; then
    echo "Linting failed. Please fix the errors before committing."
    exit 1
else
    echo "All manifests in $BUCKET_DIR/ are valid."
fi
