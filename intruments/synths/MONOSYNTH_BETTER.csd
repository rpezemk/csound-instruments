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
    gkPitch[] init 16
    gkVel[] init 16
    gkRet[] init 16
    gkTrig[] init 16

    ;################ REAL TIME MIDI DETECTOR #################
    instr 1	
        inum      notnum
        iMidiChan midichn
        knum init inum

        gkPitch[iMidiChan] = knum
     

        iVel    veloc    ;
        kVel = iVel

        gkVel[iMidiChan] = kVel

        gkRet[iMidiChan] = 1
        if gkRet[iMidiChan] == 1 then
            gkRet[iMidiChan] = 0
        endif

        gkTrig[iMidiChan] = 1
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
        iChan   init   p4 ;Ch
 
        kAtt_01 init   p5  ; A1
        kDec_01 init   p6  ; D1
        kSus_01 init   p7  ; S1
        kRel_01 init   p8  ; R1
 
        kAtt_02 init   p9  ; A2
        kDec_02 init   p10 ; D2
        kSus_02 init   p11 ; S2
        kRel_02 init   p12 ; R2
 
        kReson  init   p13
        kg1Type init   p14
        kg2Type init   p15
        kg3Type init   p16
          
        kg1oct  init   p17 
        kg2oct  init   p18 
        kg3oct  init   p19 
  
        kg1det  init   p20 
        kg2det  init   p21 
        kg3det  init   p22 
  
        kg1mix  init   p23 
        kg2mix  init   p24 
        kg3mix  init   p25 
        kPortTime init p26

        kNsMix  init   p27
        kNsType init   p28 ;  0/1 => pink/white
          
        kDryWet init   p29 ; 0/1 => dry/wet
        kFltDet init   p30 ; filter detune SEMITONES

        kLfoFreq init  p31 ; LFO FREQ
        kLfoType init  p32 ; LFO TYPE
        kLfoSymm init  p33 ; LFO Symm


        if kLfoType == 1 then 
            klfo lfo 1, kLfoFreq, 1 ; TRI 
        elseif kLfoType == 2 then 
            klfo lfo 1, kLfoFreq, 2 ; TRI 
        elseif kLfoType == 3 then 
            klfo lfo 1, kLfoFreq, 3 ; TRI 
        elseif kLfoType == 4 then 
            klfo lfo 1, kLfoFreq, 4 ; TRI 
        else
            klfo lfo 1, kLfoFreq, 5 ; TRI 
        endif

        klfo = klfo * (1 - 0.5 * (1-kLfoSymm)) + (1-kLfoSymm) * 0.5


        kTime times
        kSavedEnv_01 init 0
        kAmpEnv init 0
        kFilterEnv init 0
        kAttTimer_01 init 0
        kDecTimer_01 init 0
        kRelTimer_01 init 0

        kAnyPressed = gkTrig[iChan]
        kRetrigg = gkRet[iChan]

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

        ;printks "kAmpEnv => %f\n", 0.1, kAmpEnv
        ;printks "kFilterEnv => %f\n", 0.1, kFilterEnv



        kPorta portk gkPitch[iChan], .03
        kPorta max 1, kPorta
        kg1resPitch = cpsmidinn(max(1, kPorta + kg1oct*12 + kg1det));
        
        amix = 0
        if kg1Type == 1 then
            asig vco 0.3, kg1resPitch,  1,     0.5
        elseif kg1Type == 2 then 
            asig vco 0.3, kg1resPitch,  2,     0.5
        elseif kg1Type == 3 then 
            asig vco 0.3, kg1resPitch,  3,     0.5
        elseif kg1Type == 4 then 
            asig vco 0.3, kg1resPitch,  4,     0.5
        elseif kg1Type == 5 then 
            asig vco 0.3, kg1resPitch,  5,     0.5
        endif
        amix = amix + asig * kg1mix

        kg2resPitch = cpsmidinn(max(1, kPorta + kg2oct*12 + kg2det));
        if kg2Type == 1 then
            asig vco 0.3, kg2resPitch,  1,     0.5
        elseif kg2Type == 2 then 
            asig vco 0.3, kg2resPitch,  2,     0.5
        elseif kg2Type == 3 then 
            asig vco 0.3, kg2resPitch,  3,     0.5
        elseif kg2Type == 4 then 
            asig vco 0.3, kg2resPitch,  4,     0.5
        elseif kg2Type == 5 then 
            asig vco 0.3, kg2resPitch,  5,     0.5
        endif
        amix = amix + asig * kg2mix

        kg3resPitch = cpsmidinn(max(1, kPorta + kg3oct*12 + kg3det));
        if kg3Type == 1 then
            asig vco 0.3, kg3resPitch,  1,     0.5
        elseif kg3Type == 2 then 
            asig vco 0.3, kg3resPitch,  2,     0.5
        elseif kg3Type == 3 then 
            asig vco 0.3, kg3resPitch,  3,     0.5
        elseif kg3Type == 4 then 
            asig vco 0.3, kg3resPitch,  4,     0.5
        elseif kg3Type == 5 then 
            asig vco 0.3, kg3resPitch,  5,     0.5
        endif

        amix = amix + asig * kg3mix


        aNoise rand -1, 1
        amix = amix + aNoise * kNsMix
        asig = amix * kAmpEnv

        kResFilterVal = kFilterEnv * 12 + kPorta
        printks "klfo %f \n", 0.1, klfo
        kFilterFreqL = cpsmidinn(max(1, kResFilterVal + 0.5 * kFltDet + klfo))
        kFilterFreqR = cpsmidinn(max(1, kResFilterVal - 0.5 * kFltDet - klfo))
        asigL moogvcf asig, kFilterFreqL, kReson
        asigR moogvcf asig, kFilterFreqR, kReson

        chnset asigL*kDryWet, "MASTER_INPUT_L_01"
        chnset asigR*kDryWet, "MASTER_INPUT_R_01"
        outs asigL * (1 - kDryWet) * 0.1, asigR * (1 - kDryWet) * 0.1

        kPrevState_01 = kState_01
        kPrevState_02 = kState_02
        kPrevPressed = kAnyPressed
        kAnyPressed = 0
        gkTrig[iChan] = 0
        gkRet[iChan] = 0
        kNoteOnTrigger = 0
    endin


    instr 200 

        ain1 init 0.2
        ain2 init 0.2
        ain1 chnget "MASTER_INPUT_L_01"
        ain2 chnget "MASTER_INPUT_R_01"
        kroomsize init p4; 0.95 ; room size (range 0 to 1)
        kHFDamp init p5; high freq. damping (range 0 to 1)
        aRvbL,aRvbR freeverb ain1, ain2,kroomsize,kHFDamp
        outs aRvbL, aRvbR ; send audio to outputs
    endin

