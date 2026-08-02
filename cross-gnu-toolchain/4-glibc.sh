#!/bin/sh -e
#
# File: 4-glibc.sh
# Desc: Build glibc.
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
usage: 5-glibc.sh [options] [command]
Build glibc.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -I <dir>         Use <dir> as the installation directory.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    prepare
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
	rm -rf build-glibc
	if ! cat glibc_fhs-1.patch >/dev/null 2>&1; then
		return
	fi

	for i in `cat glibc_fhs-1.patch | grep '^---' | awk '{ print $2 }' | sed -e 's?^a/??'`; do
		if [ ! -e "${i}.orig" ]; then
			continue
		fi
		mv "${i}.orig" "$i"
	done
}

# prepare:
cmd_prepare() {
	for i in `cat glibc_fhs-1.patch | grep '^---' | awk '{ print $2 }' | sed -e 's?^a/??'`; do
		cp "$i" "${i}.orig"
	done
	patch -Np1 -i glibc_fhs-1.patch
}

# configure:
cmd_configure() {
	mkdir -p build-glibc
	cd build-glibc

	echo "rootsbindir=/usr/sbin" > configparms
	../configure                               \
		--prefix=/usr                      \
		--host="$TARGET"                   \
		--build=`../scripts/config.guess`  \
		--disable-nscd                     \
		libc_cv_slibdir=/usr/lib           \
		--enable-kernel=5.4

	cd ..
}

# build:
cmd_build() {
	make -C build-glibc -j "$JOBS"
}

# install:
cmd_install() {
	mkdir -p "${INSTALL_DIR}/lib64"
	rm -fv "${INSTALL_DIR}/lib64/ld-lsb-x86-64.so.3"

	make -C build-glibc DESTDIR="${INSTALL_DIR}" install

	sed '/RTLDLIST=/s@/usr@@g' -i "${INSTALL_DIR}/usr/bin/ldd"

	ln -sfv ../usr/lib/ld-linux-x86-64.so.2 "${INSTALL_DIR}/lib64"
	ln -sfv ../usr/lib/ld-linux-x86-64.so.2 "${INSTALL_DIR}/lib64/ld-lsb-x86-64.so.3"
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

export PATH="${TOOLCHAIN_DIR}/bin:$PATH"

# Execute commands:
if [ "$#" = 0 ]; then
	cmd_clean &&
	cmd_prepare &&
	cmd_configure &&
	cmd_build &&
	cmd_install

	exit $?
fi

cmd="$1" && shift
case "$cmd" in
	clean)     cmd_clean $@ || exit $? ;;
	prepare)   cmd_prepare $@ || exit $? ;;
	configure) cmd_configure $@ || exit $? ;;
	build)     cmd_build $@ || exit $? ;;
	install)   cmd_install $@ || exit $? ;;
	*)         echo "E: Unknown command: $cmd" >&2; exit 2 ;;
esac
