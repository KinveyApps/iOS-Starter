//
//  Book.h
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
@import Kinvey;

@interface Book : NSObject <KNVPersistable>

@property (nonatomic, strong) NSString* objectId;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSDate* publicationDate;

@end
