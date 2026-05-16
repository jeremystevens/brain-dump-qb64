' export_manager.bas - Central export coordination
' Part of Brain Dump QB64 - Export Modes System
' Responsibility: Route export requests to the correct formatter,
'                 generate filenames, parse raw idea lines into
'                 structured fields, and orchestrate file writing.
'                 NEVER renders UI. NEVER prints to screen.
' NOTE: EXPORT_FMT_* constants declared in main.bas (global scope).
'$INCLUDEONCE

' ============================================================
' Export_Init
' Called once at startup. Reserved for future config loading.
' ============================================================
SUB Export_Init
    ' Reserved for future initialization
END SUB

' ============================================================
' Export_GenerateFilename$
' Builds a timestamped export filename.
' Uses DATE$ (MM-DD-YYYY) and TIME$ (HH:MM:SS).
' Colons in TIME$ are replaced with hyphens — colons are
' illegal in Windows filenames.
' Example: ideas_export_05-15-2026_21-37.txt
' ============================================================
FUNCTION Export_GenerateFilename$ (prefix AS STRING, ext AS STRING)
    DIM d  AS STRING
    DIM t  AS STRING
    DIM ts AS STRING

    d  = DATE$                          ' MM-DD-YYYY
    t  = LEFT$(TIME$, 5)               ' HH:MM  (drop seconds)

    ' Replace the colon in HH:MM with a hyphen
    IF MID$(t, 3, 1) = ":" THEN MID$(t, 3, 1) = "-"

    ts = d + "_" + t                   ' MM-DD-YYYY_HH-MM

    Export_GenerateFilename = prefix + "_" + ts + "." + ext
END FUNCTION

' ============================================================
' Export_ExtForFormat$
' Returns the file extension string for a given format constant.
' ============================================================
FUNCTION Export_ExtForFormat$ (fmt AS INTEGER)
    SELECT CASE fmt
        CASE EXPORT_FMT_HTML
            Export_ExtForFormat = "html"
        CASE EXPORT_FMT_JSON
            Export_ExtForFormat = "json"
        CASE EXPORT_FMT_MD
            Export_ExtForFormat = "md"
        CASE ELSE
            Export_ExtForFormat = "txt"
    END SELECT
END FUNCTION

' ============================================================
' Export_ParseTimestamp$
' Extracts the timestamp from a raw idea line.
' Format: [MM-DD-YYYY HH:MM:SS] rest of line
' Returns the bracketed timestamp, or "" if not found.
' ============================================================
FUNCTION Export_ParseTimestamp$ (rawLine AS STRING)
    DIM startPos AS INTEGER
    DIM endPos   AS INTEGER

    startPos = INSTR(rawLine, "[")
    endPos   = INSTR(rawLine, "]")

    IF startPos = 1 AND endPos > 1 THEN
        Export_ParseTimestamp = MID$(rawLine, startPos, endPos - startPos + 1)
    ELSE
        Export_ParseTimestamp = ""
    END IF
END FUNCTION

' ============================================================
' Export_ParseIdeaText$
' Extracts the idea body from a raw idea line.
' Format: [timestamp] idea_text | tags
' Returns everything between the timestamp and the | separator,
' or the full remainder if no | exists.
' ============================================================
FUNCTION Export_ParseIdeaText$ (rawLine AS STRING)
    DIM afterTs  AS STRING
    DIM endTs    AS INTEGER
    DIM pipePos  AS INTEGER

    endTs = INSTR(rawLine, "]")

    IF endTs = 0 THEN
        Export_ParseIdeaText = LTRIM$(RTRIM$(rawLine))
        EXIT FUNCTION
    END IF

    afterTs = LTRIM$(MID$(rawLine, endTs + 1))

    pipePos = INSTR(afterTs, " | ")
    IF pipePos > 0 THEN
        Export_ParseIdeaText = LTRIM$(RTRIM$(LEFT$(afterTs, pipePos - 1)))
    ELSE
        Export_ParseIdeaText = LTRIM$(RTRIM$(afterTs))
    END IF
END FUNCTION

