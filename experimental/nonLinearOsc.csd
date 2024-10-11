<CsoundSynthesizer>
<CsOptions>
-+rtmidi=alsa -Ma -odac -b 512 -B1024 
</CsOptions>

<CsInstruments>
sr = 44100
ksmps = 1
nchnls = 1; STEREO XD
0dbfs  = 1

instr 1
        idt init 1/sr
        iamp = p4
        ifreq = p5
        
        kForce    init 0
        aX        init 2
        aVel      init 0.01
        aMass     init 0.03
        aK1       init 100000


        awhite unirand 2.0
        awhite = awhite - 1.0
        apink  pinkish awhite, 1, 0, 0, 1

        aF = (aX * aX * aX) + aX + apink * 0.03
        aSub = aK1 * aF
        aForce = - 1 * aSub
        aAcc = aForce/aMass
        aVel = aVel + aAcc * idt
        aDisp = aVel * idt
        aX = aX + aDisp
        



        aout = aX * 0.01
        aout clip aout, -0.5, 0.5
        aout = 0.1 * aout
        outs aout, aout
    endin

</CsInstruments>

<CsScore>
; Duration, amplitude, frequency
i1 0 3600 0.005 220
</CsScore>

</CsoundSynthesizer>