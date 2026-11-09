/*
- startup.scd - SuperDirt & Multi-Massive XL (Orbit Effects + Preset Switching)
*/

s = Server.local;

// 1. サーバーオプションの設定
s.options.numBuffers = 1024 * 256;
s.options.memSize = 8192 * 32;
// s.options.sampleRate = 48000;

// 2. リコンパイル時は古いノードを消去してクリーンにする
if (s.serverRunning) {
	s.freeAll;
};

s.waitForBoot {
	var midiout, addr;

	s.volume = -6.0;

	if (~dirt.notNil) { ~dirt.free };

	~dirt = SuperDirt(2, s);
	~dirt.loadSoundFiles;
	~dirt.loadSoundFiles(
		"/Users/tado/Library/Application Support/SuperCollider/samples-extra/*"
	);
	s.sync;

	~dirt.start(57120, 0!12);
	s.sync;
	0.5.wait;

	addr = NetAddr.new("localhost", 3333);
	OSCdef(\tidalplay, {
		arg msg;
		addr.sendMsg(*msg);
	}, '/dirt/play', n);

	// =========================================================
	// Massive XL (VSTPlugin) Setup - Through SuperDirt Orbit Effects
	// =========================================================
	// オービットの dryBus に出力することで # room / # delay / # leslie が掛かる
	// # pan と # gain は Massive XL 1台の出力全体に適用される
	SynthDef(\massiveHost, { |dryBus = 0, orbitIndex = 0, pan = 0, gain = 1|
		var sig = VSTPlugin.ar(nil, 2, id: \massive);
		// 発音中はオービットのモニターを起こす（エディタの鍵盤などイベントなしの発音用）
		SendReply.kr(
			Impulse.kr(4) * (Amplitude.kr(sig.abs.sum) > 0.0001),
			'/massiveWake',
			[0],
			orbitIndex
		);
		// Balance2 は中央で -3dB になるため、直接出力のときと同じ音量に補正する
		Out.ar(dryBus, DirtPan.ar(sig, ~dirt.numChannels, pan.lag(0.01), 2.sqrt * gain.lag(0.01)));
	}).add;
	s.sync;

	// 無音が続くと dirt_monitor は休止するので、出力に必要なものだけ再開する
	// （未設定の leslie や delay まで再開すると意図しないエフェクトが掛かる）
	OSCdef(\massiveWake, { |msg|
		~dirt.orbits[msg[2].asInteger].globalEffects.select(_.alwaysRun).do(_.resume);
	}, '/massiveWake', s.addr);

	~numMassives = 3;
	~massiveSynths = Array.newClear(~numMassives);
	~massives = Array.newClear(~numMassives);
	~currentPresets = Array.newClear(~numMassives); // 現在のプリセット番号を記録

	VSTPlugin.search(s, dir: "/Library/Audio/Plug-Ins/VST3", action: {
		Routine({
			~numMassives.do { |i|
				var synthName = ("massive" ++ (i + 1)).asSymbol;
				var hostOrbit = ~dirt.orbits[i]; // massive1 → orbit 0, massive2 → orbit 1 ...
				var cond = Condition.new;

				// オービットのエフェクトより先に処理されるよう SuperDirt グループの先頭に配置
				~massiveSynths[i] = Synth.head(
					~dirt.group,
					\massiveHost,
					[\dryBus, hostOrbit.dryBus.index, \orbitIndex, hostOrbit.orbitIndex]
				);
				s.sync;

				~massives[i] = VSTPluginController(~massiveSynths[i], id: \massive);

				~massives[i].open("Massive XL.vst3", editor: true, verbose: false, action: { |ctrl, ok|
					if (ok) {
						var defaultPreset = ("~/massive_preset_" ++ i ++ ".vstpreset").standardizePath;
						var midiPlay = DirtEventTypes.midiEvent[\play];
						var hostSynth = ~massiveSynths[i]; // play 内はイベントの環境で動くので ~ 変数を参照できない
						"*** % successfully loaded! ***".format(synthName).postln;

						// 1. SuperDirtにMIDIターゲットとして登録（\massive1, \massive2, \massive3）
						//    MIDI送信と同時に # pan / # gain / # room などをホストとオービットへ反映する
						~dirt.soundLibrary.addMIDI(synthName, ctrl.midi, (
							play: {
								// ノートを含むイベントだけ反映する（CCだけのイベントで pan や gain を初期値に戻さない）
								if(~n != \none or: { ~note.notNil }) {
									hostOrbit.server.makeBundle(~latency, {
										hostOrbit.globalEffects.do { |fx| fx.set(currentEnvironment) };
										// # gain はサンプルと同じカーブで出力レベルに反映する
										hostSynth.set(\pan, ~pan, \gain, pow(~gain.min(2) + ~overgain, 4));
									});
									// 二重に掛からないよう、ベロシティは # amp だけで決める
									~gain = 1.0;
									~overgain = 0.0;
								};
								midiPlay.value;
							}
						));

						// 2. 初期プリセット（~/massive_preset_0.vstpreset 等）があれば自動ロード
						if (File.exists(defaultPreset)) {
							~currentPresets[i] = i;
							ctrl.readProgram(defaultPreset, action: { |c, loaded|
								if (loaded) {
									"*** % loaded initial preset: % ***".format(synthName, defaultPreset).postln;
								};
							});
						};
					} {
						"*** Failed to load % ***".format(synthName).warn;
					};
					cond.unhang;
				});
				cond.hang;
				0.2.wait;
			};

			// イベント受信時のプリセット切り替え（# preset）とパラメータ制御（# vstid / # vstval）
			~dirt.receiveAction = { |event|
				~numMassives.do { |i|
					var synthName = ("massive" ++ (i + 1)).asSymbol;
					if (event[\s] == synthName) {
						// A. プリセットの動的切り替え（番号が変わったときだけ読み込む）
						if (event[\preset].notNil) {
							var pNum = event[\preset].asInteger;
							if (~currentPresets[i] != pNum) {
								var presetPath = ("~/massive_preset_" ++ pNum ++ ".vstpreset").standardizePath;
								if (File.exists(presetPath)) {
									~currentPresets[i] = pNum;
									~massives[i].readProgram(presetPath, action: { |c, ok|
										if (ok) {
											"*** % switched to preset % ***".format(synthName, pNum).postln;
										};
									});
								} {
									"*** Preset not found: % ***".format(presetPath).warn;
								};
							};
						};

						// B. VSTパラメータ直接制御
						if (event[\vstid].notNil and: { event[\vstval].notNil }) {
							~massives[i].set(event[\vstid].asInteger, event[\vstval].asFloat);
						};
					};
				};
			};

			"*** All Massive XL instances are ready to play! ***".postln;
			~massives[2].editor; // 1台目（massive1）の画面を開く
			~massives[1].editor; // 2台目（massive2）の画面を開く
			~massives[0].editor; // 3台目（massive3）の画面を開く
		}).play(AppClock);
	});
};