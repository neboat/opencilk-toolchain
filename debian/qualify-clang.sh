#!/bin/sh
# Stop at the first error
set -e

VERSION=8
DETAILED_VERSION=7~+rc1-1~exp2

echo "To install everything:"
echo "sudo dpkg -i libomp5-${VERSION}_${DETAILED_VERSION}_amd64.deb libomp-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb lldb-${VERSION}_${DETAILED_VERSION}_amd64.deb python-lldb-${VERSION}_${DETAILED_VERSION}_amd64.deb libllvm7_${DETAILED_VERSION}_amd64.deb llvm-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb liblldb-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb  libclang1-${VERSION}_${DETAILED_VERSION}_amd64.deb  libclang-common-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb  llvm-${VERSION}_${DETAILED_VERSION}_amd64.deb  liblldb-${VERSION}_${DETAILED_VERSION}_amd64.deb  llvm-${VERSION}-runtime_${DETAILED_VERSION}_amd64.deb lld-${VERSION}_${DETAILED_VERSION}_amd64.deb libfuzzer-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libclang-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libc++-${VERSION}-dev_${DETAILED_VERSION}_amd64.deb libc++1-${VERSION}_${DETAILED_VERSION}_amd64.deb libc++-${VERSION}-helpers_${DETAILED_VERSION}_all.deb clang-${VERSION}_${DETAILED_VERSION}_amd64.deb"


if test ! -f /usr/bin/llvm-config-$VERSION; then
    echo "Install llvm-$VERSION & llvm-$VERSION-dev"
    exit 1
fi
llvm-config-$VERSION --link-shared --libs &> /dev/null

echo '#include <stdlib.h>
int main() {
  char *x = (char*)malloc(10 * sizeof(char*));
  free(x);
  return x[5];
}
' > foo.c
clang-$VERSION -o foo -fsanitize=address -O1 -fno-omit-frame-pointer -g  foo.c
if ! ./foo 2>&1 | grep -q heap-use-after-free ; then
    echo "sanitize=address is failing"
    exit 42
fi

echo 'int main() {return 0;}' > foo.c
clang-$VERSION foo.c

echo '#include <stddef.h>' > foo.c
clang-$VERSION -c foo.c



# bug 903709
echo '#include <stdatomic.h>
void increment(atomic_size_t *arg) {
    atomic_fetch_add(arg, 1);
} ' > foo.c

#clang-$VERSION -v -c foo.c

echo "#include <fenv.h>" > foo.cc
NBLINES=$(clang++-$VERSION -P -E foo.cc|wc -l)
if test $NBLINES -lt 100; then
    echo "Error: more than 100 lines should be returned"
    exit 42
fi

echo '#include <emmintrin.h>' > foo.cc
clang++-$VERSION -c foo.cc

echo '
#include <string.h>
int
main ()
{
  (void) strcat;
  return 0;
}' > foo.c
clang-$VERSION -c foo.c

echo '#include <errno.h>
int main() {} ' > foo.c
clang-$VERSION foo.c

echo '#include <chrono>
int main() { }' > foo.cpp
clang++-$VERSION -std=c++11 foo.cpp

echo '#include <stdio.h>
int main() {
if (1==1) {
	printf("true");
}else{
	printf("false");
	return 42;
}
return 0;}' > foo.c
clang-$VERSION --coverage foo.c -o foo
./foo > /dev/null
if test ! -f foo.gcno; then
    echo "Coverage failed";
fi

echo "#include <iterator>" > foo.cpp
clang++-$VERSION -c foo.cpp


echo '#include <stdio.h>
int main() {
if (1==1) {
  printf("true");
}else{
  printf("false");
  return 42;
}
return 0;}' > foo.c
rm foo

if test ! -f /usr/lib/llvm-$VERSION/bin/../lib/LLVMgold.so; then
    echo "Install llvm-$VERSION-dev"
    exit 1
fi

clang-$VERSION -flto foo.c -o foo
./foo > /dev/null

clang-$VERSION -fuse-ld=gold foo.c -o foo
./foo > /dev/null

# test thinlto
echo "int foo(void) {	return 0; }"> foo.c
echo "int foo(void); int main() {foo();	return 0;}">main.c
clang-$VERSION -flto=thin -O2 foo.c main.c -o foo
./foo > /dev/null

if test ! -f /usr/bin/lld-$VERSION; then
    echo "Install lld-$VERSION"
    exit 1
fi
clang-$VERSION -fuse-ld=lld -O2 foo.c main.c -o foo
./foo > /dev/null

clang-$VERSION -fuse-ld=lld-$VERSION -O2 foo.c main.c -o foo
./foo > /dev/null

clang-$VERSION -flto=thin -O2 foo.c main.c -c
clang-$VERSION -flto=thin -O2 foo.o main.o -o a.out

cat << EOF > test_fuzzer.cc
#include <stdint.h>
#include <stddef.h>
extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  if (size > 0 && data[0] == 'H')
    if (size > 1 && data[1] == 'I')
       if (size > 2 && data[2] == '!')
       __builtin_trap();
  return 0;
}
EOF

