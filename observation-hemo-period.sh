input_file="test-data/Observation-no-narrative.ndjson"

output_file="test-data/Observation-no-narrative-modified.ndjson"

while IFS= read -r line; do
  if echo "$line" | jq -e '.code.coding[].code == "718-7"' >/dev/null; then

    effectiveDateTime=$(echo "$line" | jq -r '.effectiveDateTime')

    modified_line=$(echo "$line" | jq --arg dt "$effectiveDateTime" 'del(.effectiveDateTime) | . + { effectivePeriod: { start: $dt, end: $dt } }')

    ndjson_line=$(echo "$modified_line" | jq -c -r '@json')

    echo "$ndjson_line" >> "$output_file"
  else

    echo "$line" >> "$output_file"
  fi
done < "$input_file"