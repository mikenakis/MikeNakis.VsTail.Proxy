#!/bin/bash

set -o errexit -o nounset -o pipefail

declare my_directory
my_directory=$(realpath --relative-to="$PWD" "$0")
my_directory=$(dirname "$my_directory")
declare -r my_directory

bash $my_directory/../MikeNakis.CommonFiles/copy_files_for_project.bash --target-directory=$my_directory
