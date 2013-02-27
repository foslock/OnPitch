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

#ifndef On_Pitch_OPFFT_h
#define On_Pitch_OPFFT_h

#define SAMPLES_PER_SECOND 44100.0f

#include <Accelerate/Accelerate.h>

typedef struct _FFT_Object FFT_Object;

// Must be called before any FFT functions
FFT_Object* initializeWithMaxFFTSize(int log2n);
void destroyFTTObject(FFT_Object* fft);

// Input must be of size 'size' and output must be size*2
// It must also be in even-odd format before it's passed in
void performForwardFFT(FFT_Object* fft, COMPLEX* input, COMPLEX* output, int log2n);

float frequencyFromIndex(FFT_Object* fft, int index);
int indexFromFrequency(FFT_Object* fft, float freq);

#endif
