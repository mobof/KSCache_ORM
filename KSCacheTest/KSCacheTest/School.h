//
//  School.h
//  KSCacheTest
//
//  Created by 熊清 on 2020/8/5.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Grade.h"

NS_ASSUME_NONNULL_BEGIN

@interface School : NSObject
@property (assign,nonatomic) int uid;
@property (strong,nonatomic) NSString *name;
@property (assign,nonatomic) int level;
@property (strong,nonatomic) Grade *grade;
@end

NS_ASSUME_NONNULL_END
