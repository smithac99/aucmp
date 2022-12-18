//
//  AS_Controller.m
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import "AS_Controller.h"
@import Accelerate;

@implementation AS_Controller

-(instancetype)initWithFiles:(NSArray<NSString*>*)files params:(NSArray<NSString*>*)params
{
    if (self = [super init])
    {
        if ([files count] < 2)
            return nil;
        NSFileManager *fm = [[NSFileManager alloc]init];
        NSString *fn = files[0];
        if (![fm fileExistsAtPath:fn])
        {
            printf("%s does not exist",[fn UTF8String]);
            return nil;
        }
        afile1 = [[AS_AudioFile alloc]initWithPath:fn controller:self];
        fn = files[1];
        if (![fm fileExistsAtPath:fn])
        {
            printf("%s does not exist",[fn UTF8String]);
            return nil;
        }
        afile2 = [[AS_AudioFile alloc]initWithPath:fn controller:self];
    }
    return self;
}

-(BOOL)processFiles
{
    BOOL success = [afile1 openFile];
    if (!success)
        return success;
    success = [afile2 openFile];
    if (!success)
        return success;
    success = [afile1 readFile];
    if (!success)
        return success;
    success = [afile2 readFile];
    if (!success)
        return success;
    success = [self compareFiles];
    if (!success)
        return success;
    return success;
}

-(BOOL)compareFiles
{
    if (afile1.noFrames != afile2.noFrames)
    {
        printf("No match - Number of frames differ");
        return NO;
    }
    if (afile1.noChannels != afile2.noChannels)
    {
        printf("No match - Number of channels differ");
        return NO;
    }
    Float32 **audioData1 = [afile1 audioData];
    Float32 **audioData2 = [afile2 audioData];
    Float32 one = 1;
    Float32 *buf1 = (Float32*)malloc(afile1.noFrames * sizeof(Float32));
    Float32 *buf2 = (Float32*)malloc(afile1.noFrames * sizeof(Float32));
    Float32 maxDiff = 0;
    CGFloat totDiff = 0;
    for (int i = 0;i < afile1.noChannels;i++)
    {
        vDSP_vsbsm(audioData1[i], 1, audioData2[i], 1, &one, buf1, 1, afile1.noFrames);
        vDSP_vabs(buf1, 1, buf2, 1, afile1.noFrames);
        Float32 thismax = 0;
        vDSP_maxv(buf2, 1, &thismax, afile1.noFrames);
        if (thismax > maxDiff)
            maxDiff = thismax;
        
        Float32 sum;
        vDSP_sve(buf2, 1, &sum, afile1.noFrames);
        totDiff += sum;
    }
    Float32 avg = totDiff / (afile1.noFrames * afile1.noChannels);
    if (maxDiff == 0 && avg == 0)
        printf("Exact match");
    else
        printf("Partial match - Max difference: %g Avg difference: %g\n",maxDiff,avg);
    return YES;
}

-(void)finishUp
{
    if (_verbose)
    {
        printf("%s",[afile1.log UTF8String]);
        printf("%s",[afile2.log UTF8String]);
    }
}
@end
