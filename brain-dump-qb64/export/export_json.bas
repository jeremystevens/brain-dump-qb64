' export_json.bas - JSON export formatter
' Part of Brain Dump QB64 - Export Modes System
' Responsibility: Format and write idea records as valid JSON.
'                 Machine-readable. Future API/backup compatible.
'                 NEVER reads files. NEVER renders UI.
'$INCLUDEONCE

' ============================================================
' ExportJson_EscapeStr$
' Escapes characters that would break JSON string literals:
'   backslash -> \\
'   double-quote -> \"
' Keeps output valid for parsers and future API systems.
' ============================================================
FUNCTION ExportJson_EscapeStr$ (s AS STRING)
    DIM result  AS STRING
    DIM i       AS INTEGER
    DIM ch      AS STRING

    result = ""
    FOR i = 1 TO LEN(s)
        ch = MID$(s, i, 1)
        SELECT CASE ch
            CASE "\"
                result = result + "\\"
            CASE CHR$(34)           ' double-quote
                result = result + "\" + CHR$(34)
            CASE ELSE
                result = result + ch
        END SELECT
    NEXT i

    ExportJson_EscapeStr = result
END FUNCTION

' ============================================================
' ExportJson_WriteHeader
' Opens the JSON array. Call once before any idea records.
' ============================================================
SUB ExportJson_WriteHeader (fileNum AS INTEGER)
    PRINT #fileNum, "{"
    PRINT #fileNum, "  " + CHR$(34) + "export_source" + CHR$(34) + ": " + CHR$(34) + "Brain Dump QB64" + CHR$(34) + ","
    PRINT #fileNum, "  " + CHR$(34) + "export_date"   + CHR$(34) + ": " + CHR$(34) + DATE$ + " " + TIME$ + CHR$(34) + ","
    PRINT #fileNum, "  " + CHR$(34) + "ideas" + CHR$(34) + ": ["
END SUB

' ============================================================
' ExportJson_WriteIdea
' Writes one JSON object for a single idea.
' Comma between records is handled by export_manager (it
' prints a comma BEFORE calling this for records after the first).
' ============================================================
SUB ExportJson_WriteIdea (fileNum AS INTEGER, ideaNum AS INTEGER, timestamp AS STRING, ideaText AS STRING, tags AS STRING, priorityLabel AS STRING, isFav AS INTEGER)
    DIM q       AS STRING
    DIM favStr  AS STRING

    q = CHR$(34)

    IF isFav THEN
        favStr = "true"
    ELSE
        favStr = "false"
    END IF

    PRINT #fileNum, "    {"
    PRINT #fileNum, "      " + q + "id"        + q + ": "  + LTRIM$(STR$(ideaNum)) + ","
    PRINT #fileNum, "      " + q + "timestamp" + q + ": "  + q + ExportJson_EscapeStr$(timestamp) + q + ","
    PRINT #fileNum, "      " + q + "idea"      + q + ": "  + q + ExportJson_EscapeStr$(ideaText)  + q + ","
    PRINT #fileNum, "      " + q + "tags"      + q + ": "  + q + ExportJson_EscapeStr$(tags)      + q + ","
    PRINT #fileNum, "      " + q + "priority"  + q + ": "  + q + priorityLabel + q + ","
    PRINT #fileNum, "      " + q + "favorite"  + q + ": "  + favStr
    PRINT #fileNum, "    }"
END SUB

' ============================================================
' ExportJson_WriteFooter
' Closes the JSON array and root object.
' ============================================================
SUB ExportJson_WriteFooter (fileNum AS INTEGER, ideaCount AS INTEGER)
    PRINT #fileNum, "  ],"
    PRINT #fileNum, "  " + CHR$(34) + "total_exported" + CHR$(34) + ": " + LTRIM$(STR$(ideaCount))
    PRINT #fileNum, "}"
END SUB
