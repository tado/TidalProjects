SuperDirt.start

(
MIDIClient.init;
MIDIClient.list;
~midiOut = MIDIOut.newByName("LoopBe Internal MIDI", "LoopBe Internal MIDI");
~midiOut.latency = 0.0;
~dirt.soundLibrary.addMIDI(\midi, ~midiOut);
)