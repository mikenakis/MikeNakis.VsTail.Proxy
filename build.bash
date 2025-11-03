#!/bin/bash

# For some reason, this shebang does not work even though it is the recommended one:
# #!/usr/bin/env bash

# Magical incantation to prevent silent failure if a command fails. (though this seems to be the default behavior.)
set -e

# Magical incantation to prevent silent failure if an undefined variable is used.
set -u

# Magical incantation to enable extended pattern matching.
shopt -s extglob

RunTests=No

while [ $# -gt 0 ]; do
  case "$1" in
      Configuration=*)
      Configuration="${1#*=}"
      ;;
      RunTests=@(Yes|No))
      RunTests="${1#*=}"
      ;;
    *)
      printf "Invalid argument: '$1'\n"
      exit 1
  esac
  shift
done

printf "Configuration: ${Configuration}; RunTests: ${RunTests};\n"

# PEARL: In GitHub, the output of `dotnet build` looks completely different from what it looks when building locally.
#        For example, the output of "Message" tasks is not shown, even when "Importance" is set to "High".
#        The "-ConsoleLoggerParameters:off" magical incantation corrects this problem.
# PEARL-ON-PEARL: The "-ConsoleLoggerParameters:off" magical incantation does not work when invoking `dotnet build`
#        locally. In this case, the "-TerminalLogger:off" magical incantation is necessary.
#        So, we use -TerminalLogger:off here too, for consistency.

echo ""
echo "RESTORE ================================================================="
echo ""
dotnet restore    -TerminalLogger:off -check

echo ""
echo "BUILD ==================================================================="
echo ""
dotnet build      -TerminalLogger:off -check --configuration ${Configuration} --no-restore

if [ "${RunTests}" = "Yes" ]; then
echo ""
echo "TEST ===================================================================="
echo ""
dotnet test       -TerminalLogger:off -check --configuration ${Configuration} --no-build --verbosity normal
fi
