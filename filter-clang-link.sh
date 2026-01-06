#!/bin/sh

compiler="$1"
if ${compiler} --version | grep -qi clang
then
  :
else
  echo "* This is not Clang, no filters applied" 1>&2
  echo "$@"
  exit 0
fi

shift
"${compiler}" -### "$@" 2>clang-link.err 1>clang-link.out
status=$?

if test ${status} -ne 0
then
  cat clang-link.out
  cat clang-link.err >&2
  exit $status
fi

cmd_filtered=
for tok in `tail -1 < clang-link.err`
do
  case "${tok}" in
    \"-lsystem_*)
      echo "*** ${tok} is excluded because it would not be linkable directly">2
      ;;
    *)
      tok_deq=`echo "${tok}" | sed 's/^"//; s/"$//'`
      cmd_filtered="${cmd_filtered} ${tok_deq}"
      ;;
  esac
done
echo "${cmd_filtered}"
exit 0
