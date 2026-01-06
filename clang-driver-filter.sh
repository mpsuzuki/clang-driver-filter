#!/bin/sh

# ------------------------------------------------------
# parse options (-n, --dry-run) or (-?, -h, --help) only
# ------------------------------------------------------

dry_run="no"
my_basename=`basename $0`
case "$1" in
-h|--help)
  echo "${my_basename} is a sh script to filter the internal commands of clang."
  echo ""
  echo "${my_basename} <clang> <opt1> <opt2> ..."
  echo "    execute the final linking command after filtering the options by clang."
  echo ""
  echo "${my_basename} [-n|--dry-run] <clang> <opt1> <opt2> ..."
  echo "    show the final linking command after filtering the options by clang."
  echo ""
  echo "${my_basename} [-?|-h|--help]"
  echo "     print this help."
  exit 0
  ;;
-n|--dry-run)
  dry_run="yes"
  shift
  ;;
-*)
  echo "$1 is unknown option for ${my_basename}"
  exit 1
  ;;
*)
  # proceed to compiler check
  ;;
esac


# ------------------------------------------------------
# check compiler is clang (and supported version (todo))
# ------------------------------------------------------
compiler="$1"
if ! command -v "${compiler}" >/dev/null 2>&1
then
  echo "$1 is not an executable command" 1>&2
  exit 2
elif "${compiler}" --version 2>&1 | grep -qi clang
then
  :
else
  echo "* ${compiler} is non-Clang command, no filters applied" 1>&2
  if test "x${dry_run}" = xyes
  then
    echo "$@"
    exit 0
  else
    "$@"
  fi
fi
shift

if command -v mktemp >/dev/null 2>&1
then
  if test ! -z ${TMPDIR} -a -d ${TMPDIR} -a -w ${TMPDIR}
  then
    logdir=`mktemp -d ${TMPDIR}/clang-driver-filter.XXXXXX`
    status=$?
  else
    logdir=`mktemp -d /tmp/clang-driver-filter.XXXXXX 2>/dev/null`
    status=$?
  fi

  if test ${status} -ne 0 -o -z "${logdir}"
  then
    echo "$0: 'mktemp' does not support '-d' or failed to create a directory" >&2
  fi

  trap "rm -rf ${logdir}" EXIT
  log_stdout="${logdir}"/stdout.txt
  log_stderr="${logdir}"/stderr.txt
else
  echo "$0: requires 'mktemp' command." >&2
  exit 3
fi

# ------------------------------------------------------
# log commands constructed by clang
# ------------------------------------------------------

"${compiler}" -### "$@" 2>"${log_stderr}" 1>"${log_stdout}"
status=$?

if test ${status} -ne 0
then
  cat "${log_stdout}"
  cat "${log_stderr}" >&2
  exit $status
fi

cmd_filtered=
for tok in `tail -1 < "${log_stderr}"`
do
  case "${tok}" in
    \"-lsystem_*)
      echo "*** ${tok} is excluded because it would not be linkable directly" >&2
      ;;
    *)
      tok_deq=`echo "${tok}" | sed 's/^"//; s/"$//'`
      cmd_filtered="${cmd_filtered} ${tok_deq}"
      ;;
  esac
done
if test "x${dry_run}" = xyes
then
  echo "${cmd_filtered}"
  exit 0
else
  "${cmd_filtered}"
fi
