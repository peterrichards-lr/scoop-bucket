#!/usr/bin/env bash
# Usage: scripts/open-signed-pr.sh BRANCH TITLE BODY_FILE PATH...
#
# Commits PATH... as they are in the working tree to a new BRANCH through the
# GitHub API, then opens a pull request labelled no-issue-needed and
# squash-merges it.
#
# main requires signed commits and pull requests. Commits created with the
# createCommitOnBranch API are signed by GitHub, so this works for
# github-actions[bot] and people alike, with no bypass. A PATH that no longer
# exists is recorded as a deletion.
set -euo pipefail

if [ $# -lt 4 ]; then
  echo "Usage: $0 BRANCH TITLE BODY_FILE PATH..." >&2
  exit 2
fi

branch=$1 title=$2 body_file=$3
shift 3

repo=${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}
base=$(git rev-parse HEAD)
payload=$(mktemp)
trap 'rm -f "$payload"' EXIT

additions='[]'
deletions='[]'
for path in "$@"; do
  if [ -f "$path" ]; then
    contents=$(base64 < "$path" | tr -d '\r\n')
    additions=$(jq --arg p "$path" --arg c "$contents" '. + [{path: $p, contents: $c}]' <<< "$additions")
  else
    deletions=$(jq --arg p "$path" '. + [{path: $p}]' <<< "$deletions")
  fi
done

gh api "repos/$repo/git/refs" -f ref="refs/heads/$branch" -f sha="$base" > /dev/null

jq -n \
  --arg repo "$repo" --arg branch "$branch" --arg oid "$base" --arg headline "$title" \
  --argjson additions "$additions" --argjson deletions "$deletions" \
  '{
    query: "mutation($input: CreateCommitOnBranchInput!) { createCommitOnBranch(input: $input) { commit { oid } } }",
    variables: {input: {
      branch: {repositoryNameWithOwner: $repo, branchName: $branch},
      expectedHeadOid: $oid,
      message: {headline: $headline},
      fileChanges: {additions: $additions, deletions: $deletions}
    }}
  }' > "$payload"
gh api graphql --input "$payload" --jq '"Signed commit \(.data.createCommitOnBranch.commit.oid)"'

gh pr create --repo "$repo" --base main --head "$branch" --title "$title" --body-file "$body_file"
gh pr edit "$branch" --repo "$repo" --add-label no-issue-needed || true
# --auto needs pending required checks; with none, merge directly.
gh pr merge "$branch" --repo "$repo" --auto --squash --delete-branch \
  || gh pr merge "$branch" --repo "$repo" --squash --delete-branch
