<CsoundSynthesizer>
<CsOptions>
-+rtmidi=alsa -Ma -odac -b 512 -B1024
;-iadc    ;;;uncomment -iadc if realtime audio input is needed too
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 44
nchnls = 2; STEREO XD
0dbfs  = 1

;############### STATIC VALUES ##################
#define Square #1#
#define Pulse  #2#
#define Triangle  #3#

    instr 39 ; ##### ROUTING INSTR ################
        kPitch chnget "PORTAMENTO_OUT_01"
        kVel chnget "MIDI_VELOCITY_01"
        kstatus, kchan, kdata1, kdata2 midiin;
        kModWheel init 0
        kVolume init 0
        if(kstatus==224) then
            kbend= 2*(kdata2/64 - 1)
        endif 
        if kstatus == 176 then
            if kdata1 == 1 then
                kModWheel = kdata2 / 127.0
            endif
            if kdata1 == 7 then
                kVolume = kdata2 / 127.0
            endif
            printks "kstatus %f\n", 0.1, kstatus
            printks "kVolume %f\n", 0.1, kVolume
            printks "kModWheel %f\n", 0.1, kModWheel
        endif
        
        ;kKbdRetrigger chnget "MIDI_RETRIGGER_01"

        ;chnset kKbdRetrigger, "ENV_RETRIGGER_1"
        

        kPitch = kPitch + kbend
        kLfo_1 chnget "LFO_OUT_1"
        kLfo_2 chnget "LFO_OUT_2"
        ;######## GENERATOR #########
        chnset kPitch - 12, "GEN_NOTE_1"
        chnset kPitch - (kVolume * kLfo_1) * 0.2, "GEN_NOTE_2"
        chnset kPitch + 7 + (kVolume * kLfo_1) * 0.2 , "GEN_NOTE_3"
        chnset kPitch , "GEN_NOTE_4"
        chnset kPitch + 7 + (kVolume * kLfo_1) * 0.2 , "GEN_NOTE_6"
        chnset kPitch + 12 - (kVolume * kLfo_1) * 0.2, "GEN_NOTE_5"

        asig chnget "GEN_OUTPUT_1"
        asig2 chnget "GEN_OUTPUT_2"
        asig3 chnget "GEN_OUTPUT_3"
        asig4 chnget "GEN_OUTPUT_4"
        asig5 chnget "GEN_OUTPUT_5"
        asig6 chnget "GEN_OUTPUT_6"


        ;########## FILTER PARAMETERS #############
        kFEnv chnget "ENV_2" ; => as filter env
        chnset kFEnv*60 + (kVel * 10) + kLfo_1 * 10 + (kModWheel * 30) - 20, "FILTER_FREQ_1"
        chnset kFEnv*50 + (kVel * 10) + kLfo_1 * 15 + (kModWheel * 30) - 20, "FILTER_FREQ_2"
        chnset kFEnv-0.3, "FILTER_RES_1"
        chnset kFEnv-0.2, "FILTER_RES_2"

        ;########## AMP/MIX ###########
        iBase = 0.2
        kAmpEnv chnget "ENV_1"
        kAmpEnv = kAmpEnv * (iBase + (1-iBase) * kVel)
        asumL = (asig4 + asig5 + asig6) * kAmpEnv 
        asumR = (asig*0.7 + asig2*1.5 + asig3) * kAmpEnv

        ;######## PASS AUDIO THROUTH FILTERS ###########
        chnset asumL, "FILTER_INPUT_1"
        chnset asumR, "FILTER_INPUT_2"
        asigLeft chnget "FILTER_OUT_1"
        asigRight chnget "FILTER_OUT_2"

        ;######### OUTPUT ###################
        ;outs 0.08*asigLeft, 0.08*asigRight

        kDiff = kVolume * (kLfo_2 - 0.5)
        printks "kDiff %f\n", 0.1, kDiff
        chnset 0.08*(1 + kDiff) * asigLeft, "MASTER_INPUT_L_01"
        chnset 0.08*(1 - kDiff) * asigRight, "MASTER_INPUT_R_01"
    endin




    instr 99999 ; ######### MASTER EFFECTS && OUTPUT ##########
        ain1 init 0.2
        ain2 init 0.2
        ain1 chnget "MASTER_INPUT_L_01"
        ain2 chnget "MASTER_INPUT_R_01"
        kroomsize init 0.95 ; room size (range 0 to 1)
        kHFDamp init 0.2 ; high freq. damping (range 0 to 1)
        aRvbL,aRvbR freeverb ain1, ain2,kroomsize,kHFDamp
        outs aRvbL, aRvbR ; send audio to outputs
    endin
    
    instr 5 ; ########### LFO MODULATOR #############
        kfreq init p4    
        iInstanceNo init p5
        kamp = 0.5     
        koffset = 0.5  
        klfo lfo kamp, kfreq, 1 ; TRI 
        ; Scale and shift LFO to go from 0 to 1
        klfo_shifted = klfo + koffset
        
        SOutputName sprintf "%s%d", "LFO_OUT_", iInstanceNo
        chnset klfo_shifted, SOutputName
    endin
    
    instr 19 ;################# GENERATOR ###################
        iFilterNo init  p4 ;A
        SInputName sprintf "%s%d", "GEN_NOTE_", iFilterNo
        kCV chnget SInputName
        kCV = max(kCV, 1)
        asig vco 0.3, cpsmidinn(kCV),  $Square,     0.5
        
        SOutputName sprintf "%s%d", "GEN_OUTPUT_", iFilterNo
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

    instr 1	;################ MIDI DETECTOR #################
        inum    notnum
        knum init inum
        chnset knum, "MIDI_NOTE_01"
        iVel    veloc    ;
        kVel = iVel
        chnset kVel/127, "MIDI_VELOCITY_01" ; SCALED

        kRetrigg init 1
        chnset kRetrigg, "MIDI_RETRIGGER_01"
        if kRetrigg == 1 then
            kRetrigg = 0
        endif

        kPressed = 1
        chnset kPressed, "KEY_PRESSED"
        kThisTrig init 1
        kThisTrig = 0
    endin

    instr 8 ;############# PORTAMENTO ################
        kCurr init 5
        kPrevNote init 5
        kNote init 5
        kNote chnget "MIDI_NOTE_01"

        kRes portk kNote, .03

        chnset kRes, "PORTAMENTO_OUT_01"
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

        kAnyPressed chnget "KEY_PRESSED"

        SRetriggerName sprintf "%s%d", "ENV_RETRIGGER_", iChan_01
        kRetrigg chnget SRetriggerName

        kPrevPressed init 0

        kAttSnap_01 init 0
        kDecSnap_01 init 0
        kRelSnap_01 init 0

        kStateTrigger_01 = 0 ; 1 -> A, 4 -> R /// ADSR

        kState_01 init 0
        kPrevState_01 init 0
        kDecTimeSaved_01 init 0

        kNoteOnTrigger = max(kAnyPressed - kPrevPressed, 0)

        if kAnyPressed > kPrevPressed then
            kStateTrigger_01 = 1
        endif

        if kPrevPressed > kAnyPressed then
            printks "LineNo %f\n", 0, 158
            kStateTrigger_01 = 4
        endif


        if kRetrigg == 1 && kAnyPressed == 1 then
            printks "LineNo %f\n", 0, 164
            printks "kRetrigg = %f\n", 0, kRetrigg
            kStateTrigger_01 = 1
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
            printks "LineNo %f\n", 0, 188
            kAttSnap_01 = kTime
            kAttTimer_01 = 0
            kState_01 = 1
        endif

        if kState_01 == 1 && kAttTimer_01 >= iAtt_01 then
            printks "LineNo %f\n", 0, 194
            kDecSnap_01 = kTime
            kState_01 = 2
        endif

        if kState_01 == 2 && kAttTimer_01 > iAtt_01 + iDec_01 then
            printks "LineNo %f\n", 0, 200
            kState_01 = 3
        endif

        if kStateTrigger_01 == 4 then
            printks "LineNo %f\n", 0, 205
            kRelSnap_01 = kTime
            kState_01 = 4
        endif

        if kRelTimer_01 > iRel_01 then
            printks "LineNo %f\n", 0, 211
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
        kPress = 0
        chnset kPress, "KEY_PRESSED"
    endin
        
</CsInstruments>
<CsScore>
    ; TABLES
    f 1 0 65536 10 1
    f 2 0 4096 10 1	
    f0 30000

    i5      0.01   7200  5 1; LFO1
    i5      0.01   7200  0.5 2; LFO2

    i8      0.01   7200  2; MODULATOR
    i99999  0.01   7200  1; MASTER
    i20     0.01   7200  1; FILTER 01
    i20     0.01   7200  2; FILTER 02
    i39     0.01   7200  
    i19     0.02   7200  1; GEN 1
    i19     0.02   7200  2; GEN 2
    i19     0.02   7200  3; GEN 3
    i19     0.02   7200  4; GEN 4
    i19     0.02   7200  5; GEN 5
    i19     0.02   7200  6; GEN 6
    i1000   0.00   7200

    ;ENVELOPE INSTR
    ;----------------p4   p5  p6    p7-  p8
    ;----------------A    D   S     R--- CHAN
    i21 0.01   7200  2    2   0.2   4    1   ;AMP ENVELOPE
    i21 0.01   7200  0.5  2   0.6   4    2   ;FLT ENVELOPE
    ;i21 0.01   7200  1   2   3     4     2
e
</CsScore>
</CsoundSynthesizer>
