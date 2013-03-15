//
//  OPAudioHandler.cpp
//  On Pitch
//
//  Created by Foster Lockwood on 2/26/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//


#include "OPAudioHandlerCPP.h"
#include "OPAudioHandler.h" // For #defines

#include <AudioUnit/AudioUnit.h>
#include <stdio.h>
#include "CAXException.h"
#include "CAStreamBasicDescription.h"

/*
#define FFT_LIST_LENGTH_SHRINK_FACTOR (1)

inline float linearInterp(float valA, float valB, float fract) {
	return valA + ((valB - valA) * fract);
}

#pragma mark - Setup RIO Audio Unit

int SetupRemoteIO(AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc, CAStreamBasicDescription& outFormat) {
    try {
		// Open the output unit
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;
		desc.componentSubType = kAudioUnitSubType_RemoteIO;
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);
		
		XThrowIfError(AudioComponentInstanceNew(comp, &inRemoteIOUnit), "couldn't open the remote I/O unit");
        
		UInt32 one = 1;
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one)), "couldn't enable input on the remote I/O unit");
        
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc)), "couldn't set remote i/o render callback");
		
        // set our required format - LPCM non-interleaved 32 bit floating point
        outFormat = CAStreamBasicDescription(44100, kAudioFormatLinearPCM, 4, 1, 4, 2, 32, kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved);
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat)), "couldn't set the remote I/O unit's output client format");
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat)), "couldn't set the remote I/O unit's input client format");
        
		XThrowIfError(AudioUnitInitialize(inRemoteIOUnit), "couldn't initialize the remote I/O unit");
	} catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return 1;
	} catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
		return 1;
	}
	
	return 0;
}

void SilenceData(AudioBufferList *inData)
{
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}

#pragma mark - Render IO Render Callback

// Callback function for input audio
static OSStatus	PerformThru(
                            void						*inRefCon,
                            AudioUnitRenderActionFlags 	*ioActionFlags,
                            const AudioTimeStamp 		*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList 			*ioData)
{
    AudioHandler* THIS = (AudioHandler*)inRefCon;
    OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
	
	// Remove DC component
	for(UInt32 i = 0; i < ioData->mNumberBuffers; ++i)
		THIS->dcFilters[i].InplaceFilter((Float32*)(ioData->mBuffers[i].mData), inNumberFrames);
	
	
    if (THIS->fftBufferManager == NULL) return noErr;
    
    if (THIS->fftBufferManager->NeedsNewAudioData())
        THIS->fftBufferManager->GrabAudioData(ioData);
    
	if (THIS->mute == YES) { SilenceData(ioData); }
	
	return err;
    
}

#pragma mark - Audio Session Interruption Listener

void rioInterruptionListener(void *inClientData, UInt32 inInterruption)
{
	try {
        printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
        
        AudioHandler *THIS = (AudioHandler*)inClientData;
        
        if (inInterruption == kAudioSessionEndInterruption) {
            // make sure we are again the active session
            XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active");
            XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
        }
        
        if (inInterruption == kAudioSessionBeginInterruption) {
            XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
        }
    } catch (CAXException e) {
        char buf[256];
        fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
    }
}

#pragma mark - Audio Session Property Listener

void propListener(	void *                  inClientData,
                  AudioSessionPropertyID	inID,
                  UInt32                  inDataSize,
                  const void *            inData)
{
	AudioHandler *THIS = (AudioHandler*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		try {
            UInt32 isAudioInputAvailable;
            UInt32 size = sizeof(isAudioInputAvailable);
            XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isAudioInputAvailable), "couldn't get AudioSession AudioInputAvailable property value");
            
            if(THIS->unitIsRunning && !isAudioInputAvailable)
            {
                XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
                THIS->unitIsRunning = false;
            }
            
            else if(!THIS->unitIsRunning && isAudioInputAvailable)
            {
                XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
                
                if (!THIS->unitHasBeenCreated)	// the rio unit is being created for the first time
                {
                    XThrowIfError(SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat), "couldn't setup remote i/o unit");
                    THIS->unitHasBeenCreated = true;
                    
                    THIS->dcFilters = new DCRejectionFilter[THIS->thruFormat.NumberChannels()];
                    
                    UInt32 maxFPS;
                    size = sizeof(maxFPS);
                    XThrowIfError(AudioUnitGetProperty(THIS->rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
                    
                    THIS->fftBufferManager = new FFTBufferManager(maxFPS/FFT_LIST_LENGTH_SHRINK_FACTOR);
                    THIS->l_fftData = new int32_t[maxFPS/(2*FFT_LIST_LENGTH_SHRINK_FACTOR)];
                }
                
                XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
                THIS->unitIsRunning = true;
            }

		} catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
	}
}

AudioHandler::AudioHandler() {
    this->inputProc.inputProc = PerformThru;
	this->inputProc.inputProcRefCon = this;
    
	try {
		// Initialize and configure the audio session
		XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, this), "couldn't initialize audio session");
        
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
		XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, this), "couldn't set property listener");
        
		Float32 preferredBufferSize = .005;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
		
		UInt32 size = sizeof(hwSampleRate);
		XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
		
		XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
        
		XThrowIfError(SetupRemoteIO(rioUnit, inputProc, thruFormat), "couldn't setup remote i/o unit");
		unitHasBeenCreated = true;
		
		dcFilters = new DCRejectionFilter[thruFormat.NumberChannels()];
        
		UInt32 maxFPS;
		size = sizeof(maxFPS);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
		
		fftBufferManager = new FFTBufferManager(maxFPS);
		l_fftData = new int32_t[maxFPS/2];
        fftData = (SInt32 *)(malloc(maxFPS * sizeof(SInt32)));
        fftLength = maxFPS;
        
		XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
        
		size = sizeof(thruFormat);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &thruFormat, &size), "couldn't get the remote I/O unit's output client format");
		
		unitIsRunning = 1;
	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		unitIsRunning = 0;
		if (dcFilters) delete[] dcFilters;
	}
	catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
		unitIsRunning = 0;
		if (dcFilters) delete[] dcFilters;
	}
    
}

AudioHandler::~AudioHandler() {
    if (dcFilters) {
        delete[] dcFilters;
    }
    if (fftBufferManager) {
        delete fftBufferManager;
    }
    if (fftData) {
        free(fftData);
    }
    if (l_fftData) {
        free(l_fftData);
    }
}

void AudioHandler::RefreshFFTData() {
    if (fftBufferManager) {
        if (fftBufferManager->ComputeFFT(l_fftData)) {
            int length = fftBufferManager->GetNumberFrames() / 2;
            this->SetFFTDataWithLength(l_fftData, length);
        } else {
            hasNewFFTData = NO;
        }
    }
}

float AudioHandler::AmplitudeOfFrequency(float freq) {
    if (!fftData || fftLength <= 0 || !hasLoadedFirstFFT) {
        return 0.0f;
    }
    
    float index_m = this->IndexFromFrequency(freq);
    // float index_l = (int)index_m;
    // float fract = (index_m - index_l);
    
    // Find where the REAL index lies between the two on either side
    
    CGFloat yFract = (CGFloat)index_m / (CGFloat)(fftLength - 1);
    CGFloat fftIdx = CLAMP(yFract * ((CGFloat)fftLength), 0, fftLength);
    
    double fftIdx_i, fftIdx_f;
    fftIdx_f = modf(fftIdx, &fftIdx_i);
    
    SInt8 fft_l, fft_r;
    CGFloat fft_l_fl, fft_r_fl;
    CGFloat interpVal;
    
    fft_l = (fftData[(int)fftIdx] & 0xFF000000) >> 24;
    fft_r = (fftData[(int)fftIdx + 1] & 0xFF000000) >> 24;
    fft_l_fl = (CGFloat)(fft_l + 100);
    fft_r_fl = (CGFloat)(fft_r + 100);
    interpVal = fft_l_fl * (1. - fftIdx_f) + fft_r_fl * fftIdx_f;
    // interpVal = linearInterp(fft_l_fl, fft_r_fl, fract);
    return interpVal;
}

float AudioHandler::FrequencyFromIndex(int index) {
    return (float) index * (SAMPLES_PER_SECOND / (float)(this->fftLength) / 2.0f);
}

float AudioHandler::IndexFromFrequency(float freq) {
    return (freq / (SAMPLES_PER_SECOND / (float)(this->fftLength) / 2.0f));
}

void AudioHandler::SetFFTDataWithLength(int32_t* FFTDATA, NSUInteger LENGTH) {
    if (LENGTH != fftLength)
	{
		fftLength = LENGTH;
		fftData = (SInt32 *)(realloc(fftData, LENGTH * sizeof(SInt32)));
	}
	memmove(fftData, FFTDATA, fftLength * sizeof(Float32));
	hasNewFFTData = YES;
    hasLoadedFirstFFT = YES;
}

inline SInt32 smul32by16(SInt32 i32, SInt16 i16)
{
#if defined __arm__
	register SInt32 r;
	asm volatile("smulwb %0, %1, %2" : "=r"(r) : "r"(i32), "r"(i16));
	return r;
#else
	return (SInt32)(((SInt64)i32 * (SInt64)i16) >> 16);
#endif
}

inline SInt32 smulAdd32by16(SInt32 i32, SInt16 i16, SInt32 acc)
{
#if defined __arm__
	register SInt32 r;
	asm volatile("smlawb %0, %1, %2, %3" : "=r"(r) : "r"(i32), "r"(i16), "r"(acc));
	return r;
#else
	return ((SInt32)(((SInt64)i32 * (SInt64)i16) >> 16) + acc);
#endif
}

const Float32 DCRejectionFilter::kDefaultPoleDist = 0.975f;

DCRejectionFilter::DCRejectionFilter(Float32 poleDist) {
	Reset();
}

void DCRejectionFilter::Reset() {
	mY1 = mX1 = 0;
}

void DCRejectionFilter::InplaceFilter(Float32* ioData, UInt32 numFrames) {
	for (UInt32 i=0; i < numFrames; i++) {
        Float32 xCurr = ioData[i];
		ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1);
        mX1 = xCurr;
        mY1 = ioData[i];
	}
}
*/
