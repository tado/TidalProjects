SuperDirt.start;

(
SynthDef("testsynth1", {
	arg out;
	var sound = SinOsc.ar(440.0);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, 0.5));
}).add;

/*
d1 $ s "testsynth1"
*/


SynthDef("testsynth2", {
	arg out, sustain=1, pan;
	var env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01, 1,-3), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(440.0);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

/*
d1 $ s "testsynth2*2" # sustain "0.2" # pan "0 1"
*/


SynthDef("testsynth3", {
	arg out, sustain=1, pan, accelerate, freq;
	var env = EnvGen.ar(Env.linen(0.01, 0.98, 0.01, 1, -3), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(freq * Line.kr(1,1+accelerate, sustain));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

/*
d1 $ s "testsynth3*2" # sustain "0.2" # pan "0 1" # note "30 42"
*/


SynthDef("testsynth4", {
	arg out, sustain=1, pan, accelerate, freq;
	var env = EnvGen.ar(Env.perc(0.001, 0.999, 1, -4), timeScale:sustain, doneAction:2);
	var sound = SinOsc.ar(freq * Line.kr(1,1+accelerate, sustain));
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;


/*
d1 $ s "testsynth4*2" # sustain "0.5" # pan "0 1" # note "30 42"
*/


SynthDef("super808", {
	arg out, speed=1, sustain=1, pan, voice=0, n;
	var env, sound, freq;
	n = ((n>0)*n) + ((n<1)*3);
	freq = (n*10).midicps;
	env = EnvGen.ar(Env.linen(0.01, 0, 1, 1, -3), timeScale:sustain, doneAction:2);
	sound = LPF.ar(SinOscFB.ar(XLine.ar(100*freq, freq, 0.025/speed), voice), 9000);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env))
}).add;


/*
d1 $ s "super808*2" # sustain "0.5" # pan "0 1"
*/

/*
d1
$ jux (iter 8)
$ every 4 (gap 16)
$ every 6 (chop 8)
$ stack[
  s "super808*8" # sustain "0.5" # pan "1 0.5 0" # gain "1 0.5 0.75 0 1",
  s "testsynth4*8" # sustain "0.25" # pan "0 0.7 0.3 0.5 1" # note "52 40 47" # gain "1 0.5 0.8 1"
]
|+| vowel "e i a o u"
*/

SynthDef("supermoog", {
	arg out, sustain=1, pan, accelerate, freq;
	var env = EnvGen.ar(Env.perc(0.001, 0.999, 1, -4), timeScale:sustain, doneAction:2);
	var sound = MoogFF.ar(
        Pulse.ar([freq/4.0,freq/2.0], [0.4,0.6]),
        SinOsc.kr(LFNoise0.kr(0.42).range(0.001, 1.5)).range(20, 4000),
        0.85 * 4);
	OffsetOut.ar(out, DirtPan.ar(sound, ~dirt.numChannels, pan, env));
}).add;

/*
d1
$ jux (iter 4)
-- $ every 4 (gap 16)
-- $ every 6 (chop 8)
$ stack[
  s "super808*8" # sustain "0.5" # pan "1 0.5 0" # gain "1 0.5 0.75 0 1",
  up pat3 |=| sound "909:1",
  up pat2 |=| s "supermoog*4" # sustain "0.2" # n "-12 12" |+| vowel "a i u e o",
  up pat1 |=| s "supermoog*4" # sustain "0.3" # n "-7 12",
  up pat4 |=| s "supermoog*4" # sustain "0.4" # n "-12 0"
]
-- |+| vowel "a i u e o"
-- |+| delay "0.75" |+| delaytime "0.08 0.02 0.03" |+| delayfeedback "0.5"
*/

)