#!/bin/bash
START=$(date +%s)
# Set defaults
L1=""
L2=""
COUNT=2
LOG=1
MINLEN=0
OUTPUT=""
QUALITY=0
REJECTED=0
THREADS=4
VERSION="version 1.0.1"
LOGFILE=$(date +%F_%X.log)

usage() {
cat << EOF
Compress multiplex barcode deep sequencing data.

Erik Zwart
e.zwart@umcg.nl
$VERSION

OPTIONS:
	-a	lane 1, fastq file [L1] gzipped (required)
	-b	lane 2, fastq file [L2] gzipped (optional)
	-c	count, minimum read count threshold (default 2)
	-l	write log file (no[0]/yes[1]) (default 1)
	-h	print help message and exit
	-m	length, minimum length of read (bp)
	-o	output file containing the compressed barcode data (required)
	-q	minimum quality score of read 
		
		value must be set between 1 and 41
		https://en.wikipedia.org/wiki/FASTQ_format#Encoding
		https://en.wikipedia.org/wiki/Phred_quality_score
	
		Phred Quality Score, Probability of incorrect base call, Base call accurary
		10, 1 in 10, 	 90%
		20, 1 in 100, 	 99%
		30, 1 in 1000, 	 99.9%
		40, 1 in 10,000, 99.99%
	-r 	write out rejected (based on set filtes) reads: rejected.txt (no[0]/yes[1]) (default 0)
	-t	number of threads to be used (default 4)
	-v	print version of the program and exit

EXAMPLE:
	bash collapse-multiplex-barcodes.sh -a ./data/reads_100k.fastq.gz -o collapsed-barcodes.txt

EOF
}

test_fastq() {
	if zcat -c $1 | head -2 | tail -1 | egrep -ie '[^ACTGN]';
	then
		echo "ERROR: FASTQ data has invalid characters"
		exit 1
	fi

	if zcat -c $1 | head -4 | tail -1 | egrep -e '[^!-J]';
	then
		echo "ERROR: Invalid FASTQ quality encoding"
		exit 1
	fi
}

check_fastq() {
	if [ ! -f $1 ];
	then
		echo "ERROR: input fastq file does not exists."
		exit 1
	else
		case "$1" in
			*.gz) test_fastq $1;;
			*) echo "ERROR: input fastq file is not gzipped (.gz)."; exit 1;;
		esac
		return 0
	fi
}

stats() {
RAW_NUMBER_OF_SEQUENCES_A=$((`zcat -c $L1 | wc -l`/4))
if [[ "$L2" != "" ]];
then
	RAW_NUMBER_OF_SEQUENCES_B=$((`zcat -c $L2 | wc -l`/4))
else
	RAW_NUMBER_OF_SEQUENCES_B=0
fi
TOTAL_RAW_NUMBER_OF_SEQUENCES=$(($RAW_NUMBER_OF_SEQUENCES_A+$RAW_NUMBER_OF_SEQUENCES_B))
RESULTING_NUMBER_OF_SEQUENCES=$((`awk '{ SUM += $2 } END { print SUM } ' $OUTPUT`))
FILTERED_OUT_SEQUENCES=$(($TOTAL_RAW_NUMBER_OF_SEQUENCES-$RESULTING_NUMBER_OF_SEQUENCES))
UNIQUE_NUMBER_OF_SEQUENCES=$((`wc -l < $OUTPUT`))

cat > $LOGFILE << EOF
# ###
# Collapse multiplex barcodes
# ###
# Parameters
# ###
-a lane 1	$L1
-b lane 2	$L2
-o output file	$OUTPUT
-c minimum count	$COUNT
-l write log	$LOG
-m minimum length	$MINLEN
-t threads	$THREADS
-q mimimum quality	$QUALITY
-r writeout rejected	$REJECTED
-v version	$VERSION
# ###
# Results
# ###
raw number of sequences -a	$RAW_NUMBER_OF_SEQUENCES_A
raw number of sequences -b	$RAW_NUMBER_OF_SEQUENCES_B
total number of sequences a+b	$TOTAL_RAW_NUMBER_OF_SEQUENCES
filtered out sequences	$FILTERED_OUT_SEQUENCES
resulting number of sequences	$RESULTING_NUMBER_OF_SEQUENCES
unique number of sequences	$UNIQUE_NUMBER_OF_SEQUENCES
# ###
# Done!
# It took $DIFF seconds.
# ###
EOF
}

if [[ "$1" =~ ^((-{1,2})([Hh]$|[Hh][Ee][Ll][Pp])|)$ ]];
then
	usage; exit 1
else
	while getopts "a:b:c:l:m:o:q:r:t:v" OPTION
	do
		case $OPTION in
		a ) L1=$OPTARG ;;
		b ) L2=$OPTARG ;;
		c ) COUNT=$OPTARG ;;
		l ) LOG=$OPTARG ;;
		m ) MINLEN=$OPTARG ;;
		o ) OUTPUT=$OPTARG ;;
		q ) QUALITY=$OPTARG ;;
		r ) REJECTED=$OPTARG ;;
		t ) THREADS=$OPTARG ;;
		v ) echo $VERSION; exit 0;;
		\? )  usage; exit 1 ;;
		esac
	done
fi

if [[ "$L1" == "" ]];
then
	echo "ERROR: lane 1 [-a] requires an argument." >&2; exit 1
fi

if [[ "$COUNT" == "" ]];
then
	# minimum read count is not set, default to 2 (remove singletons)
	COUNT=0
elif [[ "$COUNT" -le 1 ]];
then
	echo "ERROR: count [-c] is set to low." >&2; exit 1
