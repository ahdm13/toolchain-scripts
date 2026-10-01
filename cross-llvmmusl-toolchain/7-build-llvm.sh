#!/bin/sh -e
#
# File: 7-build-llvm.sh
# Desc: Build clang and lld.
#

# Default values:
# ==================

default_install_dir=/
default_jobs=1
default_sysroot=/
default_toolchain_dir=/cross-llvmmusl-toolchain
default_target=x86_64-linux-musl

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 7-build-llvm.sh [options] [command]
Build clang and lld.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -D*              Option is passed to cmake.
    -I <dir>         Use <dir> as the installation directory.
    -S <dir>         Use <dir> as the sysroot for traget toolchain.
    -T <dir>         Use <dir> as the target sysroot location.

commands:
    clean
    configure
    build
    install

defaults:
    INSTALL_DIR      ${default_install_dir}
    JOBS             ${default_jobs}
    SYSROOT          ${default_sysroot}
    TOOLCHAIN_DIR    ${default_toolchain_dir}
    TARGET           ${default_target}
EOF
}

# Commands:
# ==================

# clean:
cmd_clean() {
	rm -rf build-llvm
}

# configure:
cmd_configure() {
	echo "$cmake_options_extra" | xargs -d '\n'                  \
		cmake -S llvm -B build-llvm -G "Unix Makefiles"      \
		${cmake_options_extra}                               \
		-DCMAKE_BUILD_TYPE=Release                           \
	        -DCMAKE_SYSTEM_NAME="Linux"                          \
		-DCMAKE_C_COMPILER="${TOOLCHAIN_DIR}/bin/clang"      \
		-DCMAKE_CXX_COMPILER="${TOOLCHAIN_DIR}/bin/clang++"  \
	        -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR"                \
		-DCMAKE_SYSROOT="$SYSROOT"                           \
	        -DLLVM_TARGETS_TO_BUILD=X86                          \
	        -DLLVM_ENABLE_LIBCXX=ON                              \
		-DLLVM_ENABLE_ZSTD=false                             \
		-DLLVM_ENABLE_ZLIB=false                             \
		-DLLVM_ENABLE_LIBXML2=0                              \
	        -DLLVM_ENABLE_PROJECTS="clang;lld"                   \
	        -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET"               \
	        -DCLANG_DEFAULT_RTLIB="compiler-rt"                  \
	        -DCLANG_DEFAULT_CXX_STDLIB="libc++"                  \
	        -DCLANG_DEFAULT_LINKER="lld"
}

# build:
cmd_build() {
	make -C build-llvm -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-llvm install

	clang_target_triple=`"${TOOLCHAIN_DIR}/bin/clang" -print-target-triple`
	clang_resource_dir=`"${TOOLCHAIN_DIR}/bin/clang" -print-resource-dir`

	echo $target_triple

	install_resource_dir=`echo "$clang_resource_dir" | sed -e "s?^${TOOLCHAIN_DIR}?${INSTALL_DIR}?"`
	mkdir -pv "${install_resource_dir}/lib"
	cp -av "${clang_resource_dir}/lib/${clang_target_triple}" "${install_resource_dir}/lib"
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
			cmake_options_extra="${cmake_options_extra}
$opt"
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
