for file in /Users/user/Desktop/sql_on_fhir_research/test-data/*.ndjson; do 
  while read -r line ; do
    echo -E "$line" | jq -c 'del(.text)'
  done < "$file" > "${file%.ndjson}-no-narrative.ndjson" & 
  rm "$file"
  echo "$(basename "${file//-no-narrative/}" | sed 's/\.[^.]*$//')"
done
