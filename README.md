# sql-on-fhir-research

## Synthea Setup & Configuration

Must have Java 11 or newer

### Clone Syntheas Repo

git submodule add https://github.com/synthetichealth/synthea.git
cd synthea

### Execute Tasks, check installation

./gradlew build check test

### Generate Data

./run_synthea (MAC)

.\run_synthea.bat (WINDOWS)

[-h]

[-s seed] 

[-cs clinician seed]

[-p populationSize]

[-g gender]

[-a minAge-maxAge]

[-c localConfigFilePath]

[-d localModulesDirPath]

[state [city]]

### Examples

./run_synthea Massachusetts

./run_synthea Alaska Juneau

./run_synthea -s 12345

./run_synthea -p 1000

./run_synthea -a 30-40 

./run_synthea -g F

./run_synthea -s 21 -p 100 Utah "Salt Lake City"

### Configuring FHIR

In the Synthea directory, one can choose which FHIR data gets exported by modifying the synthea.properties file located at synthea/src/main/resources/synthea.properties

if you don't want hospital or practitioner data to be generated and exported to a separate file, add these properties:

exporter.hospital.fhir.export = false
exporter.practitioner.fhir.export = false

** Generated test data is located at synthea/output/fhir **

### Move generated data to test-data folder, might need to play around with filepaths

mv -v ~/Desktop/sql_on_fhir_research/synthea/output/fhir/* ~/Desktop/sql_on_fhir_research/test-data

## Install Postgres SQL

brew install postgresql

### Start and Stop server

brew services start postgresql

brew services stop postgresql

### Use server 

psql postgres

### Load test data into database

"
CREATE TABLE json_data (
    id SERIAL PRIMARY KEY,
    data JSONB
);

COPY json_data (data)
FROM PROGRAM 'ls test-data/*.json'
WITH (FORMAT text);
"

## Install DuckDB

brew install duckdb

### Use server

duckdb