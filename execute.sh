#!/usr/bin/env bash

function install_checker() {
  export NPM_CONFIG_PREFIX=~/.npm-global
  type=$1
  package=""
  case "$type" in
  links) package="markdown-link-check";
    if [ ! -f ".linkcheck-config.json" ]; then
      wget https://raw.githubusercontent.com/axibase/atsd/master/.linkcheck-config.json
    fi
    ;;
  anchors) package="remark-cli https://github.com/unrealwork/remark-validate-links" ;;
  spelling) package="yaspeller@4.2.1 spellchecker-cli@4.0.0";
    wget https://raw.githubusercontent.com/axibase/docs-util/master/python-scripts/dictionaries_generator.py -O dictionaries_generator.py
    if [ "$GITHUB_REPOSITORY" == "axibase/atsd" ]; then
      python dictionaries_generator.py --mode=atsd
    else
      if [ -f .dictionary ]; then
          python dictionaries_generator.py --mode=legacy
      else
          python dictionaries_generator.py --mode=default
      fi
      if [ ! -f .yaspellerrc ]; then
          wget https://raw.githubusercontent.com/axibase/atsd/master/.yaspellerrc
      fi
    fi
    ;;
  style) package="markdownlint-cli@0.12.0";
    if [ ! -f .markdownlint.json ]; then
        wget https://raw.githubusercontent.com/axibase/atsd/master/.markdownlint.json
    fi
    ;;
  * ) echo "Unknown linter: ${type}" && exit 1 ;;
  esac
  npm install --global --production ${package}
}

function list_modified_md_files {
    case "$GITHUB_EVENT_NAME" in
      pull_request ) PR_ID=$(echo $GITHUB_REF | sed -n 's/.*pull\/\(.*\)\/merge/\1/p') ;
        curl -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${PR_ID}/files | jq --raw-output 'map(.filename)' | sed -n 's/ *"\(.*\)".*/\1/p' | grep "\.md$" || true ;;
      push ) git diff --name-only --diff-filter=d "HEAD^..${GITHUB_SHA}" | grep "\.md$" || true ;;
      * ) find . -name \*.md -print || true ;;
    esac
}

function linkcheck() {
  if [[ -n "$(list_modified_md_files)" ]]; then
    install_checker links
    list_modified_md_files | xargs -d '\n' -n1 ~/.npm-global/bin/markdown-link-check -v -c .linkcheck-config.json
  else
      echo "Link checking will be skipped"
  fi
}

function validate_anchors() {
  install_checker anchors
  ~/.npm-global/bin/remark -f -q --no-stdout -u "validate-links=repository:\"${GITHUB_REPOSITORY}\"" .
}

function spellcheck_retext() {
  if [[ -n "$(list_modified_md_files)" ]]; then
    install_checker spelling
    if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
      list_modified_md_files | xargs -d '\n' -n1 ~/.npm-global/bin/spellchecker --language=en-US --plugins spell repeated-words syntax-mentions syntax-urls --ignore "[A-Zx0-9./_-]+" "[u0-9a-fA-F]+" "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z" "[0-9dhms:-]+" "(metric|entity|tag|[emtv])[:0-9]*" --dictionaries .spelling --files {}
    else
      ~/.npm-global/bin/spellchecker --language=en-US --plugins spell repeated-words syntax-mentions syntax-urls --ignore "[A-Zx0-9./_-]+" "[u0-9a-fA-F]+" "[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z" "[0-9dhms:-]+" "(metric|entity|tag|[emtv])[:0-9]*" --dictionaries .spelling --files '**/*.md'
    fi
  else
      echo "Spell checking will be skipped"
  fi
}

function spellcheck_yandex() {
  if [[ -n "$(list_modified_md_files)" ]]; then
    install_checker spelling
    if [ "$GITHUB_EVENT_NAME" == "pull_request" ]; then
      list_modified_md_files | xargs -d '\n' -n1 ~/.npm-global/bin/yaspeller --dictionary .yaspeller-dictionary.json {}
    else
      ~/.npm-global/bin/yaspeller --max-requests 10 --dictionary .yaspeller-dictionary.json -e ".md" ./
    fi
  else
      echo "Spell checking will be skipped"
  fi
}


function spellcheck() {
  if [[ -n "$(list_modified_md_files)" ]]; then
    yaspeller_exit_code=0
    spellchecker_exit_code=0
    spellcheck_yandex
    yaspeller_exit_code=$?
    spellcheck_retext
    spellchecker_exit_code=$?
    exit $((spellchecker_exit_code | yaspeller_exit_code))
  else
      echo "Spell checking will be skipped"
  fi
}

function stylecheck() {
  if [[ -n "$(list_modified_md_files)" ]]; then
    install_checker style
    git clone https://github.com/axibase/docs-util --depth=1
    exit_code=0
    if [[ "$GITHUB_EVENT_NAME" == "pull_request" ]]; then
      if [[ -n "$(list_modified_md_files)" ]]; then
          list_modified_md_files | xargs -d '\n' -n1 ~/.npm-global/bin/markdownlint -i docs-util -r 'docs-util/linting-rules/*' {}
          exit_code=$?
      fi;
    else
      ~/.npm-global/bin/markdownlint -i docs-util -r 'docs-util/linting-rules/*' .
      exit_code=$?
    fi
    rm -rf docs-util
    exit $exit_code
  else
    echo "Style checking will be skipped"
  fi
}

echo "Files to be checked:"
list_modified_md_files

linter=$1
case "$linter" in
links) linkcheck ;;
anchors) validate_anchors ;;
spelling) spellcheck ;;
spelling_retext) spellcheck_retext ;;
spelling_yandex) spellcheck_yandex ;;
style) stylecheck ;;
*) echo "Unknown linter: $linter" && exit 1 ;;
esac
