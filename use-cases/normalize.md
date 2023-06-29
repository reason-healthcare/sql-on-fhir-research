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
    // YYYY format regex
    yearRegex = "^([0-9]{4})$"
    // YYYY-MM format regex
    monthRegex = "^([0-9]{4})-([0-9]{2})$"
    // YYYY-MM-DD format regex
    dateRegex = "^([0-9]{4})-([0-9]{2})-([0-9]{2})$"
    // YYYY-MM-DD-HH-mm-ss
    dateTimeRegex = "^(\d{4})-(\d{2})-(\d{2})\s(\d{2}):(\d{2}):(\d{2})$"

    if matches(inputDateTimeStr, dateRegex):
        // inputDateTimeStr is already in the form YYYY-MM-DD
        if field == 'start':
            return inputDateTimeStr
        else if field == 'end':
            return inputDateTimeStr
    else if matches(inputDateTimeStr, monthRegex):
        // inputDateTimeStr is in the form YYYY-MM
        year, month = parse(inputDateTimeStr, monthRegex)
        if field == 'start':
            return format(year, month, "01")
        else if field == 'end':
            return format(year, month, lastDayOfMonth(year, month))
    else if matches(inputDateTimeStr, yearRegex):
        // inputDateTimeStr is in the form YYYY
        year = parse(inputDateTimeStr, yearRegex)
        if field == 'start':
            return format(year, "01", "01")
        else if field == 'end':
            return format(year, "12", "31")
    else if matches(inputDateTimeStr, dateTimeRegex):
        // inputDateTimeStr is in the form YYYY-MM-DD-HH-mm-ss
        return inputDateTimeStr
    else:
        raise Exception("Invalid date format")

```
