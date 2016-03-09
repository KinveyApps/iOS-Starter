//
//  Book.m
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "Book.h"

@implementation Book

+(NSString *)kinveyCollectionName
{
    return @"Book";
}

+(NSDictionary<NSString *,NSString *> *)kinveyPropertyMapping
{
    return @{@"objectId" : KNVPersistableIdKey,
             @"title" : @"title",
             @"publicationDate" : @"publication_date"};
}

@end
