#!/bin/sh -e
#
# File: 1-build-llvm-cross.sh
# Desc: Build cross clang and lld.
#

# Default values:
# ==================

default_jobs=1
default_sysroot=/
default_toolchain_dir=/cross-llvmmusl-toolchain
default_target=x86_64-linux-musl

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 1-build-llvm-cross.sh [options] [command]
Build cross clang and lld.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -D*              Option is passed to cmake.
    -S <dir>         Use <dir> as the sysroot for traget toolchain.
    -T <dir>         Use <dir> as the target sysroot location.

commands:
    clean
    configure
    build
    install

defaults:
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
		cmake -S llvm -B build-llvm-cross -G "Unix Makefiles"\
		${cmake_options_extra}                               \
		-DCMAKE_BUILD_TYPE=Release                           \
	        -DCMAKE_SYSTEM_NAME="Linux"                          \
	        -DCMAKE_INSTALL_PREFIX="$TOOLCHAIN_DIR"              \
	        -DLLVM_TARGETS_TO_BUILD=X86                          \
	        -DLLVM_BUILD_TOOLS=ON                                \
	        -DLLVM_ENABLE_EH=ON                                  \
	        -DLLVM_ENABLE_RTTI=ON                                \
	        -DLLVM_ENABLE_LIBCXX=ON                              \
	        -DLLVM_ENABLE_PROJECTS="clang;lld"                   \
	        -DLLVM_ENABLE_RUNTIMES=""                            \
	        -DLLVM_DEFAULT_TARGET_TRIPLE="$TARGET"               \
	        -DCLANG_DEFAULT_RTLIB="compiler-rt"                  \
	        -DCLANG_DEFAULT_CXX_STDLIB="libc++"                  \
	        -DCLANG_DEFAULT_LINKER="lld"                         \
	        -DDEFAULT_SYSROOT="$SYSROOT"
}

# build:
cmd_build() {
	make -C build-llvm-cross -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-llvm-cross install
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
