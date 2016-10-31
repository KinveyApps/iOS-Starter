//
//  KCSBuilders.h
//  KinveyKit
//
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

@import Foundation;

@protocol KCSDataTypeBuilder <NSObject>
+ (id) JSONCompatabileValueForObject:(id)object;
+ (id) objectForJSONObject:(id)object;
@end

@interface KCSAttributedStringBuilder : NSObject <KCSDataTypeBuilder>
@end
@interface KCSMAttributedStringBuilder : KCSAttributedStringBuilder
@end


@interface KCSDateBuilder : NSObject <KCSDataTypeBuilder>
@end


@interface KCSSetBuilder : NSObject <KCSDataTypeBuilder>
@end
@interface KCSMSetBuilder : KCSSetBuilder
@end


@interface KCSOrderedSetBuilder : NSObject <KCSDataTypeBuilder>
@end
@interface KCSMOrderedSetBuilder : KCSOrderedSetBuilder
@end


@interface KCSCLLocationBuilder : NSObject <KCSDataTypeBuilder>
@end

@interface KCSURLBuilder : NSObject <KCSDataTypeBuilder>
@end

@interface KCSBuilders : NSObject
@end
