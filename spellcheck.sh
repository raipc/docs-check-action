#!/usr/bin/env bash

function list_modified_md_files {
    if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
        git diff --name-only --diff-filter=d $(git merge-base HEAD master) | grep "\.md$" || true
    else
        find . -name \*.md -print || true
    fi
}

if [[ -n "$(list_modified_md_files)" ]]; then
    echo "$1"
    yaspeller_exit_code=0
    spellchecker_exit_code=0
    if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
        list_modified_md_files | xargs -d '\n' -n1 ~/.npm-global/bin/yaspeller --dictionary .yaspeller-dictionary.json {}
        yaspeller_exit_code=$?
        if [ "$1" != "--single" ]; then
            list_modified_md_files | xargs -d '\n' -n1 ~/.npm-global/bin/spellchecker --language=en-US --plugins spell repeated-words syntax-mentions syntax-urls --ignore "[A-Zx0-9./_-]+" "[u0-9a-fA-F]+" "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z" "[0-9dhms:-]+" "(metric|entity|tag|[emtv])[:0-9]*" --dictionaries .spelling --files {}
            spellchecker_exit_code=$?
        fi
    else
        ~/.npm-global/bin/yaspeller --max-requests 10 --dictionary .yaspeller-dictionary.json -e ".md" ./
        yaspeller_exit_code=$?
        if [ "$1" != "--single" ]; then
            ~/.npm-global/bin/spellchecker --language=en-US --plugins spell repeated-words syntax-mentions syntax-urls --ignore "[A-Zx0-9./_-]+" "[u0-9a-fA-F]+" "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z" "[0-9dhms:-]+" "(metric|entity|tag|[emtv])[:0-9]*" --dictionaries .spelling --files '**/*.md'
            spellchecker_exit_code=$?
        fi
    fi
    exit $((spellchecker_exit_code | yaspeller_exit_code))
else
    echo "Spell checking will be skipped"
fi