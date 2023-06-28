## This use case demonstrates unit normalization for body weight. 

These Definitons have been written to two standards : Nikolai's (http://142.132.196.32:7777) and Josh's (https://joshuamandel.com/fhir-view-to-array/)


```json
{
  "name": "observation_weight",
  "from": "Observation.where(code.coding.exists(system='http://loinc.org' and code = '29463-7')).first()",
  "constants" : [{"name": "lbs_to_kg" , "value" : 0.453592}],
  "select": [
    { "name": "id", "expr": "id" },
    { "from" : "valueQuantity.where(unit='lbs')",
      "select" : [
         {"name" : "lbs" , "expr" : "value"},
         {"name" : "kg", "expr" : "value * %lbs_to_kg"}
      ]
    }
  ]
}
```

Adding this after the nested select breaks this view
```json
    ,
    { "from" : "valueQuantity.where(unit='kg')",
      "select" : [
         {"name" : "lbs", "expr" : "value * %kg_to_lbs"},
         {"name" : "kg" , "expr" : "value"}
      ]
    }
```

also this constant is added 
```json
{"name": "kg_to_lbs" , "value" : 2.20462}
```

Nikolais syntax does not allow for expression mutation?

```clojure
{:id "weight_observation",
 :from "Observation",
 :where
 [{:expr
   "code.coding.where(system='http://loinc.org' and code = '29463-7')"}],
 :select
 [{:expr "id", :name "id"}
  {:expr "code.coding.display", :name "observation"}
  {:expr "subject.getId()", :name "subject_id"}
  {:expr "valueQuantity.value", :name "weight_kg", :type "numeric"}
]}
```
These do not work
```clojure
{:expr "valueQuantity.value * 2.2", :name "weight_lbs", :type "numeric"}
{:expr "valueQuantity.value * %2.2", :name "weight_lbs", :type "numeric"}
{:expr "valueQuantity.value * '2.2' ", :name "weight_lbs", :type "numeric"}
{:expr "valueQuantity.value * %'2.2' ", :name "weight_lbs", :type "numeric"}
```

Simple weight range Query
```sql
SELECT *
FROM views.weight_observation as weight
WHERE weight.weight_kg > 50
AND weight.weight_kg < 100
```


Postgres query

-- Create a new table to hold the extracted data

```sql
-- Setup an observations table and load ndjson

DROP TABLE IF EXISTS observations;
CREATE TABLE observations (
  id SERIAL PRIMARY KEY,
  content JSONB NOT NULL
);

\copy observations(content) from './test-data/Observation-no-narrative.ndjson';

SELECT
  content -> 'id' AS id,
  content -> 'code' -> 'coding' -> 0 ->> 'display' AS code_display,
  content -> 'code' -> 'coding' -> 0 ->> 'code' AS code_code,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 2) AS subject_id,
  content -> 'valueQuantity' ->> 'value' as weight_kg
FROM observations
WHERE content -> 'code' -> 'coding' -> 0 ->> 'code' = '29463-7'
AND (content -> 'valueQuantity' ->> 'value')::NUMERIC > 50
AND (content -> 'valueQuantity' ->> 'value')::NUMERIC < 100;
```


DuckDB query

```sql
CREATE TABLE observations AS SELECT * FROM './test-data/Observation-no-narrative.ndjson';

SELECT 
    id::VARCHAR AS id,   
    code->'coding'->0->>'display'::VARCHAR AS code_display,
    code->'coding'->0->>'code'::VARCHAR AS code_code,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 2) AS subject_id,
    (valueQuantity->>'value')::NUMERIC AS weight_kg
FROM observations
WHERE code->'coding'->0->>'code' = '29463-7'
AND (valueQuantity->>'value')::NUMERIC > 50
AND (valueQuantity->>'value')::NUMERIC < 100;
```