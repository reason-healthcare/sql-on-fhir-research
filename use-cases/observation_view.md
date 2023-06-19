Can specify arbitrary type of observation (laboratory, survey, etc)
Can specify loinc code

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
  "select": [
    {
      "name": "id",
      "expr": "id"
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

'''

