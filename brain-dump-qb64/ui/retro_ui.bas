' retro_ui.bas - Fullscreen retro UI framework
' Part of Brain Dump QB64 - Fullscreen Retro UI (Phase 2)
' Responsibility: Fullscreen mode init, boot sequence,
'                 animated cursor, theme selection UI,
'                 accent color rendering, retro overlays.
'                 NO business logic. NO file handling.
' NOTE: THEME_* constants declared in main.bas.
'$INCLUDEONCE

' ============================================================
' RetroUI_Init
' Initializes the retro UI layer. Called after Theme_Init.
' Sets QB64 to fullscreen-style console mode and applies
' the active theme colors.
' ============================================================
SUB RetroUI_Init
    ' Set console to fullscreen dimensions
    WIDTH UI_COLS, UI_ROWS

    ' Apply active theme colors
    CALL Theme_Apply(g_ActiveTheme)

    ' Hide system cursor for cleaner retro feel
    ' (QB64 does not expose cursor hiding in text mode directly —
    '  the animated cursor sub provides the illusion of control)
END SUB

' ============================================================
' RetroUI_DrawBootScreen
' Dramatic typed-out boot sequence. Replaces the plain
' initialization splash from file_manager.bas.
' Each line is printed with a small delay for immersion.
' The boot sequence adapts its banner to the active theme.
' ============================================================
SUB RetroUI_DrawBootScreen
    DIM testFile  AS INTEGER
    DIM r         AS INTEGER

    ' Full black screen first
    COLOR g_ThemeFG, g_ThemeBG
    CLS

    ' Draw outer boot frame
    LOCATE 1, 1  : PRINT ASCII_BoxTop$(UI_COLS, g_ThemeBorder);
    FOR r = 2 TO UI_ROWS - 1
        LOCATE r, 1 : PRINT ASCII_BoxSide$(STRING$(UI_COLS - 2, " "), UI_COLS, g_ThemeBorder);
    NEXT r
    LOCATE UI_ROWS, 1 : PRINT ASCII_BoxBottom$(UI_COLS, g_ThemeBorder);

    ' Accent color for banner
    COLOR g_ThemeAccentFG, g_ThemeBG

    LOCATE 3, 1
    PRINT ASCII_CenterText$("BRAIN DUMP QB64", UI_COLS);
    LOCATE 4, 1
    PRINT ASCII_CenterText$("RETRO KNOWLEDGE MANAGEMENT SYSTEM", UI_COLS);
    LOCATE 5, 1
    PRINT ASCII_CenterText$("v2.0 — " + g_ThemeName, UI_COLS);

    ' Back to normal foreground
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE 7, 1
    PRINT ASCII_CenterText$(ASCII_Repeat$("-", 50), UI_COLS);

    ' Boot sequence lines with typed-out effect + synchronized beeps
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(9,  "  INITIALIZING RETRO MEMORY CORE...",         30)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(10, "  LOADING KNOWLEDGE DATABASE...",              25)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(11, "  CALIBRATING SEARCH ENGINE...",               25)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(12, "  MOUNTING PRIORITY MATRIX...",                25)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(13, "  SYNCING FAVORITES INDEX...",                 25)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(14, "  LOADING EXPORT SUBSYSTEMS...",               25)

    ' Ensure ideas.txt exists
    testFile = FREEFILE
    OPEN "ideas.txt" FOR APPEND AS testFile
    CLOSE testFile

    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(15, "  IDEAS DATABASE.................. [READY]",   20)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(16, "  CRT DISPLAY DRIVER.............. [ACTIVE]",  20)
    CALL RetroAudio_PlayBootBeep
    CALL RetroUI_TypeLine(17, "  THEME ENGINE.................... [" + LEFT$(g_ThemeName + STRING$(10, " "), 10) + "]", 20)

    LOCATE 19, 1
    PRINT ASCII_CenterText$(ASCII_Repeat$("-", 50), UI_COLS);

    ' System ready chime then accent flash
    CALL RetroAudio_PlayReady
    COLOR g_ThemeAccentFG, g_ThemeBG
    CALL RetroUI_TypeLine(21, ASCII_CenterText$("SYSTEM READY.", UI_COLS), 15)
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE 23, 1
    PRINT ASCII_CenterText$("[ PRESS ANY KEY TO ENTER ]", UI_COLS);
    SLEEP
END SUB

' ============================================================
' RetroUI_TypeLine
' Prints <text> at <row> character by character with a small
' delay between chars for the typed-out terminal effect.
' <delayMs> is the per-character delay in milliseconds.
' Uses TIMER for lightweight delay without sound dependency.
' ============================================================
SUB RetroUI_TypeLine (row AS INTEGER, text AS STRING, delayMs AS INTEGER)
    DIM i       AS INTEGER
    DIM t       AS DOUBLE
    DIM delayS  AS DOUBLE

    delayS = delayMs / 1000.0

    LOCATE row, 1
    FOR i = 1 TO LEN(text)
        PRINT MID$(text, i, 1);
        CALL RetroAudio_PlayKeypress

        t = TIMER
        DO WHILE TIMER - t < delayS AND TIMER - t >= 0
        LOOP
    NEXT i
