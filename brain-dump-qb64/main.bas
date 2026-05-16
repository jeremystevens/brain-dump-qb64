' main.bas - Idea Catcher / Brain Dump
' A simple tool to capture, review, and manage ideas
' Created by Jeremy Stevens
' 2025-08-03
' Updated: Search Everything + Priority System + Favorites System
'          + Export Modes + ASCII UI (Phase 2 P1)
'          + Fullscreen Retro UI + Themes + CRT Effects (Phase 2 P2)

' ============================================================
' Global TYPE and CONST declarations
' QB64 requires ALL of these before any SUB/FUNCTION
' in the entire compiled unit (including $Include files).
' ============================================================

' ------------------------------------------------------------
' Terminal / UI dimensions
' ------------------------------------------------------------
CONST UI_COLS = 80
CONST UI_ROWS = 25

' ------------------------------------------------------------
' Border style constants
' UI_BORDER_STYLE is the FALLBACK only — active style is
' controlled by the theme engine via Theme_GetBorderStyle%.
' ------------------------------------------------------------
CONST BORDER_SINGLE = 0
CONST BORDER_DOUBLE = 1
CONST BORDER_ROUND  = 2
CONST UI_BORDER_STYLE = BORDER_SINGLE

' ------------------------------------------------------------
' Theme ID constants — single source of truth.
' Add new themes here; Theme_SetValues in theme_manager.bas
' handles the data. No other file needs changing.
' ------------------------------------------------------------
CONST THEME_FALLOUT   = 1
CONST THEME_DOS       = 2
CONST THEME_CYBERDECK = 3

' ------------------------------------------------------------
' Sound system constants — single source of truth.
' SOUND_ENABLED: set to 0 to silence all audio output.
' SND_* events route through Sound_Play in sound_manager.bas.
' ------------------------------------------------------------
CONST SOUND_ENABLED   = -1    ' -1 = on, 0 = off

CONST SND_KEYPRESS    = 1
CONST SND_MENU_MOVE   = 2
CONST SND_CONFIRM     = 3
CONST SND_ERROR       = 4
CONST SND_NOTIFY      = 5
CONST SND_BOOT_BEEP   = 6
CONST SND_READY       = 7
CONST SND_EXPORT      = 8
CONST SND_THEME_CHANGE = 9

' ------------------------------------------------------------
' CRT effects toggle — set to 0 to disable all CRT effects.
' Useful for slower systems or accessibility preferences.
' ------------------------------------------------------------
CONST CRT_EFFECTS_ENABLED = -1    ' -1 = enabled, 0 = disabled

' ------------------------------------------------------------
' Priority level constants
' ------------------------------------------------------------
CONST PRIORITY_NONE     = 0
CONST PRIORITY_LOW      = 1
CONST PRIORITY_MEDIUM   = 2
CONST PRIORITY_HIGH     = 3
CONST PRIORITY_CRITICAL = 4

' ------------------------------------------------------------
' Favorite state constants
' ------------------------------------------------------------
CONST FAV_FALSE = 0
CONST FAV_TRUE  = -1

' ------------------------------------------------------------
' Export format constants
' ------------------------------------------------------------
CONST EXPORT_FMT_TXT  = 1
CONST EXPORT_FMT_MD   = 2
CONST EXPORT_FMT_JSON = 3
CONST EXPORT_FMT_HTML = 4

' ------------------------------------------------------------
' Search system constants
' ------------------------------------------------------------
CONST MAX_SEARCH_RESULTS = 100

' ------------------------------------------------------------
' Journal system constants
' ------------------------------------------------------------
CONST JOURNAL_FILE = "journal.txt"

' ------------------------------------------------------------
' SearchResult TYPE
' ------------------------------------------------------------
TYPE SearchResult
    id         AS INTEGER
    score      AS INTEGER
    sourceType AS STRING * 20
    title      AS STRING * 200
END TYPE

' ------------------------------------------------------------
' IdeaRecord TYPE
' ------------------------------------------------------------
TYPE IdeaRecord
    id       AS INTEGER
    priority AS INTEGER
    favorite AS INTEGER
    title    AS STRING * 200
    tags     AS STRING * 100
END TYPE

' ------------------------------------------------------------
' JournalEntry TYPE — canonical journal entry structure.
' Fixed-length strings required inside QB64 TYPE blocks.
' content truncated for in-memory use; full text stays in file.
' ------------------------------------------------------------
TYPE JournalEntry
    id           AS INTEGER
    priority     AS INTEGER
    favorite     AS INTEGER
    title        AS STRING * 100
    content      AS STRING * 200
    createdDate  AS STRING * 10
    modifiedDate AS STRING * 10
    tags         AS STRING * 100
END TYPE

' ------------------------------------------------------------
' Shared global variables — DIM SHARED must appear before any
' SUB/FUNCTION in the compiled unit. All modules read these.
' ------------------------------------------------------------
DIM SHARED g_ActiveTheme   AS INTEGER   ' current THEME_* value
DIM SHARED g_ThemeFG       AS INTEGER   ' foreground color 0-15
DIM SHARED g_ThemeBG       AS INTEGER   ' background color 0-7
DIM SHARED g_ThemeAccentFG AS INTEGER   ' accent / highlight color
DIM SHARED g_ThemeBorder   AS INTEGER   ' BORDER_* style constant
DIM SHARED g_ThemeName     AS STRING    ' display name
DIM SHARED g_SoundEnabled  AS INTEGER   ' runtime sound toggle
DIM SHARED g_SoundVolume   AS INTEGER   ' future: 0-100 scale

