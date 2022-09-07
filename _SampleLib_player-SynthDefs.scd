// Sample Players SynthDefs

//  -----------------------------------------------------------
//  -----------------------------------------------------------
//  -----------------------------------------------------------
// MONO SynthDefs //-------------------------------------------



// synthdef to play a buffer. start: in seconds.
SynthDef(\simpsamp_m, { |out, buf, amp=0.1, rate = 1, pan=0, start|
    var snd = PlayBuf.ar(1,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, Pan2.ar(snd, pan, amp));
}).add;

SynthDef(\sampGrain, { |out, buf, amp=0.1, rate = 1, stretch=1, pan=0, ovlp = 6, trigrate=33, jitter=0.01|
    var bdur = BufDur.ir(buf);
    var trig = Dust.ar(trigrate);
    var pos  = Line.ar(0, bdur, bdur * stretch, doneAction: 2) + TRand.ar(jitter.neg, jitter, trig).madd(bdur);
    var snd  = TGrains.ar(2, trig, buf, rate, pos, trigrate.reciprocal*ovlp, pan, amp );
    OffsetOut.ar(out, snd);
}).add;
/*
(instrument: \sampGrain, buf: 134, amp: 1, rate: 1/1.2, stretch: 1.0, ovlp: 8).play; // grainy stretchhhhhh
*/
SynthDef(\simpsampGlitch, { |out, buf, amp=0.1, rate = 1, pan=0, start|
    var snd, blendMess = Line.kr(-2,2, BufDur.ir(buf)).clip(0, 1);

    rate = rate * blend(1, LFNoise1.kr(Rand(2, 30), 5, 1).clip2(1), blendMess);
    snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, Pan2.ar(snd, pan, amp));
}).add;

// synthdef to play a section from a buffer. start/end in seconds
SynthDef(\sampEnv_m, { |out, buf, amp=0.1, rate = 1, pan, start, sustain=0.8, fade=0.01|
    var fadeTime = min(fade, BufDur.ir(buf)/3);
    var snd = PlayBuf.ar(1,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2
    );
    var env = EnvGen.ar(Env.linen(fadeTime, sustain, fadeTime), doneAction: 2);
    OffsetOut.ar(out, Pan2.ar(snd * env, pan, amp))
}).add;

// Stereo SynthDefs //--------------------------------------
SynthDef(\simpsamp, { |out, buf, amp=0.1, rate = 1, start|
    var snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2, doneAction:2
    );
    OffsetOut.ar(out, snd * amp);
}).add;

SynthDef(\sampEnv, { |out, buf, amp=0.1, rate = 1, start, sustain=0.8, fade=0.01|
    var fadeTime = min(fade, BufDur.ir(buf)/3);
    var snd = PlayBuf.ar(2,
        buf, rate, 1,
        start * BufSampleRate.ir(buf),
        0, 2
    );
    var env = EnvGen.ar(Env.linen(fadeTime, sustain, fadeTime), doneAction: 2);
    OffsetOut.ar(out, snd * env * amp)
}).add;

(
SynthDef(\samp, { |out, bufnum = 0, sustain = 1, begin = 0, end = 1, speed = 1, endSpeed = 1, freq = 440, pan = 0, numChan = 2|

    var sound, rate, phase, sawrate, numFrames = 1, numChans = 2, chans;

    // playback speed
    rate = Line.kr(speed, endSpeed, sustain) * (freq / 60.midicps);

    // sample phase
    // BufSampleRate adjusts the rate if the sound file doesn't have the same rate as the soundcard

    numFrames = max(BufFrames.ir(bufnum), 1); // make sure it is > 0, when no file is read yet
    sawrate = rate * BufSampleRate.ir(bufnum) / (absdif(begin, end) * numFrames);
    phase = (speed.sign * LFSaw.ar(sawrate, 1)).range(begin, end) * numFrames;

    //phase =  Sweep.ar(1, rate * BufSampleRate.ir(bufnum)) + (BufFrames.ir(bufnum) * begin);
    sound = BufRd.ar(
        numChannels: bufnum.numChannels,
        bufnum: bufnum,
        phase: phase,
        loop: 0,
        interpolation: 4 // cubic interpolation
    );

    sound = PanAz.ar(
        numChans: s.options.numOutputBusChannels,
        in: DC.ar(0!2),
        pos: pan,
        level: 0.5,
        width: 3,
        orientation: 0.5
    );
    OffsetOut.ar(out, sound)
}).add;
);

"\n**** Play Samples with:".postString;
q.printPlayers = {[\simpsamp_m, \simpsamp, \sampGrain, \simpsampGlitch, \sampEnv_m, \sampEnv, \samp].do{|i|i.postln};''};
q.printPlayers;
"check it with q.printPlayers".postln;
'';

/// e.o. SynthDefs -----------------------------------------------------------
//  -----------------------------------------------------------
//  -----------------------------------------------------------
//  -----------------------------------------------------------