#!/bin/sh
# Stop at the first error
set -e

VERSION=6.0

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

echo '#include <stddef.h>' > x.c
clang-$VERSION -c x.c

echo "#include <fenv.h>" > x.cc
NBLINES=$(clang++-$VERSION -P -E x.cc|wc -l)
if test $NBLINES -lt 100; then
    echo "Error: more than 100 lines should be returned"
    exit 42
fi

echo '#include <emmintrin.h>' > x.cc
clang++-$VERSION -c x.cc

echo '
#include <string.h>
int
main ()
{
  (void) strcat;
  return 0;
}' > x.c
clang-$VERSION -c x.c

echo '#include <errno.h>
int main() {} ' > x.c
clang-$VERSION x.c

echo '#include <chrono>
int main() { }' > x.cpp
clang++-$VERSION -std=c++11 x.cpp

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

clang++-$VERSION -fsanitize=address -fsanitize-coverage=edge test_fuzzer.cc /usr/lib/llvm-$VERSION/lib/libFuzzer.a
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
' > o.cpp
clang++-$VERSION -g -o o o.cpp
echo 'target create "./o"
b main
r
n
p a
quit' > lldb-cmd.txt
lldb-$VERSION -s lldb-cmd.txt ./o

echo "int main() { return 1; }" > foo.c
clang-$VERSION -fsanitize=efficiency-working-set -o foo foo.c
./foo > /dev/null || true

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

# only for AMD64 for now
# many sanitizers only work on AMD64
# x32 programs need to be enabled in the kernel bootparams for debian
# (https://wiki.debian.org/X32Port)
#
# SYSTEM should iterate multiple targets (eg. x86_64-unknown-none-gnu for embedded)
# MARCH should iterate the library architectures via flags
# LIB should iterate the different libraries
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

echo "#include <objc/objc.h>" > foo.m
clang-$VERSION -c foo.m

echo "Completed"

