#!/bin/bash

declare -r my_directory=$(dirname $(realpath --relative-to="$PWD" "$0"))

bash $my_directory/../MikeNakis.CommonFiles/copy_files_for_project.bash --target-directory=$my_directory
