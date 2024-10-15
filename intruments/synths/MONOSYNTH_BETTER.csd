<CsoundSynthesizer>
<CsOptions>
-+rtmidi=alsa -Ma -odac -b 512 -B1024
;-iadc    ;;;uncomment -iadc if realtime audio input is needed too
</CsOptions>
<CsInstruments>
    ;############# PERFORMANCE VALUES ################
    sr = 44100
    ksmps = 44
    nchnls = 2; STEREO XD
    0dbfs  = 1

    ;############### STATIC VALUES ##################
    #define Square #1#
    #define Pulse  #2#
    #define Triangle  #3#

    ;############### UPD PORT ###############
    gihandle OSCinit 37707
    gkPitch_01 init 40
    gkVel_01 init 0
    gkRet_01 init 0
    gkTrig_01 init 0

    ;################ REAL TIME MIDI DETECTOR #################
    instr 1	
        inum      notnum
        iMidiChan midichn
        knum init inum

        SChanName sprintfk "%s_%d_%d", "OUTPUT", 1, 1
        gkPitch_01 = knum
        chnset knum, SChanName        

        iVel    veloc    ;
        kVel = iVel

        SChanName sprintfk "%s_%d_%d", "OUTPUT", 1, 2
        chnset kVel/127, SChanName ; SCALED
        gkVel_01 = kVel

        gkRet_01 = 1
        if gkRet_01 == 1 then
            gkRet_01 = 0
        endif

        gkTrig_01 = 1
    endin

    ; ################ K-RATE CABLE INSTRUMENT ###################
    instr 777
        iSrcNo      init p4
        iSrcOutNo   init p5
        iDestType   init p6 ; k/a -> 0/1
        iDestNo     init p7
        iDestOutNo  init p8

        SChanName sprintfk "%s_%d_%d", "OUTPUT", iSrcNo, iSrcOutNo
        kValue chnget SChanName
        ; printks "SChanName %s\n", 0, SChanName
        ; printks "knum %f\n", 0, kValue
        SChanName sprintfk "%s_%d_%d", "INPUT", iDestNo, iDestOutNo
        chnset kValue, SChanName
    endin




    ;############## ENVELOPE INSTR ##############
    instr 21 
        iChan   init  p4 ;Ch

        kAtt_01 init  p5  ; A1
        kDec_01 init  p6  ; D1
        kSus_01 init  p7  ; S1
        kRel_01 init  p8  ; R1

        kAtt_02 init  p9  ; A2
        kDec_02 init  p10 ; D2
        kSus_02 init  p11 ; S2
        kRel_02 init  p12 ; R2

        kReson  init  p13



        kTime times
        kSavedEnv_01 init 0
        kAmpEnv init 0
        kFilterEnv init 0
        kAttTimer_01 init 0
        kDecTimer_01 init 0
        kRelTimer_01 init 0

        kAnyPressed = gkTrig_01
        kRetrigg = gkRet_01

        kPrevPressed init 0

        kAttSnap_01 init 0
        kAttSnap_02 init 0
        kDecSnap_01 init 0
        kDecSnap_02 init 0
        kRelSnap_01 init 0
        kRelSnap_02 init 0

        kStateTrigger_01 = 0 ; 1 -> A, 4 -> R /// ADSR
        kStateTrigger_02 = 0 ; 1 -> A, 4 -> R /// ADSR

        kState_01 init 0
        kState_02 init 0
        kPrevState_01 init 0
        kPrevState_02 init 0
        kDecTimeSaved_01 init 0
        kDecTimeSaved_02 init 0

        kNoteOnTrigger = max(kAnyPressed - kPrevPressed, 0)

        if kAnyPressed > kPrevPressed then
            kStateTrigger_01 = 1
            kStateTrigger_02 = 1
        endif

        if kPrevPressed > kAnyPressed then
            kStateTrigger_01 = 4
            kStateTrigger_02 = 4
        endif


        if kRetrigg == 1 && kAnyPressed == 1 then
            kStateTrigger_01 = 1
            kStateTrigger_02 = 1
        endif

        if kState_01 == 1 || kState_01 == 2 then
            kAttTimer_01 = kTime - kAttSnap_01
        else
            kAttTimer_01 = 0
        endif

        if kState_02 == 1 || kState_02 == 2 then
            kAttTimer_02 = kTime - kAttSnap_02
        else
            kAttTimer_02 = 0
        endif

        if kState_01 == 2 then 
            kDecTimer_01 = kTime - kDecSnap_01
        else 
            kDecTimer_01 = 0
        endif
        
        if kState_02 == 2 then 
            kDecTimer_02 = kTime - kDecSnap_02
        else 
            kDecTimer_02 = 0
        endif

        if kState_01 == 4  then
            kRelTimer_01 = kTime - kRelSnap_01
        else
            kRelTimer_01 = 0
        endif
        
        if kState_02 == 4  then
            kRelTimer_02 = kTime - kRelSnap_02
        else
            kRelTimer_02 = 0
        endif

        if kStateTrigger_01 == 1  then
            kAttSnap_01 = kTime
            kAttTimer_01 = 0
            kState_01 = 1
        endif
        
        if kStateTrigger_02 == 1  then
            kAttSnap_02 = kTime
            kAttTimer_02 = 0
            kState_02 = 1
        endif

        if kState_01 == 1 && kAttTimer_01 >= kAtt_01 then
            kDecSnap_01 = kTime
            kState_01 = 2
        endif

        if kState_02 == 1 && kAttTimer_02 >= kAtt_02 then
            kDecSnap_02 = kTime
            kState_02 = 2
        endif

        if kState_01 == 2 && kAttTimer_01 > kAtt_01 + kDec_01 then
            kState_01 = 3
        endif

        if kState_02 == 2 && kAttTimer_02 > kAtt_02 + kDec_02 then
            kState_02 = 3
        endif

        if kStateTrigger_01 == 4 then
            kRelSnap_01 = kTime
            kState_01 = 4
        endif
        
        if kStateTrigger_02 == 4 then
            kRelSnap_02 = kTime
            kState_02 = 4
        endif

        if kRelTimer_01 > kRel_01 then
            kState_01 = 0
        endif

        if kRelTimer_02 > kRel_02 then
            kState_02 = 0
        endif

        if kState_01 == 4 then
            if kPrevState_01 == 1 || kPrevState_01 == 2 || kPrevState_01 == 3 then
                kSavedEnv_01 = kAmpEnv
            endif
        endif

        if kState_02 == 4 then
            if kPrevState_02 == 1 || kPrevState_02 == 2 || kPrevState_02 == 3 then
                kSavedEnv_02 = kFilterEnv
            endif
        endif

        if kState_01 == 1 then
            kAmpEnv = kAttTimer_01 / kAtt_01
        elseif kState_01 == 2 then
            kAmpEnv = kSus_01 +  (1 - kSus_01) * (kDec_01 - kDecTimer_01)/kDec_01 
        elseif kState_01 == 3 then
            kAmpEnv = kSus_01
        elseif kState_01 == 4 then
            kRelPhase = (kRel_01 - kRelTimer_01)/kRel_01  + (kSavedEnv_01 - 1)
            kAmpEnv = max(kRelPhase, 0)
        endif

        if kState_02 == 1 then
            kFilterEnv = kAttTimer_02 / kAtt_02
        elseif kState_02 == 2 then
            kFilterEnv = kSus_02 +  (1 - kSus_02) * (kDec_02 - kDecTimer_02)/kDec_02 
        elseif kState_02 == 3 then
            kFilterEnv = kSus_02
        elseif kState_02 == 4 then
            kRelPhase = (kRel_02 - kRelTimer_02)/kRel_02  + (kSavedEnv_02 - 1)
            kFilterEnv = max(kRelPhase, 0)
        endif

        printks "kAmpEnv => %f\n", 0.1, kAmpEnv
        printks "kFilterEnv => %f\n", 0.1, kFilterEnv
        asig vco 0.3, cpsmidinn(gkPitch_01),  $Square,     0.5

        kResFilterVal = kFilterEnv * 12 + gkPitch_01
        kFilterFreq = cpsmidinn(kResFilterVal)
        asig = asig * kAmpEnv
        asig moogvcf asig, kFilterFreq, kReson
        outs asig * 0.1, asig * 0.1

        kPrevState_01 = kState_01
        kPrevState_02 = kState_02
        kPrevPressed = kAnyPressed
        kAnyPressed = 0
        kNoteOnTrigger = 0

    endin

    

    instr 1000 ; REMOVE KEYPRESS 
        kPress = 0
        gkTrig_01 = 0
        chnset kPress, "KEY_PRESSED"  
        chnset kPress, "KEY_PRESSED_1"
        chnset kPress, "KEY_PRESSED_2"
        chnset kPress, "KEY_PRESSED_3"
        chnset kPress, "KEY_PRESSED_4"
        chnset kPress, "KEY_PRESSED_5"
        chnset kPress, "KEY_PRESSED_6"
        chnset kPress, "KEY_PRESSED_7"
        chnset kPress, "KEY_PRESSED_8"
        chnset kPress, "KEY_PRESSED_9"
        chnset kPress, "KEY_PRESSED_10"
        chnset kPress, "KEY_PRESSED_11"
        chnset kPress, "KEY_PRESSED_12"
        chnset kPress, "KEY_PRESSED_13"
        chnset kPress, "KEY_PRESSED_14"
        chnset kPress, "KEY_PRESSED_15"
        chnset kPress, "KEY_PRESSED_16"
    endin
        
</CsInstruments>
<CsScore>
    ; TABLES
    f 1 0 65536 10 1
    f 2 0 4096 10 1	
    f 0 30000


;##########################################
;########### INSTRUMENT EVENTS ############
;##########################################
; instrNo   start  dur.  
;                            instance  src     src    dst     dst
;                            no.       no.     out    no      out
   ;i1  ; MIDI-key
    i777    0.01   7200                1        1      0      101    1 
    i19     0.01   7200      101     

                                   ; a d s   r    a d  s  r   q
    i21     0.01   7200      1       1 2 0.3 2    1 2 0.3 2   0.5

    i1000   0.00   7200                         ; KEYPRESS SET TO ZERO

e
</CsScore>
</CsoundSynthesizer>
