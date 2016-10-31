//
//  NSValueTransformer+Kinvey.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-12-02.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Foundation;

@interface NSValueTransformer (Kinvey)

+(void)setValueTransformer:(NSValueTransformer *)transformer
                 fromClass:(Class)fromClass
                   toClass:(Class)toClass;

+(NSValueTransformer *)valueTransformerFromClass:(Class)fromClass
                                         toClass:(Class)toClass;

+(NSValueTransformer *)valueTransformerFromClassName:(NSString*)fromClass
                                         toClassName:(NSString*)toClass;

@end
