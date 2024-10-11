<CsoundSynthesizer>
<CsOptions>
-+rtmidi=alsa -Ma -odac -b 512 -B1024 
</CsOptions>

<CsInstruments>
sr = 44100
ksmps = 1
nchnls = 2; STEREO XD
0dbfs  = 1

    instr    1
        adel	init 0
        idelay  = p4 *.001			;Delay in ms

        apin init 0.5
        
        iProportion init 0.5

        adel delay apin, idelay;ifd = amount of feedback
        areso1 reson adel, 1300, 40
        areso2 reson adel, 600, 30
        areso3 reson adel, 1000, 50
        adel = 0.72 * adel + 0.00001 * (areso1 + areso2 + areso3)


        awhite unirand 2.0
        awhite = awhite - 1.0
        apink  pinkish awhite, 1, 0, 0, 1
        apink atone apink, 10

        apReed =  adel + 0.01 * apink
        apReed clip apReed, -1, 1
        apReed = 0.9 * sin(apReed * 3.14/2)
        apReed2 lowpass2 apReed, 6000, 1
        apin = 0.76 * apReed + 0.2 * apReed2
        outs    0.029 * apin, 0.03 * apin

    endin

</CsInstruments>

<CsScore>
; Duration, amplitude, frequency
i 1  0    5  15 
</CsScore>

</CsoundSynthesizer>