```clojure
{
  :id "weight_valueset_union_example",
  :from "Observation",
  :select [
    {:expr "subject.getId()", :name "id"},
    {:from "Observation.where(code.coding.exists(system='http://loinc.org' and valueset.url='LG34372-9'))",
      :select [{:expr "valueQuantity.value", :name "kg"}]
    }
  ]
}
```

```clojure
{
  :id "weight_observations",
  :from "Observation",
  :where [
    {:expr "code.coding.exists(system='http://loinc.org' and code='29463-7' or code='3141-9' or code='3142-7' or code='75292-3' or code='79348-9' or code='8350-1' or code='8351-9')"}
  ],
  :select [
    {:expr "subject.getId()", :name "id"},
    {:expr "valueQuantity.value", :name "kg"}
  ]
}

```

```clojure
{
  :id "union_example",
  :from "Observation",
  :select [
    {:expr "subject.getId()", :name "id"},
    {:union [
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='29463-7'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='3141-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='3142-7'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='75292-3'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='79348-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='8350-1'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      },
      {:from "Observation.where(code.coding.exists(system='http://loinc.org' and code='8351-9'))", 
       :select [{:expr "valueQuantity.value", :name "kg"}]
      }
     ]
    }
  ]
}
```
