' ascii_panels.bas - ASCII border and panel rendering primitives
' Part of Brain Dump QB64 - ASCII UI System (Phase 2)
' Responsibility: Primitive drawing helpers only.
'                 Generates ASCII borders, boxes, dividers,
'                 headers, footers, and text alignment tools.
'                 NO layout coordination. NO business logic.
'                 NO file handling. NO application state.
' NOTE: BORDER_* and UI_COLS constants declared in main.bas.
'$INCLUDEONCE

' ============================================================
' ASCII_Repeat$
' Returns a string of <count> copies of <ch>.
' Core primitive — used by every other drawing function.
' ============================================================
FUNCTION ASCII_Repeat$ (ch AS STRING, count AS INTEGER)
    IF count <= 0 THEN
        ASCII_Repeat = ""
    ELSE
        ASCII_Repeat = STRING$(count, ch)
    END IF
END FUNCTION

' ============================================================
' ASCII_CenterText$
' Pads <text> with spaces so it is centred within <width>.
' If text is longer than width, returns text unchanged.
' Used for titles, labels, and status values.
' ============================================================
FUNCTION ASCII_CenterText$ (text AS STRING, width AS INTEGER)
    DIM textLen  AS INTEGER
    DIM padding  AS INTEGER
    DIM leftPad  AS INTEGER
    DIM rightPad AS INTEGER

    textLen = LEN(text)
    IF textLen >= width THEN
        ASCII_CenterText = text
        EXIT FUNCTION
    END IF

    padding  = width - textLen
    leftPad  = padding \ 2
    rightPad = padding - leftPad

    ASCII_CenterText = STRING$(leftPad, " ") + text + STRING$(rightPad, " ")
END FUNCTION

' ============================================================
' ASCII_PadRight$
' Left-aligns <text> in a field of <width>, padding with spaces.
' ============================================================
FUNCTION ASCII_PadRight$ (text AS STRING, width AS INTEGER)
    DIM textLen AS INTEGER
    textLen = LEN(text)
    IF textLen >= width THEN
        ASCII_PadRight = LEFT$(text, width)
    ELSE
        ASCII_PadRight = text + STRING$(width - textLen, " ")
    END IF
END FUNCTION

' ============================================================
' ASCII_PadLeft$
' Right-aligns <text> in a field of <width>, padding with spaces.
' ============================================================
FUNCTION ASCII_PadLeft$ (text AS STRING, width AS INTEGER)
    DIM textLen AS INTEGER
    textLen = LEN(text)
    IF textLen >= width THEN
        ASCII_PadLeft = LEFT$(text, width)
    ELSE
        ASCII_PadLeft = STRING$(width - textLen, " ") + text
    END IF
END FUNCTION

' ============================================================
' ASCII_BoxTop$
' Returns the top border string for a box of <width> columns.
' Border style is selected by <style> constant.
' Width is the OUTER width including the corner characters.
' ============================================================
FUNCTION ASCII_BoxTop$ (width AS INTEGER, style AS INTEGER)
    DIM inner AS INTEGER
    inner = width - 2   ' subtract two corner chars

    SELECT CASE style
        CASE BORDER_DOUBLE
            ASCII_BoxTop = CHR$(201) + ASCII_Repeat$(CHR$(205), inner) + CHR$(187)
        CASE BORDER_ROUND
            ASCII_BoxTop = "." + ASCII_Repeat$("-", inner) + "."
        CASE ELSE   ' BORDER_SINGLE (default)
            ASCII_BoxTop = "+" + ASCII_Repeat$("-", inner) + "+"
    END SELECT
END FUNCTION

' ============================================================
' ASCII_BoxBottom$
' Returns the bottom border string for a box of <width> columns.
' ============================================================
FUNCTION ASCII_BoxBottom$ (width AS INTEGER, style AS INTEGER)
    DIM inner AS INTEGER
    inner = width - 2

    SELECT CASE style
        CASE BORDER_DOUBLE
            ASCII_BoxBottom = CHR$(200) + ASCII_Repeat$(CHR$(205), inner) + CHR$(188)
        CASE BORDER_ROUND
            ASCII_BoxBottom = "'" + ASCII_Repeat$("-", inner) + "'"
        CASE ELSE
            ASCII_BoxBottom = "+" + ASCII_Repeat$("-", inner) + "+"
    END SELECT
END FUNCTION

' ============================================================
' ASCII_BoxSide$
' Returns one full-width row of a box with left and right
' borders and <content> centred or padded in between.
' <content> should already be the exact inner width.
' ============================================================
FUNCTION ASCII_BoxSide$ (content AS STRING, width AS INTEGER, style AS INTEGER)
    DIM inner   AS INTEGER
    DIM sideL   AS STRING
    DIM sideR   AS STRING
    DIM padded  AS STRING

    inner = width - 2

    SELECT CASE style
        CASE BORDER_DOUBLE
            sideL = CHR$(186)
            sideR = CHR$(186)
        CASE ELSE
            sideL = "|"
            sideR = "|"
    END SELECT

    ' Fit content exactly to inner width
    IF LEN(content) >= inner THEN
        padded = LEFT$(content, inner)
    ELSE
        padded = content + STRING$(inner - LEN(content), " ")
    END IF

    ASCII_BoxSide = sideL + padded + sideR
END FUNCTION

