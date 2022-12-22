//
//  main.m
//  aucmp
//
//  Created by Alan Smith on 17/12/2022.
//

#import <Foundation/Foundation.h>
#import "AS_Controller.h"

NSInteger ProcessArg(NSArray *args,NSMutableDictionary *params,NSInteger idx)
{
    NSString *arg = args[idx];
    if ([arg isEqual:@"-v"])
    {
        params[VERBOSE_KEY] = @YES;
        return idx + 1;
    }
    if ([arg isEqual:@"-x"])
    {
        if (++idx == [args count])
            return idx;
        arg = args[idx];
        float f = [arg floatValue];
        params[MAX_THRESHOLD_KEY] = @(f);
        return idx + 1;
    }
    if ([arg isEqual:@"-v"])
    {
        if (++idx == [args count])
            return idx;
        arg = args[idx];
        float f = [arg floatValue];
        params[AVG_THRESHOLD_KEY] = @(f);
        return idx + 1;
    }
    printf("unknown parameter %s\n",[arg UTF8String]);
    return idx;
}

NSArray *ProcessArgs(NSArray *args)
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray *files = [NSMutableArray array];
    NSInteger idx = 0;
    while (idx < [args count])
    {
        NSString *arg = args[idx];
        if ([arg hasPrefix:@"-"])
            idx = ProcessArg(args,params,idx);
        else
        {
            [files addObject:arg];
            idx++;
        }
    }
    return @[params,files];
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 3)
        {
            printf("Usage aucmp [-v] [-x MAX_THRESHOLD] [-g AVG_THRESHOLD] file1 file2\n");
        }
        else
        {
            NSMutableArray *args = [NSMutableArray array];
            for (int i = 1;i < argc;i++)
                [args addObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding]];
            NSArray *result = ProcessArgs(args);
            NSArray *files = result[1];
            NSDictionary *params = result[0];
            AS_Controller *cont = [[AS_Controller alloc]initWithFiles:files params:params];
            [cont processFiles];
            [cont finishUp];
        }

    }
    return 0;
}
