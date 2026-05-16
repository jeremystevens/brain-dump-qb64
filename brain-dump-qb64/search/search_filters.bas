' search_filters.bas - Post-search result filtering
' Part of Brain Dump QB64 - Search Everything System
' Responsibility: Accept raw result strings from search_engine.bas
'                 and return a filtered subset.
'                 Never renders UI. Never prints to screen.
'$INCLUDEONCE

' ============================================================
' Helper: Extract_Field$
' Pulls field N (1-based) from a pipe-delimited record string.
' e.g. Extract_Field$("1|5|some idea text #tag", 3) = "some idea text #tag"
' NOTE: This splits on ALL pipes. Use Extract_RawText$ when the
'       third field itself contains pipes (e.g. a full idea line).
' ============================================================
FUNCTION Extract_Field$ (record AS STRING, fieldNum AS INTEGER)
    DIM remaining AS STRING
    DIM token AS STRING
    DIM pipePos AS INTEGER
    DIM count AS INTEGER

    remaining = record
    count = 0

    DO WHILE LEN(remaining) > 0
        pipePos = INSTR(remaining, "|")
        count = count + 1

        IF pipePos = 0 THEN
            token = remaining
            remaining = ""
        ELSE
            token = LEFT$(remaining, pipePos - 1)
            remaining = MID$(remaining, pipePos + 1)
        END IF

        IF count = fieldNum THEN
            Extract_Field = token
            EXIT FUNCTION
        END IF
    LOOP

    Extract_Field = ""
END FUNCTION

' ============================================================
' Helper: Extract_RawText$
' Extracts the full raw idea text from a search result record.
' Result record format: lineNum|score|rawIdeaText
' Unlike Extract_Field$, this skips only the first 2 pipe
' separators and returns everything after them as a single
' string — preserving any pipes inside the raw idea text
' (e.g. the " | " between the idea body and the tags section).
' e.g. Extract_RawText$("1|15|[ts] idea | #game") = "[ts] idea | #game"
' ============================================================
FUNCTION Extract_RawText$ (record AS STRING)
    DIM p1 AS INTEGER
    DIM p2 AS INTEGER

    p1 = INSTR(record, "|")
    IF p1 = 0 THEN
        Extract_RawText = record
        EXIT FUNCTION
    END IF

    p2 = INSTR(p1 + 1, record, "|")
    IF p2 = 0 THEN
        Extract_RawText = MID$(record, p1 + 1)
        EXIT FUNCTION
    END IF

    Extract_RawText = MID$(record, p2 + 1)
END FUNCTION

' ============================================================
' Filter_By_Tag%
' Accepts a CHR$(10)-delimited result block and a tag value
' (with or without leading #). Returns only records whose
' raw text contains that tag.
' Returns filtered result string (same format as input).
' outResults$ is set as output; function returns match count.
' ============================================================
FUNCTION Filter_By_Tag% (resultBlock AS STRING, tagValue AS STRING, outResults AS STRING)
    DIM remaining AS STRING
    DIM record AS STRING
    DIM rawText AS STRING
    DIM searchTag AS STRING
    DIM nlPos AS INTEGER
    DIM count AS INTEGER

    outResults = ""
    count = 0

    ' Normalise tag: ensure it starts with #
    IF LEFT$(tagValue, 1) <> "#" THEN
        searchTag = "#" + tagValue
    ELSE
        searchTag = tagValue
    END IF

    remaining = resultBlock

    DO WHILE LEN(remaining) > 0
        nlPos = INSTR(remaining, CHR$(10))

        IF nlPos = 0 THEN
            record = remaining
            remaining = ""
        ELSE
            record = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF

        IF LEN(LTRIM$(record)) > 0 THEN
            ' Extract the full raw idea text (fields 3 onward) so that
            ' tags in the "body | tags" section are not cut off.
            rawText = Extract_RawText$(record)

            IF INSTR(UCASE$(rawText), UCASE$(searchTag)) > 0 THEN
                count = count + 1
                IF outResults = "" THEN
                    outResults = record
                ELSE
                    outResults = outResults + CHR$(10) + record
                END IF
            END IF
        END IF
    LOOP

    Filter_By_Tag = count
END FUNCTION

' ============================================================
' Filter_By_Priority%
' Filters result block to only records at or above the given
' priority level label (e.g. "high" keeps HIGH and CRITICAL).
' Uses Priority_LabelToLevel% and Priority_Parse% from
' priority_manager.bas — numeric comparison, not string matching.
' Returns match count; outResults receives filtered block.
' ============================================================
FUNCTION Filter_By_Priority% (resultBlock AS STRING, priorityValue AS STRING, outResults AS STRING)
    DIM remaining    AS STRING
    DIM record       AS STRING
    DIM rawText      AS STRING
    DIM nlPos        AS INTEGER
    DIM count        AS INTEGER
    DIM targetLevel  AS INTEGER
    DIM recordLevel  AS INTEGER

    outResults  = ""
    count       = 0

    ' Convert the string label to a numeric threshold
    targetLevel = Priority_LabelToLevel%(priorityValue)

    remaining = resultBlock

    DO WHILE LEN(remaining) > 0
        nlPos = INSTR(remaining, CHR$(10))

        IF nlPos = 0 THEN
            record    = remaining
            remaining = ""
        ELSE
            record    = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF

        IF LEN(LTRIM$(record)) > 0 THEN
            ' Extract the full raw idea text (fields 3 onward) so that
            ' priority tags in the "body | tags" section are not cut off.
            rawText     = Extract_RawText$(record)
            recordLevel = Priority_Parse%(rawText)

            ' Include if record meets or exceeds the target level
            IF recordLevel >= targetLevel THEN
                count = count + 1
                IF outResults = "" THEN
                    outResults = record
                ELSE
                    outResults = outResults + CHR$(10) + record
                END IF
            END IF
        END IF
    LOOP

    Filter_By_Priority = count
END FUNCTION

' ============================================================
' Filter_Favorites%
' Filters result block to only records marked as favorites.
' Uses Favorites_IsFavorite% from favorites_manager.bas —
' reads the fav:1 token directly; no string-tag hacks.
' Returns match count; outResults receives filtered block.
' ============================================================
FUNCTION Filter_Favorites% (resultBlock AS STRING, outResults AS STRING)
    DIM remaining AS STRING
    DIM record    AS STRING
    DIM rawText   AS STRING
    DIM nlPos     AS INTEGER
    DIM count     AS INTEGER

    outResults = ""
    count      = 0

    remaining = resultBlock

    DO WHILE LEN(remaining) > 0
        nlPos = INSTR(remaining, CHR$(10))

        IF nlPos = 0 THEN
            record    = remaining
            remaining = ""
        ELSE
            record    = LEFT$(remaining, nlPos - 1)
            remaining = MID$(remaining, nlPos + 1)
        END IF

        IF LEN(LTRIM$(record)) > 0 THEN
            ' Extract the full raw idea text (fields 3 onward) so that
            ' fav:1 markers in the "body | tags" section are not cut off.
            rawText = Extract_RawText$(record)

            IF Favorites_IsFavorite%(rawText) THEN
                count = count + 1
                IF outResults = "" THEN
                    outResults = record
                ELSE
                    outResults = outResults + CHR$(10) + record
                END IF
            END IF
        END IF
    LOOP

    Filter_Favorites = count
END FUNCTION