' ============================================================
' ASCII_BoxDivider$
' Returns a horizontal divider row that fits inside a box.
' Used to separate sections within a panel.
' ============================================================
FUNCTION ASCII_BoxDivider$ (width AS INTEGER, style AS INTEGER)
    DIM inner AS INTEGER
    inner = width - 2

    SELECT CASE style
        CASE BORDER_DOUBLE
            ASCII_BoxDivider = CHR$(199) + ASCII_Repeat$(CHR$(196), inner) + CHR$(182)
        CASE ELSE
            ASCII_BoxDivider = "+" + ASCII_Repeat$("-", inner) + "+"
    END SELECT
END FUNCTION

' ============================================================
' ASCII_DrawBox
' Draws a complete bordered box at <row>, <col> with
' <width> outer columns and <height> outer rows.
' Inner rows are filled with empty side-bordered lines.
' Uses LOCATE for precise cursor positioning.
' ============================================================
SUB ASCII_DrawBox (row AS INTEGER, col AS INTEGER, width AS INTEGER, height AS INTEGER, style AS INTEGER)
    DIM r       AS INTEGER
    DIM inner   AS INTEGER

    inner = width - 2

    ' Top border
    LOCATE row, col
    PRINT ASCII_BoxTop$(width, style);

    ' Side rows (empty content)
    FOR r = row + 1 TO row + height - 2
        LOCATE r, col
        PRINT ASCII_BoxSide$(STRING$(inner, " "), width, style);
    NEXT r

    ' Bottom border
    LOCATE row + height - 1, col
    PRINT ASCII_BoxBottom$(width, style);
END SUB

' ============================================================
' ASCII_DrawTitledBox
' Draws a bordered box with <title> centred in the top row.
' Title is rendered inside the top border line.
' ============================================================
SUB ASCII_DrawTitledBox (row AS INTEGER, col AS INTEGER, width AS INTEGER, height AS INTEGER, style AS INTEGER, title AS STRING)
    DIM inner     AS INTEGER
    DIM titleLine AS STRING
    DIM titleFit  AS STRING
    DIM sideL     AS STRING
    DIM sideR     AS STRING
    DIM r         AS INTEGER

    inner = width - 2

    ' Build styled corners and sides
    SELECT CASE style
        CASE BORDER_DOUBLE
            sideL = CHR$(186)
            sideR = CHR$(186)
        CASE ELSE
            sideL = "|"
            sideR = "|"
    END SELECT

    ' Title fits inside top border: +-- TITLE --+
    DIM titleLen AS INTEGER
    titleLen = LEN(title)

    IF titleLen + 4 >= inner THEN
        titleFit = LEFT$(title, inner)
        titleLine = sideL + titleFit + STRING$(inner - LEN(titleFit), " ") + sideR
    ELSE
        DIM dashes  AS INTEGER
        DIM lDashes AS INTEGER
        DIM rDashes AS INTEGER
        dashes  = inner - titleLen - 2   ' 2 spaces around title
        lDashes = dashes \ 2
        rDashes = dashes - lDashes

        SELECT CASE style
            CASE BORDER_DOUBLE
                titleLine = CHR$(201) + ASCII_Repeat$(CHR$(205), lDashes) + " " + title + " " + ASCII_Repeat$(CHR$(205), rDashes) + CHR$(187)
            CASE ELSE
                titleLine = "+" + ASCII_Repeat$("-", lDashes) + " " + title + " " + ASCII_Repeat$("-", rDashes) + "+"
        END SELECT
    END IF

    ' Draw top with embedded title
    LOCATE row, col
    PRINT titleLine;

    ' Draw side rows
    FOR r = row + 1 TO row + height - 2
        LOCATE r, col
        PRINT ASCII_BoxSide$(STRING$(inner, " "), width, style);
    NEXT r

    ' Draw bottom
    LOCATE row + height - 1, col
    PRINT ASCII_BoxBottom$(width, style);
END SUB

' ============================================================
' ASCII_DrawHeader
' Draws a standalone titled header bar at <row>, <col>.
' Used as a screen/section header — not inside a box.
' ============================================================
SUB ASCII_DrawHeader (row AS INTEGER, col AS INTEGER, width AS INTEGER, title AS STRING, style AS INTEGER)
    LOCATE row, col
    PRINT ASCII_BoxTop$(width, style);
    LOCATE row + 1, col
    PRINT ASCII_BoxSide$(ASCII_CenterText$(title, width - 2), width, style);
    LOCATE row + 2, col
    PRINT ASCII_BoxBottom$(width, style);
END SUB

' ============================================================
' ASCII_DrawFooter
' Draws a footer bar at <row>, <col> with centred <text>.
' ============================================================
SUB ASCII_DrawFooter (row AS INTEGER, col AS INTEGER, width AS INTEGER, text AS STRING, style AS INTEGER)
    LOCATE row, col
    PRINT ASCII_BoxSide$(ASCII_CenterText$(text, width - 2), width, style);
END SUB

' ============================================================
' ASCII_DrawDivider
' Draws a horizontal divider line at <row>, <col>.
' Used to separate sections within a content area.
' ============================================================
SUB ASCII_DrawDivider (row AS INTEGER, col AS INTEGER, width AS INTEGER, style AS INTEGER)
    LOCATE row, col
    PRINT ASCII_BoxDivider$(width, style);
END SUB

' ============================================================
' ASCII_PrintInBox
' Prints <text> at content position <row>, <col> inside a box
' whose left border is at <boxCol>.
' Handles left-padding automatically.
' ============================================================
SUB ASCII_PrintInBox (row AS INTEGER, boxCol AS INTEGER, text AS STRING)
    LOCATE row, boxCol + 1
    PRINT " " + text;
END SUB
