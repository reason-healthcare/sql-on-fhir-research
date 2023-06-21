## This use case demonstrates a join between two view definitions that screens patients for potential anemic conditions. Two separate tables are constructed and then joined on patient ID. 

These Definitons have been written to two standards : Nikolai's (http://142.132.196.32:7777) and Josh's (https://joshuamandel.com/fhir-view-to-array/)


Josh's Syntax

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
      "name" : "date",
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
      "name" : "date",
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

Nikolai's Syntax

```
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
    {:expr "effectiveDateTime", :name "hema_date"}
    {:expr "code.coding.display", :name "observation"}
    {:expr "category.coding.code", :name "category"}
    {:expr "code.coding.code", :name "code"}
    {:expr "subject.reference", :name "patient"}
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
    {:expr "effectiveDateTime", :name "hemo_date"}
    {:expr "code.coding.display", :name "observation"}
    {:expr "category.coding.code", :name "category"}
    {:expr "code.coding.code", :name "code"}
    {:expr "subject.reference", :name "patient"}
    {:expr "valueQuantity.value", :name "hemo_value", :type "numeric"}
  ]
}

```

ANSI standard query

```
SELECT distinct hema.patient, hemo.hemo_value, hema.hema_value, hemo.hemo_date, hema.hema_date
FROM views.hematocrit_observation AS hema 
JOIN views.hemoglobin_observation AS hemo
ON hema.patient = hemo.patient
WHERE hema.hema_value < 40 AND hemo.hemo_value < 14
ORDER BY hema.hema_date desc, hemo.hemo_date desc

```

Postgres query
```

-- Create a new tables to hold the extracted data
CREATE TABLE hemo (
    id text,
    effective_date_time text,
    code_coding_display text,
    code_coding_code text,
    category_coding_code text,
    subject_reference text,
    value_quantity_value text
);

CREATE TABLE hema (
    id text,
    effective_date_time text,
    code_coding_display text,
    code_coding_code text,
    category_coding_code text,
    subject_reference text,
    value_quantity_value text
);

-- Insert Nested JSON data into tables
INSERT INTO hemo (id, effective_date_time, code_coding_display, code_coding_code, category_coding_code, subject_reference, value_quantity_value)
SELECT
    content ->> 'id',
    content ->> 'effectiveDateTime',
    (content -> 'code' -> 'coding' -> 0 ->> 'display'),
    (content -> 'code' -> 'coding' -> 0 ->> 'code'),
    (content -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'),
    (content -> 'subject' ->> 'reference'),
    (content -> 'valueQuantity' ->> 'value')
FROM data
WHERE (content -> 'code' -> 'coding' -> 0 ->> 'code') = '718-7';

INSERT INTO hema (id, effective_date_time, code_coding_display, code_coding_code, category_coding_code, subject_reference, value_quantity_value)
SELECT
    content ->> 'id',
    content ->> 'effectiveDateTime',
    (content -> 'code' -> 'coding' -> 0 ->> 'display'),
    (content -> 'code' -> 'coding' -> 0 ->> 'code'),
    (content -> 'category' -> 0 -> 'coding' -> 0 ->> 'code'),
    (content -> 'subject' ->> 'reference'),
    (content -> 'valueQuantity' ->> 'value')
FROM data
WHERE (content -> 'code' -> 'coding' -> 0 ->> 'code') = '4544-3';


-- Joined & Filtered Query
SELECT
    t1.id,
    t1.subject_reference,
    t1.effective_date_time,
    t1.code_coding_display,
    t1.value_quantity_value,
    t2.code_coding_display,
    t2.value_quantity_value
FROM
    hemo AS t1
JOIN
    hema AS t2
ON
    t1.subject_reference = t2.subject_reference
WHERE
    t1.value_quantity_value::numeric < 14 
    AND
    t2.value_quantity_value::numeric < 40;
```


