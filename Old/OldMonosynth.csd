<CsoundSynthesizer>
<CsOptions>
-+rtmidi=portmidi -Ma -odac -b 512 -B1024
;-iadc    ;;;uncomment -iadc if realtime audio input is needed too
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 441
nchnls = 2; STEREO XD
0dbfs  = 1

#define Square #1#
#define Pulse  #2#
#define Triangle  #3#

    gknum init 20
    giRetriggerAtt init 0
    gkInstr2Playing init 0
    gkInstr2Count init 0

    instr 39 ; ##### ROUTING INSTR ################
        aLFO vco .1, 5,4,0.5
        kPitch chnget "MIDI_NOTE_01"
        kstatus, kchan, kdata1, kdata2 midiin;
        if(kstatus==224) then
            kbend= 2*(kdata2/64 - 1)
        endif
        kPitch = kPitch + kbend
        chnset kPitch, "GEN_NOTE_1"
        chnset kPitch - 12 , "GEN_NOTE_2"
        chnset kPitch + 7 , "GEN_NOTE_3"
        asig chnget "GEN_OUTPUT_1"
        asig2 chnget "GEN_OUTPUT_2"
        asig3 chnget "GEN_OUTPUT_3"
        kFEnv chnget "ENV_2"
        chnset kFEnv*70, "FILTER_FREQ_1"
        chnset kFEnv*69, "FILTER_FREQ_2"
        chnset kFEnv-0.3, "FILTER_RES_1"
        chnset kFEnv-0.2, "FILTER_RES_2"
        kEnv chnget "ENV_1"
        asum = (asig + asig2 + asig3) * kEnv
        asum2 = (asig*0.7 + asig2*1.5 + asig3) * kEnv
        chnset asum, "FILTER_INPUT_1"
        chnset asum2, "FILTER_INPUT_2"
        asigLeft chnget "FILTER_OUT_1"
        asigRight chnget "FILTER_OUT_2"
        outs 0.08*asigLeft, 0.08*asigRight
    endin

    instr 99999 ; ######### MASTER EFFECTS && OUTPUT ##########
    endin
    
    instr 1	;################ MIDI DETECTOR #################
        inum    notnum
        gknum = inum
        chnset gknum, "MIDI_NOTE_01"
        iamp ampmidi 1
        print iamp
        kPressed = 1
        chnset kPressed, "KEY_PRESSED"
        kThisTrig init 1
        kThisTrig = 0
    endin

    
    instr 19 ;################# GENERATOR ###################
        iFilterNo init  p4 ;A
        SInputName sprintf "%s%d", "GEN_NOTE_", iFilterNo
        SOutputName sprintf "%s%d", "GEN_OUTPUT_", iFilterNo
        kCV chnget SInputName
        kCV = max(kCV, 1)
        asig vco 0.3, cpsmidinn(kCV),          $Square,     0.5
        chnset asig, SOutputName
    endin

    instr 20 ;############## FILTER ################
        iFilterNo init  p4 ;A
        SInputName sprintf "%s%d", "FILTER_INPUT_", iFilterNo
        SOutputName sprintf "%s%d", "FILTER_OUT_", iFilterNo

        SFreqName sprintf "%s%d", "FILTER_FREQ_", iFilterNo
        SResName sprintf "%s%d", "FILTER_RES_", iFilterNo

        kPitchEnv chnget SFreqName
        kRes chnget SResName
        kPitchEnv = max(min(50, kPitchEnv), 0)
        asig chnget SInputName
        asig moogvcf asig, cpsmidinn(kPitchEnv + 40), kRes
        asig = asig
        chnset asig, SOutputName
    endin 

    instr 21 ;############## ENVELOPE INSTR ##############
        iAtt_01 init  p4 ;A
        iDec_01 init  p5 ;D
        iSus_01 init  p6 ;S
        iRel_01 init  p7 ;R
        iChan_01 init p8 ;Ch

        kTime times
        kSavedEnv_01 init 0
        kEnv_01 init 0
        kAttTimer_01 init 0
        kDecTimer_01 init 0
        kRelTimer_01 init 0

        kPrevPressed init 0

        kAttSnap_01 init 0
        kDecSnap_01 init 0
        kRelSnap_01 init 0

        kStateTrigger_01 = 0 ; 1 -> A, 4 -> R /// ADSR

        kState_01 init 0
        kPrevState_01 init 0
        kDecTimeSaved_01 init 0

        kAnyPressed chnget "KEY_PRESSED"

        kNoteOnTrigger = max(kAnyPressed - kPrevPressed, 0)

        if kNoteOnTrigger == 1 then
            if giRetriggerAtt == 1 then
                kStateTrigger_01 = 1
            elseif kAnyPressed > kPrevPressed then 
                kStateTrigger_01 = 1
            endif
            if giRetriggerAtt == 1 || (kState_01 == 0 || kState_01 == 1) then
                kStateTrigger_01 = 1
            endif
        endif

        if kPrevPressed > kAnyPressed then
            kStateTrigger_01 = 4
        endif

        if kState_01 == 1 || kState_01 == 2 then
            kAttTimer_01 = kTime - kAttSnap_01
        else
            kAttTimer_01 = 0
        endif

        if kState_01 == 2 then 
            kDecTimer_01 = kTime - kDecSnap_01
        else 
            kDecTimer_01 = 0
        endif

        if kState_01 == 4  then
            kRelTimer_01 = kTime - kRelSnap_01
        else
            kRelTimer_01 = 0
        endif

        if kStateTrigger_01 == 1  then
            kAttSnap_01 = kTime
            kState_01 = 1
        endif

        if kState_01 == 1 && kAttTimer_01 >= iAtt_01 then
            kDecSnap_01 = kTime
            kState_01 = 2
        endif

        if kState_01 == 2 && kAttTimer_01 > iAtt_01 + iDec_01 then
            kState_01 = 3
        endif

        if kStateTrigger_01 == 4 then
            kRelSnap_01 = kTime
            kState_01 = 4
        endif

        if kRelTimer_01 > iRel_01 then
            kState_01 = 0
        endif

        if kState_01 == 4 then
            if kPrevState_01 == 1 || kPrevState_01 == 2 || kPrevState_01 == 3 then
                kSavedEnv_01 = kEnv_01
            endif
        endif

        if kState_01 == 1 then
            kEnv_01 = kAttTimer_01 / iAtt_01
        elseif kState_01 == 2 then
            kEnv_01 = iSus_01 +  (1 - iSus_01) * (iDec_01 - kDecTimer_01)/iDec_01 
        elseif kState_01 == 3 then
            kEnv_01 = iSus_01
        elseif kState_01 == 4 then
            kRelPhase = (iRel_01 - kRelTimer_01)/iRel_01  + (kSavedEnv_01 - 1)
            kEnv_01 = max(kRelPhase, 0)
        endif

        SResult_01 sprintf "%s%d", "ENV_", iChan_01
        chnset kEnv_01, SResult_01

        kPrevState_01 = kState_01
        kPrevPressed = kAnyPressed
        kAnyPressed = 0
        kNoteOnTrigger = 0

    endin

    instr 1000 ; REMOVE KEYPRESS 
        kPress chnget "KEY_PRESSED"
        ;printks "kAnyPressed %f\n", 0, kPress
        kPress = 0
        chnset kPress, "KEY_PRESSED"
    endin
        
</CsInstruments>
<CsScore>
    ; TABLES
    f 1 0 65536 10 1
    f 2 0 4096 10 1	
    f0 30000


    i99999  0.01   7200  1; MASTER
    i20     0.01   7200  1; FILTER 01
    i20     0.01   7200  2; FILTER 02
    i39     0.01   7200  
    i19     0.02   7200  1; GEN 1
    i19     0.02   7200  2; GEN 2
    i19     0.02   7200  3; GEN 3
    i100    0.02   7200
    i1000   0.00   7200
    ;FILTER INSTR
    ;CONTROL INSTR

      
    ;ENVELOPE INSTR
    ;----------------p4   p5  p6    p7-  p8
    ;----------------A    D   S     R--- CHAN
    i21 0.01   7200  2  2   0.4   4    1
    i21 0.01   7200  2  2   0.4   4    2
    ;i21 0.01   7200  1   2   3     4     2
e
</CsScore>
</CsoundSynthesizer>
