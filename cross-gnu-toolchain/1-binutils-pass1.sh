#!/bin/sh
#
# File: 1-binutils-pass1.sh
# Desc: Build pass 1 of binutils.
#

# Default values:
# ==================

default_jobs=1
default_sysroot=/
default_target=x86_64-linux-gnu
default_toolchain_dir=/cross-gnu-toolchain

# Auxiliary functions:
# ==================
#

usage() {
	cat << EOF
USAGE: 1-build-pass1.sh [options] [command]
OPTIONS:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -S <dir>         Use <dir> as the sysroot for the toolchain.
    -T <dir>         Use <dir> as the toolchain installation directory.
COMMANDS:
    clean
    configure
    build
    install
DEFAULTS:
    JOBS             ${default_jobs}
    SYSROOT          ${default_sysroot}
    TARGET           ${default_target}
    TOOLCHAIN_DIR    ${default_toolchain_dir}
EOF
}

# Commands:
# ==================

# clean:
cmd_clean() {
	rm -rf build-bintuils-pass1
}

# configure:
cmd_configure() {
	mkdir -p build-binutils-pass1
	cd build-binutils-pass1

	../configure                      \
		--prefix="$TOOLCHAIN_DIR" \
		--with-sysroot="$SYSROOT" \
		--target="$TARGET"        \
		--disable-nls             \
		--enable-gprofng=no       \
		--disable-werror          \
		--enable-new-dtags        \
		--enable-default-hash-style=gnu

	cd ..
}

# build:
cmd_build() {
	make -C build-binutils-pass1 -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-binutils-pass1 install
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
		-S)
			SYSROOT="$2"
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
JOBS="${JOBS:-$default_jobs}"
SYSROOT="${SYSROOT:-$default_sysroot}"
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
