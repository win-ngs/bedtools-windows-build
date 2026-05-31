set -e;
BT=${BT-../../bin/bedtools}
TMPD=$(mktemp -d "${TMPDIR:-/tmp}/bedtools-complement.XXXXXX")
trap 'rm -rf "$TMPD"' EXIT

FAILURES=0;

check()
{
     if diff $1 $2; then
          echo ok
     else
          FAILURES=$(expr $FAILURES + 1);
          echo fail
     fi
}


###########################################################
# test baseline complement
###########################################################
echo -e "    complement.t1...\c"
echo "chr1	1	20" > exp
printf "chr1\t0\t1\n" > "$TMPD/t1.i"
printf "chr1\t20\n" > "$TMPD/t1.g"
$BT complement -i "$TMPD/t1.i" \
               -g "$TMPD/t1.g" \
               > obs
check obs exp
rm obs exp


###########################################################
# ends are covered
###########################################################
echo -e "    complement.t2...\c"
echo "chr1	1	19" > exp
printf "chr1\t0\t1\nchr1\t19\t20\n" > "$TMPD/t2.i"
printf "chr1\t20\n" > "$TMPD/t2.g"
$BT complement -i "$TMPD/t2.i" \
               -g "$TMPD/t2.g" \
               > obs
check obs exp
rm obs exp

###########################################################
# middle is covered
###########################################################
echo -e "    complement.t3...\c"
echo "chr1	0	10
chr1	15	20" > exp
printf "chr1\t10\t15\n" > "$TMPD/t3.i"
printf "chr1\t20\n" > "$TMPD/t3.g"
$BT complement -i "$TMPD/t3.i" \
               -g "$TMPD/t3.g" \
               > obs
check obs exp
rm obs exp

###########################################################
# entirety is covered
###########################################################
echo -e "    complement.t4...\c"
touch exp
printf "chr1\t0\t20\n" > "$TMPD/t4.i"
printf "chr1\t20\n" > "$TMPD/t4.g"
$BT complement -i "$TMPD/t4.i" \
               -g "$TMPD/t4.g" \
               > obs
check obs exp
rm obs exp


###########################################################
# nothing is covered
###########################################################
echo -e "    complement.t5...\c"
echo "chr1	0	20" > exp
printf "chr2\t0\t20\n" > "$TMPD/t5.i"
printf "chr1\t20\nchr2\t20\n" > "$TMPD/t5.g"
$BT complement -i "$TMPD/t5.i" \
               -g "$TMPD/t5.g" \
               > obs
check obs exp
rm obs exp

###########################################################
# Issue #356
###########################################################
echo -e "    complement.t6...\c"
echo "chr1	10000	249250621" > exp
printf "chr1\t0\t10000\ttelomere\n" > "$TMPD/t6.i"
printf "chr1\t249250621\n" > "$TMPD/t6.g"
$BT complement -i "$TMPD/t6.i" \
               -g "$TMPD/t6.g" \
               > obs
check obs exp
rm obs exp

###########################################################
# Multiple chroms 
###########################################################
echo -e "    complement.t7...\c"
echo "chr1	0	10
chr2	0	10" > exp
printf "chr1\t10\t20\nchr2\t10\t20\n" > "$TMPD/t7.i"
printf "chr1\t20\nchr2\t20\n" > "$TMPD/t7.g"
$BT complement -i "$TMPD/t7.i" \
               -g "$TMPD/t7.g" \
               > obs
check obs exp
rm obs exp

###########################################################
# Multiple chroms, chr1 is covered
###########################################################
echo -e "    complement.t8...\c"
echo "chr2	0	10" > exp
printf "chr1\t0\t20\nchr2\t10\t20\n" > "$TMPD/t8.i"
printf "chr1\t20\nchr2\t20\n" > "$TMPD/t8.g"
$BT complement -i "$TMPD/t8.i" \
               -g "$TMPD/t8.g" \
               > obs
check obs exp
rm obs exp

###########################################################
# record exceeds chrom length
###########################################################
echo -e "    complement.t9...\c"
echo -e "***** WARNING: chr1:90-110 exceeds the length of chromosome (chr1)\nchr1\t0\t90" > exp
printf "chr1\t90\t110\n" > "$TMPD/t9.i"
printf "chr1\t100\n" > "$TMPD/t9.g"
$BT complement -i "$TMPD/t9.i" \
               -g "$TMPD/t9.g" \
               &> obs
check obs exp
rm obs exp
[[ $FAILURES -eq 0 ]] || exit 1;

###########################################################
# -L only reports chroms that were in the BED file.
###########################################################
echo -e "    complement.t9...\c"
echo "chr1	0	1
chr1	500	900
chr1	950	1000" > exp
$BT complement -i issue_503.bed \
               -g issue_503.genome \
               -L \
               > obs
check obs exp
rm obs exp

###########################################################
# Now, without -L
###########################################################
echo -e "    complement.t10...\c"
echo "chr1	0	1
chr1	500	900
chr1	950	1000
chr2	0	1000
chr3	0	1000" > exp
$BT complement -i issue_503.bed \
               -g issue_503.genome \
               > obs
check obs exp
rm obs exp

[[ $FAILURES -eq 0 ]] || exit 1;