' ============================================================
' Program variables
' ============================================================
Dim choice    As String
Dim running   As Integer
Dim menuStart As Integer
Dim itemRow   As Integer
Dim menuCol   As Integer

running = -1

' ============================================================
' Startup sequence
' Order matters: theme before renderer before everything else.
' ============================================================
Call Window_Init      ' sets WIDTH, calls Theme_Init + CRT_Init
Call Sound_Init       ' copies SOUND_ENABLED const to runtime flag
Call RetroAudio_Init  ' reserved for future sound pack loading
Call RetroUI_Init     ' applies fullscreen mode + theme colors
Call RetroUI_DrawBootScreen  ' dramatic typed-out boot sequence
Call Priority_Init
Call Favorites_Init
Call Search_Init
Call Export_Init
Call Journal_Init

' ============================================================
' Main menu loop — themed ASCII window
' ============================================================
Do While running
    menuStart = Window_DrawMenuScreen%("MAIN  MENU")
    menuCol   = (UI_COLS - 38) \ 2 + 2

    itemRow = menuStart
    LOCATE itemRow,      menuCol : PRINT "  1.  Write new idea"
    LOCATE itemRow + 1,  menuCol : PRINT "  2.  Review ideas"
    LOCATE itemRow + 2,  menuCol : PRINT "  3.  Delete idea"
    LOCATE itemRow + 3,  menuCol : PRINT "  4.  Search by tag"
    LOCATE itemRow + 4,  menuCol : PRINT "  5.  Search Everything"
    LOCATE itemRow + 5,  menuCol : PRINT "  6.  Export ideas"

    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE itemRow + 6,  menuCol : PRINT "  7.  Daily journal"
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE itemRow + 7,  menuCol : PRINT "  8.  Change theme"
    LOCATE itemRow + 8,  menuCol : PRINT "  9.  Exit"

    ' Animated cursor blink while waiting
    CALL RetroUI_DrawCursor(itemRow + 10, menuCol + 2, 2)

    LOCATE itemRow + 10, menuCol
    Input "  Choose (1-9): ", choice

    Select Case choice
        Case "1" : Call RetroAudio_PlayMenuMove : Call WriteNewIdea
        Case "2" : Call RetroAudio_PlayMenuMove : Call ReviewIdeas
        Case "3" : Call RetroAudio_PlayMenuMove : Call DeleteIdea
        Case "4" : Call RetroAudio_PlayMenuMove : Call SearchByTag
        Case "5" : Call RetroAudio_PlayMenuMove : Call SearchEverything
        Case "6" : Call RetroAudio_PlayMenuMove : Call ExportScreen
        Case "7" : Call RetroAudio_PlayMenuMove : Call JournalScreen
        Case "8" : Call RetroAudio_PlayMenuMove : Call RetroUI_ThemeScreen
        Case "9"
            running = 0
            Call RetroAudio_PlayConfirm
            Call Window_Clear
            COLOR g_ThemeAccentFG, g_ThemeBG
            PRINT ASCII_CenterText$("SYSTEM SHUTDOWN. GOODBYE.", UI_COLS)
            COLOR g_ThemeFG, g_ThemeBG
            PRINT
        Case Else
            Call RetroAudio_PlayError
            LOCATE itemRow + 12, menuCol
            PRINT "  Invalid. Press any key..."
            SLEEP
    End Select
Loop

End

' ============================================================
' Include order — load-order dependent in QB64.
'
' theme_manager  — first: sets DIM SHARED color vars
' retro_ui       — second: uses theme vars, defines boot screen
' crt_effects    — third: uses theme vars
' ascii_panels   — fourth: pure primitives, no theme dependency
' window_renderer — fifth: uses theme vars + ascii_panels
' priority/favorites — before idea_manager and journal_ui
' date_helpers      — before journal_manager (date formatting)
' journal_manager   — before journal_ui and search_parser
' journal_ui        — before search_parser (uses search fns)
' search modules    — before file/idea/export managers
' ============================================================
'$Include: 'audio/sound_manager.bas'
'$Include: 'audio/retro_audio.bas'
'$Include: 'themes/theme_manager.bas'
'$Include: 'ui/retro_ui.bas'
'$Include: 'effects/crt_effects.bas'
'$Include: 'ui/ascii_panels.bas'
'$Include: 'ui/window_renderer.bas'
'$Include: 'priority/priority_manager.bas'
'$Include: 'priority/priority_ui.bas'
'$Include: 'favorites/favorites_manager.bas'
'$Include: 'favorites/favorites_ui.bas'
'$Include: 'helpers/date_helpers.bas'
'$Include: 'journal/journal_manager.bas'
'$Include: 'journal/journal_ui.bas'
'$Include: 'search/search_parser.bas'
'$Include: 'search/search_engine.bas'
'$Include: 'search/search_filters.bas'
'$Include: 'search/search_ui.bas'
'$Include: 'file_manager.bas'
'$Include: 'idea_manager.bas'
'$Include: 'export/export_manager.bas'
'$Include: 'export/export_txt.bas'
'$Include: 'export/export_markdown.bas'
'$Include: 'export/export_json.bas'
'$Include: 'export/export_html.bas'
'$Include: 'export/export_ui.bas'
'$Include: 'menu_utils.bas'
