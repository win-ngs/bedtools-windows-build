set -e; # Alert user to any uncaught error

ulimit -c unlimited

STARTWD=$(pwd);
TOOL_PASSES="";
TOOL_FAILURES="";

if [ -z "${BT+x}" ] && [ -x "${STARTWD}/../bin/bedtools.exe" ]; then
    # Native UCRT64 test runs must execute the Windows image explicitly.
    # Repeated launches through the extensionless PE file can diverge under
    # MSYS Bash, while the packaged tool is bedtools.exe.
    export BT="${STARTWD}/../bin/bedtools.exe"
fi

for tool in $(ls); do
    [ -d "${STARTWD}/${tool}" ] || continue;
    echo "Testing bedtools $tool:";
    cd "${STARTWD}/${tool}";
    bash "test-${tool}.sh" \
        && TOOL_PASSES="$TOOL_PASSES $tool" \
        || TOOL_FAILURES="$TOOL_FAILURES $tool";
done

echo
echo
echo "--------------------------"
echo " Test Results             "
echo "--------------------------"
echo "Tools passing: $TOOL_PASSES"
echo "Tools failing: $TOOL_FAILURES"
echo "NB: the 'negativecontrol' test is supposed to fail. If it wasn't caught, "
echo "something went wrong with this test script."
[ "$TOOL_FAILURES" = " negativecontrol" ] || exit 1;
