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
    repo_path=$(echo "$homepage" | sed -E 's|https://github.com/||')
    
    # Fetch repository data from GitHub API
    if command -v gh >/dev/null 2>&1; then
        repo_data=$(gh api "repos/$repo_path")
    else
        repo_data=$(curl -s "https://api.github.com/repos/$repo_path")
    fi
    
    # Extract description
    desc=$(echo "$repo_data" | jq -r '.description')
    
    # Extract topics (tags) and format them as a comma-separated string
    topics=$(echo "$repo_data" | jq -r 'if .topics and length > 0 then .topics | join(", ") else "" end')
    
    # Fetch the remote README to get the friendly title
    # We check main first, then master if main fails
    remote_readme=$(curl -sL -f "https://raw.githubusercontent.com/$repo_path/main/README.md" || curl -sL -f "https://raw.githubusercontent.com/$repo_path/master/README.md" || echo "")
    
    # Extract the first H1 header
    friendly_name=$(echo "$remote_readme" | grep -m 1 '^# ' | sed 's/^# //')
    
    # Clean up markdown formatting (like backticks) from the title
    friendly_name=$(echo "$friendly_name" | sed 's/`//g')
    
    # Fallback to file toolname if README title isn't found
    if [ -z "$friendly_name" ]; then
        friendly_name="$toolname"
    fi
    
    # Fallback to local description if API fails or returns null
    if [ -z "$desc" ] || [ "$desc" = "null" ]; then
        desc=$(jq -r '.description' "$file")
    fi
    
    TOOLS_LIST+="- **[$friendly_name]($homepage)**: $desc\n"
    
    # Add tags if they exist
    if [ -n "$topics" ]; then
        TOOLS_LIST+="  <br>*(Tags: $topics)*\n"
    fi
done

# Replace the text between the markers
awk -v text="$TOOLS_LIST" '
  BEGIN { p=1 }
  /^<!-- TOOLS_LIST_START -->/ { print; printf "%s", text; p=0 }
  /^<!-- TOOLS_LIST_END -->/ { p=1 }
  p { print }
' README.md > README.md.tmp && mv README.md.tmp README.md
