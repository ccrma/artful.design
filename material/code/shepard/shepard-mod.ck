//--------------------------------------------------------------------
// name: shepard-mod.ck
// desc: continuous shepard-risset tone generator; 
//       descending but can easily made to ascend
//
// author: Ge Wang (http://www.gewang.com/)
//   date: spring 2016
//--------------------------------------------------------------------

// pitch offset
0 => float OFFSET;
// mean for normal intensity curve
60+OFFSET => float MU;
// standard deviation for normal intensity curve
24 => float SD;
// normalize to 1.0 at x==MU
1 / gauss(MU, MU, SD) => float SCALE;
// increment per unit time (use negative for descending)
-.02 => float INC;
// unit time (change interval)
10::ms => dur T;

// starting pitches (in MIDI note numbers, octaves apart)
[ 12.0, 24, 36, 48, 60, 72, 84, 96, 108, 120 ] @=> float pitches[];
// number of tones
pitches.size() => int N;
// bank of tones
SinOsc tones[N];
// overall gain
Gain gain => dac; 10.0/N => gain.gain;
// connect to dac
for( int i; i < N; i++ ) { tones[i] => gain; }
// offset
for( int i; i < N; i++) { OFFSET +=> pitches[i]; }

// infinite time loop
while( true )
{
    for( int i; i < N; i++ )
    {
        // set frequency from pitch
        pitches[i] => Std.mtof => tones[i].freq;
        // compute loundess for each tone
        gauss( pitches[i], MU, SD ) * SCALE => float intensity;
        // map intensity to amplitude
        Math.pow(intensity,3) => tones[i].gain;
        // Math.pow(intensity*96 => Math.dbtorms,3) => tones[i].gain;
        // increment pitch
        INC +=> pitches[i];
        // wrap (for positive INC)
        // if( pitches[i] > 120+OFFSET ) 120 -=> pitches[i];
        // wrap (for negative INC)
        if( pitches[i] < 12+OFFSET )
        {
            // <<< "wrap", i, pitches[i], tones[i].gain() >>>;
            120 +=> pitches[i];
        }
    }
    
    // advance time
    T => now;
}

// normal function for loudness curve
// NOTE: chuck-1.3.5.3 and later: can use Math.gauss() instead
fun float gauss( float x, float mu, float sd )
{
    return (1 / (sd*Math.sqrt(2*pi))) 
           * Math.exp( -(x-mu)*(x-mu) / (2*sd*sd) );
}
