## This use case demonstrates joining codes based on a LOINC valueset. 

### These Definitons have been written to Nikolai's standard :  (http://142.132.196.32:7777) 

This proposal aims to improve the flattened FHIR view draft specification by streamlining the process of querying codes based on a LOINC Valueset, which is a critical concept in FHIR that allows for standardization and scalability.

We propose the introduction of a new 'valueset' operator, which works in conjunction with the 'exists' function within 'code.coding'. This approach aims to eliminate the non-scalable use of the 'union' operator for matching codes individually. Instead, users can query the entire Valueset at once, resulting in cleaner and more efficient code.

ValueSets are an important FHIR concept that group alike codes and allow for code standardization. In practice, when a user wants patient analytics they would want all codes in the valueset to be queried and standardized for the users dashboard. To that point, this use case demonstrates filtering Condition entries based on a Hypertension ValueSet and shows a related example query. 

The following SQL example uses DuckDB, a columnar DBMS that automatically parses JSON data, making it easier to query specified nested fields.

Load in valueset and condition entries

```sql
CREATE TABLE valueset AS SELECT * FROM './test-data/ValueSet-2.16.840.1.113883.3.3157.4012.json';

CREATE TABLE condition AS SELECT * FROM 'test-data/Condition-no-narrative.ndjson';
```
Extract valueset codes using duckdb's functional syntax
```sql
CREATE TABLE valueset_codes AS SELECT UNNEST(expansion.contains).code::VARCHAR AS valueCode FROM valueset WHERE id='2.16.840.1.113883.3.3157.4012';
```
Run an example query that simply selects all patients with a specific condition, in this case that conditon is Hypertension
```sql
SELECT
  condition_code,
  condition_id,
  subject_reference
FROM (
  SELECT
    UNNEST(code.coding).code::VARCHAR as condition_code,
    id AS condition_id,
    subject.reference as subject_reference
  FROM condition
) 
WHERE conditionCode IN (SELECT valueCode::VARCHAR from valueset_codes);
```
This additional query demonstrates how to query a join with patient entries in order to determine the names of the patients with specific conditions for any code in the valueset. A new patient table is created and then joined based on patient id and subject.reference 
```sql
CREATE TABLE patient AS SELECT * FROM 'test-data/Patient-no-narrative.ndjson';

SELECT
  condition_code,
  condition_id,
  subject_id,
  (patient.name::JSON)->>0->'given'->>1 AS first_name,
  (patient.name::JSON)->>0->'given'->>0 AS last_name
FROM (
  SELECT
    UNNEST(code.coding).code::VARCHAR as condition_code,
    id as condition_id,
    SPLIT_PART((subject ->> 'reference') :: TEXT, '/', 2) AS subject_id
  FROM condition
) 
JOIN
  patient ON subject_id = patient.id
WHERE condition_code IN (SELECT valueCode::VARCHAR from valueset_codes);

```
We then would like to implement the following logic in the View Layer, and the following examples show how one would go about the implementation.

This example is more of a brute force method in which the union operator is utilized to try and join all of the observations on subject ID. We switched to a bodyweight valueset as there are a reasonably small number of codes and therefore more pertinent to this example. Even people with minimal coding experience can probably tell that the syntax is a bit redundant and is not scalable past a small number of codes.
```clojure
{
  :id "union_example",
  :from "Observation",
  :select [
    {:expr "id", :name "id"},
    {:expr "subject.getId()", :name "subject_id"},
    {:union [
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='29463-7'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='3141-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='3142-7'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='75292-3'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='79348-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='8350-1'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='8351-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}, {:expr "code.coding.code", :name "code"}]
      }
     ]
    }
  ]
}

```


In the example provided below, the 'valueset' operator is used to find observations where the coding system is 'http://loinc.org' and the valueset is 'LG34372-9'. The query then selects the id, subject id, and the valueQuantity of these matched observations.

Here is an example of a proposed view that can handle observations that may have different codes based on a LOINC Valueset:

```clojure
{
  :id "weight_valueset_example",
  :from "Observation",
  :select [
    {:expr "id", :name "id"},
    {:expr "subject.getId()", :name "subject_id"},
    {:from "Observation.where(code.coding.exists(system='http://loinc.org' and valueset='LG34372-9'))",
      :select [{:expr "valueQuantity.value", :name "kg"}]
    }
  ]
}
```