#!/usr/bin/env bash
npm install --global --production yaspeller@4.2.1 spellchecker-cli@4.0.0 markdown-link-check remark-cli markdownlint-cli@0.12.0 https://github.com/unrealwork/remark-validate-links
wget https://raw.githubusercontent.com/axibase/docs-util/master/python-scripts/dictionaries_generator.py -O dictionaries_generator.py
if [ "$GITHUB_REPOSITORY" == "axibase/atsd" ]; then
    python dictionaries_generator.py --mode=atsd
else
    if [ -f .dictionary ]; then
        python dictionaries_generator.py --mode=legacy
    else
        python dictionaries_generator.py --mode=default
    fi
    if [ ! -f .markdownlint.json ]; then
        wget https://raw.githubusercontent.com/axibase/atsd/master/.markdownlint.json
    fi
    if [ ! -f .yaspellerrc ]; then
        wget https://raw.githubusercontent.com/axibase/atsd/master/.yaspellerrc
    fi
fi