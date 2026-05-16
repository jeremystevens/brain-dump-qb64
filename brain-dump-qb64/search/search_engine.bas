' search_engine.bas - Core search execution and scoring
' Part of Brain Dump QB64 - Search Everything System
' Responsibility: Match and score idea lines against a query.
'                 Never renders UI. Never prints to screen.
' NOTE: TYPE SearchResult and CONST MAX_SEARCH_RESULTS are declared
'       in main.bas (global scope) — QB64 requires TYPE/CONST before
'       any SUB/FUNCTION in the compiled unit.
' NOTE: Depends on priority_manager.bas (included before this module).
'$INCLUDEONCE

' ============================================================
' Search_Init
' Called once at startup. Reserved for future index building.
' ============================================================
SUB Search_Init
    ' Reserved for future initialization
END SUB

' ============================================================
' Search_Match%
' Returns -1 (true) if ANY token from tokenList is found in
' source (case-insensitive). tokenList is pipe-delimited.
' Returns 0 if no tokens match.
' ============================================================
FUNCTION Search_Match% (source AS STRING, tokenList AS STRING)
    DIM upperSource AS STRING
    DIM remaining   AS STRING
    DIM token       AS STRING
    DIM pipePos     AS INTEGER

    upperSource = UCASE$(source)
    remaining   = tokenList

    IF LEN(LTRIM$(RTRIM$(remaining))) = 0 THEN
        Search_Match = 0
        EXIT FUNCTION
    END IF

    DO WHILE LEN(remaining) > 0
        pipePos = INSTR(remaining, "|")

        IF pipePos = 0 THEN
            token     = remaining
            remaining = ""
        ELSE
            token     = LEFT$(remaining, pipePos - 1)
            remaining = MID$(remaining, pipePos + 1)
        END IF

        IF LEN(token) > 0 THEN
            IF INSTR(upperSource, UCASE$(token)) > 0 THEN
                Search_Match = -1
                EXIT FUNCTION
            END IF
        END IF
    LOOP

    Search_Match = 0
END FUNCTION

' ============================================================
' Search_Score%
' Scores a source line against a token list.
' Higher score = better match.
' Scoring rules:
'   +3 per token found in the idea text (before the | separator)
'   +2 per token found in the tags section (after the |)
'   +1 bonus if the full raw query appears as a phrase
'   + Priority weight bonus (Critical=+15, High=+10, Med=+5, Low=+2)
' ============================================================
FUNCTION Search_Score% (source AS STRING, tokenList AS STRING, rawQuery AS STRING)
    DIM upperSource AS STRING
    DIM ideaPart    AS STRING
    DIM tagPart     AS STRING
    DIM pipePos     AS INTEGER
    DIM remaining   AS STRING
    DIM token       AS STRING
    DIM pipeSep     AS INTEGER
    DIM score       AS INTEGER
    DIM pLevel      AS INTEGER

    upperSource = UCASE$(source)
    score       = 0

    ' Split source into idea body and tags portion
    pipePos = INSTR(source, " | ")
    IF pipePos > 0 THEN
        ideaPart = UCASE$(LEFT$(source, pipePos - 1))
        tagPart  = UCASE$(MID$(source, pipePos + 3))
    ELSE
        ideaPart = upperSource
        tagPart  = ""
    END IF

    ' Score each keyword token
    remaining = tokenList
    DO WHILE LEN(remaining) > 0
        pipeSep = INSTR(remaining, "|")

        IF pipeSep = 0 THEN
            token     = remaining
            remaining = ""
        ELSE
            token     = LEFT$(remaining, pipeSep - 1)
            remaining = MID$(remaining, pipeSep + 1)
        END IF

        IF LEN(token) > 0 THEN
            IF INSTR(ideaPart, UCASE$(token)) > 0 THEN score = score + 3
            IF LEN(tagPart) > 0 THEN
                IF INSTR(tagPart, UCASE$(token)) > 0 THEN score = score + 2
            END IF
        END IF
    LOOP

    ' Bonus: full phrase match in the body
    IF LEN(LTRIM$(rawQuery)) > 0 THEN
        IF INSTR(ideaPart, UCASE$(LTRIM$(RTRIM$(rawQuery)))) > 0 THEN
            score = score + 1
        END IF
    END IF

    ' Priority weight bonus — higher priority ideas rank higher
    pLevel = Priority_Parse%(source)
    score  = score + Priority_GetWeight%(pLevel)

    ' Favorite weight bonus — starred ideas rank higher (+20)
    score = score + Favorites_GetWeight%(source)

    Search_Score = score
END FUNCTION

' ============================================================
' Search_Query$
' Main search entry point.
' Reads ideas.txt, scores each line, and returns a compact
' result string for the UI layer to render.
'
' Result format (one entry per match, separated by CHR$(10)):
'   lineNumber|score|rawIdeaText
'
' The caller (UI layer) is responsible for all display logic.
' ============================================================
FUNCTION Search_Query$ (rawQuery AS STRING, tokenList AS STRING)
    DIM fileNum    AS INTEGER
    DIM lineText   AS STRING
    DIM lineNum    AS INTEGER
    DIM matchScore AS INTEGER
    DIM result     AS STRING
    DIM entry      AS STRING

    result  = ""
    lineNum = 0

    fileNum = FREEFILE
    OPEN "ideas.txt" FOR INPUT AS #fileNum

    DO WHILE NOT EOF(fileNum)
        LINE INPUT #fileNum, lineText

        IF LTRIM$(lineText) <> "" THEN
            lineNum = lineNum + 1

            IF Search_Match%(lineText, tokenList) THEN
                matchScore = Search_Score%(lineText, tokenList, rawQuery)

                ' Pack result as: lineNumber|score|rawText
                entry = LTRIM$(STR$(lineNum)) + "|" + _
                        LTRIM$(STR$(matchScore)) + "|" + _
                        lineText

                IF result = "" THEN
                    result = entry
                ELSE
                    result = result + CHR$(10) + entry
                END IF
            END IF
        END IF
    LOOP

    CLOSE #fileNum

    Search_Query = result
END FUNCTION
