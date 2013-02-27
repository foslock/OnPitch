//
//  OPFFT.c
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

/*
 Referenced from:
 
 http://developer.apple.com/library/ios/#documentation/Performance/Conceptual/vDSP_Programming_Guide/SampleCode/SampleCode.html#//apple_ref/doc/uid/TP40005147-CH205-CIAEJIGF
 
 */

#include <stdio.h>
#include <stdint.h>
#include <assert.h>
#include "OPFFT.h"

struct _FFT_Object {
    FFTSetup setup;
    int currentLog2n;
    COMPLEX_SPLIT middleManArray;
};

FFT_Object* initializeWithMaxFFTSize(int log2n) {
    FFT_Object* object = (FFT_Object*)malloc(sizeof(*object));
    object->setup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    object->currentLog2n = log2n;
    int size = 1 << log2n;
    object->middleManArray.realp = (float*)malloc(size/2 * sizeof(float));
    object->middleManArray.imagp = (float*)malloc(size/2 * sizeof(float));
    assert(object->setup);
    return object;
}

void destroyFTTObject(FFT_Object* fft) {
    if (fft) {
        vDSP_destroy_fftsetup(fft->setup);
        free(fft->middleManArray.realp);
        free(fft->middleManArray.imagp);
        free(fft);
    }
}

void performForwardFFT(FFT_Object* fft, COMPLEX* input, COMPLEX* output, int log2n) {
    assert(log2n <= fft->currentLog2n);
    int nOver2 = 1 << (log2n - 1);
    vDSP_ctoz(input, 2, &fft->middleManArray, 1, nOver2);
    vDSP_fft_zrip(fft->setup, &fft->middleManArray, 1, log2n, FFT_FORWARD);
    vDSP_ztoc(&fft->middleManArray, 1, output, 2, nOver2);
}

float frequencyFromIndex(FFT_Object* fft, int index) {
    return (float) index * (SAMPLES_PER_SECOND / (float)(1 << fft->currentLog2n) / 2.0f);
}

int indexFromFrequency(FFT_Object* fft, float freq) {
    return (int) (freq / (SAMPLES_PER_SECOND / (float)(1 << fft->currentLog2n) / 2.0f));
}