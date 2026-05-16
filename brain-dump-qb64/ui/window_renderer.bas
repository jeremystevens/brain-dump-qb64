' window_renderer.bas - Window and layout rendering coordinator
' Part of Brain Dump QB64 - ASCII UI System (Phase 2)
' Responsibility: Named screen regions, full window chrome,
'                 title bars, status bars, sidebars, content areas.
'                 Coordinates WHERE things go on screen.
'                 Delegates HOW to draw them to ascii_panels.bas.
'                 Uses Theme_GetBorderStyle% so border style
'                 tracks the active theme automatically.
'                 NO business logic. NO file handling.
' NOTE: UI_COLS, UI_ROWS, BORDER_* declared in main.bas.
'$INCLUDEONCE

' ============================================================
' Window_Init
' Called once at startup. Sets terminal dimensions, loads
' and applies the active theme via theme_manager.
' ============================================================
SUB Window_Init
    WIDTH UI_COLS, UI_ROWS
    CALL Theme_Init
    CALL CRT_Init
END SUB

' ============================================================
' Window_Clear
' Clears the screen in the active theme colors.
' ============================================================
SUB Window_Clear
    COLOR g_ThemeFG, g_ThemeBG
    CLS
    LOCATE 1, 1
END SUB

' ============================================================
' Window_ActiveBorder%
' Returns the border style for the current active theme.
' All drawing functions call this instead of UI_BORDER_STYLE
' so the theme controls border style dynamically.
' ============================================================
FUNCTION Window_ActiveBorder%
    Window_ActiveBorder = Theme_GetBorderStyle%
END FUNCTION

' ============================================================
' Window_DrawScreen%
' Draws the full chrome of a named screen:
'   Row 1        : App title bar (accent color)
'   Rows 2-4     : Screen title panel (border themed)
'   Rows 5-UI_ROWS-2 : Content area frame
'   Row UI_ROWS-1 : Status bar
' Returns the first usable content row inside the frame.
' ============================================================
FUNCTION Window_DrawScreen% (screenTitle AS STRING, statusText AS STRING)
    DIM contentTop AS INTEGER
    DIM border     AS INTEGER

    COLOR g_ThemeFG, g_ThemeBG
    CLS

    border     = Window_ActiveBorder%
    contentTop = 5

    ' Row 1: Accent-colored app title bar
    CALL Window_DrawAppBar(1)

    ' Rows 2-4: Themed title panel
    CALL Window_DrawTitle(2, screenTitle)

    ' Rows 5 to UI_ROWS-2: Content area frame
    CALL Window_DrawContentArea(contentTop, UI_ROWS - 2)

    ' Row UI_ROWS-1: Status bar
    CALL Window_DrawStatusBar(UI_ROWS - 1, statusText)

    Window_DrawScreen = contentTop + 1
END FUNCTION

' ============================================================
' Window_DrawAppBar
' Draws the application identity bar in accent color.
' ============================================================
SUB Window_DrawAppBar (row AS INTEGER)
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE row, 1
    PRINT ASCII_CenterText$("[ BRAIN DUMP QB64 // " + g_ThemeName + " ]", UI_COLS);
    COLOR g_ThemeFG, g_ThemeBG
END SUB

' ============================================================
' Window_DrawTitle
' Draws a 3-row titled header panel using the active border.
' ============================================================
SUB Window_DrawTitle (row AS INTEGER, title AS STRING)
    CALL ASCII_DrawHeader(row, 1, UI_COLS, UCASE$(title), Window_ActiveBorder%)
END SUB

' ============================================================
' Window_DrawContentArea
' Draws the outer frame of the main content region.
' ============================================================
SUB Window_DrawContentArea (topRow AS INTEGER, bottomRow AS INTEGER)
    DIM height AS INTEGER
    height = bottomRow - topRow + 1
    IF height < 2 THEN EXIT SUB
    CALL ASCII_DrawBox(topRow, 1, UI_COLS, height, Window_ActiveBorder%)
END SUB

