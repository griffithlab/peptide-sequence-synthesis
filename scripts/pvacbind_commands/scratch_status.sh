echo "volume  usage(TB)  quota(TB), %-used"
for g in compute-mgriffit compute-obigriffith compute-tfehnige; do 
  mmlsquota -g "$g" scratch1-fs1 | 
  awk -v grp="$g" '
    /scratch1-fs1/ {
      usageTB = $3/1024/1024/1024;
      quotaTB = $4/1024/1024/1024;
      pct = (quotaTB>0)? usageTB/quotaTB*100 : 0;
      printf "%-20s\t%8.2fTB\t%8.2fTB\t%6.2f%%\n", grp, usageTB, quotaTB, pct
    }'
done

