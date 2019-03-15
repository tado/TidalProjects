(
MIDIClient.init;

//~midiOut = MIDIOut.newByName("X18/XR18", "X18/XR18 MIDI 1");
~midiOut = MIDIOut.newByName("loopMIDI Port", "loopMIDI Port"); // substitute your own device here
~midiOut.latency = -0.55;

s.options.numAudioBusChannels = 1024 * 8;
// configure the sound server: here you could add hardware specific options
// see http://doc.sccode.org/Classes/ServerOptions.html
s.options.maxLogins = 8;
s.options.numBuffers = 1024 * 16 * 4; // increase this if you need to load more samples
s.options.memSize = 8192 * 16; // increase this if you get "alloc failed" messages
s.options.maxNodes = 1024 * 32; // increase this if you are getting drop outs and the message "too many nodes"
//s.options.numOutputBusChannels = 2; // set this to your hardware output channel size, if necessary
//s.options.numInputBusChannels = 2; // set this to your hardware input channel size, if necessary
// boot the server and start SuperDirt
s.waitForBoot {
	~dirt = SuperDirt(2, s); // two output channels, increase if you want to pan across more channels
	~dirt.start(57120, [0, 0, 0, 0, 0, 0,0,0,0,0
	]);   // start listening on port 57120, create ten orbits, each sending audio to channel 0. You can direct sounds to the orbits from tidal e.g. by: `# orbit "0 1 1"
    ~dirt.soundLibrary.addMIDI(\midi, ~midiOut);
	~dirt.loadSoundFiles;   // load samples (path containing a wildcard can be passed in)
	//~dirt.loadSoundFiles("/home/alex/SparkleShare/spicule/extra-samples/*");
	//~dirt.loadSoundFiles("/home/alex/SparkleShare/damu-samples/*");
	//~dirt.loadSoundFiles("/home/alex/SparkleShare/lucy/*");
	s.sync; // wait for samples to be read
	~dirt.startSendRMS(15);
}
)