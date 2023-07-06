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

Postgresql query
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

DuckDB query
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