' ============================================================
' Export_ParseTags$
' Extracts the tags section from a raw idea line.
' Returns everything after " | ", stripped of system tokens
' (priority:N and fav:1) so only user-visible tags remain.
' ============================================================
FUNCTION Export_ParseTags$ (rawLine AS STRING)
    DIM pipePos  AS INTEGER
    DIM tagSec   AS STRING
    DIM result   AS STRING
    DIM remaining AS STRING
    DIM token    AS STRING
    DIM spacePos AS INTEGER

    pipePos = INSTR(rawLine, " | ")
    IF pipePos = 0 THEN
        Export_ParseTags = ""
        EXIT FUNCTION
    END IF

    tagSec    = LTRIM$(RTRIM$(MID$(rawLine, pipePos + 3)))
    result    = ""
    remaining = tagSec

    ' Walk tokens, drop system markers
    DO WHILE LEN(remaining) > 0
        spacePos = INSTR(remaining, " ")
        IF spacePos = 0 THEN
            token     = remaining
            remaining = ""
        ELSE
            token     = LEFT$(remaining, spacePos - 1)
            remaining = LTRIM$(MID$(remaining, spacePos + 1))
        END IF

        IF LEN(token) > 0 THEN
            ' Skip internal system tokens
            IF LCASE$(LEFT$(token, 9))  <> "priority:" AND _
               LCASE$(LEFT$(token, 4))  <> "fav:" THEN
                IF result = "" THEN
                    result = token
                ELSE
                    result = result + " " + token
                END IF
            END IF
        END IF
    LOOP

    Export_ParseTags = result
END FUNCTION

' ============================================================
' Export_WriteIdea
' Master dispatcher — given an open file number, a raw idea
' line, and a format constant, calls the correct formatter.
' This is the single routing point; all formatters receive
' pre-parsed fields so they stay format-only.
' ============================================================
SUB Export_WriteIdea (fileNum AS INTEGER, rawLine AS STRING, fmt AS INTEGER, ideaNum AS INTEGER)
    DIM ts        AS STRING
    DIM ideaText  AS STRING
    DIM tags      AS STRING
    DIM priLabel  AS STRING
    DIM isFav     AS INTEGER
    DIM priLevel  AS INTEGER

    ts       = Export_ParseTimestamp$(rawLine)
    ideaText = Export_ParseIdeaText$(rawLine)
    tags     = Export_ParseTags$(rawLine)
    priLevel = Priority_Parse%(rawLine)
    priLabel = Priority_GetLabel$(priLevel)
    isFav    = Favorites_IsFavorite%(rawLine)

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT
            CALL ExportTxt_WriteIdea(fileNum, ideaNum, ts, ideaText, tags, priLabel, isFav)
        CASE EXPORT_FMT_HTML
            CALL ExportHtml_WriteIdea(fileNum, ideaNum, ts, ideaText, tags, priLabel, isFav)
        CASE EXPORT_FMT_JSON
            CALL ExportJson_WriteIdea(fileNum, ideaNum, ts, ideaText, tags, priLabel, isFav)
        CASE EXPORT_FMT_MD
            CALL ExportMd_WriteIdea(fileNum, ideaNum, ts, ideaText, tags, priLabel, isFav)
    END SELECT
END SUB

' ============================================================
' Export_AllIdeas
' Reads ideas.txt and exports every non-blank line.
' Returns the output filename on success, "" on failure.
' ============================================================
FUNCTION Export_AllIdeas$ (fmt AS INTEGER)
    DIM filename  AS STRING
    DIM fileNum   AS INTEGER
    DIM srcNum    AS INTEGER
    DIM lineText  AS STRING
    DIM ideaCount AS INTEGER
    DIM ext       AS STRING

    ext      = Export_ExtForFormat$(fmt)
    filename = Export_GenerateFilename$("ideas_export", ext)

    fileNum = FREEFILE
    OPEN filename FOR OUTPUT AS #fileNum

    ' Write format header
    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteHeader(fileNum,  "All Ideas Export")
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteHeader(fileNum, "All Ideas Export")
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteHeader(fileNum)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteHeader(fileNum,   "All Ideas Export")
    END SELECT

    srcNum    = FREEFILE
    ideaCount = 0

    OPEN "ideas.txt" FOR INPUT AS #srcNum
    DO WHILE NOT EOF(srcNum)
        LINE INPUT #srcNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            ideaCount = ideaCount + 1
            IF fmt = EXPORT_FMT_JSON AND ideaCount > 1 THEN
                PRINT #fileNum, ","         ' JSON array separator
            END IF
            CALL Export_WriteIdea(fileNum, lineText, fmt, ideaCount)
        END IF
    LOOP
    CLOSE #srcNum

    ' Write format footer
    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteFooter(fileNum,  ideaCount)
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteFooter(fileNum, ideaCount)
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteFooter(fileNum, ideaCount)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteFooter(fileNum,   ideaCount)
    END SELECT

    CLOSE #fileNum

    IF ideaCount = 0 THEN
        KILL filename
        Export_AllIdeas = ""
    ELSE
        Export_AllIdeas = filename
    END IF
