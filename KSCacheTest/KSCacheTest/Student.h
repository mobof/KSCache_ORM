//
//  Student.h
//  KSCacheTest
//
//  Created by 熊清 on 2020/8/5.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Student : NSObject
@property (assign,nonatomic) int uid;
@property (strong,nonatomic) NSString *name;
@property (assign,nonatomic) int age;
@property (assign,nonatomic) float height;
@property (assign,nonatomic) double weight;
@end

NS_ASSUME_NONNULL_END
