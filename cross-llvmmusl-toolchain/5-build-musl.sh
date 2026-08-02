#!/bin/sh -e
#
# File: 5-build-musl.sh
# Desc: Build musl.
#

# Default values:
# ==================

default_install_dir=/
default_jobs=1
default_target=x86_64-linux-musl
default_toolchain_dir=/cross-llvmmusl-toolchain

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 5-build-musl.sh [options] [command]
Build musl.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -D*              Option is passed to cmake.
    -I <dir>         Use <dir> as the installation directory.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    configure
    build
    install

defaults:
    INSTALL_DIR      ${default_install_dir}
    JOBS             ${default_jobs}
    TARGET           ${default_target}
    TOOLCHAIN_DIR    ${default_toolchain_dir}
EOF
}

# Commands:
# ==================

# clean:
cmd_clean() {
	rm -rf build-musl
}

# configure:
cmd_configure() {
	mkdir -p build-musl
	cd build-musl

	../configure                                   \
		--prefix=/usr                          \
		--target="$TARGET"                     \
		AR="${TOOLCHAIN_DIR}/bin/llvm-ar"      \
		CC="${TOOLCHAIN_DIR}/bin/clang"        \
		RANLIB="${TOOLCHAIN_DIR}/bin/llvm-ranlib"

	cd ..
}

# build:
cmd_build() {
	make -C build-musl -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-musl DESTDIR="$INSTALL_DIR" install

	rm -rf "${INSTALL_DIR}/lib"
	mkdir -p "${INSTALL_DIR}/usr/lib"
	ln -svf libc.so "${INSTALL_DIR}/usr/lib/ld-musl-x86_64.so.1"
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
		-t)
			TARGET="$2"
			shift
			;;
		-D*)
			cmake_options_extra="${cmake_options_extra} $opt"
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
JOBS="${JOBS:-$default_jobs}"
TARGET="${TARGET:-$default_target}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$default_toolchain_dir}"

# Execute commands:
if [ "$#" = 0 ]; then
	cmd_clean &&
	cmd_configure &&
	cmd_build &&
	cmd_install

	exit $?
fi

cmd="$1" && shift
case "$cmd" in
	clean)     cmd_clean $@ || exit $? ;;
	configure) cmd_configure $@ || exit $? ;;
	build)     cmd_build $@ || exit $? ;;
	install)   cmd_install $@ || exit $? ;;
	*)         echo "E: Unknown command: $cmd" >&2; exit 2 ;;
esac