END FUNCTION

' ============================================================
' Export_FavoritesOnly
' Reads ideas.txt and exports only favorited lines.
' Returns the output filename on success, "" on failure.
' ============================================================
FUNCTION Export_FavoritesOnly$ (fmt AS INTEGER)
    DIM filename  AS STRING
    DIM fileNum   AS INTEGER
    DIM srcNum    AS INTEGER
    DIM lineText  AS STRING
    DIM ideaCount AS INTEGER
    DIM ext       AS STRING

    ext      = Export_ExtForFormat$(fmt)
    filename = Export_GenerateFilename$("favorites_export", ext)

    fileNum = FREEFILE
    OPEN filename FOR OUTPUT AS #fileNum

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteHeader(fileNum,  "Favorites Export")
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteHeader(fileNum, "Favorites Export")
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteHeader(fileNum)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteHeader(fileNum,   "Favorites Export")
    END SELECT

    srcNum    = FREEFILE
    ideaCount = 0

    OPEN "ideas.txt" FOR INPUT AS #srcNum
    DO WHILE NOT EOF(srcNum)
        LINE INPUT #srcNum, lineText
        IF LTRIM$(lineText) <> "" THEN
            IF Favorites_IsFavorite%(lineText) THEN
                ideaCount = ideaCount + 1
                IF fmt = EXPORT_FMT_JSON AND ideaCount > 1 THEN
                    PRINT #fileNum, ","
                END IF
                CALL Export_WriteIdea(fileNum, lineText, fmt, ideaCount)
            END IF
        END IF
    LOOP
    CLOSE #srcNum

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteFooter(fileNum,  ideaCount)
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteFooter(fileNum, ideaCount)
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteFooter(fileNum, ideaCount)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteFooter(fileNum,   ideaCount)
    END SELECT

    CLOSE #fileNum

    IF ideaCount = 0 THEN
        KILL filename
        Export_FavoritesOnly = ""
    ELSE
        Export_FavoritesOnly = filename
    END IF
END FUNCTION

' ============================================================
' Export_SearchResults
' Accepts the CHR$(10)-delimited result block from the search
' system (format: lineNum|score|rawText per record) and
' exports only the matched ideas.
' Returns the output filename on success, "" on failure.
' ============================================================
FUNCTION Export_SearchResults$ (resultBlock AS STRING, fmt AS INTEGER)
    DIM filename  AS STRING
    DIM fileNum   AS INTEGER
    DIM remaining AS STRING
    DIM record    AS STRING
    DIM rawText   AS STRING
    DIM nlPos     AS INTEGER
    DIM ideaCount AS INTEGER
    DIM ext       AS STRING

    ext      = Export_ExtForFormat$(fmt)
    filename = Export_GenerateFilename$("search_export", ext)

    fileNum = FREEFILE
    OPEN filename FOR OUTPUT AS #fileNum

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteHeader(fileNum,  "Search Results Export")
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteHeader(fileNum, "Search Results Export")
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteHeader(fileNum)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteHeader(fileNum,   "Search Results Export")
    END SELECT

    ideaCount = 0
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
            ' Field 3 of the result record is the raw idea line
            rawText = Extract_Field$(record, 3)
            IF LEN(rawText) > 0 THEN
                ideaCount = ideaCount + 1
                IF fmt = EXPORT_FMT_JSON AND ideaCount > 1 THEN
                    PRINT #fileNum, ","
                END IF
                CALL Export_WriteIdea(fileNum, rawText, fmt, ideaCount)
            END IF
        END IF
    LOOP

    SELECT CASE fmt
        CASE EXPORT_FMT_TXT  : CALL ExportTxt_WriteFooter(fileNum,  ideaCount)
        CASE EXPORT_FMT_HTML : CALL ExportHtml_WriteFooter(fileNum, ideaCount)
        CASE EXPORT_FMT_JSON : CALL ExportJson_WriteFooter(fileNum, ideaCount)
        CASE EXPORT_FMT_MD   : CALL ExportMd_WriteFooter(fileNum,   ideaCount)
    END SELECT

    CLOSE #fileNum

    IF ideaCount = 0 THEN
        KILL filename
        Export_SearchResults = ""
    ELSE
        Export_SearchResults = filename
    END IF
END FUNCTION
