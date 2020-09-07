//
//  KSDB.m
//  KSCache
//
//  Created by 熊清 on 2020/7/29.
//  Copyright © 2020 格尔软件. All rights reserved.
//

#import "KSDB.h"
#import <objc/runtime.h>
#import <SQLCipher/sqlite3.h>

@implementation NSArray (entity)

- (NSString*)jsonString{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return jsonData?[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]:@"";
}

- (id)jsonValue{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return jsonData?[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]:@"";
}

@end

@implementation NSDictionary (entity)

- (NSString*)jsonString{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return jsonData?[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]:@"";
}

- (id)jsonValue{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:nil];
    return jsonData?[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]:@"";
}

- (NSObject*)entity{
    //非实体转化的字典对象
    if (self.allKeys.count > 1 || self.allKeys.count == 0) {
        return self.jsonString;
    }
    if (self.allValues.count > 0 && ![self.allValues.firstObject isKindOfClass:NSDictionary.class]) {
        return self.jsonString;
    }
    Class object_class = NSClassFromString(self.allKeys.firstObject);
    NSObject *object = [[object_class alloc] init];
    NSDictionary *object_dictionary = [self objectForKey:self.allKeys.firstObject];
    [object_dictionary.allKeys enumerateObjectsUsingBlock:^(NSString *property, NSUInteger idx, BOOL *stop) {
        SEL selector = NSSelectorFromString(property);
        if ([object respondsToSelector:selector]) {
            id value = [object_dictionary objectForKey:property];
            NSLog(@"%@",value);
            //以下为标准对象
//            [object setValue:value?([value jsonValue]?([[value jsonValue] isKindOfClass:[NSDictionary class]]?[[value JSONValue] entity]:[value JSONValue]):value):@"" forKeyPath:property];
        }
    }];
    return object;
}

@end

@implementation NSString (entity)

- (id)jsonValue{
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization isValidJSONObject:jsonData]?(jsonData?[NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil]:nil):nil;
}

@end

@implementation NSObject (category)

- (NSDictionary*)entityDictionary{
    return @{self.className:self.dictionary};
}

-(NSString*)className{
    return [NSString stringWithUTF8String:object_getClassName(self)];
}

- (NSDictionary*)dictionary{
    if ([self isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary*)self;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:0];
    [[self propertys] enumerateObjectsUsingBlock:^(id property, NSUInteger idx, BOOL *stop) {
//        SEL selector = NSSelectorFromString(property);
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//        id value = [self performSelector:selector];
//#pragma clang diagnostic pop
        id object = [self valueForKey:property];
//        if ([object customize]) {
//            object = [self valueForKey:property];
//        }
        [dict setObject:object?([object isKindOfClass:[NSArray class]] || [object isKindOfClass:[NSDictionary class]]?[object jsonValue]:object):@"" forKey:property];
    }];
    return dict;
}

- (NSArray *)propertys{
    NSMutableArray *propertys = [NSMutableArray arrayWithCapacity:0];
    if ([self isKindOfClass:NSDictionary.class]) {
        return [(NSDictionary*)self allKeys];
    }
    //实体对象属性集合
    u_int count;
    objc_property_t *properties  = class_copyPropertyList(self.class, &count);
    for (int i = 0; i < count ; i++){
        const char* propertyName = property_getName(properties[i]);
        [propertys addObject: [NSString stringWithUTF8String: propertyName]];
    }
    free(properties);
    return propertys;
}

- (NSString*)getForeignKey {
    SEL selector = NSSelectorFromString(@"foreignKey");
    if ([self respondsToSelector:selector]) {
        return [self performSelector:selector];
    }
    return nil;
}

- (NSString*)getPrimaryKey {
    SEL selector = NSSelectorFromString(@"primaryKey");
    if ([self respondsToSelector:selector]) {
        return [self performSelector:selector];
    }
    return nil;
}

- (BOOL)isCustomize {
    SEL selector = NSSelectorFromString(@"customize");
    if ([self respondsToSelector:selector]) {
        return [self performSelector:selector];
    }
    return NO;
}

