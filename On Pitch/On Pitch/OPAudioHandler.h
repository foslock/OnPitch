//
//  OPAudioHandler.h
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

// This is a C++ clas that handles most of the dirty work
// involving the microphone. I tried to get keep all the memory
// dirty code (C++) away from the prettier Objective-C, so that's
// mostly why this class exists. It handles connecting the AudioUnit,
// the render callback of the output, and the processing of the FFT.
//

#ifndef __On_Pitch__OPAudioHandler__
#define __On_Pitch__OPAudioHandler__

#include <Foundation/Foundation.h>
#include <AudioToolbox/AudioToolbox.h>
#include "FFTBufferManager.h"
#include "CAStreamBasicDescription.h"

class DCRejectionFilter;

class AudioHandler {
public:
    AudioHandler();
    ~AudioHandler();
    
    // Refreshes the current FFT data
    void RefreshFFTData();
    
    // Gets the estimated amplitude of the given frequency
    float AmplitudeOfFrequency(float freq);
    
    // Transpose from freq to index and vice versa
    float FrequencyFromIndex(int index);
    float IndexFromFrequency(float freq);
    
    // Sets the private data member from the buffer manager
    void SetFFTDataWithLength(int32_t* fft_data, NSUInteger length);
    
    BOOL						mute;
    BOOL						unitIsRunning;
    BOOL						hasNewFFTData;
    FFTBufferManager*			fftBufferManager;
    DCRejectionFilter*          dcFilters;
    
    // Use this ptr to access the FFT data present
	SInt32*						fftData;
	unsigned					fftLength;
    
	AudioUnit					rioUnit;
	
	BOOL						unitHasBeenCreated;
    
	CAStreamBasicDescription	thruFormat;
	Float64						hwSampleRate;
	
	AURenderCallbackStruct		inputProc;
	
    // Don't access these directly
	int32_t*					l_fftData;
};

class DCRejectionFilter
{
public:
	DCRejectionFilter(Float32 poleDist = DCRejectionFilter::kDefaultPoleDist);
    
	void InplaceFilter(SInt32* ioData, UInt32 numFrames, UInt32 strides);
	void Reset();
    
protected:
	
	// Coefficients
	SInt16 mA1;
	SInt16 mGain;
    
	// State variables
	SInt32 mY1;
	SInt32 mX1;
	
	static const Float32 kDefaultPoleDist;
};

#endif /* defined(__On_Pitch__OPAudioHandler__) */
