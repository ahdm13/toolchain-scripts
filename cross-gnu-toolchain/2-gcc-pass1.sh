#!/bin/sh -e
#
# File: 2-gcc-pass1.sh
# Desc: Build pass1 gcc.
#

# Default values:
# ==================

default_glibc_ver=2.43
default_jobs=1
default_sysroot=/
default_toolchain_dir=/cross-gnu-toolchain
default_target=x86_64-linux-gnu

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 2-gcc-pass1.sh [options] [command]
Build pass1 gcc.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -S <dir>         Use <dir> as the sysroot for the toolchain.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    configure
    build
    install

defaults:
    JOBS             ${default_jobs}
    GLIBC_VER        ${default_glibc_ver}
    SYSROOT          ${default_sysroot}
    TARGET           ${default_target}
    TOOLCHAIN_DIR    ${default_toolchain_dir}
EOF
}

# Commands:
# ==================

# clean:
cmd_clean() {
	rm -rf build-gcc-pass1
	if [ -f gcc/config/i386/t-linux64.orig ]; then
		mv gcc/config/i386/t-linux64.orig gcc/config/i386/t-linux64
	fi
}

# configure:
cmd_configure() {
	sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64

	mkdir -p build-gcc-pass1
	cd build-gcc-pass1

	../configure                              \
		--target="$TARGET"                \
		--prefix="$TOOLCHAIN_DIR"         \
		--with-glibc-version="$GLIBC_VER" \
		--with-sysroot="$SYSROOT"         \
		--with-newlib                     \
		--without-headers                 \
		--enable-default-pie              \
		--enable-default-ssp              \
		--disable-nls                     \
		--disable-shared                  \
		--disable-multilib                \
		--disable-threads                 \
		--disable-libatomic               \
		--disable-libgomp                 \
		--disable-libquadmath             \
		--disable-libssp                  \
		--disable-libvtv                  \
		--disable-libstdcxx               \
		--enable-languages=c,c++

	cd ..
}

# build:
cmd_build() {
	make -C build-gcc-pass1 -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-gcc-pass1 install

	libgcc_file_name=`"${TOOLCHAIN_DIR}/bin/${TARGET}-gcc" -print-libgcc-file-name`
	cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
		`dirname "$libgcc_file_name"`/include/limits.h
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
GLIBC_VER="${GLIBC_VER:-$default_glibc_ver}"
JOBS="${JOBS:-$default_jobs}"
SYSROOT="${SYSROOT:-$default_sysroot}"
TARGET="${TARGET:-$default_target}"
TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-$default_toolchain_dir}"

export PATH="${TOOLCHAIN_DIR}/bin:$PATH"

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
