# sql-on-fhir-research

## Generate Synthetic Patient Test Data

Install Synthea

./run_synthea -p 1000 --exporter.fhir.bulk_data = true

Copy from fhir output to local directory test data

cp ~synthea/output/fhir/ ~/sql_on_fhir_research/test-data

Run zsh script to remove narrative

chmod +x no-narrative.zsh
./no-narrative.zsh

## Install Postgres SQL

brew install postgresql

### Start and Stop server

brew services start postgresql

brew services stop postgresql

### Use server 

psql postgres

### Load test data into database

CREATE TABLE fhir (
  id SERIAL PRIMARY KEY,
  content JSONB NOT NULL
);

\copy fhir(content) from '/Users/user/Desktop/sql_on_fhir_research/test-data/Patient.ndjson'

## Install DuckDB

brew install duckdb

### Use server

duckdb
 
## Flattened View Template