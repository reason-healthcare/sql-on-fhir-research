## This use case demonstrates joining fields based on a LOINC valueset. 

### These Definitons have been written to two standards : Nikolai's (http://142.132.196.32:7777) and Josh's (https://joshuamandel.com/fhir-view-to-array/)
&nbsp;

### The goal of this use case is to demonstrate the process of joining multiple different codes on a single patient and several different implementations are listed below
&nbsp;

This example view is an idea on how to preprocess the valueset so that the semantics are simple and straightforward (does not work)

```clojure
{
  :id "weight_valueset_union_example",
  :from "Observation",
  :select [
    {:expr "id", :name "id"},
    {:expr "subject.getId()", :name "subject_id"},
    {:from "Observation.where(code.coding.exists(system='http://loinc.org' and valueset.url='LG34372-9'))",
      :select [{:expr "valueQuantity.value", :name "kg"}]
    }
  ]
}
```
This example is an attempt to have the code logic within the code.coding.where() method (does not work)
```clojure
{
  :id "weight_observations",
  :from "Observation",
  :where [
    {:expr "code.coding.where(system='http://loinc.org' and code='29463-7' or code='3141-9' or code='3142-7' or code='75292-3' or code='79348-9' or code='8350-1' or code='8351-9')"}
  ],
  :select [
    {:expr "id", :name "id"},
    {:expr "subject.getId()", :name "subject_id"},
    {:expr "valueQuantity.value", :name "kg"}
    {:expr "effectiveDateTime", :name "date"}
    {:expr "code.coding.code", :name "code"}
  ]
}

```
This example is more of a brute force method in which the union operator is utilized to try and join all of the observations on subject ID (does not work)
```clojure
{
  :id "union_example",
  :from "Observation",
  :select [
    {:expr "id", :name "id"},
    {:expr "subject.getId()", :name "subject_id"},
    {:union [
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='29463-7'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='3141-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='3142-7'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='75292-3'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='79348-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='8350-1'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='8351-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      }
     ]
    }
  ]
}
```
This example is similar to the example above but uses code.coding.where() instead of Observation.where(code.coding.exists())
```clojure
{
  :id "union_example",
  :from "Observation",
  :select [
    {:expr "id", :name "id"},
    {:expr "subject.getId()", :name "subject_id"},
    {:union [
      {:from "code.coding.where(system='http://loinc.org' and code='29463-7')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "code.coding.where(system='http://loinc.org' and code='3141-9')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "code.coding.where(system='http://loinc.org' and code='3142-7')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "code.coding.where(system='http://loinc.org' and code='75292-3')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "code.coding.where(system='http://loinc.org' and code='79348-9')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "code.coding.where(system='http://loinc.org' and code='8350-1')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "code.coding.where(system='http://loinc.org' and code='8351-9')", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      }
     ]
    }
  ]
}
```
This PostgreSQL query demonstrates the same union as above while using built in set operations
```sql

DROP TABLE IF EXISTS observations;
CREATE TABLE observations (
  id SERIAL PRIMARY KEY,
  content JSONB NOT NULL
);

\copy observations(content) from './test-data/Observation-no-narrative.ndjson';

SELECT 
    content->>'id' as id, 
    (content->'subject'->>'reference') as subject_id,
    (content->'code'->'coding'->0->>'code') as code,
    (content->'valueQuantity'->>'value') as kg
FROM 
    observations
WHERE
    (content->'valueQuantity'->>'value') IS NOT NULL
  AND
    (content->'code'->'coding'->0->>'code') IN ('29463-7', '3141-9', '3142-7', '75292-3', '79348-9', '8350-1', '8351-9');
```

This DuckDB query also demonstrates the same union as above while using built in set operations
```sql
CREATE TABLE observations AS SELECT * FROM './test-data/Observation-no-narrative.ndjson';

SELECT
    id::VARCHAR as id,
    subject->>'reference'::VARCHAR AS subject_id,
    code->'coding'->0->>'code'::VARCHAR AS code,
    CASE
        WHEN valueQuantity->>'value' IS NULL THEN 'NULL'
        ELSE CAST(valueQuantity->>'value' AS VARCHAR)
    END AS kg
FROM
    observations
WHERE
    code->'coding'->0->>'code' IN  ('29463-7', '3141-9', '3142-7', '75292-3', '79348-9', '8350-1', '8351-9');

```