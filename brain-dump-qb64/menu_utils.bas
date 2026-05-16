' menu_utils.bas - Menu and display utilities
' Updated: ShowHeader now delegates to Window_DrawScreen
'          so all screens automatically use the ASCII UI system.
'$INCLUDEONCE

' ============================================================
' ShowHeader
' Backward-compatible entry point called throughout the app.
' Draws the full screen chrome using the window renderer.
' Returns the first usable content row (callers LOCATE to it).
' NOTE: callers that captured the return value as a label
'       will now get the content start row automatically.
' ============================================================
SUB ShowHeader (title AS STRING)
    DIM contentRow AS INTEGER
    contentRow = Window_DrawScreen%(title, "[" + UCASE$(title) + " MODE]")
    ' Position cursor at first content row so legacy PRINT
    ' calls immediately after ShowHeader go to the right place
    LOCATE contentRow, 3
END SUB

' ============================================================
' ShowSeparator
' Draws a divider using the panel system.
' Kept for backward compatibility with legacy callers.
' ============================================================
SUB ShowSeparator (length AS INTEGER)
    PRINT ASCII_Repeat$("-", length);
END SUB

' ============================================================
' PauseWithMessage
' Pauses execution and shows a message.
' ============================================================
SUB PauseWithMessage (message AS STRING)
    PRINT
    PRINT message
    SLEEP
END SUB

' ============================================================
' GetConfirmation$
' Returns "Y" or "N" after prompting the user.
' ============================================================
FUNCTION GetConfirmation$ (prompt AS STRING)
    DIM response AS STRING

    PRINT prompt; " (y/n): ";
    INPUT response

    IF UCASE$(LEFT$(response, 1)) = "Y" THEN
        GetConfirmation = "Y"
    ELSE
        GetConfirmation = "N"
    END IF
END FUNCTION

' ============================================================
' ShowHelp
' Displays the help screen using the window renderer.
' ============================================================
SUB ShowHelp
    DIM contentRow AS INTEGER

    contentRow = Window_DrawScreen%("HELP", "[HELP MODE]")

    LOCATE contentRow,     3 : PRINT "HOW TO USE TAGS:"
    LOCATE contentRow + 1, 3 : PRINT "  Start tags with # symbol"
    LOCATE contentRow + 2, 3 : PRINT "  Examples: #project #dream #reminder #work"
    LOCATE contentRow + 3, 3 : PRINT "  Separate multiple tags with spaces"
    LOCATE contentRow + 5, 3 : PRINT "SEARCH OPERATORS:"
    LOCATE contentRow + 6, 3 : PRINT "  tag:game      priority:high    fav:true"
    LOCATE contentRow + 8, 3 : PRINT "FILE FORMAT:"
    LOCATE contentRow + 9, 3 : PRINT "  [date time] idea_text | #tags priority:N fav:1"

    LOCATE UI_ROWS - 2, 3
    PRINT "Press any key to return..."
    SLEEP
END SUB
