#!/bin/bash

# Ensure we're in the repository root
cd "$(dirname "$0")/.." || exit 1

TOOLS_LIST="The following tools are available in this bucket:\n\n"

for file in bucket/*.json; do
    filename=$(basename -- "$file")
    toolname="${filename%.*}"
    
    # Skip the example template
    if [ "$toolname" = "my-rust-tool.json.example" ]; then continue; fi
    
    homepage=$(jq -r '.homepage' "$file")
    
    # Extract the repository owner/name from the homepage URL
    # Assumes format: https://github.com/owner/repo
    repo_path=$(echo "$homepage" | sed -E 's|https://github.com/||')
    
    # Fetch description from GitHub API
    # Using gh cli if available, otherwise curl (useful for local testing)
    if command -v gh >/dev/null 2>&1; then
        desc=$(gh api "repos/$repo_path" --jq '.description')
    else
        desc=$(curl -s "https://api.github.com/repos/$repo_path" | jq -r '.description')
    fi
    
    # Fallback to local description if API fails or returns null
    if [ -z "$desc" ] || [ "$desc" = "null" ]; then
        desc=$(jq -r '.description' "$file")
    fi
    
    TOOLS_LIST+="- **[$toolname]($homepage)**: $desc\n"
done

# Replace the text between the markers
awk -v text="$TOOLS_LIST" '
  BEGIN { p=1 }
  /^<!-- TOOLS_LIST_START -->/ { print; printf "%s", text; p=0 }
  /^<!-- TOOLS_LIST_END -->/ { p=1 }
  p { print }
' README.md > README.md.tmp && mv README.md.tmp README.md
