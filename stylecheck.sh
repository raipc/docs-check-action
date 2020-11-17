#!/usr/bin/env bash

function list_modified_md_files {
    if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
        git diff --name-only --diff-filter=d $(git merge-base HEAD master) | grep "\.md$" || true
    else
        find . -name \*.md -print || true
    fi
}

if [[ -n "$(list_modified_md_files)" ]]; then
    git clone https://github.com/axibase/docs-util --depth=1
    exit_code=0
    if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
        if [[ -n "$(list_modified_md_files)" ]]; then
            list_modified_md_files | xargs -d '\n' -n1 markdownlint -i docs-util -r 'docs-util/linting-rules/*' {}
            exit_code=$?
        fi;
    else
        markdownlint -i docs-util -r 'docs-util/linting-rules/*' .
        exit_code=$?
    fi
    rm -rf docs-util
    exit $exit_code
else
    echo "Style checking will be skipped"
fi