<CsoundSynthesizer>
<CsOptions>
-+rtmidi=portmidi -Ma -iadc -odac -b 128 -B256
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 128
nchnls = 2; STEREO XD
0dbfs  = 1

gihandle OSCinit 37707

instr 1199 ;############ UDP LISTENER #############

    aIn   inch 2
    kRms rms aIn
    aout oscil 0.5, 440 + 3444*aIn, 1 
    fout "output.wav", 16, aIn ; 
    out aIn*0.3,  aIn*0.3
endin

instr 9999 ; dummy
endin

</CsInstruments>

<CsScore>
f 1 0 16384 10 1
; Score: Play instrument 1 for 5 seconds
i 1199    0 12
i 9999    0 12 ; dummy
</CsScore>
</CsoundSynthesizer>
