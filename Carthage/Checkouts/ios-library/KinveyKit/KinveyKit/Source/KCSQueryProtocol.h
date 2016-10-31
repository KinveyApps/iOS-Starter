//
//  KCSQueryProtocol.h
//  Kinvey
//
//  Created by Victor Barros on 2016-04-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;

@protocol KCSQuery <NSObject>

@property (nonatomic, readonly) NSPredicate* predicate;
@property (nonatomic, readonly) NSArray<NSSortDescriptor*>* sortDescriptors;

@end
