# IDEA : normalize(start | end) function to fix dateTime data

EX:
```json
{ 
      "name" : "dateTimeStart",
      "expr" : "effectiveDateTime.normalize('start')"
    }
```

Pseudocode
```
function isLeapYear(year):
    if year % 4 != 0:
        return false
    else:
        return true

function lastDayOfMonth(year, month):
    if month in ["04", "06", "09", "11"]:
        return "30"
    else if month == "02":
        if isLeapYear(year):
            return "29"
        else:
            return "28"
    else:
        return "31"

function normalize(inputDateTimeStr, field):
    // Initialize period FHIR object with start and end attributes
    period = new Period()

    // YYYY format regex
    yearRegex = "^([0-9]{4})$"
    // YYYY-MM format regex
    monthRegex = "^([0-9]{4})-([0-9]{2})$"
    // YYYY-MM-DD format regex
    dateRegex = "^([0-9]{4})-([0-9]{2})-([0-9]{2})$"
    
    if matches(inputDateTimeStr, dateRegex):
        // inputDateTimeStr is already in the form YYYY-MM-DD
        if field == 'start':
            period.start = inputDateTimeStr
        else if field == 'end':
            period.end = inputDateTimeStr
    else if matches(inputDateTimeStr, monthRegex):
        // inputDateTimeStr is in the form YYYY-MM
        year, month = parse(inputDateTimeStr, monthRegex)
        if field == 'start':
            period.start = format(year, month, "01")
        else if field == 'end':
            period.end = format(year, month, lastDayOfMonth(year, month))
    else if matches(inputDateTimeStr, yearRegex):
        // inputDateTimeStr is in the form YYYY
        year = parse(inputDateTimeStr, yearRegex)
        if field == 'start':
            period.start = format(year, "01", "01")
        else if field == 'end':
            period.end = format(year, "12", "31")
    else:
        raise Exception("Invalid date format")

    return period

```
