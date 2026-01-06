#!/bin/sh

# ------------------------------------------------------
# check compiler is clang (and supported version (todo).
# ------------------------------------------------------
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
  exit 1
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