/// 建表SQL
- (NSString*)sqlWithCreateTable {
    //1.组装建表SQL
    NSString *foreignKey = [self getForeignKey];
    NSString *primaryKey = [self getPrimaryKey];
    //1.1.开始建表语句
    NSMutableString *sql = [NSMutableString stringWithCapacity:0];
    [sql appendFormat:@"CREATE TABLE IF NOT EXISTS %@ (",self.className];
    [self.propertys enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if (idx > 0) {
            [sql appendString:@","];
        }
//        [sql appendFormat:@"%@ %@",key,[key isEqualToString:foreignKey] || [key isEqualToString:primaryKey]?@"INTEGER":@"NVERCHAR"];
        [sql appendFormat:@"%@ NVERCHAR",key];
    }];
    //1.2.判断实体是否提供了外键
//    if(foreignKey && foreignKey.length > 0) {
//        [sql appendFormat:@",FOREIGN KEY(%@)",foreignKey];
//    }
    //1.3.判断实体是否提供了主键
    if (primaryKey && primaryKey.length > 0) {
        [sql appendFormat:@",PRIMARY KEY(%@)",primaryKey];
    }
    //1.4.结束建表语句
    [sql appendString:@")"];
    return sql;
}

/// 返回实体对象插表SQL以及实体对象中实体属性
- (NSArray*)sqlWithInsertData {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0];
    NSMutableString *sql = [NSMutableString stringWithCapacity:0];
    [sql appendFormat:@"REPLACE INTO %@(",self.className];
    NSMutableString *values = [NSMutableString stringWithCapacity:0];
    [self.dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (values.length > 0) {
            [sql appendString:@","];
            [values appendString:@","];
        }
        [sql appendString:key];
        if ([obj isCustomize]) {//自定义类，缓存数据库
            NSString *primaryKey = [obj getPrimaryKey];
            if (primaryKey && primaryKey.length > 0) {
                [values appendFormat:@"'%@'",[obj valueForKey:primaryKey]];
                [arr addObject:obj];
            }else{
                [values appendFormat:@"'%@'",[obj dictionary]];
            }
        }else{
            [values appendFormat:@"'%@'",obj];
        }
    }];
    [sql appendFormat:@") VALUES(%@);",values];
    [arr insertObject:sql atIndex:0];
    return arr;
}

//- (Class)classWithProperty:(NSString*)pro {
//    objc_property_t property_c = class_getProperty(self.class, [property UTF8String]);
//    NSString *attributes = [NSString stringWithCString:property_getAttributes(property_c) encoding:NSUTF8StringEncoding];
//    if ([attributes hasPrefix:@"T@"]) {
//        NSArray *substrings = [attributes componentsSeparatedByString:@"\""];
//        if ([substrings count] >= 2) {
//
//        } else {
//
//        }
//    } else if ([attributes hasPrefix:@"T{"]) {
//
//    } else {
//        if ([attributes hasPrefix:@"Ti"]) {//int
//            value = [NSNumber numberWithInt:value];
//        } else if ([attributes hasPrefix:@"TI"]) {//unsigned
//            value = [NSNumber numberWithUnsignedInt:value];
//        } else if ([attributes hasPrefix:@"Ts"]) {//short
//
//        } else if ([attributes hasPrefix:@"Tl"]) {//long
//
//        } else if ([attributes hasPrefix:@"TL"]) {//unsigned long
//
//        } else if ([attributes hasPrefix:@"Tq"]) {//long long
//
//        } else if ([attributes hasPrefix:@"TQ"]) {//unsigned long long
//
//        } else if ([attributes hasPrefix:@"TB"]) {//bool
//
//        } else if ([attributes hasPrefix:@"Tf"]) {//float
//
//        } else if ([attributes hasPrefix:@"Td"]) {//double
//
//        } else if ([attributes hasPrefix:@"Tc"]) {//char
//
//        } else if ([attributes hasPrefix:@"T^i"]) {//int *
//
//        } else if ([attributes hasPrefix:@"T^I"]) {//unsigned *
//
//        } else if ([attributes hasPrefix:@"T^s"]) {//short *
//
//        } else if ([attributes hasPrefix:@"T^l"]) {//long *
//
//        } else if ([attributes hasPrefix:@"T^q"]) {//long long *
//
//        } else if ([attributes hasPrefix:@"T^Q"]) {//unsigned long long *
//
//        } else if ([attributes hasPrefix:@"T^B"]) {//bool *
//
//        } else if ([attributes hasPrefix:@"T^f"]) {//float *
//
//        } else if ([attributes hasPrefix:@"T^d"]) {//double *
//
//        } else if ([attributes hasPrefix:@"T*"]) {//char *
//
//        } else {
//            NSAssert(0, @"Unkonwn type");
//        }
//    }
//}

