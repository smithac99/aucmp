//
//  AS_Controller.h
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import <Foundation/Foundation.h>
#import "AS_AudioFile.h"

#define MAX_THRESHOLD_KEY @"maxthreshold"
#define AVG_THRESHOLD_KEY @"avgthreshold"
#define VERBOSE_KEY @"verbose"

@interface AS_Controller : NSObject
{
    AS_AudioFile *afile1,*afile2;
}
@property BOOL verbose;
@property float maxThreshold;
@property float avgThreshold;
@property Float32 avg;
@property CGFloat maxDiff;

-(instancetype)initWithFiles:(NSArray<NSString*>*)files params:(NSDictionary*)params;
-(BOOL)processFiles;
-(void)finishUp;

@end

