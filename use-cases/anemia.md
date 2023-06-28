## This use case demonstrates a join between two view definitions that screens patients for potential anemic conditions. Two separate views are constructed and then joined on patient ID. 

These Definitons have been written to two standards : Nikolai's (http://142.132.196.32:7777) and Josh's (https://joshuamandel.com/fhir-view-to-array/)

Run the observation-hemo-period.sh shell script to generate effectivePeriod dates for this demo


Josh's Syntax (JSON)

** getId() is not working for Josh's implementation ** 

```json

{
  "name": "hematocrit_observation",
  "from": "Observation",
  "where": [
    {
      "expr": "category.coding.code = 'laboratory'"
    },
    { 
      "expr" : "code.coding.code = '4544-3'" 
    }
  ],
  "select": [
    {
      "name": "id",
      "expr": "id"
    },
    {
      "name": "subject_id",
      "expr": "subject.getId()"
    },
    { 
      "name" : "hema_start",
      "expr" : "effectiveDateTime"
    },
    { 
      "name" : "hema_end",
      "expr" : "effectiveDateTime"
    },
    { 
      "name" : "category",
      "expr" : "category.coding.code"
    },
    { 
      "name" : "value" , 
      "expr" : "valueQuantity.value"
    },
    {
      "from" : "code.coding",
      "select" : [
        {
          "name": "observation",
          "expr": "display"
        },
        { 
          "name" : "code" , 
          "expr" : "code"
        }
      ]
    }
  ]
}
```

```json
{
  "name": "hemoglobin_observation",
  "from": "Observation",
  "where": [
    {
      "expr": "category.coding.code = 'laboratory'"
    },
    { 
      "expr" : "code.coding.code = '718-7'" 
    }
  ],
  "select": [
    {
      "name": "id",
      "expr": "id"
    },
    {
      "name": "subject_id",
      "expr": "subject.getId()"
    },
    { 
      "name" : "hemo_start",
      "expr" : "effectivePeriod.start"
    },
    { 
      "name" : "hemo_end",
      "expr" : "effectivePeriod.end"
    },
    { 
      "name" : "category",
      "expr" : "category.coding.code"
    },
    { 
      "name" : "value" , 
      "expr" : "valueQuantity.value"
    },
    {
      "from" : "code.coding",
      "select" : [
        {
          "name": "observation",
          "expr": "display"
        },
        { 
          "name" : "code" , 
          "expr" : "code"
        }
      ]
    }
  ]
}
```

Nikolai's Syntax (Clojure-like)
```clojure
{
 :id "hematocrit_observation",
 :from "Observation",
 :where
  [
    {:expr "code.coding.where(system='http://loinc.org' and code = '4544-3')"}
  ],
 :select
  [
    {:expr "id", :name "id"}
    {:expr "effectiveDateTime", :name "hema_start"}
    {:expr "effectiveDateTime", :name "hema_end"}
    {:expr "code.coding.display", :name "observation"}
    {:expr "category.coding.code", :name "category"}
    {:expr "code.coding.code", :name "code"}
    {:expr "subject.getId()", :name "subject_id"}
    {:expr "valueQuantity.value", :name "hema_value", :type "numeric"}
  ]
}

{
 :id "hemoglobin_observation",
 :from "Observation",
 :where
  [
    {:expr "code.coding.where(system='http://loinc.org' and code = '718-7')"}
  ],
 :select
  [
    {:expr "id", :name "id"}
    {:expr "effectivePeriod.start", :name "hemo_start"}
    {:expr "effectivePeriod.end", :name "hemo_end"}
    {:expr "code.coding.display", :name "observation"}
    {:expr "category.coding.code", :name "category"}
    {:expr "code.coding.code", :name "code"}
    {:expr "subject.getId()", :name "subject_id"}
    {:expr "valueQuantity.value", :name "hemo_value", :type "numeric"}
  ]
}
```

ANSI standard query

```sql
SELECT
  hema.subject_id,
  hemo.hemo_value,
  hema.hema_value,
  hemo.hemo_end,
  hema.hema_end
FROM 
  views.hematocrit_observation AS hema
JOIN 
  views.hemoglobin_observation AS hemo 
ON 
  hema.subject_id = hemo.subject_id
WHERE
  hema.hema_value < 40
  AND 
  hemo.hemo_value < 14
  AND 
  DATE_PART('year', DATE(hemo_end)) > 2015
  AND 
  DATE_PART('year', DATE(hema_end)) > 2015
ORDER BY
  hema.hema_end desc,
  hemo.hemo_end desc;
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

\copy observations(content) from './test-data/Observation-no-narrative-modified.ndjson';

-- Setup the hemo view, manually converted from the above view definiton
DROP VIEW IF EXISTS hemo;

CREATE VIEW hemo AS
SELECT
  content -> 'id' AS id,
  (content -> 'effectivePeriod' ->> 'start') :: TIMESTAMP AS hemo_start,
  (content -> 'effectivePeriod' ->> 'end') :: TIMESTAMP AS hemo_end,
  content -> 'code' -> 'coding' -> 0 ->> 'display' AS code_display,
  content -> 'code' -> 'coding' -> 0 ->> 'code' AS code_code,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 1) AS subject_type,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 2) AS subject_id,
  content -> 'valueQuantity' ->> 'value' as quantity_value
FROM observations
WHERE content -> 'code' -> 'coding' -> 0 ->> 'code' = '718-7';

DROP VIEW IF EXISTS hema;

CREATE VIEW hema AS
SELECT
  content -> 'id' AS id,
  (content ->> 'effectiveDateTime') :: TIMESTAMP AS hema_start,
  (content ->> 'effectiveDateTime') :: TIMESTAMP AS hema_end,
  content -> 'code' -> 'coding' -> 0 ->> 'display' AS code_display,
  content -> 'code' -> 'coding' -> 0 ->> 'code' AS code_code,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 1) AS subject_type,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 2) AS subject_id,
  content -> 'valueQuantity' ->> 'value' as quantity_value
FROM observations
WHERE content -> 'code' -> 'coding' -> 0 ->> 'code' = '4544-3';
```

-- Joined & Filtered Query

```sql
SELECT
    t1.id,
    t1.subject_id,
    t1.subject_type,
    t1.hemo_end,
    t1.code_display,
    t1.quantity_value,
    t2.code_display,
    t2.quantity_value,
    t2.subject_id,
    t2.subject_type,
    t2.hema_end
FROM
    hemo AS t1
JOIN
    hema AS t2
ON
    t1.subject_id = t2.subject_id
WHERE
    t1.quantity_value::numeric < 14 
    AND
    t2.quantity_value::numeric < 40
    AND 
    DATE_PART('year', hemo_end) > 2015
    AND 
    DATE_PART('year', hema_end) > 2015
ORDER BY
    t2.hema_end DESC, t1.hemo_end DESC;
```

DuckDB Query

```sql
CREATE TABLE observations AS SELECT * FROM './test-data/Observation-no-narrative-modified.ndjson';


DROP VIEW IF EXISTS hemo;

CREATE VIEW hemo AS
SELECT 
    id::VARCHAR AS id,   
    (effectivePeriod->>'start')::TIMESTAMP AS hemo_start ,
    (effectivePeriod->>'end')::TIMESTAMP AS hemo_end ,
    code->'coding'->0->>'display'::VARCHAR AS code_display,
    subject->>'reference'::VARCHAR AS subject_reference,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 1) AS subject_type,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 2) AS subject_id,
    (valueQuantity->>'value')::NUMERIC AS valueQuantity_value
FROM observations
WHERE code->'coding'->0->>'code' = '718-7';


DROP VIEW IF EXISTS hema;

CREATE VIEW hema AS
SELECT 
    id::VARCHAR AS id,   
    effectiveDateTime::TIMESTAMP AS hema_start ,
    effectiveDateTime::TIMESTAMP AS hema_end ,
    code->'coding'->0->>'display'::VARCHAR AS code_display,
    subject->>'reference'::VARCHAR AS subject_reference,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 1) AS subject_type,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 2) AS subject_id,
    (valueQuantity->>'value')::NUMERIC AS valueQuantity_value  
FROM observations
WHERE code->'coding'->0->>'code' = '4544-3';
```

-- Join statement

```sql
SELECT
    t1.id,
    t1.subject_id,
    t1.hemo_end,
    t1.code_display,
    t1.valueQuantity_value,
    t2.subject_id,
    t2.hema_end,
    t2.code_display,
    t2.valueQuantity_value
FROM
    hemo AS t1
JOIN
    hema AS t2
ON
    t1.subject_id = t2.subject_id
WHERE
    t1.valueQuantity_value < 14
    AND
    t2.valueQuantity_value < 40
    AND
    DATE_PART('year', t1.hemo_end) > 2015
    AND
    DATE_PART('year', t2.hema_end) > 2015
ORDER BY
    t1.hemo_end DESC, t2.hema_end DESC;
```