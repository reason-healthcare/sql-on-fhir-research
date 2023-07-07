## This use case demonstrates unit normalization for body weight. 

### These Definitons have been written to two standards : Nikolai's (http://142.132.196.32:7777) and Josh's (https://joshuamandel.com/fhir-view-to-array/)
&nbsp;

### The goal of this use case is to demonstrate the process of unit normalization for body weight measurements. The use case involves converting weight measurements between pounds (lbs) and kilograms (kg).
&nbsp;

This example view demonstrates a union operation for weight normalization as well as implementing arithmetic in the expression fields.

```json
{
  "name": "observation_weight",
  "from": "Observation.where(code.coding.exists(system='http://loinc.org' and code = '29463-7')).first()",
  "constants" : [{"name": "lbs_to_kg" , "value" : 0.453592},{"name": "kg_to_lbs" , "value" : 2.20462}],
  "select": [
    { "name": "id", "expr": "id" },
    { "union" : [
      { "from" : "valueQuantity.where(unit='lbs')",
        "select" : [
          {"name" : "lbs" , "expr" : "value"},
          {"name" : "kg", "expr" : "value * %lbs_to_kg"}
        ]
      },
      { "from" : "valueQuantity.where(unit='kg')",
        "select" : [
          {"name" : "lbs", "expr" : "value * %kg_to_lbs"},
          {"name" : "kg" , "expr" : "value"}
        ]
      }
     ]
    }
  ]
}
```

This example demonstrates the same query as the example above, but using Nikolai's syntax. It provides an alternative representation of the view with the same functionality.

```clojure
{
  :id "observation_weight",
  :from "Observation.where(code.coding.exists(system='http://loinc.org' and code='29463-7))",
  :select [
    {:name "id" :expr "id"},
    {:union [
      {:from "valueQuantity.where(unit='lbs')",
       :select [
         {:name "lbs" :expr "value"}
         {:name "kg" :expr "value * %lbs_to_kg"}
       ]
      },
      {:from "valueQuantity.where(unit='kg')",
       :select [
         {:name "lbs" :expr "value * %kg_to_lbs"}
         {:name "kg" :expr "value"}
       ]
      }
     ]
    }
  ],
  :constants [
    {:name "lbs_to_kg" :value 0.453592}
    {:name "kg_to_lbs" :value 2.20462}
  ]
}

```

This is a simple weight range Query that is based on the view definitions above.
```sql
SELECT *
FROM views.observation_weight as weight
WHERE weight.kg > 50
AND weight.kg < 100
```


Postgres query
&nbsp;

This PostgreSQL example demonstrates the same creation of a view and weight range query while also demonstrating the built in JSON extraction operators

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
  CASE
    WHEN content -> 'valueQuantity' ->> 'unit' = 'lbs' THEN (obs.content -> 'valueQuantity' ->> 'value')::NUMERIC * 0.453592
    ELSE (content -> 'valueQuantity' ->> 'value')::NUMERIC
  END AS weight_kg
FROM observations
WHERE content -> 'code' -> 'coding' -> 0 ->> 'code' = '29463-7'
AND (content -> 'valueQuantity' ->> 'value')::NUMERIC > 50
AND (content -> 'valueQuantity' ->> 'value')::NUMERIC < 100;

```


DuckDB query
&nbsp;

A similar query to the one above is created in DuckDB. Notice how the JSON extraction semantics are slightly different.

```sql
CREATE TABLE observations AS SELECT * FROM './test-data/Observation-no-narrative.ndjson';

SELECT 
    id::VARCHAR AS id,   
    code->'coding'->0->>'display'::VARCHAR AS code_display,
    code->'coding'->0->>'code'::VARCHAR AS code_code,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 2) AS subject_id,
    CASE
      WHEN valueQuantity->>'unit' = 'lbs' THEN CAST(valueQuantity->> 'value' AS FLOAT) * 0.453592
      ELSE CAST(valueQuantity->> 'value' AS FLOAT)
    END AS weight_kg
FROM observations
WHERE code->'coding'->0->>'code' = '29463-7'
AND (valueQuantity->>'value')::NUMERIC > 50
AND (valueQuantity->>'value')::NUMERIC < 100;
```