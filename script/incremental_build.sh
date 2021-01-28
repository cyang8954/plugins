#!/bin/bash
set -e

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
readonly REPO_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/nnbd_plugins.sh"

if [ "$(expr substr $(uname -s) 1 5)" == "MINGW" ]; then
  PUB=pub.bat
else
  PUB=pub
fi

# Plugins that are excluded from this task.
ALL_EXCLUDED=()
# Exclude nnbd plugins from stable.
if [ "$CHANNEL" == "stable" ]; then
  ALL_EXCLUDED=($EXCLUDED_PLUGINS_FROM_STABLE)
fi

readonly FIREBASE_LAB_EXCLUDED_LIST=(
  "package_info"
)

readonly FIREBASE_LAB_EXCLUDED=$(IFS=, ; echo "${FIREBASE_LAB_EXCLUDED_LIST[@]}")
# EXCLUDE plugins in FIREBASE_LAB_EXCLUDED_LIST when the command is firebase-test-lab.
# TODO(cyanglaz): remove this when firebase test lab tests isues are resolved for plugins in FIREBASE_LAB_EXCLUDED_LIST
# https://github.com/flutter/flutter/issues/74944
if [ "$1" == "firebase-test-lab" ]; then
  if [ ${#ALL_EXCLUDED[@]} -eq 0 ]; then
      ALL_EXCLUDED=("$FIREBASE_LAB_EXCLUDED")
  else
      ALL_EXCLUDED=("$ALL_EXCLUDED, $FIREBASE_LAB_EXCLUDED")
  fi
fi

if [ ${#ALL_EXCLUDED[@]} -eq 0 ]; then
  ALL_EXCLUDED=("")
else
  echo "Excluding the following plugins: $ALL_EXCLUDED"
fi

# Plugins that deliberately use their own analysis_options.yaml.
#
# This list should only be deleted from, never added to. This only exists
# because we adopted stricter analysis rules recently and needed to exclude
# already failing packages to start linting the repo as a whole.
#
# TODO(mklim): Remove everything from this list. https://github.com/flutter/flutter/issues/45440
CUSTOM_ANALYSIS_PLUGINS=(
)

# Comma-separated string of the list above
readonly CUSTOM_FLAG=$(IFS=, ; echo "${CUSTOM_ANALYSIS_PLUGINS[*]}")
# Set some default actions if run without arguments.
ACTIONS=("$@")
if [[ "${#ACTIONS[@]}" == 0 ]]; then
  ACTIONS=("analyze" "--custom-analysis" "$CUSTOM_FLAG" "test" "java-test")
elif [[ "${ACTIONS[@]}" == "analyze" ]]; then
  ACTIONS=("analyze" "--custom-analysis" "$CUSTOM_FLAG")
fi

BRANCH_NAME="${BRANCH_NAME:-"$(git rev-parse --abbrev-ref HEAD)"}"

# This has to be turned into a list and then split out to the command line,
# otherwise it gets treated as a single argument.
PLUGIN_SHARDING=($PLUGIN_SHARDING)

if [[ "${BRANCH_NAME}" == "master" ]]; then
  echo "Running for all packages"
  (cd "$REPO_DIR" && $PUB global run flutter_plugin_tools "${ACTIONS[@]}" --exclude="$ALL_EXCLUDED" ${PLUGIN_SHARDING[@]})
else
  # Sets CHANGED_PACKAGES
  check_changed_packages

  if [[ "$CHANGED_PACKAGES" == "" ]]; then
    echo "No changes detected in packages."
    echo "Running for all packages"
    (cd "$REPO_DIR" && $PUB global run flutter_plugin_tools "${ACTIONS[@]}" --exclude="$ALL_EXCLUDED" ${PLUGIN_SHARDING[@]})
  else
    echo running "${ACTIONS[@]}"
    (cd "$REPO_DIR" && $PUB global run flutter_plugin_tools "${ACTIONS[@]}" --plugins="$CHANGED_PACKAGES" --exclude="$ALL_EXCLUDED" ${PLUGIN_SHARDING[@]})
    echo "Running version check for changed packages"
    # TODO(egarciad): Enable this check once in master.
    # (cd "$REPO_DIR" && $PUB global run flutter_plugin_tools version-check --base_sha="$(get_branch_base_sha)")
  fi
fi