' ============================================================
' Window_DrawStatusBar
' Draws the status bar with theme foreground color.
' ============================================================
SUB Window_DrawStatusBar (row AS INTEGER, statusText AS STRING)
    DIM padded AS STRING
    padded = ASCII_PadRight$(statusText, UI_COLS - 2)
    LOCATE row, 1
    PRINT ASCII_BoxSide$(padded, UI_COLS, Window_ActiveBorder%);
END SUB

' ============================================================
' Window_DrawSidebar
' Draws a vertical sidebar panel.
' ============================================================
SUB Window_DrawSidebar (topRow AS INTEGER, bottomRow AS INTEGER, col AS INTEGER, width AS INTEGER, title AS STRING)
    DIM height AS INTEGER
    height = bottomRow - topRow + 1
    IF height < 2 THEN EXIT SUB

    IF LEN(LTRIM$(title)) > 0 THEN
        CALL ASCII_DrawTitledBox(topRow, col, width, height, Window_ActiveBorder%, title)
    ELSE
        CALL ASCII_DrawBox(topRow, col, width, height, Window_ActiveBorder%)
    END IF
END SUB

' ============================================================
' Window_ContentRow%
' Returns actual screen row for content line <lineNum>.
' ============================================================
FUNCTION Window_ContentRow% (lineNum AS INTEGER)
    DIM row AS INTEGER
    row = 5 + lineNum
    IF row > UI_ROWS - 3 THEN row = UI_ROWS - 3
    Window_ContentRow = row
END FUNCTION

' ============================================================
' Window_PrintContent
' Prints <text> at content line <lineNum>, indented 2 spaces.
' ============================================================
SUB Window_PrintContent (lineNum AS INTEGER, text AS STRING)
    DIM row    AS INTEGER
    DIM maxLen AS INTEGER

    row    = Window_ContentRow%(lineNum)
    maxLen = UI_COLS - 4

    LOCATE row, 3
    IF LEN(text) > maxLen THEN
        PRINT LEFT$(text, maxLen);
    ELSE
        PRINT text;
    END IF
END SUB

' ============================================================
' Window_DrawPopup%
' Draws a centred popup box for future modal dialogs.
' Returns the first content row inside the popup.
' ============================================================
FUNCTION Window_DrawPopup% (title AS STRING, width AS INTEGER, height AS INTEGER)
    DIM startCol AS INTEGER
    DIM startRow AS INTEGER

    startCol = (UI_COLS - width) \ 2 + 1
    startRow = (UI_ROWS - height) \ 2 + 1

    IF startCol < 1 THEN startCol = 1
    IF startRow < 1 THEN startRow = 1

    CALL ASCII_DrawTitledBox(startRow, startCol, width, height, Window_ActiveBorder%, title)

    Window_DrawPopup = startRow + 1
END FUNCTION

' ============================================================
' Window_DrawMenuScreen%
' Specialised layout for the main menu.
' Draws accent app bar, a centred themed menu box.
' Returns the first row inside the menu box.
' ============================================================
FUNCTION Window_DrawMenuScreen% (menuTitle AS STRING)
    DIM menuWidth  AS INTEGER
    DIM menuHeight AS INTEGER
    DIM menuCol    AS INTEGER
    DIM menuRow    AS INTEGER

    COLOR g_ThemeFG, g_ThemeBG
    CLS

    ' Accent app bar
    CALL Window_DrawAppBar(1)

    ' Themed divider
    LOCATE 2, 1
    PRINT ASCII_Repeat$(CHR$(196), UI_COLS);

    ' Centred themed menu box
    menuWidth  = 38
    menuHeight = 19
    menuCol    = (UI_COLS - menuWidth) \ 2 + 1
    menuRow    = 3

    CALL ASCII_DrawTitledBox(menuRow, menuCol, menuWidth, menuHeight, Window_ActiveBorder%, menuTitle)

    ' Bottom tagline in accent color
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE UI_ROWS, 1
    PRINT ASCII_CenterText$("[ BRAIN DUMP QB64 — RETRO KNOWLEDGE SYSTEM ]", UI_COLS);
    COLOR g_ThemeFG, g_ThemeBG

    Window_DrawMenuScreen = menuRow + 1
END FUNCTION
