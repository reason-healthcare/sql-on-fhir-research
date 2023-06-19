Can specify arbitrary type of observation (laboratory, survey, etc)
Can specify loinc code

(Done to both standards : http://142.132.196.32:7777 , https://joshuamandel.com/fhir-view-to-array/)

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
      "name": "observation",
      "expr": "code.coding.display"
    },
    { 
      "name" : "category",
      "expr" : "category.coding.code"
    },
    { 
      "name" : "code" , 
      "expr" : "code.coding.code"
    },
    {
      "from": "valueQuantity",
      "select": [
        {
          "name": "value",
          "expr": "value"
        }
      ]
    }
  ]
}

{:id "hematocrit_observation",
 :from "Observation",
 :where
 [{:expr
   "code.coding.where(system='http://loinc.org' and code = '4544-3')"}],
 :select
 [{:expr "id", :name "id"}
  {:expr "effectiveDateTime", :name "date"}
  {:expr "code.coding.display", :name "observation"}
  {:expr "category.coding.code", :name "category"}
  {:expr "code.coding.code", :name "code"}
  {:expr "subject.reference", :name "patient"}
  {:expr "valueQuantity.value", :name "hema_value", :type "numeric"}]}



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
      "name": "observation",
      "expr": "code.coding.display"
    },
    { 
      "name" : "category",
      "expr" : "category.coding.code"
    },
    { 
      "name" : "code" , 
      "expr" : "code.coding.code"
    },
    {
      "from": "valueQuantity",
      "select": [
        {
          "name": "value",
          "expr": "value"
        }
      ]
    }
  ]
}

{:id "hemoglobin_observation",
 :from "Observation",
 :where
 [{:expr
   "code.coding.where(system='http://loinc.org' and code = '718-7')"}],
 :select
 [{:expr "id", :name "id"}
  {:expr "effectiveDateTime", :name "date"}
  {:expr "code.coding.display", :name "observation"}
  {:expr "category.coding.code", :name "category"}
  {:expr "code.coding.code", :name "code"}
  {:expr "subject.reference", :name "patient"}
  {:expr "valueQuantity.value", :name "hema_value", :type "numeric"}]}

```

ANSI standard query

```json
select hema.patient, hemo.hemo_value, hema.hema_value
from views.hematocrit_observation as hema 
join views.hemoglobin_observation as hemo
on hema.patient = hemo.patient
where hema.hema_value < 40 and hemo.hemo_value < 14
```