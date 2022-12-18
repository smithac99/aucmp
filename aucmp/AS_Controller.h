//
//  AS_Controller.h
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import <Foundation/Foundation.h>
#import "AS_AudioFile.h"


@interface AS_Controller : NSObject
{
    AS_AudioFile *afile1,*afile2;
}
@property BOOL verbose;

-(instancetype)initWithFiles:(NSArray<NSString*>*)files params:(NSArray<NSString*>*)params;
-(BOOL)processFiles;
-(void)finishUp;

@end

