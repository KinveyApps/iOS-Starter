//
//  KCSLogTests.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-05-07.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KinveyKit/KinveyKit.h>
#import "KCSLogTests.h"

@implementation KCSLogTests

- (void)setUp {
    [super setUp];
    
    self.logs = [NSMutableArray array];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.stdoutCopy = dup(STDOUT_FILENO);
        self.stderrCopy = dup(STDERR_FILENO);
    });
    
    self.pipe = [NSPipe pipe];
    dup2(self.pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO);
    dup2(self.pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:NSFileHandleReadCompletionNotification object:self.pipe.fileHandleForReading];
    [self.pipe.fileHandleForReading readInBackgroundAndNotify];
}

-(void)handleNotification:(NSNotification*)notification
{
    NSString *str = [[NSString alloc] initWithData:notification.userInfo[NSFileHandleNotificationDataItem]
                                          encoding:NSUTF8StringEncoding];
    [self.logs addObject:str];
    NSFileHandle* fileHandleForReading = notification.object;
    [fileHandleForReading readInBackgroundAndNotify];
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadCompletionNotification object:self.pipe.fileHandleForReading];
    
    dup2(self.stdoutCopy, STDOUT_FILENO);
    dup2(self.stderrCopy, STDERR_FILENO);
    
    [self.pipe.fileHandleForWriting closeFile];
    [self.pipe.fileHandleForReading closeFile];
    
    [self.logs removeAllObjects];
    
    [[KCSUser activeUser] logout];
    
    NSLog(@"Test");
    
    [super tearDown];
}

@end
