#!/bin/sh
#
# File: 6-build-llvm-runtimes.sh
# Desc: Build LLVM runtimes.

# Default values:
# ==================

default_install_dir=/
default_jobs=1
default_sysroot=/
default_target=x86_64-linux-musl
default_toolchain_dir=/cross-llvmmusl-toolchain

# Auxiliary functions:
# ==================

# usage: Display help text
usage() {
	cat << EOF
usage: 6-build-llvm-runtimes.sh [options] [command]
Build LLVM runtimes.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -D*              Option is passed to cmake.
    -I <dir>         Use <dir> as the installation directory.
    -S <dir>         Use <dir> as the sysroot for the toolchain.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    configure
    build
    install

defaults:
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
	rm -rf build-llvm-runtimes
}

# configure:
cmd_configure() {
	cmake -S runtimes -B build-llvm-runtimes -G "Unix Makefiles"     \
		${cmake_options_extra}                                   \
		-DCMAKE_BUILD_TYPE=Release                               \
		-DCMAKE_INSTALL_PREFIX="${INSTALL_DIR}/usr"              \
		-DCMAKE_C_COMPILER="${TOOLCHAIN_DIR}/bin/clang"          \
		-DCMAKE_CXX_COMPILER="${TOOLCHAIN_DIR}/bin/clang++"      \
		-DCMAKE_SYSTEM_NAME=Linux                                \
		-DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx"      \
		-DLIBUNWIND_USE_COMPILER_RT=true                         \
		-DLIBCXX_USE_COMPILER_RT=true                            \
		-DLIBCXX_HAS_MUSL_LIBC=On                                \
		-DLIBCXXABI_USE_COMPILER_RT=true                         \
		-DCMAKE_SYSROOT="$SYSROOT"                               \
		-DCMAKE_C_COMPILER_TARGET="$TARGET"                      \
		-DCMAKE_CXX_COMPILER_TARGET="$TARGET"                    \
		-DLLVM_TARGETS_TO_BUILD=X86                              \
		-DLLVM_ENABLE_ZSTD=false                                 \
		-DLLVM_ENABLE_ZLIB=false                                 \
		-DLIBCXX_HAS_ATOMIC_LIB=false                            \
		-DLIBCXXABI_HAS_CXA_THREAD_ATEXIT_IMPL=false             \
		-DCXX_SUPPORTS_FNO_EXCEPTIONS_FLAG=true                  \
		-DCMAKE_C_COMPILER_WORKS=true                            \
		-DCMAKE_CXX_COMPILER_WORKS=true
}

# build:
cmd_build() {
	make -C build-llvm-runtimes -j "$JOBS"
}

# install:
cmd_install() {
	make -C build-llvm-runtimes install
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
