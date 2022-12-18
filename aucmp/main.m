//
//  main.m
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import <Foundation/Foundation.h>
#import "AS_Controller.h"

NSArray *ProcessArgs(NSArray *args)
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray *files = [NSMutableArray array];
    NSInteger idx = 0;
    while (idx < [args count])
    {
        NSString *arg = args[idx];
        if ([arg isEqual:@"-v"])
            params[arg] = @YES;
        else
            [files addObject:arg];
        idx++;
    }
    return @[params,files];
}
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3)
        {
            printf("Usage aucmp [-v] file1 file2\n");
        }
        else
        {
            NSMutableArray *args = [NSMutableArray array];
            for (int i = 1;i < argc;i++)
                [args addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
            NSArray *result = ProcessArgs(args);
            NSArray *files = result[1];
            NSDictionary *params = result[0];
            AS_Controller *cont = [[AS_Controller alloc]initWithFiles:files params:result[1]];
            if (params[@"-v"])
                cont.verbose = YES;
            [cont processFiles];
            [cont finishUp];
        }

    }
    return 0;
}
