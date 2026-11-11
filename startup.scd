/*
- startup.scd - SuperDirt & Multi-Massive XL (Orbit Effects + Preset Switching by # n)
- 起動時に実行されるのは SuperDirt の起動まで
- Massive XL はファイル下部の ( ) ブロックを手動で評価して読み込む
*/

// startup.scd の読み込み中であることを示すフラグ（ファイル末尾で false に戻す）
// 起動時はファイル全体が実行されるため、このフラグが true の間は下部のブロックは何もしない
~startupLoading = true;

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

	"*** SuperDirt is ready. Massive XL を使うときは startup.scd 下部のブロックを評価 ***".postln;
};


/*
==========================================================
Massive XL（手動で評価する）
- "SuperDirt is ready" と表示された後に、( ) の中にカーソルを置いて Cmd+Return で評価する
- 1. をもう一度評価すると、読み込み済みの Massive XL を解放してから読み込み直す（Cmd+. の後の復旧にも使える）

TidalCycles からの使い方
- d1 $ s "massive" # n "0" # note "c5"
- # n はプリセット番号。massive-presets フォルダの .vstpreset を名前順に並べた番号で、0 から始まる
  （数を超えると先頭に戻る。# n を省略すると 0 番）
- # note は音程
- Massive XL は3台あり、s "massive" はオービットで台が決まる（d1 → 1台目、d2 → 2台目、d3 → 3台目）
  d1〜d3 で別々のプリセットを同時に鳴らせる
- s "massive1" 〜 "massive3" と書くと、オービットに関係なく台を直接指定できる
- 番号と名前の対応は、下の「一覧表示」ブロックで確認できる
==========================================================
*/

// massive-presets フォルダを読み直して、プリセット番号（# n）と名前の対応を表示する
~massiveScanPresets = { |post = true|
	var files = PathName(Platform.userAppSupportDir +/+ "massive-presets").files
		.select { |f| f.extension == "vstpreset" }
		.sort { |a, b| a.fileName.toLower < b.fileName.toLower };
	~massivePresets = files.collect(_.fullPath);
	if (post) {
		if (files.isEmpty) { "*** massive-presets に .vstpreset がありません ***".warn };
		files.do { |f, i| "# n %: %".format(i, f.fileNameWithoutExtension).postln };
	};
	~massivePresets
};

