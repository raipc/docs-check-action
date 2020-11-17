#!/usr/bin/env bash

function list_modified_md_files {
    if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
        git diff --name-only --diff-filter=d $(git merge-base HEAD master) | grep "\.md$" || true
    else
        find . -name \*.md -print || true
    fi
}

echo "Files to be checked:"
list_modified_md_files