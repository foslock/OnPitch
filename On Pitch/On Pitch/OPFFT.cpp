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

FFTObject::FFTObject(uint32_t maxFrames) {
    uint32_t log2n = log2f(maxFrames);
    this->setup = vDSP_create_fftsetup(log2n, FFT_RADIX2);
    this->currentMaxFrames = maxFrames;
    this->currentLog2n = log2n;
    this->middleManArray.realp = (float*)malloc(maxFrames/2 * sizeof(float));
    this->middleManArray.imagp = (float*)malloc(maxFrames/2 * sizeof(float));
    this->finalMagnitudes = (float*)malloc(maxFrames/2 * sizeof(float));
    bzero(this->finalMagnitudes, maxFrames * sizeof(float));
    assert(this->setup);
}

FFTObject::~FFTObject() {
    vDSP_destroy_fftsetup(this->setup);
    free(this->middleManArray.realp);
    free(this->middleManArray.imagp);
    free(this->finalMagnitudes);
    free(this);
}

void FFTObject::performForwardFFT(int32_t* audioBuffer, COMPLEX* output) {
    int log2n = this->currentLog2n;
    int nOver2 = this->currentMaxFrames / 2;
    
    vDSP_ctoz((COMPLEX*)audioBuffer, 2, &this->middleManArray, 1, nOver2);
    vDSP_fft_zrip(this->setup, &this->middleManArray, 1, log2n, FFT_FORWARD);
    vDSP_zvmags(&this->middleManArray, 1, this->finalMagnitudes, 1, this->currentMaxFrames);
    
    float fftMax = 0.0;
    vDSP_maxmgv(this->finalMagnitudes, 1, &fftMax, this->currentMaxFrames);
    
    // printf("Max: %f\n", fftMax);
    
    /*
    static int counter = 0;
    if (counter <= 0) {
        printf("Frames: %d, \n", this->currentMaxFrames);
        for (uint32_t i = 0; i < nOver2; i++) {
            printf("i: %d mag: %f\n", i, this->finalMagnitudes[i]);
        }
        counter = 100;
    } else {
        counter--;
    }
    */
    // vDSP_ztoc(&this->middleManArray, 1, output, 2, nOver2);
}

float FFTObject::frequencyFromIndex(int index) {
    return (float) index * (SAMPLES_PER_SECOND / (float)(1 << this->currentLog2n) / 2.0f);
}

int FFTObject::indexFromFrequency(float freq) {
    return (int) (freq / (SAMPLES_PER_SECOND / (float)(1 << this->currentLog2n) / 2.0f));
}