// 1. Massive XL を読み込む
(
if (~startupLoading == true) {
	"*** Massive XL は startup.scd 下部のブロックを評価すると読み込まれます ***".postln;
} {
	fork({
		if (~dirt.isNil or: { s.serverRunning.not }) {
			"*** SuperDirt is not running. startup.scd で起動してから評価してください ***".warn;
		} {
			// 読み込み済みのホストがあれば解放する（Cmd+. 後などで既にないノードのエラーは表示しない）
			~massiveSynths.do { |x|
				x !? { s.sendBundle(nil, ['/error', -1], ['/n_free', x.nodeID], ['/error', -2]) };
			};
			~dirt.receiveAction = nil;
			s.sync;

			// =========================================================
			// Massive XL (VSTPlugin) Setup - Through SuperDirt Orbit Effects
			// =========================================================
			// オービットの dryBus に出力することで # room / # delay / # leslie が掛かる
			// # pan / # gain / # hpf / # bpf / # lpf は Massive XL 1台の出力全体に適用される
			SynthDef(\massiveHost, { |dryBus = 0, orbitIndex = 0, pan = 0, gain = 1,
				cutoff = 0, resonance = 0, hcutoff = 0, hresonance = 0, bandf = 0, bandq = 10|
				var sig = VSTPlugin.ar(nil, 2, id: \massive);
				var filtered;
				// 周波数が 0 のときはバイパスし、オン・オフはクロスフェードしてクリックを防ぐ
				// オフの間は直前の周波数を保持し、次にオンにしたときにそこから動かす
				var withFilter = { |in, freq, makeFilter|
					var on = freq.abs > 0;
					var f = Gate.kr(freq.abs, on).clip(20, SampleRate.ir / 2).lag(0.02);
					var mix = on.lag(0.02);
					(makeFilter.(in, f) * mix) + (in * (1 - mix))
				};
				// 発音中はオービットのモニターを起こす（エディタの鍵盤などイベントなしの発音用）
				SendReply.kr(
					Impulse.kr(4) * (Amplitude.kr(sig.abs.sum) > 0.0001),
					'/massiveWake',
					[0],
					orbitIndex
				);
				// SuperDirt のフィルタと同じ順番（hpf → bpf → lpf）・同じ計算で掛ける
				filtered = withFilter.(sig, hcutoff, { |in, f| RHPF.ar(in, f, hresonance.lag(0.02).linexp(0, 1, 1, 0.001)) });
				filtered = withFilter.(filtered, bandf, { |in, f|
					var q = max(1, bandq).lag(0.02);
					BPF.ar(in, f, 1 / q) * q
				});
				filtered = withFilter.(filtered, cutoff, { |in, f| RLPF.ar(in, f, resonance.lag(0.02).linexp(0, 1, 1, 0.001)) });
				// Balance2 は中央で -3dB になるため、直接出力のときと同じ音量に補正する
				Out.ar(dryBus, DirtPan.ar(filtered, ~dirt.numChannels, pan.lag(0.01), 2.sqrt * gain.lag(0.01)));
			}).add;
			s.sync;

			// 無音が続くと dirt_monitor は休止するので、出力に必要なものだけ再開する
			// （未設定の leslie や delay まで再開すると意図しないエフェクトが掛かる）
			OSCdef(\massiveWake, { |msg|
				~dirt.orbits[msg[2].asInteger].globalEffects.select(_.alwaysRun).do(_.resume);
			}, '/massiveWake', s.addr);

			~numMassives = 3; // Massive XL の台数（1台目 → orbit 0、2台目 → orbit 1 ...）
			~massiveSynths = Array.newClear(~numMassives);
			~massives = Array.newClear(~numMassives);
			// 台ごとの状態: 読み込み済みプリセットのパス、切り替えが終わる時刻、最後に鳴らす音の時刻
			~massivePresetState = Array.fill(~numMassives, { (ready: false, path: nil, busyUntil: 0, lastOnset: 0) });
			~massiveScanPresets.(false);

			VSTPlugin.search(s, dir: "/Library/Audio/Plug-Ins/VST3", action: {
				Routine({
					// play 内はイベントの環境で動くので ~ 変数を参照できない。ローカル変数に入れておく
					var num = ~numMassives;
					var controllers = ~massives, hostSynths = ~massiveSynths, states = ~massivePresetState;
					var hostOrbits = num.collect { |i| ~dirt.orbits[i] };
					var midiPlay = DirtEventTypes.midiEvent[\play];
					// プリセットの切り替えにかかる時間（秒）。この間に届いたノートは鳴らないので、切り替え直後の
					// ノートはここまで遅らせる。切り替え直後の音が抜けるときは大きくする
					var switchTime = 0.1;
					var makePlay, firstReady;

					num.do { |i|
						var name = "massive" ++ (i + 1);
						var cond = Condition.new;

						// オービットのエフェクトより先に処理されるよう SuperDirt グループの先頭に配置
						~massiveSynths[i] = Synth.head(
							~dirt.group,
							\massiveHost,
							[\dryBus, hostOrbits[i].dryBus.index, \orbitIndex, hostOrbits[i].orbitIndex]
						);
						s.sync;

						~massives[i] = VSTPluginController(~massiveSynths[i], id: \massive);

						~massives[i].open("Massive XL.vst3", editor: true, verbose: false, action: { |ctrl, ok|
							if (ok) {
								// 初期プリセット: 1台目に 0 番、2台目に 1 番 ... を読み込んでおく
								var path = if (~massivePresets.size > 0) { ~massivePresets.wrapAt(i) };
								"*** % successfully loaded! ***".format(name).postln;
								states[i][\ready] = true;
								if (path.notNil) {
									states[i][\path] = path;
									ctrl.readProgram(path, action: { |c, loaded|
										if (loaded) {
											"*** % loaded initial preset: % ***".format(name, PathName(path).fileNameWithoutExtension).postln;
										};
									});
								};
							} {
								"*** Failed to load % ***".format(name).warn;
							};
							cond.unhang;
						});
						cond.hang;
						0.2.wait;
					};

					// SuperDirt から呼ばれる再生処理。fixedIndex が nil のときはオービットで台を決める
					makePlay = { |fixedIndex|
						{
							var i = fixedIndex ?? { (~orbit ? 0).asInteger % num };
							var st = states[i];
							if (st[\ready]) {
								var ctrl = controllers[i], hostSynth = hostSynths[i], hostOrbit = hostOrbits[i];
								~midiout = ctrl.midi;

								// # vstid / # vstval: VSTパラメータ直接制御
								if (~vstid.notNil and: { ~vstval.notNil }) {
									ctrl.set(~vstid.asInteger, ~vstval.asFloat);
								};

								// ノートを含むイベントだけ反映する（CCだけのイベントで pan や gain を初期値に戻さない）
								if (~n != \none or: { ~note.notNil }) {
									var presets = topEnvironment[\massivePresets];
									var now = thisThread.seconds;
									var onset = now + (~latency ? 0);
									var path, switchAt;

									// # n のプリセットが今と違うときだけ読み込む（直前のノートが鳴り始めてから切り替える）
									if (presets.size > 0) {
										path = presets.wrapAt(if (~n == \none) { 0 } { ~n.asInteger });
									};
									if (path.notNil and: { path != st[\path] }) {
										switchAt = max(now, st[\lastOnset] + 0.01);
										st[\path] = path;
										st[\busyUntil] = switchAt + switchTime;
										hostOrbit.server.sendBundle(
											if (switchAt > now) { switchAt - now },
											ctrl.readProgramMsg(path)
										);
									};
									// 切り替え中のノートは鳴らないので、切り替えが終わるまで遅らせる
									onset = max(onset, st[\busyUntil]);
									st[\lastOnset] = max(st[\lastOnset], onset);
									~latency = onset - now;

									// # n はプリセット番号に使うので、音程は # note だけで決める
									if (~note.isNil) {
										~note = 0;
										~freq = (~octave * 12).midicps;
									};

									// MIDI送信と同時に # pan / # gain / # lpf / # room などをホストとオービットへ反映する
									hostOrbit.server.makeBundle(~latency, {
										hostOrbit.globalEffects.do { |fx| fx.set(currentEnvironment) };
										// # gain はサンプルと同じカーブで出力レベルに反映する
										// フィルタは指定がなければ 0（バイパス）、Q は SuperDirt と同じ既定値にする
										hostSynth.set(
											\pan, ~pan, \gain, pow(~gain.min(2) + ~overgain, 4),
											\cutoff, ~cutoff ? 0, \resonance, ~resonance ? 0,
											\hcutoff, ~hcutoff ? 0, \hresonance, ~hresonance ? 0,
											\bandf, ~bandf ? 0, \bandq, ~bandq ? 10
										);
									});
									// 二重に掛からないよう、ベロシティは # amp だけで決める
									~gain = 1.0;
									~overgain = 0.0;
								};
								midiPlay.value;
							};
						}
					};

					// SuperDirt に登録する: \massive はオービットで台が決まり、\massive1 〜 は台を直接指定する
					firstReady = states.detectIndex { |st| st[\ready] };
					if (firstReady.notNil) {
						~dirt.soundLibrary.addMIDI(\massive, controllers[firstReady].midi, (play: makePlay.(nil)));
						num.do { |i|
							if (states[i][\ready]) {
								~dirt.soundLibrary.addMIDI(("massive" ++ (i + 1)).asSymbol, controllers[i].midi, (play: makePlay.(i)));
							};
						};
						"*** All Massive XL instances are ready to play! ***".postln;
						~massiveScanPresets.value;
					};

					// 画面は1台目（massive1）だけ開く。他の台は ~massives[1].editor; や ~massives[2].editor; を評価すると開く
					~massives[0].editor;
				}).play(AppClock);
			});
		};
	}, AppClock);
};
);

