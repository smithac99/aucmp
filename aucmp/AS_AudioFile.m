//
//  AS_AudioFile.m
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import "AS_AudioFile.h"
#import "AS_Controller.h"

static AudioFormatFlags CalculateLPCMFlags(UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, BOOL inIsFloat, BOOL inIsBigEndian, BOOL inIsNonInterleaved)
{
    inIsNonInterleaved = NO;
    return (inIsFloat ? kAudioFormatFlagIsFloat : kAudioFormatFlagIsSignedInteger) | (inIsBigEndian ? ((UInt32)kAudioFormatFlagIsBigEndian) : 0) | ((inValidBitsPerChannel == inTotalBitsPerChannel) ? kAudioFormatFlagIsPacked : kAudioFormatFlagIsAlignedHigh) | (inIsNonInterleaved ? ((UInt32)kAudioFormatFlagIsNonInterleaved) : 0);
}

static AudioStreamBasicDescription FillOutASBDForLPCM(Float64 inSampleRate, UInt32 inChannelsPerFrame, UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, BOOL inIsFloat, BOOL inIsBigEndian, BOOL inIsNonInterleaved)
{
    inIsNonInterleaved = NO;
    AudioStreamBasicDescription outASBD;
    outASBD.mSampleRate = inSampleRate;
    outASBD.mFormatID = kAudioFormatLinearPCM;
    outASBD.mFormatFlags = CalculateLPCMFlags(inValidBitsPerChannel, inTotalBitsPerChannel, inIsFloat, inIsBigEndian, inIsNonInterleaved);
    outASBD.mBytesPerPacket = (inIsNonInterleaved ? 1 : inChannelsPerFrame) * (inTotalBitsPerChannel / 8);
    outASBD.mFramesPerPacket = 1;
    outASBD.mBytesPerFrame = (inIsNonInterleaved ? 1 : inChannelsPerFrame) * (inTotalBitsPerChannel / 8);
    outASBD.mChannelsPerFrame = inChannelsPerFrame;
    outASBD.mBitsPerChannel = inValidBitsPerChannel;
    return outASBD;
}

@implementation AS_AudioFile

-(instancetype)initWithPath:(NSString*)filepath controller:(AS_Controller*)cont
{
    if (self = [super init])
    {
        path = filepath;
        controller = cont;
        self.log = [[NSMutableString alloc]init];
        [self addToLog:path];
        for (int i = 0;i < MAX_CHANNELS;i++)
            audioData[i] = NULL;
    }
    return self;
}

-(void)dealloc
{
    for (int i = 0;i < _noChannels;i++)
        if (audioData[i])
            free(audioData[i]);
}

-(Float32**)audioData
{
    return audioData;
}

-(void)addToLog:(NSString*)s
{
    [self.log appendFormat:@"%@\n",s];
}

-(BOOL)openFile
{
    return [self openFile:[NSURL fileURLWithPath:path]];
}

-(BOOL)openFile:(NSURL*)url
{
    OSStatus err = ExtAudioFileOpenURL((__bridge CFURLRef)url,&audioFileRef);
    if (err)
    {
        NSLog(@"ExtAudioFileOpenURL %d",err);
        return NO;
    }
    UInt32 size = sizeof(fileASBD);
    err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_FileDataFormat, &size, &fileASBD);
    if (err)
    {
        NSLog(@"ExtAudioFileGetProperty kExtAudioFileProperty_FileDataFormat %d",err);
        return NO;
    }
    NSString *displayFormat = (NSString*)CFBridgingRelease(UTCreateStringForOSType(fileASBD.mFormatID));
    [self addToLog:[NSString stringWithFormat:@"Format: %@ Sample Rate: %g Channels: %d",displayFormat,fileASBD.mSampleRate,fileASBD.mChannelsPerFrame]];
    size = sizeof(afID);
    err = ExtAudioFileGetProperty(audioFileRef, kExtAudioFileProperty_AudioFile, &size, &afID);
    if (err)
    {
        NSLog(@"ExtAudioFileGetProperty kExtAudioFileProperty_AudioFile %d",err);
        return NO;
    }
    _noChannels = fileASBD.mChannelsPerFrame;
    lpcmASBD = FillOutASBDForLPCM(fileASBD.mSampleRate,fileASBD.mChannelsPerFrame,32,32,YES,NO,NO);
    size = sizeof(lpcmASBD);
    err = ExtAudioFileSetProperty(audioFileRef, kExtAudioFileProperty_ClientDataFormat, size, &lpcmASBD);
    if (err)
    {
        NSLog(@"ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat %d",err);
        return NO;
    }
    return YES;
}

-(BOOL)readFile
{
    SInt64 npackets;
    UInt32 size = sizeof(UInt64);
    OSStatus err = AudioFileGetProperty(afID, kAudioFilePropertyAudioDataPacketCount, &size, &npackets);
    if (err || npackets == 0)
        NSLog(@"get data packet count: err=%ld npackets=%qd\n", (long int)err,npackets);

    UInt64 frameUpperLimit = npackets * fileASBD.mFramesPerPacket;
    _noFrames = 0;
    UInt32 kSrcBufSize = 32768;
    char *srcBuffer[MAX_CHANNELS];
    for (int i = 0;i < lpcmASBD.mChannelsPerFrame;i++)
    {
        srcBuffer[i] = (char*)malloc(kSrcBufSize);
        audioData[i] = (Float32*)malloc(frameUpperLimit * lpcmASBD.mBytesPerFrame);
        dataPosition[i] = audioData[i];
    }
    AudioBufferList *fillBufList = (AudioBufferList*)calloc(1, sizeof(*fillBufList) + 1 *sizeof(fillBufList->mBuffers[0]));
    fillBufList->mNumberBuffers = lpcmASBD.mChannelsPerFrame;
    for (int i = 0;i < lpcmASBD.mChannelsPerFrame;i++)
    {
        fillBufList->mBuffers[i].mNumberChannels = 1;
        fillBufList->mBuffers[i].mDataByteSize = kSrcBufSize;
        fillBufList->mBuffers[i].mData = srcBuffer[i];
    }

    while (1)
    {
        UInt32 numFrames = (kSrcBufSize / lpcmASBD.mBytesPerFrame);
        OSStatus err = ExtAudioFileRead (audioFileRef, &numFrames, fillBufList);
        if (err)
            NSLog(@"ExtAudioFileRead %d",err);
        _noFrames += numFrames;
        if (numFrames)
        {
            [self processBuffer:srcBuffer noFrames:numFrames];
        }
        else
        {
            [self addToLog:[NSString stringWithFormat:@"No frames: %@",@(_noFrames)]];
            break;
        }
    }
    return YES;
}

-(void)processBuffer:(char**)bufferData noFrames:(UInt32)framesRead
{
    for (int i = 0;i < lpcmASBD.mChannelsPerFrame;i++)
    {
        char *srcBuffer;
        srcBuffer = (char*)bufferData[i];
        memcpy(dataPosition[i],srcBuffer,framesRead * sizeof(Float32));
        dataPosition[i] += framesRead;
    }
}

@end
