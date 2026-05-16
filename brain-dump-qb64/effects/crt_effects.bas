' crt_effects.bas - CRT visual simulation effects
' Part of Brain Dump QB64 - Fullscreen Retro UI (Phase 2)
' Responsibility: CRT aesthetic effects using QB64 COLOR
'                 and LOCATE. All effects are text-mode safe
'                 and guarded by CRT_EFFECTS_ENABLED.
'                 NO business logic. NO data management.
' NOTE: CRT_EFFECTS_ENABLED, UI_COLS, UI_ROWS in main.bas.
'       Theme shared vars (g_ThemeFG etc.) from theme_manager.
'$INCLUDEONCE

' ============================================================
' CRT_Init
' Called once at startup after Theme_Init.
' Reserved for future: effect intensity config, audio hooks.
' ============================================================
SUB CRT_Init
    ' Reserved for future effect configuration loading
END SUB

' ============================================================
' CRT_DrawScanlines
' Simulates CRT scanlines by dimming every other content row
' within a region using a lower-intensity color briefly,
' then restoring. In text mode this means briefly printing
' dim characters on alternating rows.
' Only runs if CRT_EFFECTS_ENABLED is true (-1).
' <topRow> and <bottomRow> define the affected region.
' ============================================================
SUB CRT_DrawScanlines (topRow AS INTEGER, bottomRow AS INTEGER)
    DIM r      AS INTEGER
    DIM dimFG  AS INTEGER
    DIM t      AS DOUBLE

    IF NOT CRT_EFFECTS_ENABLED THEN EXIT SUB

    ' Use a dimmer version of foreground (dark = FG - 8 if bright, else 8)
    dimFG = g_ThemeFG
    IF dimFG > 7 THEN
        dimFG = dimFG - 8   ' bright -> dark variant
    ELSE
        dimFG = 8           ' dark -> dark gray fallback
    END IF

    ' Flash alternating rows dim for a brief moment
    COLOR dimFG, g_ThemeBG
    FOR r = topRow TO bottomRow STEP 2
        LOCATE r, 2
        PRINT STRING$(UI_COLS - 2, CHR$(176));   ' dim shade block
    NEXT r

    ' Hold briefly
    t = TIMER
    DO WHILE TIMER - t < 0.04 AND TIMER - t >= 0 : LOOP

    ' Restore — redraw those rows as spaces in normal color
    COLOR g_ThemeFG, g_ThemeBG
    FOR r = topRow TO bottomRow STEP 2
        LOCATE r, 2
        PRINT STRING$(UI_COLS - 2, " ");
    NEXT r
END SUB

' ============================================================
' CRT_DrawFlicker
' Simulates CRT screen flicker by rapidly toggling colors
' once. Creates a brief authentic phosphor pulse.
' Only runs if CRT_EFFECTS_ENABLED is true (-1).
' ============================================================
SUB CRT_DrawFlicker
    DIM t AS DOUBLE

    IF NOT CRT_EFFECTS_ENABLED THEN EXIT SUB

    ' Flash to bright accent
    COLOR g_ThemeAccentFG, g_ThemeBG

    t = TIMER
    DO WHILE TIMER - t < 0.06 AND TIMER - t >= 0 : LOOP

    ' Restore normal
    COLOR g_ThemeFG, g_ThemeBG
END SUB

' ============================================================
' CRT_DrawGlow
' Simulates a phosphor glow pulse on the app title bar
' by briefly printing it in accent color then restoring.
' Only runs if CRT_EFFECTS_ENABLED is true (-1).
' ============================================================
SUB CRT_DrawGlow (row AS INTEGER, text AS STRING)
    DIM t AS DOUBLE

    IF NOT CRT_EFFECTS_ENABLED THEN EXIT SUB

    ' Glow pulse: accent color
    COLOR g_ThemeAccentFG, g_ThemeBG
    LOCATE row, 1
    PRINT ASCII_CenterText$(text, UI_COLS);

    t = TIMER
    DO WHILE TIMER - t < 0.08 AND TIMER - t >= 0 : LOOP

    ' Settle to normal foreground
    COLOR g_ThemeFG, g_ThemeBG
    LOCATE row, 1
    PRINT ASCII_CenterText$(text, UI_COLS);
END SUB

' ============================================================
' CRT_ApplyEffects
' Convenience wrapper — applies all active CRT effects once
' in sequence. Called at key moments (screen transitions,
' boot, theme change). All effects self-guard internally.
' <contentTop> and <contentBottom> define the scanline zone.
' ============================================================
SUB CRT_ApplyEffects (contentTop AS INTEGER, contentBottom AS INTEGER)
    IF NOT CRT_EFFECTS_ENABLED THEN EXIT SUB

    CALL CRT_DrawFlicker
    CALL CRT_DrawScanlines(contentTop, contentBottom)
END SUB