if test ! -f /usr/lib/llvm-$VERSION/lib/libFuzzer.a; then
    echo "Install libfuzzer-$VERSION-dev";
    exit -1;
fi

clang++-$VERSION -fsanitize=address -fsanitize-coverage=edge,trace-pc test_fuzzer.cc /usr/lib/llvm-$VERSION/lib/libFuzzer.a
if ! ./a.out 2>&1 | grep -q -E "(Test unit written|PreferSmall)"; then
    echo "fuzzer"
    exit 42
fi
clang-$VERSION -fsanitize=fuzzer test_fuzzer.cc
if ! ./a.out 2>&1 | grep -q -E "(Test unit written|PreferSmall)"; then
    echo "fuzzer"
    exit 42
fi

echo 'int main() {
	int a=0;
	return a;
}
' > foo.c
clang++-$VERSION -g -o bar foo.c


if test ! -f /usr/lib/llvm-$VERSION/lib/libomp.so; then
    echo "Install libomp-$VERSION-dev";
    exit -1;
fi

# OpenMP
echo '
//test.c
#include "omp.h"
#include <stdio.h>

int main(void) {
  #pragma omp parallel
  printf("thread %d\n", omp_get_thread_num());
}
' > foo.c
clang-$VERSION foo.c -fopenmp -o o
./o > /dev/null


if test ! -f /usr/lib/llvm-$VERSION/lib/libomp.so; then
    echo "Install libomp-$VERSION-dev";
    exit -1;
fi

# libc++
echo '
#include <vector>
#include <string>
#include <iostream>
using namespace std;
int main(void) {
    vector<string> tab;
    tab.push_back("the");
    tab.push_back("world");
    tab.insert(tab.begin(), "Hello");

    for(vector<string>::iterator it=tab.begin(); it!=tab.end(); ++it)
    {
        cout << *it << " ";
    }
    return 0;
}' > foo.cpp
clang++-$VERSION -stdlib=libc++ foo.cpp -o o
if ! ldd o 2>&1|grep -q  libc++.so.1; then
#    if ! ./a.out 2>&1 |  -q -E "(Test unit written|PreferSmall)"; then
    echo "not linked against libc++.so.1"
    exit -1
fi
if ! ldd o 2>&1|grep -q  libc++abi.so.1; then
    echo "not linked against libc++abi.so.1"
    exit -1
fi
./o > /dev/null
clang++-$VERSION -std=c++11 -stdlib=libc++ foo.cpp -o o
./o > /dev/null
clang++-$VERSION -std=c++14 -stdlib=libc++ foo.cpp -lc++experimental -o o
./o > /dev/null

# fs from C++17
echo '
#include <filesystem>
#include <type_traits>
using namespace std::filesystem;
int main() {
  static_assert(std::is_same<
          path,
          std::filesystem::path
      >::value, "");
}' > foo.cpp
clang++-$VERSION -std=c++17 -stdlib=libc++ foo.cpp -lc++experimental -lc++fs -o o
./o > /dev/null

/usr/lib/llvm-7/bin/clang++-libc++ -std=c++17 foo.cpp -lc++experimental -lc++fs -o o
./o > /dev/null
clang++-libc++-$VERSION -std=c++17 foo.cpp -lc++experimental -lc++fs -o o
./o > /dev/null

g++ -nostdinc++ -I/usr/lib/llvm-$VERSION/bin/../include/c++/v1/ -L/usr/lib/llvm-$VERSION/lib/ \
    foo.cpp -nodefaultlibs -std=c++17 -lc++ -lc++abi -lm -lc -lgcc_s -lgcc
./o > /dev/null

echo "b main
run
bt
quit" > lldb-cmd.txt

if test ! -f /usr/bin/lldb-$VERSION; then
    echo "Install lldb-$VERSION";
    exit -1;
fi


lldb-$VERSION -s lldb-cmd.txt bar
echo '
#include <vector>
int main (void)
{  std::vector<int> a;
  a.push_back (0);
}
' > foo.cpp
clang++-$VERSION -g -o foo foo.cpp
echo 'target create "./foo"
b main
r
n
p a
quit' > lldb-cmd.txt
lldb-$VERSION -s lldb-cmd.txt ./foo

echo "int main() { return 1; }" > foo.c
clang-$VERSION -fsanitize=efficiency-working-set -o foo foo.c
./foo > /dev/null || true


if test ! -f /usr/lib/llvm-$VERSION/lib/libclangToolingInclusions.a; then
    echo "Install libclang-$VERSION-dev";
    exit -1;
fi

