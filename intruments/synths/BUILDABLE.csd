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

    ;################ REAL TIME MIDI DETECTOR #################
    instr 1	
        inum      notnum
        iMidiChan midichn
        knum init inum

        SChanName sprintfk "%s_%d", "MIDI_NOTE", iMidiChan

        chnset knum, SChanName        

        iVel    veloc    ;
        kVel = iVel

        SChanName sprintfk "%s_%d", "MIDI_VELOCITY", iMidiChan
        chnset kVel/127, SChanName ; SCALED

        kRetrigg init 1
        SChanName sprintfk "%s_%d", "MIDI_RETRIGGER", iMidiChan
        chnset kRetrigg, SChanName

        if kRetrigg == 1 then
            kRetrigg = 0
        endif

        kPressed = 1
        SChanName sprintfk "%s_%d", "KEY_PRESSED", iMidiChan
        chnset kPressed, SChanName
    endin


    ; ############## INTERNAL PRESS ###############

    ;############# PORTAMENTO ################
    instr 8 
        iInstanceNo init p4
        iMidiChan init p5
        kCurr init 5
        kPrevNote init 5
        kNote init 5
        SChanName sprintfk "%s_%d", "MIDI_NOTE", iMidiChan
        kNote chnget SChanName

        kRes portk kNote, .03
        SChanName sprintfk "%s_%d", "PORTAMENTO_OUT", iMidiChan
        chnset kRes, SChanName
    endin
    

    ; ################ OSC RECEIVER -- ROUTING CREATOR #################
    instr 99077 
    
        kInstanceNo   init 0
        kRoutingCount init 1
        kMidiChan     init 0
        kEnvNo        init 1
        kGotData OSClisten gihandle, "/mono/createrouting", "ff", kInstanceNo, kMidiChan
        if kGotData == 1 then

            event "i", 39,  0,  3600*4, kInstanceNo, kMidiChan
            event "i",  8,  0,  3600*4, kInstanceNo, kMidiChan
            ;i21 0.01           7200    2    2   0.2   4    1   ;AMP ENVELOPE
            event "i", 21,  0,  3600*4, 1,   2,  0.3,  4,   1
            event "i", 21,  0,  3600*4, 1,   2,  0.3,  4,   2
            kRoutingCount = kRoutingCount + 1
            kEnvNo = kEnvNo + 1
        endif

        kDestInstrNo init 0
        kInstanceNo init 0
        kParamNo init 0
        kValue init 0
        kGotData OSClisten gihandle, "/monosynth", "ffff", kDestInstrNo, kInstanceNo, kParamNo, kValue
        if kGotData == 1 then
            SChanName sprintfk "%s_%d_%d_%d", "OSC_DATA", kDestInstrNo, kInstanceNo, kParamNo
            chnset kValue, SChanName
        endif
    endin



    ;############## ROUTING INSTR ################
    instr 39
        iRoutingNo  init p1
        iInstanceNo init p4
        iMidiChan init p5
        kTranspose  init 0
        kPortamento init 0
        kAllowRetr  init 0
        kPBendRange init 2
        
        kG1_Type    init 1
        kG2_Type    init 1
        kG3_Type    init 1
        kG4_Type    init 1
        kG5_Type    init 1
        kG6_Type    init 1

        kG1_Tran    init -12
        kG2_Tran    init 12
        kG3_Tran    init -12
        kG4_Tran    init -12
        kG5_Tran    init 7
        kG6_Tran    init 24

        kG1_Mix    init 1
        kG2_Mix    init 1
        kG3_Mix    init 1
        kG4_Mix    init 1
        kG5_Mix    init 1
        kG6_Mix    init 1

        kF1_F        init 23
        kF1_Q        init 0.3
        kF1_p_track  init 12
        kF1_v_track  init 12
        kF1_mod      init 30

        kF2_F      init 21
        kF2_Q      init 0.3
        kF2_p_track  init 12
        kF2_v_track  init 12
        kF2_mod      init 30

        SChanName sprintfk "%s_%d", "PORTAMENTO_OUT", iMidiChan
        kPitch chnget SChanName
        kPitch = kPitch + kTranspose


        SChanName sprintfk "%s_%d", "MIDI_VELOCITY", iMidiChan
        kVel chnget SChanName
        kstatus, kchan, kdata1, kdata2 midiin;
        kModWheel init 0
        kVolume init 0
        if(kstatus==224) then
            kbend= kPBendRange*(kdata2/64 - 1)
        endif 
        if kstatus == 176 then
            if kdata1 == 1 then
                kModWheel = kdata2 / 127.0
            endif
            if kdata1 == 7 then
                kVolume = kdata2 / 127.0
            endif
        endif
    
        kPitch = kPitch + kbend
        kLfo_1 chnget "LFO_OUT_1"
        kLfo_2 chnget "LFO_OUT_2"
        ;######## GENERATOR #########
        chnset kPitch + kG1_Tran, "GEN_NOTE_1"
        chnset kPitch + kG2_Tran, "GEN_NOTE_2"
        chnset kPitch + kG3_Tran, "GEN_NOTE_3"
        chnset kPitch + kG4_Tran, "GEN_NOTE_4"
        chnset kPitch + kG5_Tran, "GEN_NOTE_6"
        chnset kPitch + kG6_Tran, "GEN_NOTE_5"

        asig1 chnget "GEN_OUTPUT_1"
        asig2 chnget "GEN_OUTPUT_2"
        asig3 chnget "GEN_OUTPUT_3"
        asig4 chnget "GEN_OUTPUT_4"
        asig5 chnget "GEN_OUTPUT_5"
        asig6 chnget "GEN_OUTPUT_6"

        asig1 = asig1 * kG1_Mix
        asig2 = asig2 * kG2_Mix
        asig3 = asig3 * kG3_Mix
        asig4 = asig4 * kG4_Mix
        asig5 = asig5 * kG5_Mix
        asig6 = asig6 * kG6_Mix


        ;########## FILTER PARAMETERS #############
        kFEnv chnget "ENV_2" ; => as filter env
        chnset kF1_F + kFEnv*kF1_p_track + (kVel * kF1_v_track) + (kModWheel * kF1_mod) , "FILTER_FREQ_1"
        chnset kF2_F + kFEnv*kF2_p_track + (kVel * kF2_v_track) + (kModWheel * kF2_mod) , "FILTER_FREQ_2"
        chnset kFEnv-0.3, "FILTER_RES_1"
        chnset kFEnv-0.2, "FILTER_RES_2"

        ;########## AMP/MIX ###########
        iBase = 0.2
        kAmpEnv chnget "ENV_1"
        kAmpEnv = kAmpEnv * (iBase + (1-iBase) * kVel)
        asumR = (asig1*0.7 + asig2*1.5 + asig3) * kAmpEnv
        asumL = (asig4 + asig5 + asig6) * kAmpEnv 

        ;######## PASS AUDIO THROUTH FILTERS ###########
        chnset asumL, "FILTER_INPUT_1"
        chnset asumR, "FILTER_INPUT_2"
        asigLeft chnget "FILTER_OUT_1"
        asigRight chnget "FILTER_OUT_2"

        ;######### OUTPUT ###################
        ;outs 0.08*asigLeft, 0.08*asigRight

        kDiff = kVolume * (kLfo_2 - 0.5)

        chnset 0.1 * asigLeft, "MASTER_INPUT_L_1"
        chnset 0.1 * asigRight, "MASTER_INPUT_R_1"
    endin



    ; ######### MASTER EFFECTS && OUTPUT ##########
    instr 99999 
        ain1 init 0.2
        ain2 init 0.2
        ain1 chnget "MASTER_INPUT_L_1"
        ain2 chnget "MASTER_INPUT_R_1"
        kroomsize init 0.95 
        kHFDamp init 0.2 
        aRvbL,aRvbR freeverb ain1, ain2,kroomsize,kHFDamp
        outs aRvbL, aRvbR
    endin
    
    instr 5 ; ########### LFO MODULATOR #############
        iInstanceNo init p4
        kfreq init p5    
        kamp = 0.5     
        koffset = 0.5  
        klfo lfo kamp, kfreq, 1 ; TRI 
        klfo_shifted = klfo + koffset
        SOutputName sprintf "%s%d", "LFO_OUT_", iInstanceNo
        chnset klfo_shifted, SOutputName
    endin
    
    ;################# GENERATOR ###################
    instr 19 
        iFilterNo init  p4 ;A
        SInputName sprintf "%s%d", "GEN_NOTE_", iFilterNo
        kCV chnget SInputName
        kCV = max(kCV, 1)
        asig vco 0.3, cpsmidinn(kCV),  $Square,     0.5
        SOutputName sprintf "%s%d", "GEN_OUTPUT_", iFilterNo
        chnset asig, SOutputName
    endin

    ;############## FILTER ################
    instr 20 
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




    ;############## ENVELOPE INSTR ##############
    instr 21 
        iAtt_1 init  p4 ;A
        iDec_1 init  p5 ;D
        iSus_1 init  p6 ;S
        iRel_1 init  p7 ;R
        iChan_1 init p8 ;Ch
        iMidiChan init 1
        kTime times
        kSavedEnv_1 init 0
        kEnv_1 init 0
        kAttTimer_1 init 0
        kDecTimer_1 init 0
        kRelTimer_1 init 0
        SChanName sprintfk "%s_%d", "KEY_PRESSED", iMidiChan
        kAnyPressed chnget SChanName

        SRetriggerName sprintf "%s_%d", "ENV_RETRIGGER", iChan_1
        kRetrigg chnget SRetriggerName

        kPrevPressed init 0

        kAttSnap_1 init 0
        kDecSnap_1 init 0
        kRelSnap_1 init 0

        kStateTrigger_1 = 0 ; 1 -> A, 4 -> R /// ADSR

        kState_1 init 0
        kPrevState_1 init 0
        kDecTimeSaved_1 init 0

        kNoteOnTrigger = max(kAnyPressed - kPrevPressed, 0)

        if kAnyPressed > kPrevPressed then
            kStateTrigger_1 = 1
        endif

        if kPrevPressed > kAnyPressed then
            kStateTrigger_1 = 4
        endif


        if kRetrigg == 1 && kAnyPressed == 1 then
            kStateTrigger_1 = 1
        endif

        if kState_1 == 1 || kState_1 == 2 then
            kAttTimer_1 = kTime - kAttSnap_1
        else
            kAttTimer_1 = 0
        endif

        if kState_1 == 2 then 
            kDecTimer_1 = kTime - kDecSnap_1
        else 
            kDecTimer_1 = 0
        endif

        if kState_1 == 4  then
            kRelTimer_1 = kTime - kRelSnap_1
        else
            kRelTimer_1 = 0
        endif

        if kStateTrigger_1 == 1  then
            kAttSnap_1 = kTime
            kAttTimer_1 = 0
            kState_1 = 1
        endif

        if kState_1 == 1 && kAttTimer_1 >= iAtt_1 then
            kDecSnap_1 = kTime
            kState_1 = 2
        endif

        if kState_1 == 2 && kAttTimer_1 > iAtt_1 + iDec_1 then
            kState_1 = 3
        endif

        if kStateTrigger_1 == 4 then
            kRelSnap_1 = kTime
            kState_1 = 4
        endif

        if kRelTimer_1 > iRel_1 then
            kState_1 = 0
        endif

        if kState_1 == 4 then
            if kPrevState_1 == 1 || kPrevState_1 == 2 || kPrevState_1 == 3 then
                kSavedEnv_1 = kEnv_1
            endif
        endif

        if kState_1 == 1 then
            kEnv_1 = kAttTimer_1 / iAtt_1
        elseif kState_1 == 2 then
            kEnv_1 = iSus_1 +  (1 - iSus_1) * (iDec_1 - kDecTimer_1)/iDec_1 
        elseif kState_1 == 3 then
            kEnv_1 = iSus_1
        elseif kState_1 == 4 then
            kRelPhase = (iRel_1 - kRelTimer_1)/iRel_1  + (kSavedEnv_1 - 1)
            kEnv_1 = max(kRelPhase, 0)
        endif

        SResult_1 sprintf "%s%d", "ENV_", iChan_1
        chnset kEnv_1, SResult_1

        kPrevState_1 = kState_1
        kPrevPressed = kAnyPressed
        kAnyPressed = 0
        kNoteOnTrigger = 0

    endin

    instr 1000 ; REMOVE KEYPRESS 
        kPress = 0
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
    i3      0.01   7200  ; INITIAL INSTR
;                          instance
;                            no.
    i5      0.01   7200       1       5; LFO1
    i5      0.01   7200       2       0.5; LFO2
     

    i99999  0.01   7200       1          ; MASTER
    i99077  0.01   7200       1          ; UDP OSC LISTENER
    i20     0.01   7200       1          ; FILTER 01
    i20     0.01   7200       2          ; FILTER 02

    
    i19     0.02   7200       1          ; GEN 1
    i19     0.02   7200       2          ; GEN 2
    i19     0.02   7200       3          ; GEN 3
    i19     0.02   7200       4          ; GEN 4
    i19     0.02   7200       5          ; GEN 5
    i19     0.02   7200       6          ; GEN 6

    i1000   0.00   7200           ; KEYPRESS SET TO ZERO

e
</CsScore>
</CsoundSynthesizer>