END SUB

' ============================================================
' RetroUI_DrawCursor
' Draws an animated blinking block cursor at <row>, <col>.
' Blinks <cycles> times then returns. Uses TIMER.
' The cursor character is themed to the active palette.
' ============================================================
SUB RetroUI_DrawCursor (row AS INTEGER, col AS INTEGER, cycles AS INTEGER)
    DIM i      AS INTEGER
    DIM t      AS DOUBLE
    DIM onChar AS STRING

    onChar = CHR$(219)   ' full block █

    FOR i = 1 TO cycles
        ' Show cursor
        COLOR g_ThemeAccentFG, g_ThemeBG
        LOCATE row, col
        PRINT onChar;

        t = TIMER
        DO WHILE TIMER - t < 0.3 AND TIMER - t >= 0 : LOOP

        ' Hide cursor
        LOCATE row, col
        PRINT " ";

        t = TIMER
        DO WHILE TIMER - t < 0.3 AND TIMER - t >= 0 : LOOP
    NEXT i

    COLOR g_ThemeFG, g_ThemeBG
END SUB

' ============================================================
' RetroUI_DrawAccentBar
' Draws a full-width bar in the accent color at <row>.
' Used for the app title bar and highlighted headers.
' ============================================================
SUB RetroUI_DrawAccentBar (row AS INTEGER, text AS STRING)
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE row, 1
    PRINT ASCII_CenterText$(text, UI_COLS);
    COLOR g_ThemeFG, g_ThemeBG
END SUB

' ============================================================
' RetroUI_SetColorTheme
' Public entry point for switching themes at runtime.
' Applies the theme, redraws the screen base, and saves.
' ============================================================
SUB RetroUI_SetColorTheme (themeID AS INTEGER)
    CALL Theme_Apply(themeID)
    CALL Theme_Save
END SUB

' ============================================================
' RetroUI_ThemeScreen
' Interactive theme selection screen.
' Shows all themes, lets user pick one, applies it immediately,
' saves to theme.cfg, and confirms persistence.
' ============================================================
SUB RetroUI_ThemeScreen
    DIM choice    AS STRING
    DIM crow      AS INTEGER
    DIM newTheme  AS INTEGER
    DIM changed   AS INTEGER

    changed  = 0
    newTheme = g_ActiveTheme

    crow = Window_DrawScreen%("CHANGE THEME", "[THEME ENGINE]  [CURRENT: " + g_ThemeName + "]")

    LOCATE crow,     3 : PRINT "Select a retro terminal theme:"
    LOCATE crow + 1, 3 : PRINT ASCII_Repeat$("-", 44)

    LOCATE crow + 3,  3 : PRINT "  1.  FALLOUT TERMINAL"
    LOCATE crow + 4,  3 : PRINT "       Green on black. Classic phosphor vault terminal."

    LOCATE crow + 6,  3 : PRINT "  2.  DOS HACKER SYSTEM"
    LOCATE crow + 7,  3 : PRINT "       White on blue. Sharp DOS command-line style."

    LOCATE crow + 9,  3 : PRINT "  3.  CYBERDECK NOTEBOOK"
    LOCATE crow + 10, 3 : PRINT "       Cyan/magenta on black. Cyberpunk neon aesthetic."

    LOCATE crow + 12, 3 : PRINT "  4.  Keep current theme and return"

    ' Show current theme in accent color
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE crow + 14, 3
    PRINT "  Currently active: [" + g_ThemeName + "]"
    COLOR g_ThemeFG, g_ThemeBG

    LOCATE crow + 15, 3
    INPUT "  Your choice (1-4): ", choice

    SELECT CASE LTRIM$(RTRIM$(choice))
        CASE "1" : newTheme = THEME_FALLOUT  : changed = -1
        CASE "2" : newTheme = THEME_DOS      : changed = -1
        CASE "3" : newTheme = THEME_CYBERDECK: changed = -1
        CASE ELSE: changed = 0
    END SELECT

    IF changed THEN
        ' Apply the new theme colors immediately
        CALL Theme_Apply(newTheme)

        ' Save to disk — persists across sessions
        CALL Theme_Save

        ' Play theme change chime in new theme's tones
        CALL RetroAudio_PlayThemeChange

        ' Confirm on the now-recolored screen
        crow = Window_DrawScreen%("THEME SAVED", "[THEME ENGINE]  [" + g_ThemeName + "]")

        COLOR g_ThemeAccentFG, g_ThemeBG
        LOCATE crow,     3 : PRINT "  Theme applied:  [" + g_ThemeName + "]"
        COLOR g_ThemeFG, g_ThemeBG
        LOCATE crow + 1, 3 : PRINT "  Saved to theme.cfg"
        LOCATE crow + 2, 3 : PRINT "  This theme will load automatically next time."
        LOCATE crow + 4, 3 : PRINT "  Press any key to return to menu..."
        SLEEP
    END IF
END SUB
