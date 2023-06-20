
```json
{
  "name": "condition_identifiers",
  "from": "Condition",
  "where" : [ { 
    "expr" : "clinicalStatus.coding.code = 'active'" 
    } ],
  "select" : [
    { 
      "name": "id", 
      "expr": "id" 
    },
    { 
      "from" : "code.coding" ,
      "select" : [
        { 
          "name" : "code" , 
          "expr" : "code"
        },
        { 
          "name" : "diagnosis" , 
          "expr" : "display"
        }
      ]
    },
    { "name" : "patient" , 
      "expr" : "subject.reference"}
  ]
}
```

```
{
:id "condition_identifiers",
:from "Condition",
:where [{:expr "clinicalStatus.coding.code = 'active'"}],
  :select [
    {:name "id", :expr "id"},
    {:from "code.coding",
      :select [
        {:name "code", :expr "code"},
        {:name "diagnosis", :expr "display"}
      ]
    },
    {:name "patient", :expr "subject.reference"}
  ]
}
```

```
SELECT patient, COUNT(*) AS num_diagnoses
FROM views.condition_identifiers
GROUP BY patient
HAVING COUNT(*) > 1;
```