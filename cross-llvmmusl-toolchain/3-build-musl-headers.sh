#!/bin/sh -e
#
# File: 3-build-musl-headers.sh
# Desc: Build musl headers.
#

# Default values:
# ==================

default_install_dir=/
default_toolchain_dir=/cross-llvmmusl-toolchain
default_target=x86_64-linux-musl

# Auxiliary functions:
# ==================

# usage: Display help text:
usage() {
	cat << EOF
usage: 3-build-musl-headers.sh [options] [command]
Build musl headers.

options:
    -h               Display this help text.
    -t <target>      Set the target triple to <target>.
    -I <dir>         Use <dir> as the installation directory.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    configure
    install

defaults:
    INSTALL_DIR      ${default_install_dir}
    TARGET           ${default_target}
    TOOLCHAIN_DIR    ${default_toolchain_dir}
EOF
}

# Commands:
# ==================

# clean:
cmd_clean() {
	rm -rf build-musl-headers
}

# configure:
cmd_configure() {
	mkdir -p build-musl-headers
	cd build-musl-headers

	../configure                              \
		--prefix=/usr                     \
		--target="$TARGET"                \
		AR="${TOOLCHAIN_DIR}/bin/llvm-ar" \
		CC="${TOOLCHAIN_DIR}/bin/clang"   \
		RANLIB="${TOOLCHAIN_DIR}/bin/llvm-ranlib"

	cd ..
}

# install:
cmd_install() {
	make -C build-musl-headers DESTDIR="$INSTALL_DIR" install-headers
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
		-t)
			TARGET="$2"
			shift
			;;
		-I)
			INSTALL_DIR="$2"
			shift
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
INSTALL_DIR="${INSTALL_DIR:-$default_install_dir}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$default_toolchain_dir}"
TARGET="${TARGET:-$default_target}"

# Execute commands:
if [ "$#" = 0 ]; then
	cmd_clean &&
	cmd_configure &&
	cmd_install

	exit $?
fi

cmd="$1" && shift
case "$cmd" in
	clean)     cmd_clean $@ || exit $? ;;
	configure) cmd_configure $@ || exit $? ;;
	install)   cmd_install $@ || exit $? ;;
	*)         echo "E: Unknown command: $cmd" >&2; exit 2 ;;
esac