@end

#define DOC_PATH    NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES)[0]
@interface KSDB(){
    sqlite3 *database;
}
@end
@implementation KSDB
#pragma mark - | Public interface
#pragma mark -连接数据库
- (bool)openDB:(NSString*)dbPath withCipher:(NSString*)cipher{
    NSString *dbName;
    if ([dbPath hasPrefix:DOC_PATH]) {
        if ([dbPath hasSuffix:@".db"]) {
            dbName = dbPath;
        }else{
            dbName = [dbPath stringByAppendingString:@".db"];
        }
    }else{
        if ([dbPath hasSuffix:@".db"]) {
            dbName = [DOC_PATH stringByAppendingPathComponent:dbPath];
        }else{
            dbName = [DOC_PATH stringByAppendingPathComponent:[dbPath stringByAppendingString:@".db"]];
        }
    }
    int success;
    success = sqlite3_open(dbName.UTF8String, &database);
    if (success == SQLITE_OK) {
        if (cipher && cipher.length > 0){
            NSData *keyData = [NSData dataWithBytes:cipher.UTF8String length:(NSUInteger)strlen(cipher.UTF8String)];
            success = sqlite3_key(database, keyData.bytes, (int)keyData.length);
            if (![self openSuccess]) {
                success = -1;
            }
        }
    }else{
        sqlite3_close(database);
    }
    return (success == SQLITE_OK);
}

- (bool)connectDB:(NSString*)dbPath withCipher:(NSData*)cipher {
    NSMutableString *dbName = [NSMutableString stringWithCapacity:0];
    if ([dbPath hasPrefix:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0]]) {
        if ([dbPath hasSuffix:@".db"]) {
            [dbName appendString:dbPath];
        }else{
            [dbName appendString:[dbPath stringByAppendingString:@".db"]];
        }
    }else{
        if ([dbPath hasSuffix:@".db"]) {
            [dbName appendString:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:dbPath]];
        }else{
            [dbName appendString:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0] stringByAppendingPathComponent:[dbPath stringByAppendingString:@".db"]]];
        }
    }
    int success;
    success = sqlite3_open(dbName.UTF8String, &database);
    if (success == SQLITE_OK) {
        if (cipher && cipher.length > 0){
            success = sqlite3_key(database, cipher.bytes, (int)cipher.length);
            if (![self openSuccess]) {
                success = -1;
            }
        }
    }else{
        sqlite3_close(database);
    }
    return (success == SQLITE_OK);
}

- (bool)openForeignKey {
    int success = SQLITE_OK;
    NSString *sql = @"PRAGMA foreign_keys = ON";
    sqlite3_stmt *stmt;
    success = sqlite3_prepare_v2(database, [sql UTF8String], -1, &stmt, NULL);
    sqlite3_step(stmt);
    return (success == SQLITE_OK);
}

#pragma mark -断开连接数据库
- (bool)closeDB{
    int success = SQLITE_OK;
    if (database) {
        success = sqlite3_close(database);
        database = nil;
    }
    return (success == SQLITE_OK);
}

