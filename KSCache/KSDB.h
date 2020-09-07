//
//  KSDB.h
//  KSCache
//
//  Created by 熊清 on 2020/7/29.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum CONDITION_TYPE {
    CONDITION_TYPE_BESIDES,
    CONDITION_TYPE_EITHER,
} CONDITION_TYPE;

@interface NSArray (entity)

/**
 * @returned    json串
 */
- (NSString*_Nullable)jsonString;

@end

@interface NSDictionary (entity)

/**
 * @returned    json串
 */
- (NSString*_Nullable)jsonString;

/**
 * 将实体对象链表实例化为实体对象
 * @returned    实体对象
 */
- (NSObject*_Nullable)entity;

@end

@interface NSString (entity)

- (id _Nullable )jsonValue;

@end

@interface NSObject (entity)

/**
 * 实体类名
 * @returned    实体类名
 */
- (NSString*_Nonnull)className;

/**
 * 实体对象链表
 * @returned    实体(实体类名:实体(属性:值)链表)链表
 * @example     people:(name:"junny",age:"27",sex:"female")
 */
- (NSDictionary*_Nullable)entityDictionary;

/**
 * @returned    实体(属性:值)链表
 */
- (NSDictionary*_Nullable)dictionary;

@end

NS_ASSUME_NONNULL_BEGIN

@interface KSDB : NSObject

/**
 * 连接数据库，使用字符串密钥
 * @param dbPath    数据库文件路径
 * @param cipher    数据库加密的密码
 */
- (bool)openDB:(NSString*)dbPath withCipher:(NSString*)cipher;

/// 连接数据库，使用DATA密钥
/// @param dbPath 数据库文件路径
/// @param cipher 数据库加密的密码
- (bool)connectDB:(NSString*)dbPath withCipher:(NSData*)cipher;

/**
 * 关闭数据库
 */
- (bool)closeDB;

/**
 * 新增或更新数据
 * @param entity    需要新增或更新的实体对象
 * @explain 使用sqlite的replace语法,实体对象统一使用uuid作为唯一标识
 * @返回值:-1/数据保存或更新失败,0/数据更新成功,>0/数据保存成功
 */
-(int64_t)cacheEntity:(NSObject*)entity;

/**
 * 删除实例对象
 * @param entityClass  数据库表对象
 * @param conditions    条件组,可以是多个条件
 * @param type                是同时满足所有条件还是满足其中一个
 */
-(bool)removeEntity:(Class)entityClass
          condition:(NSDictionary*)conditions
               meet:(CONDITION_TYPE)type;

/**
 * 根据sql语句删除实例对象
 * @param entityClass   数据库表对象
 * @param sql                   查询条件sql语句
 */
-(bool)removeEntity:(Class)entityClass
               with:(NSString*)sql;
/**
 * 获取实例列表
 * @param entityClass   数据库表对象
 */
-(NSArray*)listEntity:(Class)entityClass;

/**
 * 获取实例列表
 * @param entityClass   数据库表对象
 * @param singleField   不重复出现的列
 */
-(NSArray*)listEntity:(Class)entityClass
          singleField:(NSString*)singleField;

/**
 * 根据条件获取实例列表
 * @param entityClass   数据库表对象
 * @param conditions     条件组,可以是多个条件
 * @param type                 是同时满足所有条件还是满足其中一个
 */
-(NSArray*)listEntity:(Class)entityClass
            condition:(NSDictionary*)conditions
                 meet:(CONDITION_TYPE)type;

/**
 * 根据条件获取实例列表
 * @param entityClass   数据库表对象
 * @param conditions     条件组,可以是多个条件
 * @param index               从哪条开始
 * @param number             取多少条数据
 */
-(NSArray*)listEntity:(Class)entityClass
            condition:(NSDictionary*)conditions
                 meet:(CONDITION_TYPE)type
                start:(int)index
                 step:(int)number;

/**
 * 根据条件获取实例列表
 * @param entityClass   数据库表对象
 * @param sql                   查询条件sql语句
 */
-(NSArray*)listEntity:(Class)entityClass
                 with:(NSString*)sql;

@end

NS_ASSUME_NONNULL_END
