//
//  AppDelegate.m
//  KSCacheTest
//
//  Created by 熊清 on 2020/8/5.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import "AppDelegate.h"
#import "School.h"
#import <KSCache/KSDB.h>

@interface AppDelegate ()
@property (strong,nonatomic) KSDB *database;
@property (strong,nonatomic) School *school;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    Student *student = [[Student alloc] init];
    student.name = @"小明";
    student.uid = 101;
    student.age = 15;
    student.height = 155;
    student.weight = 55;
    
    Grade *grade = [[Grade alloc] init];
    grade.name = @"高一班";
    grade.uid = 1001;
    grade.level = 1;
    grade.student = student;
    
    _school = [[School alloc] init];
    _school.name = @"贺龙高级中学";
    _school.uid = 10001;
    _school.level = 1;
    _school.grade = grade;
    
    _database = [[KSDB alloc] init];
    if ([_database openDB:@"test" withCipher:@"123456"]) {
        [_database cacheEntity:_school];
    }
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
