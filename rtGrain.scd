//bank of granular samplers for the monome

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////VARIABLES////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
(
~m = MonoM.new("/granulator", 0);
~m.useDevice(0);

~synths = Array.newClear(128);
~buffers = Array.newClear(128);

~firstKey = nil;
~secondPos = nil;
)

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////OSCDEFS//////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
(
OSCdef(\record,
	{
		arg grid;
		var pos = grid[1]+(grid[2]*16);

		if (~firstKey == nil)//if first key is pressed
		{
			~firstKey = grid;

			if (grid[3] == 1)//pressed
			{
				if ((grid[2] == 0) && (grid[1] >= 8) && (grid[1] < 15))//horizontal group
				{
					"horizontal ".post;
					~posToHGroup.value(grid).postln;
				};

				if ((grid[1] == 15) && (grid[2] > 0))//vertical group
				{
					"vertical ".post;
					~posToVGroup.value(grid).postln;
				};

				if ((grid[2] >= 1) && (grid[1] >= 8) && (grid[1] < 15))//element keys
				{
					"element ".post;
					~posToElement.value(grid).postln;
				};
			};

			if (grid[3] == 0)//released
			{
				~firstKey = nil;
			};
		};

		if (~firstKey != nil)//if second key is pressed
		{
			if (grid[3] == 1)//pressed
			{
				if ((~firstKey[2] == 0) && (~firstKey[1] >= 8) && (~firstKey[1] < 15))//horizontal group
				{
					if ((grid[1] == ~firstKey[1]) && (~firstKey[2] == (grid[2] + 1)))//horizontal volume (parameter)
					{
						"horizontal volume".postln;
					};
				};

				if ((~firstKey[1] == 15) && (~firstKey[2] > 0))//vertical group
				{
					if ((grid[2] == ~firstKey[2]) && (grid[1] == (~fistKey[1] - 1)))//vertical volume (parameter)
					{
					};
				};

				if ((~firstKey[2] >= 1) && (~firstKey[1] >= 8) && (~firstKey[1] < 15))//element keys
				{
					"element ".post;
					~posToElement.value(grid).postln;
				};
			};

			if (grid[3] == 0)//released
			{
			};
		};

	}, "/granulator/grid/key";
);
)

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////FUNCTIONS////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
(
~posToElement = //map gridposition to element index (for indexing arrays)
{
	arg grid;
	var x = grid[1] - 8, y = grid[2] - 1;

	((x)+(y*7));
};

~posToHGroup = //map gridposition to horizontal group index
{
	arg grid;

	(grid[1] - 8);
};

~posToVGroup = //map gridposition to vertical group index
{
	arg grid;

	(grid[2] -1);
};
)

///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////SYNTHDEFS////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////
(
SynthDef(\bufferRecord,
	{
		arg buf, inBus;

		RecordBuf.ar(SoundIn.ar(inBus), buf, 0, 0.5, 0.5);
	};
).add

SynthDef(\granulator,
	{
		arg amp = 0.8, out = 0, buf, centerPos = 0.5, dur = 0.1, rate = 10, playSpeed = 1, spray = 0.2;
		var bufDur = BufDur.kr(buf), pos, trigger, signal;

		//grain position relative to buffer length
		centerPos = bufDur * centerPos;
		//grain position + noise*spray
		pos = (centerPos + WhiteNoise.kr.range(((bufDur/2) * spray) * -1, (bufDur/2)*spray)).fold(0, 1);
		//trigger
		trigger = Dust.ar(rate);
		//output signal
		signal = GrainBuf.ar(1, trigger, dur, buf, playSpeed, pos, 2, pan, -1, mul: amp);

		Out.ar(out, signal);
	};
).add;
)