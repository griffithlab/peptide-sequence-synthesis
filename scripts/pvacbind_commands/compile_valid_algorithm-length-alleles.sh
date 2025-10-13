#Get valid alleles for each algorithm from pvactools
#Also get valid lengths for each algorithm from a defined expectation (saved in a config file)
#For a few algorithms with different lengths valid for each HLA alleles, import those separately
#Once all this info is gathered produce a master list of valid Length-HLA-Algorithm combinations for which we expect calculations to be possible

#isub -p false -i 'susannakiwala/pvactools:7.0.0a6' -m 4

PVACTOOLS_VERSION="7.0.0"
WORKING_BASE=/storage1/fs1/mgriffit/Active/immune/pvactools_percentiles/peptide-sequence-synthesis/scripts/pvacbind_commands
ALG_NAMES_FILE=$WORKING_BASE/algorithm_info/classI_algorithm_names_${PVACTOOLS_VERSION}.txt
ALG_SUPPORTED_LENGTHS_FILE=$WORKING_BASE/algorithm_info/classI_supported_lengths_by_algorithm.txt
SMM_SUPPORTED_LENGTHS_FILE=$WORKING_BASE/algorithm_info/smm-human.tsv
SMMPMBEC_SUPPORTED_LENGTHS_FILE=$WORKING_BASE/algorithm_info/smmpmbec-human.tsv
GLOBAL_MIN_LENGTH=8
GLOBAL_MAX_LENGTH=11
OUTPUT_KEY_FILE=${WORKING_BASE}/algorithm_allele_length_key/Length-HLA-Algorithm_Keys_${PVACTOOLS_VERSION}.txt

#Initialize the output file
> "$OUTPUT_KEY_FILE"

#Load in the class I algorithm names
mapfile -t ALGORITHMS < "$ALG_NAMES_FILE"

#Get all the HLA alleles supported by each class I algorithm and store these is files, one per algorithm
for ALGO in "${ALGORITHMS[@]}"; do
  echo $ALGO
  echo "pvacbind valid_alleles -s human -p $ALGO > $WORKING_BASE/algorithm_allele_length_key/algorithm_alleles/${ALGO}.valid_alleles.txt"
  pvacbind valid_alleles -s human -p $ALGO > $WORKING_BASE/algorithm_allele_length_key/algorithm_alleles/${ALGO}.valid_alleles.txt
done

#Load in the supporting lengths for each algorithm where supported lengths do not vary by HLA allele
while IFS=":" read -r alg range; do
    #Skip blank lines or lines starting with "#"
    [[ -z "$alg" || "$alg" =~ ^[[:space:]]*# ]] && continue

    alg=$(echo "$alg" | xargs)        # trim whitespace
    min=$(echo "$range" | cut -d- -f1 | xargs)
    max=$(echo "$range" | cut -d- -f2 | xargs)
    
    ALG_FILE="$WORKING_BASE/algorithm_allele_length_key/algorithm_alleles/${alg}.valid_alleles.txt"

    #Skip to the next iteration if the algorithm HLA file does not exist or is empty, or if its one of the algorithms that must be treated specially
    if [[ ! -f "$ALG_FILE"  || "$alg" == "SMM" || "$alg" == "SMMPMBEC" ]]; then
      echo "Skipping $alg — file not found: $ALG_FILE"
      continue
    fi

    #Load in the valid HLA alleles for the current algorithm
    mapfile -t HLAS < $ALG_FILE

    #Iterate over the valid lengths for this algorithm
    echo "Algorithm: $alg (range $min-$max)"
    for ((len=min; len<=max; len++)); do
	#Skip lengths that are outside the specified Max/Min of interest above
        if (( len < GLOBAL_MIN_LENGTH || len > GLOBAL_MAX_LENGTH )); then
            echo "  Length: $len not within global min/max"
            continue
        fi
        echo "  Length: $len"

        #For each valid HLA alleles for this algorithm and create a key string represnting the Length-HLA-Algorithm combination
        for HLA_NAME in "${HLAS[@]}"; do
            #skip all but the HLA-A/B/C alleles 
            #if [[ ! "$HLA_NAME" =~ HLA-[ABC]\* ]]; then
            #  echo "    HLA name does not match A/B/C $HLA_NAME"
            #  continue
            #fi

            HLA_NAME="${HLA_NAME//\*/_}"
            HLA_NAME="${HLA_NAME//\:/_}"
            RUN_NAME=LEN-${len}_${HLA_NAME}_ALG-${alg}
            echo $RUN_NAME >> $OUTPUT_KEY_FILE
        done
    done
done < "$ALG_SUPPORTED_LENGTHS_FILE"

#Separately handle SMM that has supported lengths that vary by HLA allele
alg="SMM"
echo "Algorithm: $alg (custom lengths per algorithm) from input file:"
echo $SMM_SUPPORTED_LENGTHS_FILE
while read -r species HLA_NAME len; do
  # Skip empty lines or comments if any
  [[ -z "$species" || "$species" =~ ^# ]] && continue

  #Skip lengths that are outside the specified Max/Min of interest above
  if (( len < GLOBAL_MIN_LENGTH || len > GLOBAL_MAX_LENGTH )); then
      echo "  Length: $len not within global min/max"
      continue
  fi

  #skip all but the HLA-A/B/C alleles 
  #if [[ ! "$HLA_NAME" =~ _HLA-[ABC]\* ]]; then
  #    echo "    HLA name does not match A/B/C $HLA_NAME"
  #    continue
  #fi

  HLA_NAME="${HLA_NAME//\*/_}"
  HLA_NAME="${HLA_NAME//\:/_}"
  RUN_NAME=LEN-${len}_${HLA_NAME}_ALG-${alg}
  echo $RUN_NAME >> $OUTPUT_KEY_FILE

done < "$SMM_SUPPORTED_LENGTHS_FILE"

#Separately handle SMMPMBEC that has supported lengths that vary by HLA allele
alg="SMMPMBEC"
echo "Algorithm: $alg (custom lengths per algorithm) from input file:"
echo $SMMPMBEC_SUPPORTED_LENGTHS_FILE
while read -r species HLA_NAME len; do
  # Skip empty lines or comments if any
  [[ -z "$species" || "$species" =~ ^# ]] && continue

  #Skip lengths that are outside the specified Max/Min of interest above
  if (( len < GLOBAL_MIN_LENGTH || len > GLOBAL_MAX_LENGTH )); then
      echo "  Length: $len not within global min/max"
      continue
  fi

  #skip all but the HLA-A/B/C alleles 
  #if [[ ! "$HLA_NAME" =~ _HLA-[ABC]\* ]]; then
  #    echo "    HLA name does not match A/B/C $HLA_NAME"
  #    continue
  #fi

  HLA_NAME="${HLA_NAME//\*/_}"
  HLA_NAME="${HLA_NAME//\:/_}"
  RUN_NAME=LEN-${len}_${HLA_NAME}_ALG-${alg}
  echo $RUN_NAME >> $OUTPUT_KEY_FILE

done < "$SMMPMBEC_SUPPORTED_LENGTHS_FILE"


