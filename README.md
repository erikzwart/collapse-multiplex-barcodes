# collapse-multiplex-barcodes
Collapse deep-sequencing multiplex barcode data

OPTIONS:

-l1, -lane1
	fastq file [L1] gzipped
  
-l2, -lane2
	fastq file [L2] gzipped

-c, -count
	minimum read count threshold, default 2

-m, -length
	minimum length of read (bp)

-o, -output
	output file containing the compressed barcode data
  
-t, -threads
	OPTIONAL: number of threads to be used, default 4

-q, -quality
	OPTIONAL: minimum quality score of read
	value must be set between 1 and 40
	https://en.wikipedia.org/wiki/FASTQ_format#Encoding
	https://en.wikipedia.org/wiki/Phred_quality_score

	Phred Quality Score, Probability of incorrect base call, Base call accurary
	10, 1 in 10, 90%
	20, 1 in 100, 99%
	30, 1 in 1000, 99.9%
	40, 1 in 10,000, 99.99%

-h, -help
	print help message and exit
  
-v, -version
	print version of the program and exit
  
USAGE:

bash ./collapse-multiplex-barcodes.sh -l1 data.fastq -o out.txt
