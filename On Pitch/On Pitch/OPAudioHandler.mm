//
//  OPAudioHandler.m
//  On Pitch
//
//  Created by Foster Lockwood on 3/14/13.
//  Copyright (c) 2013 Tufts Dev Team. All rights reserved.
//

#import "OPAudioHandler.h"
#import "CAXException.h"
#import "CAStreamBasicDescription.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import "FFTBufferManager.h"
#import <stdio.h>

// These values should be in a more conventional location for a bunch of preprocessor defines in your real code
#define DBOFFSET -74.0
// DBOFFSET is An offset that will be used to normalize the decibels to a maximum of zero.
// This is an estimate, you can do your own or construct an experiment to find the right value
#define LOWPASSFILTERTIMESLICE .001
// LOWPASSFILTERTIMESLICE is part of the low pass filter and should be a small positive value

static const Float32 kDefaultPoleDist = 0.975f;

@interface OPRejectionFilter : NSObject

@property (assign) Float32 mY1;
@property (assign) Float32 mX1;

- (void)inplaceFilter:(Float32*)ioData withFrames:(UInt32)numFrames;
- (void)reset;

@end

@interface OPAudioHandler () {
    int32_t* fftDataBuffer;
    
    AudioUnit rioUnit;
    
    BOOL unitHasBeenCreated;
    
    CAStreamBasicDescription thruFormat;
    Float64 hwSampleRate;
    
    AURenderCallbackStruct inputProc;
}

@property (assign) BOOL hasNewFFTData;
@property (assign) BOOL hasLoadedFirstFFT;

@property (assign) NSUInteger fftLength;
@property (assign) float currentFFTMaxValue; // This is the largest magnitude (abs val)
@property (assign) NSUInteger currentFFTMaxIndex; // Index into this value ^^^
@property (assign) float currentMaxVolume;

@property (assign) FFTBufferManager* fftBufferManager;
@property (strong) OPRejectionFilter* dcFilter;

@end

@implementation OPAudioHandler
@synthesize fftDataBuffer = fftDataBuffer;

#pragma mark - Initialization

- (void)initMe {
    void* pointerToSelf = (__bridge void*)self;
    inputProc.inputProc = PerformThru;
	inputProc.inputProcRefCon = pointerToSelf;
    
    self.dcFilter = [[OPRejectionFilter alloc] init];
    
	try {
		// Initialize and configure the audio session
		XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, pointerToSelf), "couldn't initialize audio session");
        
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
		XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, propListener, pointerToSelf), "couldn't set property listener");
        
		Float32 preferredBufferSize = .005;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");
		
		UInt32 size = sizeof(hwSampleRate);
		XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
		
		XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
        
		XThrowIfError(SetupRemoteIO(rioUnit, inputProc, thruFormat), "couldn't setup remote i/o unit");
		unitHasBeenCreated = true;
        
		UInt32 maxFPS;
		size = sizeof(maxFPS);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
		
		self.fftBufferManager = new FFTBufferManager(maxFPS);
        fftDataBuffer = (int32_t*)(malloc(maxFPS/2 * sizeof(int32_t)));
        self.fftLength = maxFPS/2;
        
		XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
        
		size = sizeof(thruFormat);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &thruFormat, &size), "couldn't get the remote I/O unit's output client format");
		
		_running = 1;
	}
	catch (CAXException &e) {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		_running = 0;
	}
	catch (...) {
		fprintf(stderr, "An unknown error occurred\n");
		_running = 0;
	}
}

- (id)init {
    self = [super init];
    if (self) {
        [self initMe];
    }
    return self;
}

- (void)dealloc {
    if (self.fftBufferManager) {
        delete self.fftBufferManager;
    }
    if (fftDataBuffer) {
        free(fftDataBuffer);
    }
}


#pragma mark - Public Methods

- (void)refreshFFTData {
    if (self.fftBufferManager) {
        if (self.fftBufferManager->ComputeFFT(fftDataBuffer)) {
            self.fftLength = self.fftBufferManager->GetNumberFrames() / 2;
            self.hasNewFFTData = YES;
            self.hasLoadedFirstFFT = YES;
            
            // Get max value in FFT
            float maxValue = 0.0f;
            for (int i = 0; i < self.fftLength; i++) {
                float val = fabsf(fftDataBuffer[i]);
                if (val > maxValue) {
                    maxValue = val;
                    self.currentFFTMaxIndex = i;
                }
            }
            // printf("%d\n", self.currentFFTMaxIndex);
            self.currentFFTMaxValue = maxValue;
        } else {
            self.hasNewFFTData = NO;
            self.currentFFTMaxValue = 0.0f;
        }
    }
}

- (float)amplitudeOfFrequency:(float)freq {
    if (!fftDataBuffer || self.fftLength <= 0 || !self.hasLoadedFirstFFT) {
        return 0.0f;
    }
    
    float index_m = [self indexFromFrequency:freq];
    
    NSUInteger indexInMiddle = (NSUInteger)index_m;
    NSUInteger indexToLeft = indexInMiddle - 1;
    NSUInteger indexToRight = indexInMiddle + 1;
    
    float distToLeft = 1.0f - (index_m - indexToLeft) / 2.0f;
    float distToMiddle = 1.0f - (index_m - indexInMiddle) / 2.0f;
    float distToRight = 1.0f - (index_m - indexToRight) / 2.0f;
    
    int32_t middleVal = fftDataBuffer[indexInMiddle];
    int32_t leftVal = fftDataBuffer[indexToLeft];
    int32_t rightVal = fftDataBuffer[indexToRight];
    
    float avgVal = (fabsf(middleVal) * distToLeft +
                    fabsf(leftVal) * distToMiddle +
                    fabsf(rightVal) * distToRight) / 3.0f;
    
    if (self.currentFFTMaxValue > 0) {
        return avgVal / self.currentFFTMaxValue;
    } else {
        return 0.0f;
    }
}

