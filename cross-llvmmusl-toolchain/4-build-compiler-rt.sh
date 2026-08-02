#!/bin/sh -e
#
# File: 4-build-compiler-rt.sh
# Desc: Build compiler-rt for clang.
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
usage: 4-build-compiler-rt.sh [options] [command]
Build compiler-rt for clang.

options:
    -h               Display this help text.
    -j <N>           Perform <N> number of jobs simultaneously.
    -t <target>      Set the target triple to <target>.
    -D*              Option is passed to cmake.
    -S <dir>         Use <dir> as the sysroot for the toolchain.
    -T <dir>         Use <dir> as the toolchain directory.

commands:
    clean
    configure
    build
    install

defaults:
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
	rm -rf build-compiler-rt
}

# configure:
cmd_configure() {
	install_dir=`"${TOOLCHAIN_DIR}/bin/clang" -print-resource-dir`
	clang_target_triple=`"${TOOLCHAIN_DIR}/bin/clang" -print-target-triple`
	
	# Configure:
	cmake -S compiler-rt -B build-compiler-rt -G "Unix Makefiles"    \
		${cmake_options_extra}                                   \
		-DCMAKE_INSTALL_PREFIX="$install_dir"                    \
		-DCMAKE_SYSROOT="$SYSROOT"                               \
		-DCMAKE_SYSTERM_NAME=Linux                               \
		-DCMAKE_BUILD_TYPE=Release                               \
		-DCMAKE_C_COMPILER="${TOOLCHAIN_DIR}/bin/clang"     \
		-DCMAKE_CXX_COMPILER="${TOOLCHAIN_DIR}/bin/clang++" \
		-DCMAKE_ASM_COMPILER_TARGET="$TARGET"                    \
		-DCMAKE_C_COMPILER_TARGET="$TARGET"                      \
		-DCMAKE_CXX_COMPILER_TARGET="$TARGET"                    \
		-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON                     \
		-DCOMPILER_RT_BUILD_CTX_PROFILE=OFF                      \
		-DCOMPILER_RT_BUILD_SANITIZERS=OFF                       \
		-DCOMPILER_RT_BUILD_LIBFUZZER=OFF                        \
		-DCOMPILER_RT_BUILD_BUILTINS=ON                          \
		-DCOMPILER_RT_BUILD_MEMPROF=OFF                          \
		-DCOMPILER_RT_BUILD_PROFILE=OFF                          \
		-DCOMPILER_RT_BUILD_XRAY=OFF                             \
		-DCOMPILER_RT_BUILD_ORC=OFF                              \
		-DCOMPILER_RT_BUILD_CRT=ON                               \
		-DCMAKE_C_FLAGS="-nostdlib"                              \
		-DCMAKE_CXX_FLAGS="-nostdlib"
}

# build:
cmd_build() {
	make -C build-compiler-rt -j "$JOBS"
}

# install:
cmd_install() {
	install_dir=`"${TOOLCHAIN_DIR}/bin/clang" -print-resource-dir`
	clang_target_triple=`"${TOOLCHAIN_DIR}/bin/clang" -print-target-triple`
	
	make -C build-compiler-rt install

	cd "${install_dir}/lib"
	mkdir -pv "$clang_target_triple"

	mv -v linux/clang_rt.crtbegin-x86_64.o    "${clang_target_triple}/crtbeginS.o"
	mv -v linux/clang_rt.crtend-x86_64.o      "${clang_target_triple}/crtendS.o"
	mv -v linux/libclang_rt.builtins-x86_64.a "${clang_target_triple}/libclang_rt.builtins.a"

	rmdir -v linux 2>/dev/null || true
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
