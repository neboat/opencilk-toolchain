#!/usr/bin/bash -eu

# Initial version:
# https://src.fedoraproject.org/rpms/redhat-rpm-config/blob/rawhide/f/brp-llvm-compile-lto-elf

CLANG_FLAGS=$@

if test -z $P_TO_LLVM; then
    echo "P_TO_LLVM isn't set"
    exit 1
fi

if test -z $NJOBS; then
    echo "NJOBS isn't set"
    exit 1
fi

if test -z $VERSION; then
    echo "VERSION isn't set"
    exit 1
fi

NCPUS=$NJOBS

check_convert_bitcode () {
  local file_name=$(realpath ${1})
  local file_type=$(file ${file_name})

  shift
  CLANG_FLAGS="$@"

  if [[ "${file_type}" == *"LLVM IR bitcode"* ]]; then
    # Check the output of llvm-strings for the command line, which is in the LLVM bitcode because
    # we pass -frecord-gcc-switches.
    # Check for a line that has "-flto" after (or without) "-fno-lto".
    llvm-strings ${file_name} | while read line ; do
      flto=$(echo $line   | grep -o -b -e -flto     | tail -n 1 | cut -d : -f 1)
      fnolto=$(echo $line | grep -o -b -e -fno-lto  | tail -n 1 | cut -d : -f 1)

      if test -n "$flto" && { test -z "$fnolto" || test "$flto" -gt "$fnolto"; } ; then
        echo "Compiling LLVM bitcode file ${file_name}."
        clang ${CLANG_FLAGS} -fno-lto -Wno-unused-command-line-argument \
          -x ir ${file_name} -c -o ${file_name}
        break
      fi
      done
  elif [[ "${file_type}" == *"current ar archive"* ]]; then
    echo "Unpacking ar archive ${file_name} to check for LLVM bitcode components."
    # create archive stage for objects
    local archive_stage=$(mktemp -d)
    local archive=${file_name}
    pushd ${archive_stage}
    ar x ${archive}
    for archived_file in $(find -not -type d); do
      check_convert_bitcode ${archived_file} ${CLANG_FLAGS}
      echo "Repacking ${archived_file} into ${archive}."
      ar r ${archive} ${archived_file}
    done
    popd
  fi
}

echo "Checking for LLVM bitcode artifacts"
export -f check_convert_bitcode
# Deduplicate by device:inode to avoid processing hardlinks in parallel.
find "$P_TO_LLVM/debian/" -type f -name "*.[ao]" -printf "%D:%i %p\n" | \
  awk '!seen[$1]++' | cut -d" " -f2- | \
  xargs -d"\n" -r -n1 -P$NCPUS bash -c "check_convert_bitcode \$@ $CLANG_FLAGS" ARG0
