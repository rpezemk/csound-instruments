<CsoundSynthesizer>
<CsOptions>
-+rtmidi=portmidi -Ma -odac -b 512 -B1024
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 441
nchnls = 2; STEREO XD
0dbfs  = 1

gihandle OSCinit 37707

instr 1199 ;############ UDP LISTENER #############
    kreceiverNo init 0
    kpitch init 30
    kveloc init 0
    klen   init 0
    ktied  init 0
    kghost init 0
    ; //TODO kreceiverNo implementation
    kNoteTrigger OSClisten gihandle, "/notetrigger", "ffffff", kpitch, kveloc, klen, ktied, kghost, kreceiverNo
    
    ; //TODO send event to kreceiverNo instrument

    aout oscil 0.5, cpsmidinn(kpitch + 40), 1   ; Oscillator at received frequency
    out aout, aout
endin

instr 9999 ; dummy
endin

</CsInstruments>

<CsScore>
f 1 0 16384 10 1
; Score: Play instrument 1 for 5 seconds
i 1199    0 5000
i 9999 0 5000 ; dummy
</CsScore>
</CsoundSynthesizer>
