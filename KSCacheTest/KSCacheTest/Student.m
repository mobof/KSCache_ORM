//
//  Student.m
//  KSCacheTest
//
//  Created by 熊清 on 2020/8/5.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import "Student.h"

@implementation Student
- (NSString*_Nonnull)primaryKey{
    return @"uid";
}

- (NSString*_Nonnull)foreignKey{
    return nil;
}

- (BOOL)customize{
    return YES;
}
@end
