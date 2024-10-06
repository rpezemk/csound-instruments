<CsoundSynthesizer>
<CsOptions>
-+rtmidi=portmidi -Ma -odac -b 256 -B1024
;-iadc    ;;;uncomment -iadc if realtime audio input is needed too
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 441
nchnls = 1
0dbfs  = 1

    gknum init 20
    gkNoteOnTrigger init 0
    giRetriggerAtt init 0
    gkAnyPressed init 0
    gkPrevPressed init 0
    gkInstr2Playing init 0
    gkInstr2Count init 0
    ;################ MIDI DETECTOR #################
    instr 1	 
        inum    notnum
        gknum = inum
        iamp ampmidi 1
        print iamp
        gkAnyPressed = 1
        kThisTrig init 1
        if kThisTrig == 1 then 
            gkNoteOnTrigger = 1
        endif
        kThisTrig = 0
    endin

    ;################# MONO PLAYER ###################
    instr 19
        kTime times
        kAttTrig init 0
        kDecTrig init 0
        kRelTrig init 0
        gkNoteOnTrigger init 0

        gkAnyPressed init 0
        gkPrevPressed init 0
        kOnTrig init 0
        kOffTrig init 0
        
        kstatus, kchan, kdata1, kdata2 midiin;
        if(kstatus==224) then
            kbend= 2*(kdata2/64 - 1)
        endif

        iSquare = 1
        iPulse = 2
        iTriangle = 3
        ; ;kloop lpshold 3, 0, 0, 0, 2, 12, 2, 24, 2
        kCV = gknum+kbend
        asig1 vco 0.3, cpsmidinn(kCV),          iSquare,     0.5
        asig2 vco 0.4, cpsmidinn(kCV+0.03),     iPulse,      0.3
        asig3 vco 1,   cpsmidinn(kCV-0.04),     iPulse,      0.6

        kEnv chnget "ENV_1"
        kfEnv chnget "ENV_1"

        asig = 1/3*(asig1+asig2+asig3)
        asig clip asig, 1, 1
        asig = asig*kEnv
        kmoogF min 130, gknum+kbend+kfEnv*30
        asig moogvcf asig, cpsmidinn(kmoogF), 0.7
        outs 0.02*asig
    endin

    ;############## ENVELOPE INSTR ##############
    instr 21 
        iAtt init  p4 ;A
        iDec init  p5 ;D
        iSus init  p6 ;S
        iRel init  p7 ;R
        iChan init p8 ;Ch
        
        kTime times
        kSavedEnv init 0
        kEnv init 0
        kAttTimer init 0
        kDecTimer init 0
        kRelTimer init 0
        kIsRel init 0

        kAttSnap init 0
        kDecSnap init 0
        kRelSnap init 0

        kAttTrig = 0
        kDecTrig = 0
        kSusTrig = 0
        kRelTrig = 0

        kState init 0
        kPrevState init 0
        kDecTimeSaved init 0

        if gkNoteOnTrigger == 1 then
            if giRetriggerAtt == 1 then
                kAttTrig = 1
            elseif gkAnyPressed > gkPrevPressed then 
                kAttTrig = 1
            endif
            if giRetriggerAtt == 1 || (kState == 0 || kState == 1) then
                kAttTrig = 1
            endif
        endif

        if gkPrevPressed > gkAnyPressed then
            kRelTrig = 1
        endif


        if kState == 1 || kState == 2 then
            kAttTimer = kTime - kAttSnap
        else
            kAttTimer = 0
        endif

        if kState == 2 then 
            kDecTimer = kTime - kDecSnap
        else 
            kDecTimer = 0
        endif

        if kState == 4  then
            kRelTimer = kTime - kRelSnap
        else
            kRelTimer = 0
        endif

        if kAttTrig == 1  then
            kAttSnap = kTime
            kState = 1
        endif

        if kState == 1 && kAttTimer >= iAtt then
            kDecTrig = 1
            kDecSnap = kTime
            kState = 2
        endif

        if kState == 2 && kAttTimer > iAtt + iDec then
            kSusTrig = 1
            kState = 3
        endif

        if kRelTrig == 1 then
            kRelSnap = kTime
            kState = 4
        endif

        if kRelTimer > iRel then

            kState = 0
        endif

        if kState == 4 then
            if kPrevState == 1 || kPrevState == 2 then
                kSavedEnv = kEnv
            elseif  kPrevState == 3 then
                kSavedEnv = iSus
            endif
        endif

        if kState == 1 then
            kEnv = kAttTimer / iAtt
        elseif kState == 2 then
            kEnv = iSus +  (1 - iSus) * (iDec - kDecTimer)/iDec 
        elseif kState == 3 then
            kEnv = iSus
        elseif kState == 4 then
            kRelPhase = (iRel - kRelTimer)/iRel  + (kSavedEnv - 1)
            kEnv = max(kRelPhase, 0)
        endif

        SResult sprintf "%s%d", "ENV_", iChan
        chnset kEnv, SResult

        kPrevState = kState
        gkPrevPressed = gkAnyPressed
        gkAnyPressed = 0
        gkNoteOnTrigger = 0
    endin

</CsInstruments>
<CsScore>
    ; TABLES
    f 1 0 65536 10 1
    f 2 0 4096 10 1	
    f0 30000

    ; EVENTS
    ;         
      
    i19 0      7200  
    ;----------------p4   p5  p6    p7-  p8
    ;----------------A    D   S     R--- CHAN
    i21 0.01   7200  0.1  2   0.5   4    1
    ;i21 0.01   7200  1   2   3     4     2
e
</CsScore>
</CsoundSynthesizer>
