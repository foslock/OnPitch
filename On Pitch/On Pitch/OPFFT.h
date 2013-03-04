//
//  OPFFT.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//


//
// This class is currently UNUSED.
// I originally thought using the vDSP code (in the Accelerate framework)
// would be the ideal, but there was Apple sample code that already did
// a FFT on mic input so I adapted that instead. It uses the rad2fft
// implementation.
//

#define SAMPLES_PER_SECOND 44100.0f

#include <CoreAudio/CoreAudioTypes.h>
#include <Accelerate/Accelerate.h>

class FFTObject {
public:
    FFTObject(uint32_t maxFrames);
    ~FFTObject();
    
    // Input must be of size 'size' and output must be size*2
    // It must also be in even-odd format before it's passed in
    void performForwardFFT(int32_t* audioBuffer, COMPLEX* output);
    
    float frequencyFromIndex(int index);
    int indexFromFrequency(float freq);
    
private:
    FFTSetup setup;
    uint32_t currentMaxFrames;
    uint32_t currentLog2n;
    COMPLEX_SPLIT middleManArray;
    float* finalMagnitudes;
};