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
         {"name" : "kg" , "expr" : "value"},
         {"name" : "lbs", "expr" : "value * %kg_to_lbs"}
      ]
    }
```

also this constant is added 
```json
{"name": "kg_to_lbs" , "value" : 2.20462}
```