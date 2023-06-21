# sql-on-fhir-research

## Generate Synthetic Patient Test Data

Install Synthea

```
./run_synthea -p 100 --exporter.fhir.bulk_data=true
```

Copy from fhir output to local directory test data

```
cp /path/to/synthea/output/fhir/ ./test-data
```

Run zsh script to remove narrative

```
chmod +x no-narrative.zsh
./no-narrative.zsh
```

## Install Postgres SQL

```
brew install postgresql
```

### Start and Stop server

```
brew services start postgresql
brew services stop postgresql
```

### Use server 

```
psql postgres
```

## Install DuckDB

```
brew install duckdb
```

### Use server

```
duckdb
```
