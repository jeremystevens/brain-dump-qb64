' run_tests.bas - Standalone QB64 test runner for Brain Dump QB64
' ============================================================
' HOW TO RUN
' 1. Open this file in QB64-PE.
' 2. Press F5 (Run) — no extra files needed.
' 3. Results print to the console: [PASS] / [FAIL] per test,
'    then a final summary line with totals.
'
' WHAT IS TESTED (pure-logic modules — no file I/O, no UI)
'   priority_manager.bas   — priority levels, weights, parsing
'   favorites_manager.bas  — fav:1 detection, tags, weights
'   search_parser.bas      — tokeniser, filter operator stripping
'   search_engine.bas      — Search_Match%, Search_Score%
'   search_filters.bas     — Extract_Field$, Extract_RawText$,
'                            Filter_By_Tag%, Filter_By_Priority%,
'                            Filter_Favorites%
'   export_manager.bas     — Export_ExtForFormat$, ParseTimestamp$,
'                            ParseIdeaText$, ParseTags$
'   export_json.bas        — ExportJson_EscapeStr$
'   export_html.bas        — ExportHtml_EscapeStr$
'
' WHAT IS NOT TESTED HERE (require file I/O or screen access)
'   Search_Query$          — reads ideas.txt
'   Export_AllIdeas$       — reads/writes files
'   Export_FavoritesOnly$  — reads/writes files
'   Export_GenerateFilename$ — uses real DATE$/TIME$
'   All UI/rendering subs  — require a QB64 SCREEN
' ============================================================

' ============================================================
' Global CONST declarations — mirrored from main.bas.
' QB64 requires ALL CONST/TYPE before any SUB/FUNCTION.
' ============================================================

' UI dimensions
CONST UI_COLS = 80
CONST UI_ROWS = 25

' Border style constants
CONST BORDER_SINGLE = 0
CONST BORDER_DOUBLE = 1
CONST BORDER_ROUND  = 2
CONST UI_BORDER_STYLE = BORDER_SINGLE

' Theme ID constants
CONST THEME_FALLOUT   = 1
CONST THEME_DOS       = 2
CONST THEME_CYBERDECK = 3

' Sound system constants
CONST SOUND_ENABLED  = -1
CONST SND_KEYPRESS   = 1
CONST SND_MENU_MOVE  = 2
CONST SND_CONFIRM    = 3
CONST SND_ERROR      = 4
CONST SND_NOTIFY     = 5
CONST SND_BOOT_BEEP  = 6
CONST SND_READY      = 7
CONST SND_EXPORT     = 8
CONST SND_THEME_CHANGE = 9

' CRT effects toggle
CONST CRT_EFFECTS_ENABLED = -1

' Priority level constants
CONST PRIORITY_NONE     = 0
CONST PRIORITY_LOW      = 1
CONST PRIORITY_MEDIUM   = 2
CONST PRIORITY_HIGH     = 3
CONST PRIORITY_CRITICAL = 4

' Favorite state constants
CONST FAV_FALSE = 0
CONST FAV_TRUE  = -1

' Export format constants
CONST EXPORT_FMT_TXT  = 1
CONST EXPORT_FMT_MD   = 2
CONST EXPORT_FMT_JSON = 3
CONST EXPORT_FMT_HTML = 4

' Search system constants
CONST MAX_SEARCH_RESULTS = 100

' ============================================================
' Global TYPE declarations — mirrored from main.bas.
' ============================================================
TYPE SearchResult
    id         AS INTEGER
    score      AS INTEGER
    sourceType AS STRING * 20
    title      AS STRING * 200
END TYPE

TYPE IdeaRecord
    id       AS INTEGER
    priority AS INTEGER
    favorite AS INTEGER
    title    AS STRING * 200
    tags     AS STRING * 100
END TYPE

' ============================================================
' Shared global variables — mirrored from main.bas.
' ============================================================
DIM SHARED g_ActiveTheme   AS INTEGER
DIM SHARED g_ThemeFG       AS INTEGER
DIM SHARED g_ThemeBG       AS INTEGER
DIM SHARED g_ThemeAccentFG AS INTEGER
DIM SHARED g_ThemeBorder   AS INTEGER
DIM SHARED g_ThemeName     AS STRING
DIM SHARED g_SoundEnabled  AS INTEGER
DIM SHARED g_SoundVolume   AS INTEGER

' ============================================================
' Test infrastructure counters
' ============================================================
DIM SHARED g_TestPassed AS INTEGER
DIM SHARED g_TestFailed AS INTEGER

' ============================================================
' Initialise shared state to safe defaults
' (avoids undefined-variable issues in tested functions)
' ============================================================
g_ActiveTheme   = THEME_FALLOUT
g_ThemeFG       = 2
g_ThemeBG       = 0
g_ThemeAccentFG = 10
g_ThemeBorder   = BORDER_DOUBLE
g_ThemeName     = "TEST RUNNER"
g_SoundEnabled  = 0
g_SoundVolume   = 0

g_TestPassed = 0
g_TestFailed = 0

' ============================================================
' Test runner banner
' ============================================================
PRINT STRING$(60, "=")
PRINT "  BRAIN DUMP QB64 — TEST SUITE"
PRINT STRING$(60, "=")

' ============================================================
' Run all test suites
' ============================================================
CALL TestSuite_PriorityManager
CALL TestSuite_FavoritesManager
CALL TestSuite_SearchParser
CALL TestSuite_SearchEngine
CALL TestSuite_SearchFilters
CALL TestSuite_ExportManager

' ============================================================
' Final summary
' ============================================================
PRINT
PRINT STRING$(60, "=")
IF g_TestFailed = 0 THEN
    PRINT "  ALL TESTS PASSED  [" + LTRIM$(STR$(g_TestPassed)) + " / " + _
          LTRIM$(STR$(g_TestPassed)) + "]"
ELSE
    PRINT "  RESULTS: " + LTRIM$(STR$(g_TestPassed)) + " passed, " + _
          LTRIM$(STR$(g_TestFailed)) + " FAILED  (" + _
          LTRIM$(STR$(g_TestPassed + g_TestFailed)) + " total)"
END IF
PRINT STRING$(60, "=")
PRINT
PRINT "Press any key to exit..."
SLEEP

END

' ============================================================
' $Include order — source modules (pure logic only, no UI/audio)
' ============================================================
'$Include: '../priority/priority_manager.bas'
'$Include: '../favorites/favorites_manager.bas'
'$Include: '../search/search_parser.bas'
'$Include: '../search/search_engine.bas'
'$Include: '../search/search_filters.bas'
'$Include: '../export/export_manager.bas'
'$Include: '../export/export_txt.bas'
'$Include: '../export/export_markdown.bas'
'$Include: '../export/export_json.bas'
'$Include: '../export/export_html.bas'

' ============================================================
' $Include order — test framework and individual test modules
' ============================================================
'$Include: 'test_framework.bas'
'$Include: 'test_priority_manager.bas'
'$Include: 'test_favorites_manager.bas'
'$Include: 'test_search_parser.bas'
'$Include: 'test_search_engine.bas'
'$Include: 'test_search_filters.bas'
'$Include: 'test_export_manager.bas'