- (float)frequencyFromIndex:(float)index {
    return index * (SAMPLES_PER_SECOND / (float)(self.fftLength) / 2.0f);
}

- (float)indexFromFrequency:(float)frequency {
    return frequency / (SAMPLES_PER_SECOND / (float)(self.fftLength) / 2.0f);
}

#pragma mark - Audio Unit Setup

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

#pragma mark - Audio Unit Callback

// Callback function for audio unit I/O
static OSStatus	PerformThru(
                            void						*inRefCon,
                            AudioUnitRenderActionFlags 	*ioActionFlags,
                            const AudioTimeStamp 		*inTimeStamp,
                            UInt32 						inBusNumber,
                            UInt32 						inNumberFrames,
                            AudioBufferList 			*ioData) {
    OPAudioHandler* THIS = (__bridge OPAudioHandler*)inRefCon;
    OSStatus err = AudioUnitRender(THIS->rioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
	Float32* samples = (Float32*)(ioData->mBuffers[0].mData);
    
	// Remove DC component
	for (UInt32 i = 0; i < ioData->mNumberBuffers; ++i) { // WHY THE PRE-INCREMENT? NO IDEA!
        [THIS.dcFilter reset];
        [THIS.dcFilter inplaceFilter:samples withFrames:inNumberFrames];
    }
	
    if (THIS.fftBufferManager != NULL) {
        if (THIS.fftBufferManager->NeedsNewAudioData())
            THIS.fftBufferManager->GrabAudioData(ioData);
    }

    THIS.currentMaxVolume = 0.0f;
    for (int i = 0; i < inNumberFrames; i++) {
        //Step 2: for each sample, get its amplitude's absolute value.
        Float32 absoluteValueOfSampleAmplitude = fabsf(samples[i]);
        if (absoluteValueOfSampleAmplitude > THIS.currentMaxVolume) {
            THIS.currentMaxVolume = absoluteValueOfSampleAmplitude;
        }
    }

	if (THIS.isMuted == YES) { SilenceData(ioData); }
	
	return err;
    
}

#pragma mark - Audio Session Interruption Listener

void rioInterruptionListener(void *inClientData, UInt32 inInterruption) {
	try {
        printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
        
        OPAudioHandler* THIS = (__bridge OPAudioHandler*)inClientData;
        
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
                  const void *            inData) {
	OPAudioHandler* THIS = (__bridge OPAudioHandler*)inClientData;
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		try {
            UInt32 isAudioInputAvailable;
            UInt32 size = sizeof(isAudioInputAvailable);
            XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioInputAvailable, &size, &isAudioInputAvailable), "couldn't get AudioSession AudioInputAvailable property value");
            
            if(THIS.isRunning && !isAudioInputAvailable)
            {
                XThrowIfError(AudioOutputUnitStop(THIS->rioUnit), "couldn't stop unit");
                THIS.running = false;
            }
            
            else if(!THIS.isRunning && isAudioInputAvailable)
            {
                XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
                
                if (!THIS->unitHasBeenCreated)	// the rio unit is being created for the first time
                {
                    XThrowIfError(SetupRemoteIO(THIS->rioUnit, THIS->inputProc, THIS->thruFormat), "couldn't setup remote i/o unit");
                    THIS->unitHasBeenCreated = true;
                    
                    UInt32 maxFPS;
                    size = sizeof(maxFPS);
                    XThrowIfError(AudioUnitGetProperty(THIS->rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
                    
                    THIS.fftBufferManager = new FFTBufferManager(maxFPS);
                    THIS->fftDataBuffer = (int32_t*)(malloc(maxFPS/2 * sizeof(int32_t)));
                    THIS->_fftLength = maxFPS/2;
                }
                
                XThrowIfError(AudioOutputUnitStart(THIS->rioUnit), "couldn't start unit");
                THIS.running = true;
            }
		} catch (CAXException e) {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
	}
}

#pragma mark - FFT Operations



#pragma mark - Audio Unit Helpers

inline SInt32 smul32by16(SInt32 i32, SInt16 i16) {
#if defined __arm__
	register SInt32 r;
	asm volatile("smulwb %0, %1, %2" : "=r"(r) : "r"(i32), "r"(i16));
	return r;
#else
	return (SInt32)(((SInt64)i32 * (SInt64)i16) >> 16);
#endif
}

inline SInt32 smulAdd32by16(SInt32 i32, SInt16 i16, SInt32 acc) {
#if defined __arm__
	register SInt32 r;
	asm volatile("smlawb %0, %1, %2, %3" : "=r"(r) : "r"(i32), "r"(i16), "r"(acc));
	return r;
#else
	return ((SInt32)(((SInt64)i32 * (SInt64)i16) >> 16) + acc);
#endif
}

inline float linearInterp(float valA, float valB, float fract) {
	return valA + ((valB - valA) * fract);
}

void SilenceData(AudioBufferList *inData) {
	for (UInt32 i=0; i < inData->mNumberBuffers; i++)
		memset(inData->mBuffers[i].mData, 0, inData->mBuffers[i].mDataByteSize);
}

@end

#pragma mark - Rejection Filter Implementation

@implementation OPRejectionFilter

- (void)inplaceFilter:(Float32*)ioData withFrames:(UInt32)numFrames {
    for (UInt32 i=0; i < numFrames; i++) {
        Float32 xCurr = ioData[i];
		ioData[i] = ioData[i] - self.mX1 + (kDefaultPoleDist * self.mY1);
        self.mX1 = xCurr;
        self.mY1 = ioData[i];
	}
}

- (void)reset {
    self.mY1 = self.mX1 = 0;
}

@end