#pragma mark -保存数据
- (sqlite_int64)cacheEntity:(NSObject*)entity{
    //1.创建或升级数据库表
    sqlite_int64 ret = [self createOrUpgradeTable:entity];
    if (ret != SQLITE_OK) {
        NSLog(@"创建数据表或升级数据表结构失败,%@",[self lastErrorMessage]);
        return ret;
    }
    //2.保存数据
    NSArray *array = [entity sqlWithInsertData];
    ret = sqlite3_exec(self->database, [array.firstObject UTF8String], NULL, NULL, NULL);
    if (ret != SQLITE_OK) {
        NSLog(@"保存数据失败:%@ \n原因:%@",array.firstObject,[self lastErrorMessage]);
        return ret;
    }
    //3.保存实体属性
    if (array.count > 1) {
        for (int i = 1; i < array.count; i++) {
            [self cacheEntity:array[i]];
        }
    }
    ret = sqlite3_last_insert_rowid(self->database);
    return ret;
}

#pragma mark -根据条件删除数据
-(bool)removeEntity:(Class)entityClass
          condition:(NSDictionary*)conditions
               meet:(CONDITION_TYPE)type{
    NSMutableString *sql = [NSMutableString stringWithCapacity:0];
    if (conditions) {
        [[conditions allKeys] enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
            if (idx > 0) {
                [sql appendString:type == CONDITION_TYPE_BESIDES?@" and ":@" or "];
            }
            [sql appendFormat:@"%@ = %@",key,[conditions objectForKey:key]];
        }];
    }
    __block int success;
    NSString *conditionSql = [NSString stringWithFormat:@"DELETE FROM %@ %@",NSStringFromClass(entityClass),([sql length] > 0?[NSString stringWithFormat:@"WHERE %@",sql]:@"")];
    success = sqlite3_exec(database,[conditionSql UTF8String], NULL, NULL, NULL);
    if (success != SQLITE_OK){
        NSLog(@"删除数据失败:%@",sql);
    }
    return (success == SQLITE_OK);
}

#pragma mark -通过SQL删除数据
-(bool)removeEntity:(Class)entityClass
               with:(NSString*)sql{
    int success;
    NSString *conditionSql = [NSString stringWithFormat:@"DELETE FROM %@ %@",NSStringFromClass(entityClass),([sql length] > 0?[NSString stringWithFormat:@"WHERE %@",sql]:@"")];
    success = sqlite3_exec(database,[conditionSql UTF8String], NULL, NULL, NULL);
    if (success != SQLITE_OK){
        NSLog(@"删除数据失败:%@",sql);
    }
    return (success == SQLITE_OK);
}

#pragma mark -查询所有数据
-(NSArray*)listEntity:(Class)entityClass{
    return [self listEntity:entityClass with:[NSString stringWithFormat:@"SELECT * FROM %@;",NSStringFromClass(entityClass)]];
}

#pragma mark -查询所有数据并根据字段分组并根据主键降序排序
//-(NSArray*)listEntity:(Class)entityClass singleField:(NSString*)singleField{
//    return [self listEntity:entityClass with:[NSString stringWithFormat:@"SELECT * FROM (SELECT * FROM %@ ORDER BY %@) as r GROUP BY %@ ORDER BY %@ DESC;",NSStringFromClass(entityClass),[entityClass primaryKey], singleField, [entityClass primaryKey]]];
//}

#pragma mark -根据条件查询数据
-(NSArray*)listEntity:(Class)entityClass condition:(NSDictionary*)conditions meet:(CONDITION_TYPE)type{
    if (!conditions || ![conditions isKindOfClass:[NSDictionary class]]) {
        return [self listEntity:entityClass];
    }
    NSMutableString *sql = [NSMutableString stringWithCapacity:0];
    [[conditions allKeys] enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        if (idx > 0) {
            [sql appendString:type == CONDITION_TYPE_BESIDES?@" and ":@" or "];
        }
        [sql appendFormat:@"%@ = %@",key,[conditions objectForKey:key]];
    }];
    return [self listEntity:entityClass with:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@",NSStringFromClass(entityClass),sql]];
}

