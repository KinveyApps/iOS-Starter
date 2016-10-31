//
//  KCSObjcRuntime.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Foundation;

@interface KCSObjcRuntime : NSObject

+(NSString*)typeForProperty:(NSString*)propertyName
                   inObject:(id)obj;

+(NSString*)typeForProperty:(NSString*)propertyName
                inClassName:(NSString*)className;

+(NSString*)typeForProperty:(NSString*)propertyName
                    inClass:(Class)clazz;

+(NSSet<NSString*>*)propertyNamesForObject:(id)obj;

+(NSSet<NSString*>*)propertyNamesForClassName:(NSString*)className;

+(NSSet<NSString*>*)propertyNamesForClass:(Class)clazz;

+(NSSet<NSString*>*)ivarNamesForObject:(id)obj;

+(NSSet<NSString*>*)ivarNamesForClass:(Class)clazz;

+(NSSet<NSString*>*)methodsForObject:(id)obj;

+(NSSet<NSString*>*)methodsForClass:(Class)clazz;

@end