rm -rf cmaketest && mkdir cmaketest
cat > cmaketest/CMakeLists.txt <<EOF
cmake_minimum_required(VERSION 2.8.12)
project(SanityCheck)
find_package(LLVM $VERSION REQUIRED CONFIG)
message(STATUS "LLVM_CMAKE_DIR: \${LLVM_CMAKE_DIR}")
if(NOT EXISTS "\${LLVM_TOOLS_BINARY_DIR}/clang")
message(FATAL_ERROR "Invalid LLVM_TOOLS_BINARY_DIR: \${LLVM_TOOLS_BINARY_DIR}")
endif()
# TODO add version to ClangConfig.cmake and use $VERSION below
find_package(Clang REQUIRED CONFIG)
find_file(H clang/AST/ASTConsumer.h PATHS \${CLANG_INCLUDE_DIRS} NO_DEFAULT_PATH)
message(STATUS "CLANG_INCLUDE_DIRS: \${CLANG_INCLUDE_DIRS}")
if(NOT H)
message(FATAL_ERROR "Invalid Clang header path: \${CLANG_INCLUDE_DIRS}")
endif()
EOF
mkdir cmaketest/standard cmaketest/explicit
echo "Test: CMake find LLVM and Clang in default path"
(cd cmaketest/standard && CC=clang-$VERSION CXX=clang++-$VERSION cmake ..)
echo "Test: CMake find LLVM and Clang in explicit prefix path"
(cd cmaketest/explicit && CC=clang-$VERSION CXX=clang++-$VERSION CMAKE_PREFIX_PATH=/usr/lib/llvm-$VERSION cmake ..)
rm -rf cmaketest

CLANG=clang-$VERSION
#command -v "$CLANG" 1>/dev/null 2>/dev/null || { printf "Usage:\n%s CLANGEXE [ARGS]\n" "$0" 1>&2; exit 1; }
#shift

TEMPDIR=$(mktemp -d); trap "rm -rf \"$TEMPDIR\"" 0

cat > "$TEMPDIR/test.c" <<EOF
#include <stdlib.h>
#include <stdio.h>
int main ()
{
#if __has_feature(address_sanitizer)
  puts("address_sanitizer");
#endif
#if __has_feature(thread_sanitizer)
  puts("thread_sanitizer");
#endif
#if __has_feature(memory_sanitizer)
  puts("memory_sanitizer");
#endif
#if __has_feature(undefined_sanitizer)
  puts("undefined_sanitizer");
#endif
#if __has_feature(dataflow_sanitizer)
  puts("dataflow_sanitizer");
#endif
#if __has_feature(efficiency_sanitizer)
  puts("efficiency_sanitizer");
#endif
  printf("Ok\n");
  return EXIT_SUCCESS;
}
EOF

#clean up
rm -f a.out bar crash-* foo foo.* lldb-cmd.txt main.c test_fuzzer.cc foo.* o

# only for AMD64 for now
# many sanitizers only work on AMD64
# x32 programs need to be enabled in the kernel bootparams for debian
# (https://wiki.debian.org/X32Port)
#
# SYSTEM should iterate multiple targets (eg. x86_64-unknown-none-gnu for embedded)
# MARCH should iterate the library architectures via flags
# LIB should iterate the different libraries
echo "if it fails, please run"
echo "apt-get install libc6-dev:i386 libgcc-5-dev:i386 libc6-dev-x32 libx32gcc-5-dev libx32gcc-8-dev"
for SYSTEM in ""; do
    for MARCH in -m64 -m32 -mx32 "-m32 -march=i686"; do
        for LIB in --rtlib=compiler-rt -fsanitize=address -fsanitize=thread -fsanitize=memory -fsanitize=undefined -fsanitize=dataflow; do # -fsanitize=efficiency-working-set; do
            if test "$MARCH" == "-m32" -o "$MARCH" == "-mx32"; then
                if test $LIB == "-fsanitize=thread" -o $LIB == "-fsanitize=memory" -o $LIB == "-fsanitize=dataflow" -o $LIB == "-fsanitize=address" -o $LIB == "-fsanitize=undefined"; then
                    echo "Skip $MARCH / $LIB";
                    continue
                fi
            fi
            if test "$MARCH" == "-m32 -march=i686"; then
                if test $LIB == "-fsanitize=memory" -o $LIB == "-fsanitize=thread" -o $LIB == "-fsanitize=dataflow"; then
                     echo "Skip $MARCH / $LIB";
                     continue
                fi
            fi
            XARGS="$SYSTEM $MARCH $LIB"
            printf "\nTest: clang %s\n" "$XARGS"
            rm -f "$TEMPDIR/test"
            "$CLANG" $XARGS -o "$TEMPDIR/test" "$@" "$TEMPDIR/test.c"
            [ ! -e "$TEMPDIR/test" ] || { "$TEMPDIR/test" || printf 'Error\n'; }
        done
    done
done

echo "If the following fails, try setting an environment variable such as:"
echo "OBJC_INCLUDE_PATH=/usr/lib/gcc/x86_64-linux-gnu/8/include"
echo "libobjc-8-dev should be also installed"
echo "#include <objc/objc.h>" > foo.m
clang-$VERSION -c foo.m

if test ! -f /usr/lib/llvm-$VERSION/lib/libclangBasic.a; then
    echo "Install libclang-$VERSION-dev"
    exit 1
fi

echo "Completed"
