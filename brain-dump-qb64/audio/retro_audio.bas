' retro_audio.bas - Retro sound effect named event wrappers
' Part of Brain Dump QB64 - Retro Sound Design (Phase 2 P3)
' Responsibility: Named audio events for every UI interaction.
'                 All callers (UI, menus, boot) use these subs.
'                 Routes to Sound_Play — never calls SOUND directly.
'                 NO rendering. NO storage logic.
' NOTE: SND_* and SOUND_ENABLED constants in main.bas.
'$INCLUDEONCE

' ============================================================
' RetroAudio_Init
' Called once at startup after Sound_Init.
' Reserved for future: loading theme sound packs from disk.
' ============================================================
SUB RetroAudio_Init
    ' Reserved for future sound pack loading
END SUB

' ============================================================
' RetroAudio_PlayKeypress
' Subtle tick for each typed character.
' Used in RetroUI_TypeLine during boot sequence.
' Keep extremely short — must not lag typing animation.
' ============================================================
SUB RetroAudio_PlayKeypress
    CALL Sound_Play(SND_KEYPRESS)
END SUB

' ============================================================
' RetroAudio_PlayMenuMove
' Light feedback when user navigates to a menu option.
' Called when a valid menu choice is made.
' ============================================================
SUB RetroAudio_PlayMenuMove
    CALL Sound_Play(SND_MENU_MOVE)
END SUB

' ============================================================
' RetroAudio_PlayConfirm
' Success sound — idea saved, theme applied, action complete.
' ============================================================
SUB RetroAudio_PlayConfirm
    CALL Sound_Play(SND_CONFIRM)
END SUB

' ============================================================
' RetroAudio_PlayError
' Error / invalid input feedback.
' Called on empty input, invalid menu choice, failed action.
' ============================================================
SUB RetroAudio_PlayError
    CALL Sound_Play(SND_ERROR)
END SUB

' ============================================================
' RetroAudio_PlayNotify
' Notification sound — search results found, favorites loaded.
' ============================================================
SUB RetroAudio_PlayNotify
    CALL Sound_Play(SND_NOTIFY)
END SUB

' ============================================================
' RetroAudio_PlayBootBeep
' Single short beep per boot sequence line.
' Called inside RetroUI_DrawBootScreen per system check line.
' ============================================================
SUB RetroAudio_PlayBootBeep
    CALL Sound_Play(SND_BOOT_BEEP)
END SUB

' ============================================================
' RetroAudio_PlayReady
' Multi-note "system ready" chime. Plays in background (MB).
' Called at the end of the boot sequence.
' ============================================================
SUB RetroAudio_PlayReady
    CALL Sound_Play(SND_READY)
END SUB

' ============================================================
' RetroAudio_PlayExport
' Sound for a successful export operation.
' ============================================================
SUB RetroAudio_PlayExport
    CALL Sound_Play(SND_EXPORT)
END SUB

' ============================================================
' RetroAudio_PlayThemeChange
' Plays after a theme switch — uses the NEW theme's tones.
' Must be called after Theme_Apply so g_ActiveTheme is set.
' ============================================================
SUB RetroAudio_PlayThemeChange
    CALL Sound_Play(SND_THEME_CHANGE)
END SUB

' ============================================================
' RetroAudio_PlayBootSequence
' Full coordinated boot audio sequence.
' Called from RetroUI_DrawBootScreen between typed lines.
' Each call plays one boot beep — boot screen calls this
' once per system check line for synchronized audio+visual.
' ============================================================
SUB RetroAudio_PlayBootSequence
    CALL Sound_Play(SND_BOOT_BEEP)
END SUB

' ============================================================
' RetroAudio_PlayAmbientLoop
' Future ambient audio hook — CRT hum, static, keyboard noise.
' Currently a no-op placeholder; implement when QB64 audio
' library support for looping is added.
' ============================================================
SUB RetroAudio_PlayAmbientLoop
    ' Reserved for future ambient audio system
    ' Future: PLAY "MB ..." with loop support
    ' Future: WAV/OGG streaming via _SNDOPEN
END SUB
