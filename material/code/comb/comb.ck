// feedforward: input, delay, output
adc => Gain node => dac;
// feedback from delay output back to input
node => Delay delay => Gain attenuation => node;

// amount of delay (in samples)
500 => float L;
// set delay
L::samp => delay.delay;
// radius R
.99999 => float R;
// set attenuation as function of R and L
Math.pow( R, L ) => attenuation.gain;

// time loop
while( true ) 1::second => now;