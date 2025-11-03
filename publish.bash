#!/bin/bash

# For some reason, this shebang does not work even though it is the recommended one:
# #!/usr/bin/env bash

# Magical incantation to prevent silent failure if a command fails. (though this seems to be the default behavior.)
set -e

# Magical incantation to prevent silent failure if an undefined variable is used.
set -u

# Magical incantation to enable extended pattern matching.
shopt -s extglob

while [ $# -gt 0 ]; do
  case "$1" in
      Configuration=*)
      Configuration="${1#*=}"
      ;;
      ProjectName=*)
      ProjectName="${1#*=}"
      ;;
      Version=*)
      Version="${1#*=}"
      ;;
      Address=*)
      Address="${1#*=}"
      ;;
      ApiKey=*)
      ApiKey="${1#*=}"
      ;;
    *)
      printf "Invalid argument: '$1'\n"
      exit 1
  esac
  shift
done

printf "Configuration: ${Configuration}; ProjectName: ${ProjectName}; Version: ${Version}; Address: ${Address}; ApiKey: ${ApiKey}\n"

echo ""
echo "PACK ===================================================================="
echo ""
dotnet pack       -TerminalLogger:off -check --configuration ${Configuration} --no-build --property:PackageVersion=${Version}
echo "It worked, I guess."

echo ""
echo "NUGET PUSH =============================================================="
echo ""
dotnet nuget push ${ProjectName}/bin/${Configuration}/*.nupkg --source ${Address} --api-key ${ApiKey}

