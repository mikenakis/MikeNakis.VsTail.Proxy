#!/bin/bash

# [Claude] Keep the whole script inside a block that ends with `exit`, because the copy that this script starts may
#    replace this very file while bash is executing it.
# [Claude] Bash reads a block in full before executing it, and the `exit` keeps bash from reading the file any further.
{

set -o errexit -o nounset -o pipefail

if (( $# > 0 )); then
	echo "This script accepts no arguments; got: $*" >&2
	exit 1
fi

declare my_directory
my_directory=$(realpath --relative-to="$PWD" "$0")
my_directory=$(dirname "$my_directory")
declare -r my_directory

bash $my_directory/../MikeNakis.CommonFiles/copy_files_for_project.bash --target-directory=$my_directory

exit
}