#pragma mark -分组查询数据
//-(NSArray*)listEntity:(Class)entityClass
//            condition:(NSDictionary*)conditions
//                 meet:(CONDITION_TYPE)type
//                start:(int)index
//                 step:(int)number{
//    if (index < 0 || number <= 0) {
//        return [self listEntity:entityClass condition:conditions meet:type];
//    }
//    if (!conditions || ![conditions isKindOfClass:[NSDictionary class]]) {
//        return [self listEntity:entityClass];
//    }
//    NSMutableString *sql = [NSMutableString stringWithCapacity:0];
//    [[conditions allKeys] enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
//        if (idx > 0) {
//            [sql appendString:type == CONDITION_TYPE_BESIDES?@" and ":@" or "];
//        }
//        [sql appendFormat:@"%@ = %@",key,[conditions objectForKey:key]];
//    }];
//    return [self listEntity:entityClass with:[NSString stringWithFormat:@"SELECT * FROM %@ WHERE %@ ORDER BY %@ DESC LIMIT %d,%d;",NSStringFromClass(entityClass),sql,[entityClass primaryKey],index,number]];
//}

-(NSArray*)listEntity:(Class)entityClass with:(NSString*)sql{
    __block NSMutableArray *entitys = [NSMutableArray arrayWithCapacity:0];
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(database, [sql UTF8String], -1, &stmt, nil) == SQLITE_OK) {
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSObject *object = [[entityClass alloc] init];
            for (int col = 0; col < sqlite3_column_count(stmt);col++) {
                SEL selector = NSSelectorFromString([NSString stringWithUTF8String:sqlite3_column_name(stmt, col)]);
                if ([object respondsToSelector:selector]) {
                    id value = [NSString stringWithUTF8String:(const char*)sqlite3_column_text(stmt, col)];
                    //传说应用暂时使用
                    if (value) {
                        if ([[value jsonValue] isKindOfClass:[NSDictionary class]]) {
                            [object setValue:[[value jsonValue] entity] forKeyPath:[NSString stringWithUTF8String:sqlite3_column_name(stmt, col)]];
                        }else{
                            [object setValue:value forKeyPath:[NSString stringWithUTF8String:sqlite3_column_name(stmt, col)]];
                        }
                    }else{
                        [object setValue:@"" forKeyPath:[NSString stringWithUTF8String:sqlite3_column_name(stmt, col)]];
                    }
                    //以下为标准对象
//                    [object setValue:value?([value JSONValue]?([[value JSONValue] isKindOfClass:[NSDictionary class]]?[[value JSONValue] entity]:[value JSONValue]):value):@"" forKeyPath:[NSString stringWithUTF8String:sqlite3_column_name(stmt, col)]];
                }
            }
            [entitys addObject:object];
        }
        sqlite3_finalize(stmt);
    }

    return entitys;
}

#pragma mark - | Private Interface
#pragma mark -数据库连接是否成功
- (bool)openSuccess{
    //验证数据库解密是否成功
    return sqlite3_exec(database, [@"SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;" UTF8String], NULL, NULL, NULL) == SQLITE_OK;
}

#pragma mark -创建或升级数据库
- (sqlite_int64)createOrUpgradeTable:(NSObject*)entity {
    //1.判断是否需要升级数据库
    NSArray *propertys = [self checkUpgradeTable:entity];
    //1.1.表结构无变化,直接创建
    if (!propertys) {
        return sqlite3_exec(database, [entity sqlWithCreateTable].UTF8String, NULL, NULL, NULL);
    }
    //1.2.表结构变化，需要升级
    if (propertys.count > 1) {//当数据表不需升级时，propertys仅包含原数据表结构字段
        return [self upgradeTable:entity withProperties:propertys];
    }
    return SQLITE_OK;
}

