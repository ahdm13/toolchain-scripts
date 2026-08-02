#!/bin/sh -e
#
# File: 2-build-kernel-headers.sh
# Desc: Build kernel headers.
#

# Default values:
# ==================

default_jobs=1
default_install_dir=/

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 2-build-kernel-headers.sh [options] [command]
Build kernel headers.

options:
    -h          Display this help text.
    -j <N>      Perform <N> number of jobs simultaneously.
    -I <dir>    Use <dir> as the installation directory.

commands:
    clean
    build
    install

defaults:
    JOBS           ${default_jobs}
    INSTALL_DIR    ${default_install_dir}
EOF
}

# Commands:
# ==================

# clean:
cmd_clean() {
	make mrproper
	make clean
}

# build:
cmd_build() {
	make -j "$JOBS" headers
}

# install:
cmd_install() {
	make INSTALL_HDR_PATH="${INSTALL_DIR}" headers_install
}

# Main script:
# ==================

# Parse command-line options:
while [ "$#" != 0 ]; do
	opt="$1"
	case "$opt" in
		-h)
			usage
			exit 0
			;;
		-j)
			JOBS="$2"
			shift
			;;
		-I)
			INSTALL_DIR="$2"
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
JOBS="${JOBS:-$default_jobs}"
INSTALL_DIR="${INSTALL_DIR:-$default_install_dir}"

# Execute commands:
if [ "$#" = 0 ]; then
	cmd_clean &&
	cmd_build &&
	cmd_install

	exit $?
fi

cmd="$1" && shift
case "$cmd" in
	clean)     cmd_clean $@ || exit $? ;;
	build)     cmd_build $@ || exit $? ;;
	install)   cmd_install $@ || exit $? ;;
	*)         echo "E: Unknown command: $cmd" >&2; exit 2 ;;
esac
