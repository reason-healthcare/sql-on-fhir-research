## This use case demonstrates a join between two view definitions that screens patients for potential anemic conditions. It also attempts to tackle date normalization in SQL. Two separate views are constructed and then joined on patient ID. 

These Definitons have been written to two standards : Nikolai's (http://142.132.196.32:7777) and Josh's (https://joshuamandel.com/fhir-view-to-array/)

This use case demonstrates the creation of two independent view definitions and having a SQL query join the tables based upon Subject ID. The equivalent Data tables are also created in PostgreSQL and DuckDB in order to display the utility of choosing to create a view definition over writing the native SQL.

This use case also demonstrates how to normalize different date related FHIR objects into a start and end date in order to have more efficient date related queries. One should run the observation-hemo-period.sh shell script to generate effectivePeriod dates for this demo


The following view definitions use Josh's Syntax and extract Observation ID, Subject ID, Start and End Date, value, and Loinc code from the ndjson Observation Data.

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
      "expr": "subject.reference.getId()"
    },
    { 
      "name" : "dateTimeStart",
      "expr" : "effectiveDateTime"
    },
    { 
      "name" : "dateTimeEnd",
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
      "expr": "subject.reference.getId()"
    },
    { 
      "name" : "dateTimeStart",
      "expr" : "effectivePeriod.start"
    },
    { 
      "name" : "dateTimeEnd",
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

The following view definitions are exactly the same as the ones above but use Nikolai's Syntax 
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
    {:expr "effectiveDateTime", :name "dateTimeStart"}
    {:expr "effectiveDateTime", :name "dateTimeEnd"}
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
    {:expr "effectiveDateTime", :name "dateTimeStart"}
    {:expr "effectiveDateTime", :name "dateTimeEnd"}
    {:expr "code.coding.display", :name "observation"}
    {:expr "category.coding.code", :name "category"}
    {:expr "code.coding.code", :name "code"}
    {:expr "subject.getId()", :name "subject_id"}
    {:expr "valueQuantity.value", :name "hemo_value", :type "numeric"}
  ]
}
```

This is a SQL query that utilizes the view definitions created above. It filters based upon critical hemoglobin and hematocrit values as well as filtering past a certain date.

```sql
SELECT
  hema.subject_id,
  hemo.hemo_value,
  hema.hema_value,
  hemo.dateTimeEnd,
  hema.dateTimeEnd
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
  DATE_PART('year', DATE(dateTimeEnd)) > 2015
  AND 
  DATE_PART('year', DATE(dateTimeEnd)) > 2015
ORDER BY
  hema.dateTimeEnd desc,
  hemo.dateTimeEnd desc;
```

This is an equivalent implementation of the view definitions above in Postgres SQL. Notice how the semantics and syntax are more involved than the straightforward view implementation.

```sql

DROP TABLE IF EXISTS observations;
CREATE TABLE observations (
  id SERIAL PRIMARY KEY,
  content JSONB NOT NULL
);

\copy observations(content) from './test-data/Observation-no-narrative-modified.ndjson';

DROP VIEW IF EXISTS hemo;

CREATE VIEW hemo AS
SELECT
  content -> 'id' AS id,
  (content -> 'effectivePeriod' ->> 'start') :: TIMESTAMP AS dateTimeStart,
  (content -> 'effectivePeriod' ->> 'end') :: TIMESTAMP AS dateTimeEnd,
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
  (content ->> 'effectiveDateTime') :: TIMESTAMP AS dateTimeStart,
  (content ->> 'effectiveDateTime') :: TIMESTAMP AS dateTimeEnd,
  content -> 'code' -> 'coding' -> 0 ->> 'display' AS code_display,
  content -> 'code' -> 'coding' -> 0 ->> 'code' AS code_code,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 1) AS subject_type,
  SPLIT_PART((content -> 'subject' ->> 'reference') :: TEXT, '/', 2) AS subject_id,
  content -> 'valueQuantity' ->> 'value' as quantity_value
FROM observations
WHERE content -> 'code' -> 'coding' -> 0 ->> 'code' = '4544-3';
```

-- Join & Filter Statement

```sql
SELECT
    t1.id,
    t1.subject_id,
    t1.subject_type,
    t1.dateTimeEnd,
    t1.code_display,
    t1.quantity_value,
    t2.code_display,
    t2.quantity_value,
    t2.subject_id,
    t2.subject_type,
    t2.dateTimeEnd
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
    DATE_PART('year', dateTimeEnd) > 2015
    AND 
    DATE_PART('year', dateTimeEnd) > 2015
ORDER BY
    t2.dateTimeEnd DESC, t1.dateTimeEnd DESC;
```

We also implement the views in DuckDB to show a columnar SQL implementation in addition to the row SQL (Postgres) implementation. 

```sql
CREATE TABLE observations AS SELECT * FROM './test-data/Observation-no-narrative-modified.ndjson';


DROP VIEW IF EXISTS hemo;

CREATE VIEW hemo AS
SELECT 
    id::VARCHAR AS id,   
    (effectivePeriod->>'start')::TIMESTAMP AS dateTimeStart ,
    (effectivePeriod->>'end')::TIMESTAMP AS dateTimeEnd ,
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
    effectiveDateTime::TIMESTAMP AS dateTimeStart ,
    effectiveDateTime::TIMESTAMP AS dateTimeEnd ,
    code->'coding'->0->>'display'::VARCHAR AS code_display,
    subject->>'reference'::VARCHAR AS subject_reference,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 1) AS subject_type,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 2) AS subject_id,
    (valueQuantity->>'value')::NUMERIC AS valueQuantity_value  
FROM observations
WHERE code->'coding'->0->>'code' = '4544-3';
```

-- Join & Filter statement

```sql
SELECT
    t1.id,
    t1.subject_id,
    t1.dateTimeEnd,
    t1.code_display,
    t1.valueQuantity_value,
    t2.subject_id,
    t2.dateTimeEnd,
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
    DATE_PART('year', t1.dateTimeEnd) > 2015
    AND
    DATE_PART('year', t2.dateTimeEnd) > 2015
ORDER BY
    t1.dateTimeEnd DESC, t2.dateTimeEnd DESC;
```