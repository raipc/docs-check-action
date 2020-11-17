#!/usr/bin/env bash

function list_modified_md_files {
    if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
        git diff --name-only --diff-filter=d $(git merge-base HEAD master) | grep "\.md$" || true
    else
        find . -name \*.md -print || true
    fi
}

if [[ "$ENABLE_CHECK" = "true" && -n "$(list_modified_md_files)" ]]; then
    if [ ! -f ".linkcheck-config.json" ]; then
        wget https://raw.githubusercontent.com/axibase/atsd/master/.linkcheck-config.json
    fi
    list_modified_md_files | xargs -d '\n' -n1 markdown-link-check -v -c .linkcheck-config.json
else
    echo "Link checking will be skipped"
fi