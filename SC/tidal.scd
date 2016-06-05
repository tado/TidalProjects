//基本編
(
//単純な楽器の定義
SynthDef("scsine", {
    arg freq;
    var out, env;
    out = SinOsc.ar(freq).dup();
    env = EnvGen.ar(Env.perc(), doneAction:2);
    Out.ar(0, out*env);
}).add;
);

//応用編
(
// 1つ目の楽器 "schh" の定義
SynthDef("schh", {
    arg vol=1.2, freq=3000, atk=0.01, rel=0.2, pos=0;
    var  sig, rev, filt, env, pan, out;
    sig=WhiteNoise.ar(0.5);
    filt=RHPF.ar(sig, freq, LFDNoise3.kr(0.5).range(0.001, 2) );
    rev=FreeVerb.ar(filt, 0.7, 1);
    pan=Pan2.ar(rev, pos, vol);
    env=EnvGen.ar(Env.perc(atk, rel), doneAction:2);
    out=pan*env;
    Out.ar(0, out);
}).add;

// 2つ目の楽器 "scbass" の定義
SynthDef("scbass", {
    arg freq = 52.8, pos = 0.0, vol = 1.0;
    var bass =
    SinOsc.ar(0, (Sweep.ar(1.0, 2pi * [freq, 740]) + (pi/3)).wrap(-pi, pi), [2, 0.05]).mean.tanh *
    EnvGen.ar(Env([0, 0.5, 0.4, 0], [0, 0.2, 0.01], -5), doneAction: 2);
    bass = Pan2.ar(bass, pos) * vol;
    bass = CompanderD.ar(bass);
    Out.ar(0, bass);
}).add;
);