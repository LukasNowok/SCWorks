////////Synths////////
/////////////////////////////////////////////////////////////////////////////////////////////////////
///CARRIER OSCILLATOR
(
SynthDef(\osc,
	{
		arg freq, amp, firstFreqBus, firstAmpBus;
		var out, freqBus, ampBus, lag = 0.5;

		///creates an array of all buses to listen to (vertical line in routing matrix)0, 7, 14, 21...
		freqBus =
		In.ar(firstFreqBus, 1)+
		In.ar(firstFreqBus+7, 1)+
		In.ar(firstFreqBus+14, 1)+
		In.ar(firstFreqBus+21, 1)+
		In.ar(firstFreqBus+28, 1)+
		In.ar(firstFreqBus+35, 1)+
		In.ar(firstFreqBus+42, 1);

		ampBus =
		In.ar(firstAmpBus, 1)+
		In.ar(firstAmpBus+7, 1)+
		In.ar(firstAmpBus+14, 1)+
		In.ar(firstAmpBus+21, 1)+
		In.ar(firstAmpBus+28, 1)+
		In.ar(firstAmpBus+35, 1)+
		In.ar(firstAmpBus+42, 1);

		out = SinOsc.ar(Lag.kr(freq, lag)+freqBus, mul: Lag.kr(amp, lag)+ampBus);

		Out.ar(0, out);
	}
).add;

///ROUTING SYNTH
SynthDef(\routing,
	{
		arg inBus, outBus, amp;
		var lag = 0.5;

		Out.ar(outBus, In.ar(inBus)*Lag.kr(amp, lag));
	}
).add;

///MODULATORS
SynthDef(\sinMod,
	{
		arg freq, amp, outBus;
		var out, lag = 0.5;

		out = VarSaw.ar(Lag.kr(freq, lag), width: 0.2, mul: Lag.kr(amp, lag));

		Out.ar(outBus, out);
	}
).add;
)
Status API Training Shop Blog About
