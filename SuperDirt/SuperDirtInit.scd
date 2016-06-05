include("SuperDirt");

(
s.options.numBuffers = 1024 * 16;
s.options.memSize = 8192 * 16;
s.options.maxNodes = 1024 * 32;
s.options.numOutputBusChannels = 2;
s.options.numInputBusChannels = 2;
s.waitForBoot {
    ~dirt = SuperDirt(2, s);
    ~dirt.loadSoundFiles;
    s.sync;
    ~dirt.start(57120, [0, 0]);
}
)

/*
d1 $ sound "[sn bd sn*2 bd, cy drum:1, drum:2]" |+| bandf "1500 1332 881" |+| bandq "80"
*/

// start modulating the bandpass filter
(
SynthDef("dirt_bpf" ++ ~dirt.numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	bandqf = bandqf * SinOsc.kr(XLine.kr(1, 30, Rand(0.2, 0.3)), Rand(0, 2pi), 0.1, 1);
	bandq = max(bandq, 1.0);
	signal = BPF.ar(signal, bandqf, 1/bandq) * bandq;
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)

// make it a chord and cursor position dependent
(
SynthDef("dirt_bpf" ++ ~dirt.numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	var freq = bandqf * SinOsc.kr(XLine.kr(1, 30, Rand(0.2, 0.3)), Rand(0, 2pi), 0.1, 1);
	freq = freq * MouseY.kr(0.5, (1, 1.1 ..1.5), 1) ** MouseX.kr(0.5, 1.2);
	freq = max(freq, 1.0);
	signal = BPF.ar(signal, freq, 1/bandq).sum * bandq;
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)

// depend on a continuous node proxy
(
Ndef(\mod, {
	var x;
	x = SinOsc.kr(0.4, 0, 0.1, 1);
	x = x * SinOsc.kr(0.34 * (1..3)).range(0.5, (1, 1.1 ..1.5)) ** SinOsc.kr(0.32).range(0.5, 1.2);
});

SynthDef("dirt_bpf" ++ ~dirt.numChannels, { |out, bandqf = 440, bandq = 10|
	var signal = In.ar(out, ~dirt.numChannels);
	var freq = bandqf * Ndef.ar(\mod);
	freq = max(freq, 1.0);
	signal = BPF.ar(signal, freq, 1/bandq).sum * bandq;
	ReplaceOut.ar(out, signal)
}, [\ir, \ir, \ir]).add;
)

// define a bus you'll be using for routing

~bus = Bus.audio(s, numChannels:2); // assuming stereo, expand if needed

~d1.outBus = ~bus; // play into that bus.


/*
Now, playing patterns in d1 in tidal should be silent.
*/

// listen directly
(
Ndef(\x, {
	var dirt = InBus.ar(~bus, 2);
	dirt
}).play;

)

// resonant low pass filter controlled by cursor
(
Ndef(\x, {
	var dirt = InBus.ar(~bus, 2);
	RLPF.ar(dirt, MouseY.kr(30, 20000, 1), MouseX.kr(0.01, 1, 1))
}).play;
)

// ... and so on.




/*
cleaning up when you're done:
*/

~d1.outBus = 0;
~bus.free;




// algorave mastering, roughly according to
// https://mccormick.cx/news/entries/heuristic-for-algorave-mastering
(
~busses = ~dirt.orbits.collect { |each|
	var bus = Bus.audio(~dirt.server, ~dirt.numChannels);
	each.outBus = bus;
	bus
}
);

(
Ndef(\x, {
	var level = 2;
	var distortion = 10;
	var reverbFeedback = 0.1;
	var all = ~busses.collect { |each| InBus.ar(each, each.numChannels) };
	var mix = all.sum { |x|
		var d = { 0.01.rand } ! x.size;
		DelayN.ar(x, d, d)
	};
	var loop = LocalIn.ar(~dirt.numChannels);
	5.do { loop = AllpassL.ar(loop, 0.15, { ExpRand(0.03, 0.15) } ! 2, 3) };
	mix = loop * reverbFeedback + mix;
	mix = LeakDC.ar(mix);
	LocalOut.ar(mix);
	mix = Compander.ar(mix, mix, 0.3, slopeBelow:1, slopeAbove:0.5, clampTime:0.01, relaxTime:0.01);
	mix = (mix * distortion).tanh * (level / distortion.max(1));
	mix
}).play;
);



/*
cleaning up when you're done:
*/
(
Ndef(\x).clear;
~busses.do { |x| x.free };
~dirt.orbits.do { |x| x.outBus = 0 };
);

/*

How to add new effects to Tidal and SuperDirt.

This is a three step process.

1. add the desired parameters to Tidal, so it can be used
2. add a module definition to Superdirt, so it can be found when the parameter is not nil
3. add the synth def to SuperDirt, so it can be played


The following example adds a weird spectral delay
This assumes you have an instance of SuperDirt accessible via ~dirt

*/


// in Haskell

// (1) in  Sound/Tidal/Params.hs
// this adds two new  parameters "tsdelay" (float, delay time) and "xsdelay" (int, delay structure)

/*

tsdelay :: Pattern Double -> ParamPattern
tsdelay = make' VF tsdelay_p
tsdelay_p = F "tsdelay" Nothing

xsdelay :: Pattern Int -> ParamPattern
xsdelay = make' VI xsdelay_p
xsdelay_p = I "xsdelay" Nothing

*/

// ... or you can run this in the interpreter:
/*

let tsdelay = make' VF tsdelay_p
    tsdelay_p = F "tsdelay" Nothing

let xsdelay = make' VI xsdelay_p
    xsdelay_p = I "xsdelay" Nothing
*/



// in SuperCollider

// (2) add a module for superdirt
// this adds a responder for the parameter
// for more examples see synths/core-modules

(
~dirt.addModule('spectral-delay', { |dirtEvent|
	dirtEvent.sendSynth('spectral-delay' ++ ~dirt.numChannels,
		// OPTIONAL
		// passing this array of parameters could be left out,
		// but it makes it clear what happens
		[
			xsdelay: ~xsdelay,
			tsdelay: ~tsdelay,
			sustain: ~sustain,
			out: ~out
		]
	)
}, { ~sdelay.notNil or: { ~xsdelay.notNil } }); // play synth only if at least one of the two was given
)

// here you can see the effect order:
~dirt.modules;

// OPTIONAL: you can reorder the effects, if you want e.g. the lpf to come after the delay:
~dirt.orderModules(['spectral-delay', 'hpf', 'klm']);


// (3) make a synthdef (for more examples see core-synths)
(

var numChannels =  ~dirt.numChannels;

SynthDef("spectral-delay" ++ numChannels, { |out, tsdelay, xsdelay = 1, sustain|

	var signal, delayTime, delays, freqs, filtered;
	var size = 16;
	var maxDelayTime = 0.2;

	signal = In.ar(out, numChannels);
	delayTime = tsdelay * maxDelayTime;
	filtered = (1..size).sum { |i|
		var filterFreq = i.linexp(1, size, 40, 17000);
		var sig = BPF.ar(signal, filterFreq, 0.005);
		// the delay pattern is determined from xsdelay by bitwise-and:
		DelayN.ar(sig, maxDelayTime, i & xsdelay * (1/size) * delayTime )
	};
	signal = signal * 0.2 + (filtered * 4); // this controls wet/dry
	ReplaceOut.ar(out, signal)

}).add;
)

/*

now you should be able to write in tidal:

d1 $ sound "can*4" # tsdelay "0 0.25 0.5 0.75 1" # xsdelay "3 124 3 12 62 2"



*/
o