</CsInstruments>
<CsScore>
    ; TABLES
    f 1 0 65536 10 1
    f 2 0 4096 10 1	
    f 0 30000

; instrNo   start  dur.  
;                            instance  src     src    dst     dst
;                            no.       no.     out    no      out
   ;i1  ; MIDI-key
    i777    0.01   7200                1        1      0      101    1 
    i19     0.01   7200      101     

                                                               

    ;######### MONOSYNTH ##################################################
    i21     0.01   7200      1     \                                      ;# 
                                                                          ;#  
    ;a d s   r    a d s   r                                               ;#  
     1 2 0.3 2    1 2 0.3 2        \                                      ;# 
    ;osc  type        octave       detune         mix                     ;# 
    ;q    g1 g2 g3    g1  g2  g3   g1  g2  g3     g1   g2   g3            ;#  
     0.6  1  1  1    -1    0   1   0   0.1 -0.2   1   0.5   0.3   \       ;#   
    ;_____________________._____________________                          ;#  
    ;noise.....           |filter               |                         ;#  
    ;port  mix    type    |dry/wet    detune    |                         ;#          
     0.1   0.3     0        0.2        1        \                         ;#   
    ;LFO
    ; F  T  S
      2  2  1
    ;#######################################################################

    ;MASTER                  room    damp
    i200    0.01   7200      0.3     0.8
e
</CsScore>
</CsoundSynthesizer>
