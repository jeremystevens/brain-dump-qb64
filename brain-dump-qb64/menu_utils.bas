' menu_utils.bas - Menu and display utilities
'$INCLUDEONCE

' Display a separator line
SUB ShowSeparator (length AS INTEGER)
    PRINT STRING$(length, "=")
END SUB

' Display formatted header
SUB ShowHeader (title AS STRING)
    DIM titleLen AS INTEGER
    titleLen = LEN(title)
    
    CALL ShowSeparator(titleLen + 4)
    PRINT "= "; title; " ="
    CALL ShowSeparator(titleLen + 4)
    PRINT
END SUB

' Pause with custom message
SUB PauseWithMessage (message AS STRING)
    PRINT
    PRINT message
    SLEEP
END SUB

' Get yes/no confirmation
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

' Display help text
SUB ShowHelp
    CLS
    CALL ShowHeader("IDEA CATCHER HELP")
    
    PRINT "HOW TO USE TAGS:"
    PRINT "- Start tags with # symbol"
    PRINT "- Examples: #project #dream #reminder #work"
    PRINT "- Separate multiple tags with spaces"
    PRINT
    PRINT "EXAMPLES:"
    PRINT "Idea: 'Build a mobile app for tracking habits'"
    PRINT "Tags: '#project #app #mobile'"
    PRINT
    PRINT "FILE FORMAT:"
    PRINT "Ideas are stored in 'ideas.txt' in your QB64 folder"
    PRINT "Format: [date time] idea_text | tags"
    PRINT
    CALL PauseWithMessage("Press any key to return...")
END SUB