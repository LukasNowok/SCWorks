(
~m = MonoM.new("/monome", 0);
~m.useDevice(0);

//node groups for synth-arrays
~modGroup = Group.new;
~routingGroup = Group.after(~modGroup);
~oscGroup = Group.after(~routingGroup);

//arrays of buses
~inBuses = Array.fill(7, {Bus.audio(s, 1)}); //output of modulators
~outFreqBuses = Array.fill(49, {Bus.audio(s, 1)}); //frequency modulation
~outAmpBuses = Array.fill(49, {Bus.audio(s, 1)}); //amplitude modulation

//arrays of mod/osc/routing synths
~modSynths = Array.fill(7, {arg i; Synth(\sinMod, [\outBus, ~inBuses[i]], ~modGroup)});
~freqRoutingSynths = Array.fill(49, {arg i; Synth(\routing, [\inBus, ~inBuses[(i/7).floor], \outBus, ~outFreqBuses[i]], ~routingGroup)});
~ampRoutingSynths = Array.fill(49, {arg i; Synth(\routing, [\inBus, ~inBuses[(i/7).floor], \outBus, ~outAmpBuses[i]], ~routingGroup)});
~oscSynths = Array.fill(7, {arg i; Synth(\osc, [\firstFreqBus, ~outFreqBuses[i], \firstAmpBus, ~outAmpBuses[i]], ~oscGroup)});

//array of amplitudes/frequencies for all mods/oscs/routings
~modAmpArray = Array.fill(7, {0});
~modFreqArray = Array.fill(7, {0});
~oscAmpArray = Array.fill(7, {0});
~oscFreqArray = Array.fill(7, {0});
~ampRoutingArray = Array.fill(49, {0});
~freqRoutingArray = Array.fill(49, {0});

//index of currently selected element (osc/mod/matrix)
~modeIndex = 0;

//led state of frequency and amp mode
~freqState = Array.fill(8, {Array.newClear(8)});
~ampState = Array.fill(8, {Array.newClear(8)});

//gui window
~w = Window.new("shruti");
~w.front;

/////////////////////////////////////////////////////////////////////////////////////////////////////
OSCdef(\freqShruti,
	{
		arg mes;

		defer{//call defer to run on AppClock (to be able to call GUI objects)
			if(mes[3] == 1)//button ON
			{
				//modeswitch
				if((mes[1] == 0) && (mes[2] == 0))
				{
					//switch between modes by enabling the other and disabling the current
					"mode".postln;
					OSCdef(\ampShruti).enable;
					~m.ledset(0, 0, 1);
					OSCdef(\freqShruti).disable;
				};

				//osc
				if((mes[2] == 0) && (mes[1] > 0) && (mes[1] < 8))
				{
					~posToOsc.value(mes).postln; //osc index
					"oscFreq".postln;

					//assign ~modeIndex to change currently selected element
					~modeIndex = ~posToOsc.value(mes);

					//assign keyDownAction to change freq of osc
					~w.view.keyDownAction = ~oscFreq;
				};

				//mod
				if((mes[1] == 0) && (mes[2] > 0))
				{
					~posToMod.value(mes).postln; //mod index
					"modFreq".postln;

					//assign ~modeIndex to change currently selected element
					~modeIndex = ~posToMod.value(mes);
					//assign keyDownAction to change freq of mod
					~w.view.keyDownAction = ~modFreq;
				};

				//matrix
				if((mes[1] > 0) && (mes[2] > 0) && (mes[1] < 8) && (mes[2] < 8))
				{
					~posToMatrix.value(mes).postln; //matrix index
					"matrixFreq".postln;

					//assign ~modeIndex to change currently selected element
					~modeIndex = ~posToMatrix.value(mes);
					//assign keyDownAction to change amount (amp) of freqRouting
					~w.view.keyDownAction = ~freqMatrix;
				};
			};

			if(mes[3] == 0)//button OFF
			{
				///off///

				//assign empty keyDownAction to take no action
				~w.view.keyDownAction = ~void;
			};
		};

	}, "/monome/grid/key";
).enable;
/////////////////////////////////////////////////////////////////////////////////////////////////////
OSCdef(\ampShruti,
	{
		arg mes;

		defer{//call defer to run on AppClock (to be able to call GUI objects)
			if(mes[3] == 1)
			{
				//modeswitch
				if((mes[1] == 0) && (mes[2] == 0))
				{
					//switch between modes by enabling the other and disabling the current
					"mode".postln;
					OSCdef(\freqShruti).enable;
					~m.ledset(0, 0, 0);
					OSCdef(\ampShruti).disable;
				};

				//osc
				if((mes[2] == 0) && (mes[1] > 0) && (mes[1] < 8))
				{
					~posToOsc.value(mes); //osc index
					"oscAmp".postln;

					//assign ~modeIndex to change currently selected element
					~modeIndex = ~posToOsc.value(mes);
					//assign keyDownAction to change freq of mod
					~w.view.keyDownAction = ~oscAmp;
				};

				//mod
				if((mes[1] == 0) && (mes[2] > 0))
				{
					~posToMod.value(mes); //mod index
					"modAmp".postln;

					//assign ~modeIndex to change currently selected element
					~modeIndex = ~posToMod.value(mes);
					//assign keyDownAction to change freq of mod
					~w.view.keyDownAction = ~modAmp;
				};

				//matrix
				if((mes[1] > 0) && (mes[2] > 0) && (mes[1] < 8) && (mes[2] < 8))
				{
					~posToMatrix.value(mes); //matrix index
					"matrixAmp".postln;

					//assign ~modeIndex to change currently selected element
					~modeIndex = ~posToMatrix.value(mes);
					//assign keyDownAction to change freq of mod
					~w.view.keyDownAction = ~ampMatrix;
				};
			};

			if(mes[3] == 0)
			{
				///off///
			};
		};

	}, "/monome/grid/key";
).disable;

/////////////////////////////////////////////////////////////////////////////////////////////////////
///store grid-key state in array
~store =
{
	arg array, mes1, mes2, mes3;
	array.put([mes1,mes2], mes3);
};
///push stored state on grid
~push =
{
	arg state;
	64.do(
		{
			arg i;
			~m.levset(state.at((i/7).floor), state.at(i%8), state.at((i/8).floor).at(i%8));
		};
	);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////
//calculating matrix/osc/mod index from x/y position (mes as arguments)
~posToMatrix =
{
	arg mes;
	((mes[1]-1)+((mes[2]-1)*7));
};
~posToOsc =
{
	arg mes;
	(mes[1]-1);
};
~posToMod =
{
	arg mes;
	(mes[2]-1);
};

/////////////////////////////////////////////////////////////////////////////////////////////////////
//keyDownAction functions

//modFreq//////////////////////////
~modFreq =
{
	arg view, char, modifiers, unicode, keycode;
	var step = 1, value, ledLevel, highLimit = 1000;

	value = ~modFreqArray.at(~modeIndex);

	ledLevel = value.linlin(0, 100, 0, 15).clip(0, 15);

	case
	///rotation to right///
	{keycode == 18}
	{
		//increase value by step
		value = value+step;
		//change element in array
		~modFreqArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~modSynths.at(~modeIndex).set(\freq, value);
		//set grid led
		~m.levset(0, ~modeIndex+1, ledLevel);
	}
	///rotation to left///
	{keycode == 29}
	{
		//decrease value by step
		value = value-step;
		//change element in array
		~modFreqArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~modSynths.at(~modeIndex).set(\freq, value);
		//set grid led
		~m.levset(0, ~modeIndex+1, ledLevel);
	}
	///buttonpress
	{keycode == 19}
	{
		//set element in array to 0
		~modFreqArray.put(~modeIndex, 0);
		//set synth to 0
		~modSynths.at(~modeIndex).set(\freq, 0);
	};
	value.postln;
};
//modAmp//////////////////////////
~modAmp =
{
	arg view, char, modifiers, unicode, keycode;
	var step = 0.01, value, ledLevel, highLimit = 1.0;

	value = ~modAmpArray.at(~modeIndex);

	ledLevel = value.linlin(0, 1.0, 0, 15).clip(0, 15);

	case
	///rotation to right///
	{keycode == 18}
	{
		//increase value by step
		value = value+step;
		//change element in array
		~modAmpArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~modSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		~m.levset(0, ~modeIndex+1, ledLevel);
	}
	///rotation to left///
	{keycode == 29}
	{
		//decrease value by step
		value = value-step;
		//change element in array
		~modAmpArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~modSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		~m.levset(0, ~modeIndex+1, ledLevel);
	}
	///buttonpress
	{keycode == 19}
	{
		//set element in array to 0
		~modAmpArray.put(~modeIndex, 0);
		//set synth to 0
		~modSynths.at(~modeIndex).set(\amp, 0);
	};
	value.postln;
};
//oscFreq//////////////////////////
~oscFreq =
{
	arg view, char, modifiers, unicode, keycode;
	var step = 1, value, ledLevel, highLimit = 1000;

	value = ~oscFreqArray.at(~modeIndex);

	ledLevel = value.linlin(0, 100, 0, 15).clip(0, 15);

	case
	///rotation to right///
	{keycode == 18}
	{
		//increase value by linear step
		value = value+step;
		//change element in array
		~oscFreqArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~oscSynths.at(~modeIndex).set(\freq, value);
		//set grid led
		~m.levset(~modeIndex+1, 0, ledLevel);
	}
	///rotation to left///
	{keycode == 29}
	{
		//decrease value by linear step
		value = value-step;
		//change element in array
		~oscFreqArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~oscSynths.at(~modeIndex).set(\freq, value);
		//set grid led
		~m.levset(~modeIndex+1, 0, ledLevel);
	}
	///buttonpress
	{keycode == 19}
	{
		//set element in array to 0
		~modFreqArray.put(~modeIndex, 0);
		//set synth to 0
		~modSynths.at(~modeIndex).set(\freq, 0);
	};
	value.postln;
};
//oscAmp//////////////////////////
~oscAmp =
{
	arg view, char, modifiers, unicode, keycode;
	var step = 0.01, value, ledLevel, highLimit = 1.0;

	value = ~oscAmpArray.at(~modeIndex);

	ledLevel = value.linlin(0, 1.0, 0, 15).clip(0, 15);

	case
	///rotation to right///
	{keycode == 18}
	{
		//increase value by step
		value = value+step;
		//change element in array
		~oscAmpArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~oscSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		~m.levset(0, ~modeIndex+1, ledLevel);
	}
	///rotation to left///
	{keycode == 29}
	{
		//decrease value by step
		value = value-step;
		//change element in array
		~oscAmpArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~oscSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		~m.levset(0, ~modeIndex+1, ledLevel);
	}
	///buttonpress
	{keycode == 19}
	{
		//set element in array to 0
		~oscAmpArray.put(~modeIndex, 0);
		//set synth to 0
		~oscSynths.at(~modeIndex).set(\amp, 0);
	};
	value.postln;
};
//freqMatrix//////////////////////////
~freqMatrix =
{
	arg view, char, modifiers, unicode, keycode;
	var step = 1, value, ledLevel, highLimit = 1000;

	value = ~freqRoutingArray.at(~modeIndex);

	ledLevel = value.linlin(0, 1.0, 0, 15).clip(0, 15);

	case
	///rotation to right///
	{keycode == 18}
	{
		//increase value by step
		value = value+step;
		//change element in array
		~freqRoutingArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~freqRoutingSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		/////////////////////
	}
	///rotation to left///
	{keycode == 29}
	{
		//decrease value by step
		value = value-step;
		//change element in array
		~freqRoutingArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~freqRoutingSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		/////////////////////
	}
	///buttonpress
	{keycode == 19}
	{
		//set element in array to 0
		~ampRoutingArray.put(~modeIndex, 0);
		//set Synth
		~freqRoutingSynths.at(~modeIndex).set(\amp, 0);
	};
	value.postln;
};
//ampMatrix//////////////////////////
~ampMatrix =
{
	arg view, char, modifiers, unicode, keycode;
	var step = 0.01, value, ledLevel, highLimit = 1.0;

	value = ~ampRoutingArray.at(~modeIndex);

	ledLevel = value.linlin(0, 1.0, 0, 15).clip(0, 15);

	case
	///rotation to right///
	{keycode == 18}
	{
		//increase value by step
		value = value+step;
		//change element in array
		~ampRoutingArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~ampRoutingSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		/////////////////////
	}
	///rotation to left///
	{keycode == 29}
	{
		//decrease value by step
		value = value-step;
		//change element in array
		~ampRoutingArray.put(~modeIndex, value);
		//scale to exponential range
		value = (value.linexp(0, highLimit, 0.1, highLimit))-0.1;
		//set synth
		~ampRoutingSynths.at(~modeIndex).set(\amp, value);
		//set grid led
		/////////////////////
	}
	///buttonpress
	{keycode == 19}
	{
		//set element in array to 0
		~ampRoutingArray.put(~modeIndex, 0);
		//set Synth
		~ampRoutingSynths.at(~modeIndex).set(\amp, 0);
	};
	value.postln;
};
//empty Action//////////////////////////
~void =
{
};
)

~m.ledall(0);

(
~inBuses.free;
~outFreqBuses.free;
~outAmpBuses.free;
)