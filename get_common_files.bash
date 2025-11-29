#!/bin/bash

set -o errexit -o nounset -o pipefail

function get()
{
	bash ../MikeNakis.CommonFiles/copy_file.bash "--source=$1" "--target=${2-}"
}

get .editorconfig 
get .gitignore
get .gitattributes
get AllCode.globalconfig 
get AllProjects.proj.xml 
get BannedApiAnalyzers.proj.xml 
get BannedSymbols.txt 
get definitions.bash 
get get_version.bash 
get ProductionCode.globalconfig 
get TestCode.globalconfig 