// 2. Massive XL を解放する（SuperDirt はそのまま使える）
(
if (~startupLoading != true) {
	~massiveSynths.do { |x|
		x !? { s.sendBundle(nil, ['/error', -1], ['/n_free', x.nodeID], ['/error', -2]) };
	};
	~massiveSynths = nil;
	~massives = nil;
	~massivePresetState = nil;
	~dirt !? {
		~dirt.receiveAction = nil;
		~dirt.soundLibrary.freeSynths([\massive, \massive1, \massive2, \massive3]);
	};
	"*** Massive XL instances are freed ***".postln;
};
);


/*
 * Massive XL プリセット管理
 * - プリセットは massive-presets フォルダの .vstpreset。名前順に並べた番号が # n になる
 * - 順番を決めたいときは "00_bass" "01_lead" のように名前の先頭に番号を付ける
 */

// Massive XL の今の音をプリセットとして保存する（保存後に番号と名前の一覧を表示する）
(
if (~startupLoading != true) {
	var index = 0;       // massive1 → 0, massive2 → 1, massive3 → 2
	var name = "massive" ++ (index + 1); // 保存する名前（.vstpreset は自動で付く）。"bass01" など自由に付けられる
	var path = Platform.userAppSupportDir +/+ "massive-presets" +/+ name ++ ".vstpreset";
	~massives[index].writeProgram(path, { |ctrl, ok|
		if (ok) {
			"*** massive% saved: % ***".format(index + 1, path).postln;
			~massivePresetState[index][\path] = path; // この台は保存したプリセットを読み込み済みとして扱う
			~massiveScanPresets.value;
		} {
			"*** massive% could not save: % ***".format(index + 1, path).warn;
		};
	});
};
);

// Massive XL にプリセットを手動で読み込む（エディタで音を作るとき用。演奏中の切り替えは # n で行う）
(
if (~startupLoading != true) {
	var index = 0;       // massive1 → 0, massive2 → 1, massive3 → 2
	var name = "massive" ++ (index + 1); // 読み込む名前（.vstpreset は書かない）
	var path = Platform.userAppSupportDir +/+ "massive-presets" +/+ name ++ ".vstpreset";
	if (File.exists(path)) {
		~massives[index].readProgram(path, { |ctrl, ok|
			if (ok) {
				"*** massive% loaded: % ***".format(index + 1, path).postln;
				~massivePresetState[index][\path] = path; // この台は読み込んだプリセットを読み込み済みとして扱う
			} {
				"*** massive% could not load: % ***".format(index + 1, path).warn;
			};
		});
	} {
		"*** Preset not found: % ***".format(path).warn;
	};
};
);

// 保存済みの Massive XL プリセットを、番号（# n）と一緒に一覧表示する
(
if (~startupLoading != true) {
	~massiveScanPresets.value;
};
);

~startupLoading = false;
