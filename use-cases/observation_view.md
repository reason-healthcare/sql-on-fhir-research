Can specify arbitrary type of observation (laboratory, survey, etc)
Can specify loinc code

```
{
  "name": "observation_identifiers",
  "from": "Observation",
  "where": [{ "expr": "category.coding.code = 'survey'" }, 
            {"expr" : "code.coding.code = '38208-5'"}],
  "select": [
    { "name": "id", "expr": "id" },
    { "name" : "observation" , "expr" : "code.coding.display" },
    {
    "from" : "valueQuantity",
    "select" : [
       { "name" : "value" , "expr" : "value" }
      ] 
    } 
  ]
}
```
