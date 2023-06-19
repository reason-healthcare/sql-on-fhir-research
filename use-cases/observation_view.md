Can specify arbitrary type of observation (laboratory, survey, etc)
Can specify loinc code

<<<<<<< HEAD
'''json
{
  "name": "observation_identifiers",
  "from": "Observation",
  %%%
  "where": [
    {
      %% laboratory | survey | vital-signs %%
      "expr": "category.coding.code = 'laboratory'"
    },
    { 
      %% respective code in the codebase %% 
      "expr" : "code.coding.code = '21000-5'" 
    }
  ],
  %%%
=======
```json
{
  "name": "observation_identifiers",
  "from": "Observation",
  "where": [
    {
      "expr": "category.coding.code = 'survey'"
    },
    {
      "expr": "code.coding.code = '38208-5'"
    }
  ],
>>>>>>> 09adc270bdec1fbd5a2dd45394a14d5344d9eb78
  "select": [
    {
      "name": "id",
      "expr": "id"
    },
    {
      "name": "observation",
      "expr": "code.coding.display"
    },
<<<<<<< HEAD
    { 
      "name" : "category",
      "expr" : "category.coding.code"
    },
    { 
      "name" : "code" , 
      "expr" : "code.coding.code"
    },
=======
>>>>>>> 09adc270bdec1fbd5a2dd45394a14d5344d9eb78
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
<<<<<<< HEAD

'''

=======
```
>>>>>>> 09adc270bdec1fbd5a2dd45394a14d5344d9eb78
