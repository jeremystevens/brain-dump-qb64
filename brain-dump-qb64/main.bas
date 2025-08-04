' main.bas - Idea Catcher / Brain Dump
' A simple tool to capture, review, and manage ideas
' Created by Jeremy Stevens
' 2025-08-03

Dim choice As String
Dim running As Integer

' Initialize
running = -1
Print "=== IDEA CATCHER / BRAIN DUMP ==="
Print "Loading..."

' Create ideas file if it doesn't exist
Call InitializeSystem

Do While running
    Cls
    Print "=== IDEA CATCHER ==="
    Print
    Print "1. Write new idea"
    Print "2. Review ideas"
    Print "3. Delete idea"
    Print "4. Search by tag"
    Print "5. Exit"
    Print
    Input "Choose option (1-5): ", choice

    Select Case choice
        Case "1"
            Call WriteNewIdea
        Case "2"
            Call ReviewIdeas
        Case "3"
            Call DeleteIdea
        Case "4"
            Call SearchByTag
        Case "5"
            running = 0
            Print "Thanks for using Idea Catcher!"
        Case Else
            Print "Invalid choice. Press any key to continue..."
            Sleep
    End Select
Loop

End

' Include modules
'$Include: 'file_manager.bas'
'$Include: 'idea_manager.bas'
'$Include: 'menu_utils.bas'
