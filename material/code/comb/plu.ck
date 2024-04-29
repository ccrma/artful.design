// feedforward: input, delay, output
Noise noise => DelayL delay => dac;
// feedback from delay output back to input
delay => Gain attenuation => OneZero lowpass => delay;

// amount of delay (in samples)
100 => float L;
// set delay
L::samp => delay.delay;
// radius R
.99999 => float R;
// set attenuation as function of R and L
Math.pow( R, L ) => attenuation.gain;
// set for lowpass filter
-1 => lowpass.zero;

// begin noise as input
1 => noise.gain;
// let there be noise for one delay length
L::samp => now;
// cease fire
0 => noise.gain;

// advance time to let sound play and decay
(Math.log(.0001) / Math.log(R))::samp => now;

// message
<<< "done...", "" >>>;
