//
//  Grade.m
//  KSCacheTest
//
//  Created by 熊清 on 2020/8/5.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import "Grade.h"

@implementation Grade
- (NSString*_Nonnull)primaryKey{
    return @"uid";
}

- (NSString*_Nonnull)foreignKey{
    return @"student";
}

- (BOOL)customize{
    return YES;
}
@end
