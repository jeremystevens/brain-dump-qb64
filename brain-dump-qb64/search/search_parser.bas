' search_parser.bas - Query parsing and tokenization
' Part of Brain Dump QB64 - Search Everything System
' Responsibility: Break raw user input into searchable tokens and named filters
'$INCLUDEONCE

' ============================================================
' Parse_Search_Query$
' Returns the plain keyword portion of a query string,
' stripping any named filter operators (tag:, priority:, fav:)
' ============================================================
FUNCTION Parse_Search_Query$ (rawQuery AS STRING)
    DIM result AS STRING
    DIM token AS STRING
    DIM remaining AS STRING
    DIM spacePos AS INTEGER

    result = ""
    remaining = LTRIM$(RTRIM$(rawQuery))

    ' Walk through space-delimited tokens
    DO WHILE LEN(remaining) > 0
        spacePos = INSTR(remaining, " ")

        IF spacePos = 0 THEN
            token = remaining
            remaining = ""
        ELSE
            token = LEFT$(remaining, spacePos - 1)
            remaining = LTRIM$(MID$(remaining, spacePos + 1))
        END IF

        ' Only keep tokens that are NOT named filter operators
        IF INSTR(LCASE$(token), "tag:") = 0 AND _
           INSTR(LCASE$(token), "priority:") = 0 AND _
           INSTR(LCASE$(token), "fav:") = 0 AND _
           INSTR(LCASE$(token), "favorite:") = 0 AND _
           INSTR(LCASE$(token), "starred:") = 0 THEN
            IF result = "" THEN
                result = token
            ELSE
                result = result + " " + token
            END IF
        END IF
    LOOP

    Parse_Search_Query = LTRIM$(RTRIM$(result))
END FUNCTION

' ============================================================
' Extract_Search_Tokens$
' Returns all plain keyword tokens as a pipe-delimited string
' e.g. "build app fast" -> "build|app|fast"
' ============================================================
FUNCTION Extract_Search_Tokens$ (rawQuery AS STRING)
    DIM cleaned AS STRING
    DIM result AS STRING
    DIM token AS STRING
    DIM remaining AS STRING
    DIM spacePos AS INTEGER

    result = ""
    cleaned = Parse_Search_Query$(rawQuery)
    remaining = LTRIM$(RTRIM$(cleaned))

    DO WHILE LEN(remaining) > 0
        spacePos = INSTR(remaining, " ")

        IF spacePos = 0 THEN
            token = remaining
            remaining = ""
        ELSE
            token = LEFT$(remaining, spacePos - 1)
            remaining = LTRIM$(MID$(remaining, spacePos + 1))
        END IF

        IF LEN(token) > 0 THEN
            IF result = "" THEN
                result = token
            ELSE
                result = result + "|" + token
            END IF
        END IF
    LOOP

    Extract_Search_Tokens = result
END FUNCTION

' ============================================================
' Extract_Search_Filters$
' Extracts the value of a named filter operator from a query.
' filterName should be one of: "tag", "priority", "fav", "favorite"
' Returns the value after the colon, or "" if not found.
' e.g. query = "build tag:game priority:high"
'      Extract_Search_Filters$("tag") -> "game"
' ============================================================
FUNCTION Extract_Search_Filters$ (rawQuery AS STRING, filterName AS STRING)
    DIM remaining AS STRING
    DIM token AS STRING
    DIM spacePos AS INTEGER
    DIM colonPos AS INTEGER
    DIM prefix AS STRING
    DIM value AS STRING

    remaining = LTRIM$(RTRIM$(rawQuery))
    prefix = LCASE$(filterName) + ":"

    DO WHILE LEN(remaining) > 0
        spacePos = INSTR(remaining, " ")

        IF spacePos = 0 THEN
            token = remaining
            remaining = ""
        ELSE
            token = LEFT$(remaining, spacePos - 1)
            remaining = LTRIM$(MID$(remaining, spacePos + 1))
        END IF

        ' Check if this token starts with the filter prefix
        IF LCASE$(LEFT$(token, LEN(prefix))) = prefix THEN
            value = MID$(token, LEN(prefix) + 1)
            Extract_Search_Filters = LTRIM$(RTRIM$(value))
            EXIT FUNCTION
        END IF
    LOOP

    Extract_Search_Filters = ""
END FUNCTION
