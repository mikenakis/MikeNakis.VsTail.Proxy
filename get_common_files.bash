#!/bin/bash

set -o errexit -o nounset -o pipefail

bash ../MikeNakis.CommonFiles/copy_files.bash "$(dirname $0)" \
.editorconfig \
.gitignore \
.gitattributes \
AllCode.globalconfig \
AllProjects.proj.xml \
BannedApiAnalyzers.proj.xml \
BannedSymbols.txt \
ProductionCode.globalconfig \
TestCode.globalconfig
# build.bash
# publish.bash
