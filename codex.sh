#!/bin/bash
# codex.sh, ABr
#
# Locate/run codex within vs code folder

# locate script source directory
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
the_codex_script_dir="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# codex binary
#find "$HOME"/.vscode/extensions -name codex -type f 2>/dev/null
the_codex_binary_path=`find "$HOME"/.vscode/extensions -name codex -type f 2>/dev/null | sort -r | head -n 1`
if [ ! -x "$the_codex_binary_path" ] ; then
  echo 'Unable to locate codex binary'
	exit 1
fi

# run command
"$the_codex_binary_path" "$@"

