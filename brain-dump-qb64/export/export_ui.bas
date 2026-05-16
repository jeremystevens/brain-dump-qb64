' export_ui.bas - Export system UI screens
' Part of Brain Dump QB64 - Export Modes System
' Responsibility: ALL screen rendering for the export feature.
'                 Uses window_renderer for screen chrome.
'$INCLUDEONCE

' ============================================================
' Export_SelectFormat%
' Presents format menu; returns an EXPORT_FMT_* constant.
' ============================================================
FUNCTION Export_SelectFormat%
    DIM inputStr AS STRING

    PRINT "  Select export format:"
    PRINT "    1. TXT      - Plain text  (any editor)"
    PRINT "    2. Markdown - .md file    (GitHub / docs)"
    PRINT "    3. JSON     - .json file  (machine readable)"
    PRINT "    4. HTML     - .html file  (browser)"
    PRINT
    INPUT "  Format (1-4, Enter=TXT): ", inputStr

    SELECT CASE LTRIM$(RTRIM$(inputStr))
        CASE "2" : Export_SelectFormat = EXPORT_FMT_MD
        CASE "3" : Export_SelectFormat = EXPORT_FMT_JSON
        CASE "4" : Export_SelectFormat = EXPORT_FMT_HTML
        CASE ELSE : Export_SelectFormat = EXPORT_FMT_TXT
    END SELECT
END FUNCTION

' ============================================================
' ExportScreen
' Main export screen — choose what to export, then format.
' ============================================================
SUB ExportScreen
    DIM choice   AS STRING
    DIM fmt      AS INTEGER
    DIM filename AS STRING
    DIM crow     AS INTEGER

    crow = Window_DrawScreen%("EXPORT IDEAS", "[EXPORT MODE]")

    LOCATE crow,     3 : PRINT "What would you like to export?"
    LOCATE crow + 2, 3 : PRINT "  1.  All ideas"
    LOCATE crow + 3, 3 : PRINT "  2.  Favorites only"
    LOCATE crow + 4, 3 : PRINT "  3.  Cancel"
    LOCATE crow + 6, 3
    INPUT "Choose (1-3): ", choice

    SELECT CASE LTRIM$(RTRIM$(choice))
        CASE "1"
            LOCATE crow + 8, 3
            fmt      = Export_SelectFormat%
            LOCATE crow + 10, 3 : PRINT "Exporting all ideas..."
            filename = Export_AllIdeas$(fmt)
            LOCATE crow + 11, 3
            CALL Export_ShowResult(filename)

        CASE "2"
            LOCATE crow + 8, 3
            fmt      = Export_SelectFormat%
            LOCATE crow + 10, 3 : PRINT "Exporting favorites..."
            filename = Export_FavoritesOnly$(fmt)
            LOCATE crow + 11, 3
            CALL Export_ShowResult(filename)

        CASE ELSE
            LOCATE crow + 8, 3 : PRINT "Export cancelled."
            SLEEP 1
            EXIT SUB
    END SELECT

    LOCATE UI_ROWS - 2, 3 : PRINT "Press any key to return to menu..."
    SLEEP
END SUB

' ============================================================
' ExportSearchResultsScreen
' Inline export offer after search results are displayed.
' ============================================================
SUB ExportSearchResultsScreen (resultBlock AS STRING)
    DIM confirm  AS STRING
    DIM fmt      AS INTEGER
    DIM filename AS STRING

    LOCATE UI_ROWS - 2, 3
    INPUT "Export these results? (Y/N): ", confirm

    IF UCASE$(LEFT$(LTRIM$(confirm), 1)) <> "Y" THEN EXIT SUB

    PRINT
    fmt      = Export_SelectFormat%
    PRINT
    PRINT "  Exporting search results..."
    filename = Export_SearchResults$(resultBlock, fmt)
    CALL Export_ShowResult(filename)
    SLEEP 2
END SUB

' ============================================================
' Export_ShowResult
' Prints success or failure message in place.
' ============================================================
SUB Export_ShowResult (filename AS STRING)
    IF LEN(LTRIM$(filename)) > 0 THEN
        CALL RetroAudio_PlayExport
        PRINT "  Export complete!  File: " + filename
    ELSE
        CALL RetroAudio_PlayError
        PRINT "  Nothing to export — no matching ideas found."
    END IF
END SUB
