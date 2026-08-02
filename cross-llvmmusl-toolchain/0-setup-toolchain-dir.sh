#!/bin/sh -e
#
# File: 0-setup-toolchain.sh
# Desc: Create and setup the toolchain directory.
#

# Default values:
# ==================

default_toolchain_dir=/cross-llvmmusl-toolchain

# Auxiliary commands:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 0-setup-toolchain.sh [options] [commands]
Create and setup the toolchain directory.

options:
    -h               Display this help text.
    -T <dir>         Use <dir> as the target toolchain directory.

commands:
    setup

defaults:
    TOOLCHAIN_DIR    ${default_toolchain_dir}
EOF
}

# Commands:
# ==================

# setup:
cmd_setup() {
	rm -rf "$TOOLCHAIN_DIR"
	mkdir -p "$TOOLCHAIN_DIR"
	ln -sf . "${TOOLCHAIN_DIR}/usr"
}

# Main script:
# ==================

# Parse command-line arguments:
while [ "$#" != 0 ]; do
	opt="$1"
	case "$opt" in
		-h)
			usage
			exit 0
			;;
		-T)
			TOOLCHAIN_DIR="$2"
			shift
			;;
		-*)
			echo "E: Unrecognized option: ${opt}" >&2
			exit 1
			;;
		*)
			break
			;;
	esac
	if [ "$#" = 0 ]; then
		echo "E: Option '${opt}' requires an operand" >&2
		exit 1
	fi
	shift
done

# Assign default values for unspecified variables:
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$default_toolchain_dir}"

# Execute commands:
if [ "$#" = 0 ]; then
	cmd_setup
	exit $?
fi

cmd="$1" && shift
case "$cmd" in
	setup) cmd_setup $@ || exit $? ;;
	*)     echo "E: Unknown command: $cmd" >&2; exit 2 ;;
esac
