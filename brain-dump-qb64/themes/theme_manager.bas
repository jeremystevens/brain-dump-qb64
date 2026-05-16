' theme_manager.bas - Theme loading, saving, and application
' Part of Brain Dump QB64 - Fullscreen Retro UI (Phase 2)
' Responsibility: Theme state management, persistence, color/border
'                 lookups. Centralised theme configuration.
'                 NO rendering. NO UI. NO business logic.
' NOTE: THEME_* and CRT_* constants declared in main.bas.
'       BORDER_* constants declared in main.bas.
'$INCLUDEONCE

' ============================================================
' Shared theme state — accessible by all modules.
' DIM SHARED is required because QB64 has no global scope
' for variables; CONST is handled in main.bas.
' ============================================================
' NOTE: All g_Theme* shared variables are declared as
'       DIM SHARED in main.bas (global scope) — QB64 requires
'       DIM SHARED before any SUB/FUNCTION in compiled unit.

' ============================================================
' Theme_Init
' Called once at startup. Loads saved theme from disk,
' or applies the default (THEME_FALLOUT) if no config exists.
' ============================================================
SUB Theme_Init
    CALL Theme_Load
    CALL Theme_Apply(g_ActiveTheme)
END SUB

' ============================================================
' Theme_SetValues
' Internal helper — sets all shared theme variables for
' a given THEME_* constant. Single source of theme data.
' Add new themes here only — no other file needs changing.
' ============================================================
SUB Theme_SetValues (themeID AS INTEGER)
    SELECT CASE themeID
        CASE THEME_DOS
            g_ActiveTheme   = THEME_DOS
            g_ThemeFG       = 7     ' light gray
            g_ThemeBG       = 1     ' blue
            g_ThemeAccentFG = 15    ' bright white
            g_ThemeBorder   = BORDER_SINGLE
            g_ThemeName     = "DOS HACKER SYSTEM"

        CASE THEME_CYBERDECK
            g_ActiveTheme   = THEME_CYBERDECK
            g_ThemeFG       = 11    ' bright cyan
            g_ThemeBG       = 0     ' black
            g_ThemeAccentFG = 13    ' bright magenta
            g_ThemeBorder   = BORDER_DOUBLE
            g_ThemeName     = "CYBERDECK NOTEBOOK"

        CASE ELSE   ' THEME_FALLOUT (default)
            g_ActiveTheme   = THEME_FALLOUT
            g_ThemeFG       = 2     ' green
            g_ThemeBG       = 0     ' black
            g_ThemeAccentFG = 10    ' bright green
            g_ThemeBorder   = BORDER_DOUBLE
            g_ThemeName     = "FALLOUT TERMINAL"
    END SELECT
END SUB

' ============================================================
' Theme_Apply
' Applies a theme: sets shared variables AND calls COLOR.
' Called at startup and whenever the theme changes.
' Every screen that calls Window_DrawScreen% benefits
' automatically because Window_Init calls Theme_Apply.
' ============================================================
SUB Theme_Apply (themeID AS INTEGER)
    CALL Theme_SetValues(themeID)
    COLOR g_ThemeFG, g_ThemeBG
    CLS
END SUB

' ============================================================
' Theme_GetColor%
' Returns the current theme color value for a named role.
' colorRole:  0 = foreground  1 = background  2 = accent
' ============================================================
FUNCTION Theme_GetColor% (colorRole AS INTEGER)
    SELECT CASE colorRole
        CASE 1  : Theme_GetColor = g_ThemeBG
        CASE 2  : Theme_GetColor = g_ThemeAccentFG
        CASE ELSE : Theme_GetColor = g_ThemeFG
    END SELECT
END FUNCTION

' ============================================================
' Theme_GetBorderStyle%
' Returns the current theme's BORDER_* constant.
' Called by ascii_panels and window_renderer so border style
' tracks the active theme automatically.
' ============================================================
FUNCTION Theme_GetBorderStyle%
    Theme_GetBorderStyle = g_ThemeBorder
END FUNCTION

' ============================================================
' Theme_GetName$
' Returns the display name of the active theme.
' ============================================================
FUNCTION Theme_GetName$
    Theme_GetName = g_ThemeName
END FUNCTION

' ============================================================
' Theme_Save
' Persists the active theme ID to theme.cfg.
' Format: a single line "theme=N"
' Called after the user selects a new theme.
' ============================================================
SUB Theme_Save
    DIM fileNum AS INTEGER

    fileNum = FREEFILE
    OPEN "theme.cfg" FOR OUTPUT AS #fileNum
    PRINT #fileNum, "theme=" + LTRIM$(STR$(g_ActiveTheme))
    CLOSE #fileNum
END SUB

' ============================================================
' Theme_Load
' Reads theme.cfg and restores the saved theme ID.
' Falls back to THEME_FALLOUT if file is missing or corrupt.
' Called once from Theme_Init at startup.
' ============================================================
SUB Theme_Load
    DIM fileNum   AS INTEGER
    DIM lineText  AS STRING
    DIM eqPos     AS INTEGER
    DIM savedID   AS INTEGER
    DIM fileExists AS INTEGER

    ' Default before any file is read
    g_ActiveTheme = THEME_FALLOUT

    ' Check file exists by opening for INPUT and catching failure
    ' via a test open — if length is 0 the file is empty/missing
    fileNum   = FREEFILE
    fileExists = 0

    OPEN "theme.cfg" FOR APPEND AS #fileNum   ' APPEND creates if missing
    IF LOF(fileNum) > 0 THEN fileExists = -1
    CLOSE #fileNum

    IF NOT fileExists THEN EXIT SUB

    fileNum = FREEFILE
    OPEN "theme.cfg" FOR INPUT AS #fileNum

    IF NOT EOF(fileNum) THEN
        LINE INPUT #fileNum, lineText
        eqPos = INSTR(lineText, "=")
        IF eqPos > 0 THEN
            savedID = VAL(MID$(lineText, eqPos + 1))
            IF savedID = THEME_FALLOUT   OR _
               savedID = THEME_DOS       OR _
               savedID = THEME_CYBERDECK THEN
                g_ActiveTheme = savedID
            END IF
        END IF
    END IF

    CLOSE #fileNum
END SUB

' ============================================================
' Theme_Next%
' Cycles to the next available theme ID.
' Used by the quick-cycle key in the theme selection screen.
' ============================================================
FUNCTION Theme_Next%
    SELECT CASE g_ActiveTheme
        CASE THEME_FALLOUT   : Theme_Next = THEME_DOS
        CASE THEME_DOS       : Theme_Next = THEME_CYBERDECK
        CASE ELSE            : Theme_Next = THEME_FALLOUT
    END SELECT
END FUNCTION
