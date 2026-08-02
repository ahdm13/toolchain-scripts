#!/bin/sh
#
# File: 5-libstdc++.sh
# Desc: Build libstdc++.

# Default values:
# ==================

default_gcc_ver=15.2.0
default_install_dir=/
default_jobs=1
default_sysroot=/
default_target=x86_64-linux-gnu
default_toolchain_dir=/cross-gnu-toolchain

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 5-libstdc++.sh [options] [command]
Build libstdc++.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -I <dir>         Use <dir> as the installation directory.
    -S <dir>         Use <dir> as the sysroot for the toolchain.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    configure
    build
    install

defaults:
    GCC_VER          ${default_gcc_ver}
    INSTALL_DIR      ${default_install_dir}
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
	rm -rf build-libstdc++
}

# configure:
cmd_configure() {
	mkdir -p build-libstdc++
	cd build-libstdc++

	../libstdc++-v3/configure          \
		--host="$TARGET"           \
		--build=`../config.guess`  \
		--prefix=/usr              \
		--disable-multilib         \
		--disable-nls              \
		--disable-libstdcxx-pch    \
		--with-gxx-include-dir="/gxx_include"

	cd ..
}

# build:
cmd_build() {
	make -C build-libstdc++ -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-libstdc++ DESTDIR="$INSTALL_DIR" install

	rm -rf "${TOOLCHAIN_DIR}/${TARGET}/include/c++/${GCC_VER}"
	mkdir -pv "${TOOLCHAIN_DIR}/${TARGET}/include/c++"
	mv -v "${INSTALL_DIR}/gxx_include" "${TOOLCHAIN_DIR}/${TARGET}/include/c++/${GCC_VER}"

	find "${INSTALL_DIR}/usr/lib" -type f -name '*.la' -delete
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
		-I)
			INSTALL_DIR="$2"
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
GCC_VER="${GCC_VER:-$default_gcc_ver}"
INSTALL_DIR="${INSTALL_DIR:-$default_install_dir}"
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
