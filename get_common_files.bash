#!/bin/bash
declare -r here=$(dirname $(realpath --relative-to="$PWD" "$0"))
bash $here/../MikeNakis.CommonFiles/copy_files_for_project.bash --target-directory=$here
