//
//  AS_AudioFile.h
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import <Foundation/Foundation.h>
@import CoreAudio;
@import CoreAudioTypes;

@import AudioToolbox;
@class AS_Controller;

#define MAX_CHANNELS 5

@interface AS_AudioFile : NSObject
{
    ExtAudioFileRef audioFileRef;
    NSString *path;
    __weak AS_Controller *controller;
    AudioStreamBasicDescription fileASBD,lpcmASBD;
    AudioFileID afID;
    Float32 *audioData[MAX_CHANNELS],*dataPosition[MAX_CHANNELS];
}

@property NSInteger noFrames;
@property int noChannels;
@property NSMutableString *log;

-(instancetype)initWithPath:(NSString*)filepath controller:(AS_Controller*)cont;
-(BOOL)openFile:(NSURL*)url;
-(BOOL)openFile;
-(BOOL)readFile;
-(Float32**)audioData;

@end

