#Get valid alleles for each algorithm from pvactools
#Also get valid lengths for each algorithm from a defined expectation (saved in a config file)
#For a few algorithms with different lengths valid for each HLA alleles, import those separately
#Once all this info is gathered produce a master list of valid Length-HLA-Algorithm combinations for which we expect calculations to be possible

#isub -p false -i 'susannakiwala/pvactools:7.0.0a6' -m 4

PVACTOOLS_VERSION="7.0.0"
WORKING_BASE=/storage1/fs1/mgriffit/Active/immune/pvactools_percentiles/peptide-sequence-synthesis/scripts/pvacbind_commands
ALG_NAMES_FILE=$WORKING_BASE/algorithm_info/classI_algorithm_names_${PVACTOOLS_VERSION}.txt
ALG_SUPPORTED_LENGTHS_FILE=$WORKING_BASE/algorithm_info/supported_lengths_by_algorithm.txt
GLOBAL_MIN_LENGTH=8
GLOBAL_MAX_LENGTH=11

#load in the class I algorithm names
mapfile -t ALGORITHMS < "$ALG_NAMES_FILE"

#Get all the HLA alleles supported by each class I algorithm
for ALGO in "${ALGORITHMS[@]}"; do
  echo $ALGO
  echo "pvacbind valid_alleles -s human -p $ALGO > $WORKING_BASE/algorithm_allele_length_key/algorithm_alleles/${ALGO}.valid_alleles.txt"
  pvacbind valid_alleles -s human -p $ALGO > $WORKING_BASE/algorithm_allele_length_key/algorithm_alleles/${ALGO}.valid_alleles.txt
done

#Load in the supporting lengths for each algorithm where supported lengths do not vary by HLA allele
while IFS=":" read -r alg range; do
    # skip blank lines or lines starting with "#"
    [[ -z "$alg" || "$alg" =~ ^[[:space:]]*# ]] && continue

    alg=$(echo "$alg" | xargs)        # trim whitespace
    min=$(echo "$range" | cut -d- -f1 | xargs)
    max=$(echo "$range" | cut -d- -f2 | xargs)
    
    ALG_FILE="$WORKING_BASE/algorithm_allele_length_key/algorithm_alleles/${alg}.valid_alleles.txt"

    # Skip to the next iteration if the algorithm HLA file does not exist or is empty
    if [[ ! -f "$ALG_FILE"  || "$alg" == "SMM" || "$alg" == "SMMPMBEC" ]]; then
      echo "Skipping $alg — file not found: $ALG_FILE"
      continue
    fi

    mapfile -t HLAS < $ALG_FILE

    echo "Algorithm: $alg (range $min-$max)"
    for ((len=min; len<=max; len++)); do
        echo "  Length: $len"

        # Get the valid HLA alleles for this algorithm and create a key string: 
        for HLA_NAME in "${HLAS[@]}"; do
          RUN_NAME=LEN-${len}_${HLA_NAME}_ALG-${alg}
        done
    done
done < "$ALG_SUPPORTED_LENGTHS_FILE"

#Separately handle SMM and SMMPMBEC that have supported lengths that vary by HLA allele


