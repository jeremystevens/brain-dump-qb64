' date_helpers.bas - Date formatting, parsing, and utility functions
' Part of Brain Dump QB64 - Daily Journal Mode (Phase 3)
' Responsibility: All date/time formatting and calculation logic.
'                 No rendering. No journal storage logic.
' NOTE: No CONST/TYPE here — all in main.bas per QB64 rules.
'$INCLUDEONCE

' ============================================================
' Date_GetCurrent$
' Returns today's date in YYYY-MM-DD format.
' QB64's DATE$ returns MM-DD-YYYY — this reformats it.
' YYYY-MM-DD sorts correctly as a plain string (lexicographic).
' ============================================================
FUNCTION Date_GetCurrent$
    DIM d AS STRING
    d = DATE$   ' MM-DD-YYYY

    Date_GetCurrent = RIGHT$(d, 4) + "-" + LEFT$(d, 2) + "-" + MID$(d, 4, 2)
END FUNCTION

' ============================================================
' Date_GetTimestamp$
' Returns a full bracketed timestamp: [YYYY-MM-DD HH:MM:SS]
' Used as the prefix for every journal entry line.
' ============================================================
FUNCTION Date_GetTimestamp$
    DIM d AS STRING
    DIM t AS STRING

    d = DATE$   ' MM-DD-YYYY
    t = TIME$   ' HH:MM:SS

    Date_GetTimestamp = "[" + RIGHT$(d, 4) + "-" + LEFT$(d, 2) + "-" + MID$(d, 4, 2) + " " + t + "]"
END FUNCTION

' ============================================================
' Date_Format$
' Converts a stored YYYY-MM-DD date to a display-friendly
' format: "May 16, 2026"
' Returns the input unchanged if it cannot be parsed.
' ============================================================
FUNCTION Date_Format$ (isoDate AS STRING)
    DIM yr  AS STRING
    DIM mo  AS STRING
    DIM dy  AS STRING
    DIM moNum AS INTEGER

    IF LEN(isoDate) <> 10 THEN
        Date_Format = isoDate
        EXIT FUNCTION
    END IF

    yr    = LEFT$(isoDate, 4)
    mo    = MID$(isoDate, 6, 2)
    dy    = RIGHT$(isoDate, 2)
    moNum = VAL(mo)

    DIM moName AS STRING
    SELECT CASE moNum
        CASE 1  : moName = "January"
        CASE 2  : moName = "February"
        CASE 3  : moName = "March"
        CASE 4  : moName = "April"
        CASE 5  : moName = "May"
        CASE 6  : moName = "June"
        CASE 7  : moName = "July"
        CASE 8  : moName = "August"
        CASE 9  : moName = "September"
        CASE 10 : moName = "October"
        CASE 11 : moName = "November"
        CASE 12 : moName = "December"
        CASE ELSE : moName = mo
    END SELECT

    ' Strip leading zero from day
    IF LEFT$(dy, 1) = "0" THEN dy = RIGHT$(dy, 1)

    Date_Format = moName + " " + dy + ", " + yr
END FUNCTION

' ============================================================
' Date_Parse$
' Extracts the YYYY-MM-DD date from a journal line timestamp.
' Journal lines start with [YYYY-MM-DD HH:MM:SS]
' Returns "" if no valid date found.
' ============================================================
FUNCTION Date_Parse$ (rawLine AS STRING)
    DIM startPos AS INTEGER
    DIM candidate AS STRING

    startPos = INSTR(rawLine, "[")
    IF startPos = 0 THEN
        Date_Parse = ""
        EXIT FUNCTION
    END IF

    ' Date is chars 2-11 inside the bracket: [YYYY-MM-DD ...]
    IF LEN(rawLine) >= startPos + 10 THEN
        candidate = MID$(rawLine, startPos + 1, 10)
        IF Date_IsValid%(candidate) THEN
            Date_Parse = candidate
            EXIT FUNCTION
        END IF
    END IF

    Date_Parse = ""
END FUNCTION

' ============================================================
' Date_IsValid%
' Returns -1 if the string is a valid YYYY-MM-DD date.
' Returns 0 otherwise. Basic structural check only.
' ============================================================
FUNCTION Date_IsValid% (isoDate AS STRING)
    DIM mo AS INTEGER
    DIM dy AS INTEGER

    IF LEN(isoDate) <> 10 THEN
        Date_IsValid = 0
        EXIT FUNCTION
    END IF

    IF MID$(isoDate, 5, 1) <> "-" OR MID$(isoDate, 8, 1) <> "-" THEN
        Date_IsValid = 0
        EXIT FUNCTION
    END IF

    mo = VAL(MID$(isoDate, 6, 2))
    dy = VAL(RIGHT$(isoDate, 2))

    IF mo < 1 OR mo > 12 OR dy < 1 OR dy > 31 THEN
        Date_IsValid = 0
        EXIT FUNCTION
    END IF

    Date_IsValid = -1
END FUNCTION

' ============================================================
' Date_Compare%
' Compares two YYYY-MM-DD strings lexicographically.
' Returns:  1 if a > b (a is later)
'           0 if a = b
'          -1 if a < b (a is earlier)
' Used for future sorting and timeline browsing.
' ============================================================
FUNCTION Date_Compare% (a AS STRING, b AS STRING)
    IF a > b THEN
        Date_Compare = 1
    ELSEIF a < b THEN
        Date_Compare = -1
    ELSE
        Date_Compare = 0
    END IF
END FUNCTION

' ============================================================
' Date_GetWeekday$
' Returns the day name for a YYYY-MM-DD date string.
' Uses QB64's internal date arithmetic via DATEVALUE.
' Falls back gracefully if date is unparseable.
' ============================================================
FUNCTION Date_GetWeekday$ (isoDate AS STRING)
    ' QB64 does not expose a direct weekday function.
    ' We use a simple Zeller-style calculation on the numbers.
    DIM yr  AS INTEGER
    DIM mo  AS INTEGER
    DIM dy  AS INTEGER
    DIM dow AS INTEGER
    DIM k   AS INTEGER
    DIM m   AS INTEGER
    DIM y   AS INTEGER

    IF NOT Date_IsValid%(isoDate) THEN
        Date_GetWeekday = ""
        EXIT FUNCTION
    END IF

    yr = VAL(LEFT$(isoDate, 4))
    mo = VAL(MID$(isoDate, 6, 2))
    dy = VAL(RIGHT$(isoDate, 2))

    ' Zeller's congruence (0=Saturday, 1=Sunday ... 6=Friday)
    IF mo < 3 THEN
        mo = mo + 12
        yr = yr - 1
    END IF

    k   = yr MOD 100
    m   = yr \ 100
    dow = (dy + ((13 * (mo + 1)) \ 5) + k + (k \ 4) + (m \ 4) - (2 * m)) MOD 7

    ' Normalize to 0=Sunday
    dow = ((dow + 6) MOD 7)

    SELECT CASE dow
        CASE 0 : Date_GetWeekday = "Sunday"
        CASE 1 : Date_GetWeekday = "Monday"
        CASE 2 : Date_GetWeekday = "Tuesday"
        CASE 3 : Date_GetWeekday = "Wednesday"
        CASE 4 : Date_GetWeekday = "Thursday"
        CASE 5 : Date_GetWeekday = "Friday"
        CASE 6 : Date_GetWeekday = "Saturday"
    END SELECT
END FUNCTION