else
	case "$COUNT" in
		(*[!0-9]*|'') echo "ERROR: count [-c] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi

if [[ "$LOG" -lt 0 ]];
then
	echo "ERROR: log [-l] should be set to either 1 or 0." >&2; exit 1
elif [[ "$LOG" -gt 1 ]];
then
	echo "ERROR: log [-l] should be set to either 1 or 0." >&2; exit 1
fi


if [[ "$MINLEN" == "" ]];
then
	# minimum read length is not set, default to 0 (in effect ignore setting)
	MINLEN=0
elif [[ "$MINLEN" -gt 150 ]];
then
	echo "WARNING: minlen [-m] is set higher then expected."
elif [[ "$MINLEN" -le -1 ]];
then
	echo "ERROR: minlen [-m] is set to low." >&2; exit 1
else
	case "$MINLEN" in
		(*[!0-9]*|'') echo "ERROR: minlen [-m] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi

# see if minimum read length is set to high
if `zcat -c $L1 | head -2 | tail -1 | awk '{if (length($0) < '$MINLEN') {exit 0} else {exit 1} }'`;
then
	echo "ERROR: minlen [-m] minimum set to high." >&2; exit 1
fi

if [[ "$OUTPUT" == "" ]];
then
	echo "ERROR: output [-o] requires an argument." >&2; exit 1
fi

if [[ "$QUALITY" == "" ]];
then
	# minimum read quality is not set, defaulting to lowest setting 0 (0=!==33)
	QUALITY=0
elif [[ "$QUALITY" -lt 0 || "$QUALITY" -gt 41 ]];
then
	echo "ERROR: quality [-q] invalid argument, value must be set between 1 and 41." >&2; exit 1
else
	case "$QUALITY" in
		(*[!0-9]*|'') echo "ERROR: quality [-q] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi 

# convert decimal to ascii value + phred offset
PHRED=$(printf "\\$(printf '%03o' $(( $QUALITY + 33 )))")

if [[ "$REJECTED" -ne 0 && "$REJECTED" -ne 1 ]];
then
	echo "ERROR: rejected [-r] should be set to 0 or 1 (no or yes)." >&2; exit 1
fi

if [[ "$THREADS" == "" ]];
then
	# number of threads is not set, defaulting to 4 threads
	THREADS=4
elif [[ "$THREADS" -le 0 ]];
then
	# number of threads is set to 0 or lower, defaulting to 4 threads
	THREADS=4
elif [[ "$THREADS" -gt 32 ]];
then
	echo "WARNING: threads [-t] is set to $THREADS"
	echo "Are you sure your system supports that?"
else
	case "$THREADS" in
		(*[!0-9]*|'') echo "ERROR: threads [-t] invalid argument." >&2; exit 1
		(*			) ;;
	esac
fi

if [[ $L1 ]]; then check_fastq $L1; else echo "ERROR: lane 1 [-a] is not set."; exit 1; fi
if [[ $L2 ]]; then check_fastq $L2; fi

zcat -c $L1 $L2 | 
awk '{
if (NR % 4 == 0) {
	if ($1 ~ /[^'$PHRED'-'J']/) {pass = 0} else {pass = 1}}
};
{
if (NR % 4 == 2 && pass) {
	if (length($1) >= '$MINLEN') {print $1}}
}' |
sort --parallel=$THREADS | 
uniq -d -c | 
sort --parallel=$THREADS -nr | 
sed -e 's/\s*//;s/\s/\t/' |	
awk 'BEGIN {FS = "\t"; OFS = "\t"};
{
	if ('$COUNT' == 0) {print $2,$1} else {
		if ($1 >= '$COUNT') {print $2,$1}
	}
}' > $OUTPUT

END=$(date +%s)
DIFF=$(( $END - $START ))

if [[ "$LOG" -eq 1 ]];
then
	stats
fi


if [[ "$REJECTED" -eq 1 ]];
then
REJECTED_READS=""
REJECTED_READS_A=""
REJECTED_READS_B=""

REJECTED_READS_A=`zcat -c $L1 $L2 | 
awk '{
	if (NR % 4 == 0) {
		if ($1 ~ /[^'$PHRED'-'J']/) {pass = 1} else {pass = 0}
	}
};
{
if (NR % 4 == 2) {
	if (length($1) < '$MINLEN') {
		print $1
	} else if (pass) {
		print $i
	}

}
}' |
sort --parallel=$THREADS | 
uniq -c | 
sort --parallel=$THREADS -nr | 
sed -e 's/\s*//;s/\s/\t/'`

if [[ "$COUNT" -ge 2 ]];
then
	REJECTED_READS_B=`zcat -c $L1 $L2 | 
	awk '{
	if (NR % 4 == 0) {
		if ($1 ~ /[^'$PHRED'-'J']/) {pass = 0} else {pass = 1}}
	};
	{
	if (NR % 4 == 2 && pass) {
		if (length($1) >= '$MINLEN') {print $1}}
	}' |
	sort --parallel=$THREADS | 
	uniq -c | 
	sort --parallel=$THREADS -nr | 
	sed -e 's/\s*//;s/\s/\t/' |	
	awk 'BEGIN {FS = "\t"; OFS = "\t"};
	{
		if ($1 < '$COUNT') {print $1,$2}
	}'`
fi
	
REJECTED_READS="${REJECTED_READS_A}
${REJECTED_READS_B}"
echo "$REJECTED_READS" | 
sort --parallel=$THREADS -nr | 
awk 'BEGIN {FS = "\t"; OFS = "\t"};{print $2,$1}' > rejected.txt
pigz --best -f -p $THREADS rejected.txt

fi