#pragma mark -检查是否需要升级数据库
//返回字段数组，仅包含最多两个成员
//首成员是已创建表的表字段用(,)拼接的字符串，尾成员是需要更新的表字段用(,)拼接的字符串
-(NSArray*)checkUpgradeTable:(NSObject*)entity{
    //1.查询表结构,枚举出表结构列
    NSMutableString *sql = [NSMutableString stringWithFormat:@"PRAGMA table_info('%@')",[entity className]];
    NSMutableArray *cols = [[NSMutableArray alloc] initWithCapacity:0];
    sqlite3_stmt *stmt;
    int64_t code = sqlite3_prepare_v2(database, [sql UTF8String], -1, &stmt, nil);
    if (code != SQLITE_OK) {
        return nil;
    }
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        for (int col = 0; col < sqlite3_column_count(stmt);col++) {
            const char *col_c = sqlite3_column_name(stmt,col);
            const char *val_c = (const char *)sqlite3_column_text(stmt,col);
            if (val_c == NULL) {
                continue;
            }
            NSString *col = [NSString stringWithUTF8String:col_c];
            NSString *val = [NSString stringWithUTF8String:val_c];
            if ([col isEqualToString:@"name"]) {
                [cols addObject:val];
            }
        }
    }
    sqlite3_finalize(stmt);
    //说明表还未创建
    if (cols.count == 0) {
        return nil;
    }
    
    //说明表已存在
    NSArray *properties = [entity propertys];
    //遍历最新表字段，判断升级并生成SQL
    __block bool upgrade = false;
    [properties enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        if ([cols indexOfObject:key] == NSNotFound) {
            upgrade = true;
            [cols insertObject:@"''" atIndex:idx];
        }
    }];
    return upgrade ? @[[cols componentsJoinedByString:@","],[properties componentsJoinedByString:@","]] : @[[cols componentsJoinedByString:@","]];
}

#pragma mark -根据数据库表升级检查进行升级
- (int64_t)upgradeTable:(NSObject*)entity withProperties:(NSArray*)properties {
    NSMutableArray *transaction = [[NSMutableArray alloc] init];
    [transaction addObject:[NSString stringWithFormat:@"DROP TABLE IF EXISTS temp_%@;",[entity className]]];
    [transaction addObject:[NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO temp_%@;",[entity className],[entity className]]];
    [transaction addObject:[entity sqlWithCreateTable]];
    [transaction addObject:[NSString stringWithFormat:@"INSERT INTO %@(%@) SELECT %@ FROM temp_%@;",[entity className],properties.lastObject,properties.firstObject,[entity className]]];
    [transaction addObject:[NSString stringWithFormat:@"DROP TABLE temp_%@;",[entity className]]];
    @try{
        if (sqlite3_exec(database, "begin transaction", 0, 0, NULL)==SQLITE_OK){
            NSLog(@"数据结构发生变化,通过事务进行数据库表升级");
            sqlite3_stmt *statement;
            for (int i = 0; i<transaction.count; i++){
                NSString *sql = [transaction objectAtIndex:i];
                if (sqlite3_prepare_v2(database,[sql UTF8String], -1, &statement, NULL) == SQLITE_OK){
                    if (sqlite3_step(statement) != SQLITE_DONE)
                        sqlite3_finalize(statement);
                }else{
                    NSLog(@"升级数据表事务失败:%@, error:%@", sql, [self lastErrorMessage]);
                    if (sqlite3_exec(database, "rollback transaction", NULL, NULL, NULL) == SQLITE_OK){
                        NSLog(@"回滚事务成功");
                    }else{
                        NSLog(@"回滚事务失败:%@",[self lastErrorMessage]);
                    }
                    return -1;
                }
            }
            if (sqlite3_exec(database, "commit transaction", NULL, NULL, NULL) == SQLITE_OK){
                NSLog(@"升级数据表事务执行成功");
                return SQLITE_OK;
            }else{
                NSLog(@"提交事务失败:%@",[self lastErrorMessage]);
                return -1;
            }
        }else{
            NSLog(@"开始事务失败,失败原因%@",[self lastErrorMessage]);
            return -1;
        }
    }@catch(NSException *e){
        NSLog(@"升级数据库遇到异常:%@",e);
        if (sqlite3_exec(database, "rollback transaction", 0, 0, NULL) == SQLITE_OK){
            NSLog(@"回滚事务成功");
        }else{
            NSLog(@"回滚事务失败:%@",[self lastErrorMessage]);
        }
        return -1;
    }
    @finally{
    }
}

#pragma mark -数据库操作错误信息
- (NSString*)lastErrorMessage {
    return [NSString stringWithUTF8String:sqlite3_errmsg(database)];
}

@end
