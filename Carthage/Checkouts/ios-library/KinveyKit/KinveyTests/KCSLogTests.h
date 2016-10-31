//
//  KCSLogTests.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-20.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSTestCase.h"

@interface KCSLogTests : KCSTestCase

@property (nonatomic, strong) NSPipe* pipe;
@property (nonatomic, strong) NSMutableArray* logs;
@property (nonatomic) int stdoutCopy;
@property (nonatomic) int stderrCopy;

@end
