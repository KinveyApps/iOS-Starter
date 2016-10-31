//
//  KCSFileStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 6/18/13.
//  Copyright (c) 2013-2015 Kinvey. All rights reserved.
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


#import "KCSFileStoreTests.h"
#import "TestUtils.h"

#import "KCSFile.h"
#import "KCSFileStore.h"
#import "NSArray+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"
#import "KCSHiddenMethods.h"
#import "NSDate+KinveyAdditions.h"
#import "KCSFileUtils.h"

#define KTAssertIncresing(var) \
{ \
KTAssertCountAtLeast(1, var); \
NSMutableArray* lastdouble = [NSMutableArray arrayWith:var.count copiesOf:@(-1)]; \
for (id v in var) { \
NSArray* vArr = [NSArray wrapIfNotArray:v]; \
[vArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) { \
double thisdouble = [obj doubleValue]; \
XCTAssertTrue(thisdouble >= [lastdouble[idx] doubleValue], @"should be increasing value"); \
lastdouble[idx] = @(thisdouble); \
}];\
}}


#define SETUP_PROGRESS \
NSMutableArray* progresses = [NSMutableArray array]; \
NSMutableArray* datas = [NSMutableArray array];
#define PROGRESS_BLOCK \
^(NSArray *objects, double percentComplete) { \
XCTAssertTrue([NSThread isMainThread]); \
[progresses addObject:@(percentComplete)]; \
[datas addObject:[objects valueForKeyPath:@"length"]]; \
}
#define ASSERT_PROGESS \
KTAssertIncresing(progresses); \
KTAssertIncresing(datas);

#define CLEAR_PROGRESS [progresses removeAllObjects]; [datas removeAllObjects];
#define ASSERT_NO_PROGRESS KTAssertCount(0,progresses);

#define SLEEP_TIMEINTERVAL 20
#define PAUSE NSLog(@"sleeping for %u seconds....",SLEEP_TIMEINTERVAL); [NSThread sleepForTimeInterval:SLEEP_TIMEINTERVAL];


#define kTestId @"testData"
#define kTestMimeType @"text/plain"
#define kTestFilename @"test.txt"
#define kTestSize testData().length

#define kImageFilename @"mavericks.jpg"
#define kImageMimeType @"image/jpeg"
#define kImageSize 3510397

//copy for testing
@interface KCSDownloadStreamRequest : NSObject
@property (nonatomic) unsigned long long bytesWritten;
@end


@implementation KCSFileStoreTests

NSData* testData()
{
    NSString* loremIpsum = @"Et quidem saepe quaerimus verbum Latinum par Graeco et quod idem valeat; Non quam nostram quidem, inquit Pomponius iocans; Ex rebus enim timiditas, non ex vocabulis nascitur. Nunc vides, quid faciat. Tum Piso: Quoniam igitur aliquid omnes, quid Lucius noster? Graece donan, Latine voluptatem vocant. Mihi, inquam, qui te id ipsum rogavi? Quem Tiberina descensio festo illo die tanto gaudio affecit, quanto L. Primum in nostrane potestate est, quid meminerimus? Si quidem, inquit, tollerem, sed relinquo. Quo modo autem philosophus loquitur? Sic enim censent, oportunitatis esse beate vivere.";
    NSData* ipsumData = [loremIpsum dataUsingEncoding:NSUTF16BigEndianStringEncoding];
    return ipsumData;
}

NSData* testData2()
{
    NSString* hipsterIpsum = @"Selfies magna deep v consequat, esse dolor Banksy Marfa quis. Banh mi gastropub tofu, gluten-free twee literally narwhal. Narwhal fanny pack cardigan duis ex meh. Tofu cornhole nihil viral intelligentsia Tonx nisi DIY. Kogi chillwave helvetica, fap artisan mumblecore eu sapiente PBR irure put a bird on it fixie dolore small batch. Aliquip consequat proident, before they sold out street art letterpress vegan Tonx helvetica Williamsburg Terry Richardson Godard. Vero trust fund photo booth, artisan dolor irure ennui Cosby sweater labore Tonx fixie gastropub.";
    NSData* ipsumData = [hipsterIpsum dataUsingEncoding:NSUTF16BigEndianStringEncoding];
    return ipsumData;
}

- (NSURL*) largeImageURL
{
    return [[NSBundle bundleForClass:[self class]] URLForResource:@"mavericks" withExtension:@"jpg"];
}

- (void) setUpTestFile
{
    KCSMetadata* metadata = [[KCSMetadata alloc] init];
    [metadata setGloballyWritable:YES];
    [metadata setGloballyReadable:YES];
    
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:@{ KCSFileId : kTestId, KCSFileACL : metadata, KCSFileMimeType : kTestMimeType, KCSFileFileName : kTestFilename} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
}

- (KCSFile*) getMetadataForId:(NSString*)fileId
{
    KCSAppdataStore* metaStore = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    __block KCSFile* info = nil;
    [metaStore loadObjectWithID:fileId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertCount(1, objectsOrNil);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (objectsOrNil.count > 0) {
            info = objectsOrNil[0];
        }
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    return info;
}

- (NSURL*) getDownloadURLForId:(NSString*)fileId
{
    KCSFile* downloadFile = [self getMetadataForId:fileId];
    NSURL* downloadURL = downloadFile.remoteURL;
    XCTAssertNotNil(downloadURL, @"Should have a valid download URL");
    return downloadURL;
}

- (void)setUp
{
    [super setUp];
    
    XCTAssertTrue([TestUtils setUpKinveyUnittestBackend:self], @"Should be set up.");
    
    [self createAutogeneratedUser];
    
    self.done = NO;
    [self setUpTestFile];
}

- (void)tearDown
{
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:kTestId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        if (errorOrNil != nil && errorOrNil.code == KCSNotFoundError) {
            //was hopefully removed by a test
        } else {
            STAssertNoError;
            XCTAssertEqual((unsigned long)1, count, @"should have deleted the temp data");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    [super tearDown];
}

#pragma mark - Download Data

- (void)testDownloadBasic
{
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadData:kTestId completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.localURL, @"should have no local url for data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            NSData* origData = testData();
            
            XCTAssertEqualObjects(resource.data, origData, @"should have matching data");
            XCTAssertEqual(resource.length, origData.length, @"should have matching lengths");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS
}

- (void) testDownloadDataError
{
    //step 1. download data that doesn't exist
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadData:@"BAD-ID" completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNil(downloadedResources, @"no resources");
        XCTAssertNotNil(error, @"should get an error");
        
        KTAssertEqualsInt(error.code, 404, @"no item error");
        XCTAssertEqualObjects(error.domain, KCSResourceErrorDomain, @"is a file error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    KTAssertCount(0, progresses);
}

- (void) testDownloadToFile
{
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFile:kTestId options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.data, @"should have no local data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            XCTAssertNotNil(resource.remoteURL, @"should have a remote URL");
            
            NSURL* localURL = resource.localURL;
            XCTAssertNotNil(localURL, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
            
            [[NSFileManager defaultManager] removeItemAtURL:resource.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS
}

- (void) testDownloadToFileCancel
{
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    KCSRequest* request = [KCSFileStore downloadFile:kTestId
                                             options:nil
                                     completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        XCTFail();
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
}

- (void) testDownloadToFileOptionsFilename
{
    NSString* filename = @"hookemsnivy.rtf";
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:kTestId options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            
            NSURL* localURL = dlFile.localURL;
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertEqualObjects([localURL lastPathComponent], filename, @"local file should have the specified filename");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[localURL path]], @"should exist");
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            STAssertNoError_;
            
            NSData* origData = testData();
            KTAssertEqualsInt([attributes[NSFileSize] intValue], origData.length, @"should have matching data");
            
            [[NSFileManager defaultManager] removeItemAtURL:localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testDownloadArrayOfFileIds
{
    //1. upload two files
    //2. download two files
    //3. check there are two valid files
    __block NSString* file2Id = nil;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2Id = uploadInfo.fileId;
        XCTAssertFalse([file2Id isEqualToString:kTestId], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    [KCSFileStore downloadFile:@[kTestId, file2Id] options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        downloads = downloadedResources;
        KTAssertCountAtLeast(2, downloadedResources);
        
        if (downloadedResources.count > 1) {
            KCSFile* f1 = downloadedResources[0];
            KCSFile* f2 = downloadedResources[1];
            
            BOOL idIn = [@[kTestId, file2Id] containsObject:f1.fileId];
            XCTAssertTrue(idIn, @"test id should match");
            XCTAssertNotNil(f1.localURL, @"should have a local id");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f1.localURL path]], @"file should exist");
            
            BOOL idIn2 = [@[kTestId, file2Id] containsObject:f2.fileId];
            XCTAssertTrue(idIn2, @"test id should match");
            XCTAssertNotNil(f2.localURL, @"should have a local id");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f2.localURL path]], @"file should exist");
            
            XCTAssertFalse([f1.fileId isEqual:f2.fileId], @"should be different ids");
            XCTAssertFalse([f1.localURL isEqual:f2.localURL], @"Should be different files");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    for (KCSFile* f in downloads) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:f.localURL error:&error];
        STAssertNoError_;
    }
}

- (void) testDownloadArrayOfDatas
{
    //1. upload two files
    //2. download two dats
    //3. check there are two datas files
    __block NSString* file2Id = nil;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2Id = uploadInfo.fileId;
        XCTAssertFalse([file2Id isEqualToString:kTestId], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    [KCSFileStore downloadData:@[kTestId, file2Id] completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        downloads = downloadedResources;
        //TODO
//        KTAssertCount(2, downloadedResources);
        
        if (downloadedResources.count > 1) {
            KCSFile* f1 = downloadedResources[0];
            KCSFile* f2 = downloadedResources[1];
            
            BOOL idIn = [@[kTestId, file2Id] containsObject:f1.fileId];
            XCTAssertTrue(idIn, @"test id should match");
            //TODO
    //        XCTAssertNotNil(f1.data, @"should have data");
            
            BOOL idIn2 = [@[kTestId, file2Id] containsObject:f2.fileId];
            XCTAssertTrue(idIn2, @"test id should match");
            //TODO
    //        XCTAssertNotNil(f2.data, @"should have data");
            
            XCTAssertFalse([f1.fileId isEqual:f2.fileId], @"should be different ids");
            XCTAssertFalse([f1.localURL isEqual:f2.localURL], @"Should be different files");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}


- (void) testDownloadToFileOnlyIfNewerAndIsNotNewer
{
    //1. download a file
    //2. try to redownload that file and see the short-circuit
    
    __block NSDate* firstDate = nil;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFile:kTestId options:@{KCSFileOnlyIfNewer : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.data, @"should have no local data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            NSURL* localURL = resource.localURL;
            XCTAssertNotNil(localURL, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
            
            firstDate = [attr fileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    PAUSE
    
    [progresses removeAllObjects];
    [datas removeAllObjects];
    __weak __block XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    [KCSFileStore downloadFile:kTestId options:@{KCSFileOnlyIfNewer : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.data, @"should have no local data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            NSURL* localURL = resource.localURL;
            XCTAssertNotNil(localURL, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSDate* secondDate = [attr fileModificationDate];
            //TODO
//            KTAssertEqualsDates(secondDate, firstDate);
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
            
            [[NSFileManager defaultManager] removeItemAtURL:resource.localURL error:&error];
        }
        
        STAssertNoError_
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload2 = nil;
    }];
    KTAssertCount(1, progresses); //progress called once when using local - to deal with progress bars
}

- (void) testDownloadToFileOnlyIfNewerAndIsNewer
{
    //0. clear the old file
    NSURL* downloadsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* destinationURL = [NSURL URLWithString:kTestFilename relativeToURL:downloadsDir];
    [[NSFileManager defaultManager] removeItemAtURL:destinationURL error:NULL];
    
    //1. download a file
    //2. update the file
    //3. try to redownload that file and see the short-circuit
    
    __block NSDate* firstDate = nil;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFile:kTestId options:@{KCSFileOnlyIfNewer : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.data, @"should have no local data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            NSURL* localURL = resource.localURL;
            XCTAssertNotNil(localURL, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
            
            firstDate = [attr fileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    PAUSE;
    
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:@{KCSFileId : kTestId, KCSFileMimeType : kTestMimeType} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        
        NSDate* uploadLMT = uploadInfo.metadata.lastModifiedTime;
        XCTAssertTrue([uploadLMT isLaterThan:firstDate], @"should update the LMT");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    [progresses removeAllObjects];
    [datas removeAllObjects];
    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:kTestId options:@{KCSFileOnlyIfNewer : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.data, @"should have no local data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            NSURL* localURL = resource.localURL;
            XCTAssertNotNil(localURL, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSDate* secondDate = [attr fileModificationDate];
            XCTAssertTrue([secondDate isLaterThan:firstDate], @"should be updated");
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
            
            [[NSFileManager defaultManager] removeItemAtURL:resource.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS;
}

- (void) testDownloadToFileIfNewerButFileDeleted
{
    //1. download a file
    //2. delete the file
    //3. try to redownload that file and see the short-circuit
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    __block KCSFile* file;
    [KCSFileStore downloadFile:kTestId options:@{KCSFileOnlyIfNewer : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            file = downloadedResources[0];
            XCTAssertNil(file.data, @"should have no local data");
            XCTAssertEqualObjects(file.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(file.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(file.mimeType, kTestMimeType, @"should have a mime type");
            
            NSURL* localURL = file.localURL;
            XCTAssertNotNil(file, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:[file.localURL path] error:&error];
    STAssertNoError_;
    
    [progresses removeAllObjects];
    [datas removeAllObjects];
    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    [KCSFileStore downloadFile:kTestId options:@{KCSFileOnlyIfNewer : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.data, @"should have no local data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            NSURL* localURL = resource.localURL;
            XCTAssertNotNil(localURL, @"should have a URL");
            BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[localURL path]];
            XCTAssertTrue(exists, @"file should exist");
            
            error = nil;
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[localURL path] error:&error];
            XCTAssertNil(error, @"%@",error);
            
            NSData* origData = testData();
            KTAssertEqualsInt([attr[NSFileSize] intValue], origData.length, @"should have matching data");
            
            [[NSFileManager defaultManager] removeItemAtURL:resource.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS;
}

- (void) testDownloadFileSpecifyFilename
{
    NSString* filename = [NSString stringWithFormat:@"TEST-%@",[NSString UUID]];
    NSURL* destinationURL = [KCSFileUtils fileURLForName:filename];
    //[NSURL URLWithString:filename relativeToURL:downloadsDir];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[destinationURL path]], @"Should start with a fresh file");
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS;
    __block KCSFile* file;
    [KCSFileStore downloadFile:kTestId options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        KTAssertCountAtLeast(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            file = downloadedResources[0];
            
            XCTAssertNotNil(file.filename, @"should have a filename");
            XCTAssertEqualObjects(file.filename, filename, @"filename should match specified");
            XCTAssertNotNil(file.localURL, @"should have a local url");
            XCTAssertEqualObjects(file.localURL, destinationURL, @"should have gone to specified location");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    NSError* error;
    [[NSFileManager defaultManager] removeItemAtPath:[file.localURL path] error:&error];
    STAssertNoError_;
}

- (void) testDownloadFilesSpecifyFilenames
{
    //1. upload two files
    //2. download two files with names
    //3. check there are two valid files & have specified names
    __block NSString* file2Id = nil;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData2() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2Id = uploadInfo.fileId;
        XCTAssertFalse([file2Id isEqualToString:kTestId], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSString* filename1 = [NSString stringWithFormat:@"TEST-%@",[NSString UUID]];
    NSString* filename2 = [NSString stringWithFormat:@"TEST-%@",[NSString UUID]];
    NSURL* downloadsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* destinationURL1 = [NSURL URLWithString:filename1 relativeToURL:downloadsDir];
    NSURL* destinationURL2 = [NSURL URLWithString:filename2 relativeToURL:downloadsDir];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[destinationURL1 path]], @"Should start with a fresh file");
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[destinationURL2 path]], @"Should start with a fresh file");
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    [KCSFileStore downloadFile:@[kTestId, file2Id] options:@{KCSFileFileName : @[filename1, filename2]} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        downloads = downloadedResources;
        KTAssertCountAtLeast(2, downloadedResources);
        
        if (downloadedResources.count > 1) {
            KCSFile* f1 = downloadedResources[0];
            KCSFile* f2 = downloadedResources[1];
            
            BOOL idIn = [@[kTestId, file2Id] containsObject:f1.fileId];
            XCTAssertTrue(idIn, @"test id should match");
            XCTAssertNotNil(f1.localURL, @"should have a local id");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f1.localURL path]], @"file should exist");
            
            BOOL idIn2 = [@[kTestId, file2Id] containsObject:f2.fileId];
            XCTAssertTrue(idIn2, @"test id should match");
            XCTAssertNotNil(f2.localURL, @"should have a local id");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f2.localURL path]], @"file should exist");
            
            XCTAssertFalse([f1.fileId isEqual:f2.fileId], @"should be different ids");
            XCTAssertFalse([f1.localURL isEqual:f2.localURL], @"Should be different files");
            
            BOOL nameIn1 = [@[filename1, filename2] containsObject:f1.filename];
            BOOL nameIn2 = [@[filename1, filename2] containsObject:f2.filename];
            XCTAssertTrue(nameIn1, @"file 1 should have the appropriate filename");
            XCTAssertTrue(nameIn2, @"file 1 should have the appropriate filename");
            
            KCSFile* data2File = [f1.fileId isEqualToString:file2Id] ? f1 : f2;
            XCTAssertEqualObjects(data2File.filename, filename2, @"f2 should match filename 2");
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[data2File.localURL path] error:&error];
            STAssertNoError_
            KTAssertEqualsInt([attr fileSize], testData2().length, @"should be tesdata2");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    for (KCSFile* f in downloads) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:f.localURL error:&error];
        STAssertNoError_;
    }
}

- (void) testDownloadFilesSpecifyFilenamesError
{
    //1. download two files with names, but only 1 has a file
    //2. check that one is good and the other is null
    
    NSString* file2Id = @"NOFILE";
    
    NSString* filename1 = [NSString stringWithFormat:@"TEST-%@",[NSString UUID]];
    NSString* filename2 = [NSString stringWithFormat:@"TEST-%@",[NSString UUID]];
    NSURL* downloadsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL* destinationURL1 = [NSURL URLWithString:filename1 relativeToURL:downloadsDir];
    NSURL* destinationURL2 = [NSURL URLWithString:filename2 relativeToURL:downloadsDir];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[destinationURL1 path]], @"Should start with a fresh file");
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[destinationURL2 path]], @"Should start with a fresh file");
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    [KCSFileStore downloadFile:@[kTestId, file2Id] options:@{KCSFileFileName : @[filename1, filename2]} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        downloads = downloadedResources;
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* f1 = downloadedResources[0];
            
            BOOL idIn = [@[kTestId, file2Id] containsObject:f1.fileId];
            XCTAssertTrue(idIn, @"test id should match");
            XCTAssertNotNil(f1.localURL, @"should have a local id");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f1.localURL path]], @"file should exist");
            
            BOOL nameIn1 = [@[filename1, filename2] containsObject:f1.filename];
            XCTAssertTrue(nameIn1, @"file 1 should have the appropriate filename");
            
            XCTAssertEqualObjects(f1.filename, filename1, @"f1 should match filename 21");
            NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[f1.localURL path] error:&error];
            STAssertNoError_
            KTAssertEqualsInt([attr fileSize], testData().length, @"should be tesdata");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    for (KCSFile* f in downloads) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:f.localURL error:&error];
        STAssertNoError_;
    }
}

- (void) testDownloadFileByQuery
{
    //step 1. upload known type - weird mimetype
    //step 2. query and expect the file back
    //step 3. cleanup
    
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block KCSFile* uploadedFile = nil;
    NSString* umt = [NSString stringWithFormat:@"test/%@", [NSString UUID]];
    [KCSFileStore uploadData:testData2() options:@{KCSFileMimeType : umt} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"should have a file");
        XCTAssertEqualObjects(uploadInfo.mimeType, umt, @"mimesshould match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have an id");
        uploadedFile = uploadInfo;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    XCTAssertNotNil(uploadedFile, @"file should be ready");
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS;
    KCSQuery* query = [KCSQuery queryOnField:KCSFileMimeType withExactMatchForValue:umt];
    [KCSFileStore downloadFileByQuery:query completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(downloadedResources, @"get a download");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertEqualObjects(dlFile, uploadedFile, @"files should match");
            XCTAssertNotNil(dlFile.localURL, @"should be file file");
            XCTAssertNil(dlFile.data, @"should have no data");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS;
    
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:uploadedFile.localURL error:&error];
    STAssertNoError_;
}

- (void) testDownloadFileByQueryCancel
{
    //step 1. upload known type - weird mimetype
    //step 2. query and expect the file back
    //step 3. cleanup
    
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block KCSFile* uploadedFile = nil;
    NSString* umt = [NSString stringWithFormat:@"test/%@", [NSString UUID]];
    [KCSFileStore uploadData:testData2() options:@{KCSFileMimeType : umt} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"should have a file");
        XCTAssertEqualObjects(uploadInfo.mimeType, umt, @"mimesshould match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have an id");
        uploadedFile = uploadInfo;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    XCTAssertNotNil(uploadedFile, @"file should be ready");
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS;
    KCSQuery* query = [KCSQuery queryOnField:KCSFileMimeType withExactMatchForValue:umt];
    KCSRequest* request = [KCSFileStore downloadFileByQuery:query
                                            completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        STAssertNoError_;
        XCTAssertNotNil(downloadedResources, @"get a download");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertEqualObjects(dlFile, uploadedFile, @"files should match");
            XCTAssertNotNil(dlFile.localURL, @"should be file file");
            XCTAssertNil(dlFile.data, @"should have no data");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
    
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:uploadedFile.localURL error:&error];
    STAssertNoError_;
}

- (void) testDownloadDataByQuery
{
    //step 1. upload known type - weird mimetype
    //step 2. query and expect the file back
    //step 3. cleanup
    
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block KCSFile* uploadedFile = nil;
    NSString* umt = [NSString stringWithFormat:@"test/%@", [NSString UUID]];
    [KCSFileStore uploadData:testData2() options:@{KCSFileMimeType : umt} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"should have a file");
        XCTAssertEqualObjects(uploadInfo.mimeType, umt, @"mimesshould match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have an id");
        uploadedFile = uploadInfo;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    XCTAssertNotNil(uploadedFile, @"file should be ready");
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS;
    KCSQuery* query = [KCSQuery queryOnField:KCSFileMimeType withExactMatchForValue:umt];
    [KCSFileStore downloadDataByQuery:query completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(downloadedResources, @"get a download");
        //TODO
        KTAssertCountAtLeast(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertEqualObjects(dlFile, uploadedFile, @"files should match");
            //TODO
//            XCTAssertNil(dlFile.localURL, @"should be no file");
//            XCTAssertNotNil(dlFile.data, @"should have some data");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS;
    
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:uploadedFile.localURL error:&error];
    STAssertNoError_;
}

- (void) testDownloadDataByQueryCancel
{
    //step 1. upload known type - weird mimetype
    //step 2. query and expect the file back
    //step 3. cleanup
    
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block KCSFile* uploadedFile = nil;
    NSString* umt = [NSString stringWithFormat:@"test/%@", [NSString UUID]];
    [KCSFileStore uploadData:testData2() options:@{KCSFileMimeType : umt} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"should have a file");
        XCTAssertEqualObjects(uploadInfo.mimeType, umt, @"mimesshould match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have an id");
        uploadedFile = uploadInfo;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    XCTAssertNotNil(uploadedFile, @"file should be ready");
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS;
    KCSQuery* query = [KCSQuery queryOnField:KCSFileMimeType withExactMatchForValue:umt];
    KCSRequest* request = [KCSFileStore downloadDataByQuery:query
                                            completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        STAssertNoError_;
        XCTAssertNotNil(downloadedResources, @"get a download");
        //TODO
        KTAssertCountAtLeast(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertEqualObjects(dlFile, uploadedFile, @"files should match");
            //TODO
            //            XCTAssertNil(dlFile.localURL, @"should be no file");
            //            XCTAssertNotNil(dlFile.data, @"should have some data");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
    
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtURL:uploadedFile.localURL error:&error];
    STAssertNoError_;
}

- (void) testDownloadFileByQueryNoneFound
{
    //step 1. query and expect nothing back (e.g. weird mimetype
    //step 2. cleanup
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS;
    KCSQuery* query = [KCSQuery queryOnField:KCSFileMimeType withExactMatchForValue:@"test/NO-VALUE"];
    [KCSFileStore downloadDataByQuery:query completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(downloadedResources, @"get a download");
        KTAssertCount(0, downloadedResources);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    KTAssertCount(0, progresses);
}

// *** TODO: *** reminder to check why this test case is causing crashes
//
//- (void) testGetByFileName
//{
//    self.done = NO;
//    __block NSString* fileId;
//    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
//        STAssertNoError_;
//        fileId = uploadInfo.fileId;
//        self.done = YES;
//    } progressBlock:nil];
//    [self poll];
//    
//    self.done = NO;
//    SETUP_PROGRESS
//    [KCSFileStore downloadDataByName:kImageFilename completionBlock:^(NSArray *downloadedResources, NSError *error) {
//        STAssertNoError_;
//        //assert one KCSFile & its data is the right data
//        XCTAssertNotNil(downloadedResources, @"should have a resource");
//        KTAssertCount(1, downloadedResources);
//        
//        KCSFile* resource = downloadedResources[0];
//        XCTAssertNil(resource.localURL, @"should have no local url for data");
//        XCTAssertNotNil(resource.data, @"Should have data");
//        XCTAssertEqualObjects(resource.fileId, fileId, @"file ids should match");
//        XCTAssertEqualObjects(resource.filename, kImageFilename, @"should have a filename");
//        XCTAssertEqualObjects(resource.mimeType, kImageMimeType, @"should have a mime type");
//        KTAssertEqualsInt(resource.length, kImageSize, @"should have matching lengths");
//        KTAssertEqualsInt(resource.data.length, kImageSize, @"should have matching lengths");
//        
//        self.done = YES;
//    } progressBlock:PROGRESS_BLOCK];
//    [self poll];
//    ASSERT_PROGESS
//    
//    if (fileId) {
//        self.done = NO;
//        [KCSFileStore deleteFile:fileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
//            STAssertNoError;
//            self.done = YES;
//        }];
//        [self poll];
//    }
//}

- (void) testGetByFilenames
{
    //1. upload two files
    //2. download two files
    //3. check there are two valid files
    __block NSString* file2name = nil;
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2name = uploadInfo.filename;
        XCTAssertFalse([file2name isEqualToString:kTestFilename], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    NSArray* names = @[kTestFilename, file2name];
    [KCSFileStore downloadFileByName:names completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        downloads = downloadedResources;
        KTAssertCount(2, downloadedResources);
        
        if (downloadedResources.count > 1) {
            KCSFile* f1 = downloadedResources[0];
            KCSFile* f2 = downloadedResources[1];
            
            BOOL idIn = [names containsObject:f1.filename];
            XCTAssertTrue(idIn, @"test name should match");
            XCTAssertNotNil(f1.localURL, @"should have a local url");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f1.localURL path]], @"file should exist");
            
            BOOL idIn2 = [names containsObject:f2.filename];
            XCTAssertTrue(idIn2, @"test name should match");
            XCTAssertNotNil(f2.localURL, @"should have a local url");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[f2.localURL path]], @"file should exist");
            
            XCTAssertFalse([f1.fileId isEqual:f2.fileId], @"should be different ids");
            XCTAssertFalse([f1.localURL isEqual:f2.localURL], @"Should be different files");
            XCTAssertFalse([f1.filename isEqual:f2.filename], @"should have different filenames");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    for (KCSFile* f in downloads) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:f.localURL error:&error];
        STAssertNoError_;
    }
}

- (void) testGetByFilenamesCancel
{
    //1. upload two files
    //2. download two files
    //3. check there are two valid files
    __block NSString* file2name = nil;
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2name = uploadInfo.filename;
        XCTAssertFalse([file2name isEqualToString:kTestFilename], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    NSArray* names = @[kTestFilename, file2name];
    KCSRequest* request = [KCSFileStore downloadFileByName:names
                                           completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        XCTFail();
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
    
    for (KCSFile* f in downloads) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:f.localURL error:&error];
        STAssertNoError_;
    }
}

- (void) testDownloadByFileByFilenameError
{
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFileByName:@"NO-NAME" completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(0, downloadedResources);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    KTAssertCount(0, progresses);
}

- (void) testGetFileIsNotThere
{
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFile:@"NOSUCHFILE" options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNotNil(error, @"should get an error");
        XCTAssertNil(downloadedResources, @"should get no resources");
        XCTAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"Should be a file error");
        KTAssertEqualsInt(error.code, KCSNotFoundError, @"should be a 404");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    KTAssertCount(0, progresses);
    KTAssertCount(0, datas);
}

#pragma mark - download by data
- (void) testDownloadDataByMultipleIds
{
    //1. upload two files
    //2. download two files
    //3. check there are two valid files
    __block NSString* file2Id = nil;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2Id = uploadInfo.fileId;
        XCTAssertFalse([file2Id isEqualToString:kTestId], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSArray* downloads;
    [KCSFileStore downloadData:@[kTestId, file2Id] completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        downloads = downloadedResources;
        KTAssertCountAtLeast(2, downloadedResources);
        
        if (downloadedResources.count > 1) {
            //TODO
//            KTAssertCount(2, downloadedResources);
            KCSFile* f1 = downloadedResources[0];
            KCSFile* f2 = downloadedResources[1];
            
            BOOL idIn = [@[kTestId, file2Id] containsObject:f1.fileId];
            XCTAssertTrue(idIn, @"test id should match");
            //TODO
//            XCTAssertNil(f1.localURL, @"should not have a local id");
//            XCTAssertNotNil(f1.data, @"should have data");
//            XCTAssertEqualObjects(f1.data, testData(), @"data should match");
            
            BOOL idIn2 = [@[kTestId, file2Id] containsObject:f2.fileId];
            XCTAssertTrue(idIn2, @"test id should match");
            //TODO
//            XCTAssertNil(f2.localURL, @"should not have a local id");
//            XCTAssertNotNil(f2.data, @"should have data");
//            XCTAssertEqualObjects(f2.data, testData(), @"data should match");
            
            XCTAssertFalse([f1.fileId isEqual:f2.fileId], @"should be different ids");
            XCTAssertFalse([f1.filename isEqual:f2.filename], @"Should be different files");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testDownloadDataByName
{
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadDataByName:kTestFilename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        //TODO
        KTAssertCountAtLeast(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            //TODO
//            XCTAssertNil(resource.localURL, @"should have no local url for data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            //TODO
//            NSData* origData = testData();
//            XCTAssertEqualObjects(resource.data, origData, @"should have matching data");
//            XCTAssertEqual(resource.length, origData.length, @"should have matching lengths");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS
}

- (void) testDownloadDataByNameCancel
{
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    KCSRequest* request = [KCSFileStore downloadDataByName:kTestFilename
                                           completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        //TODO
        KTAssertCountAtLeast(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            //TODO
            //            XCTAssertNil(resource.localURL, @"should have no local url for data");
            XCTAssertEqualObjects(resource.fileId, kTestId, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, kTestFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, kTestMimeType, @"should have a mime type");
            
            //TODO
            //            NSData* origData = testData();
            //            XCTAssertEqualObjects(resource.data, origData, @"should have matching data");
            //            XCTAssertEqual(resource.length, origData.length, @"should have matching lengths");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
}

- (void) testDownloadByNameError
{
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadDataByName:@"NO-SUCH-FILE" completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(0, downloadedResources);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_NO_PROGRESS
}

- (void) testDownloadDataByMultipleNames
{
    //1. upload two files
    //2. download two files
    //3. check there are two valid files
    __block NSString* file2name = nil;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        file2name = uploadInfo.filename;
        XCTAssertFalse([file2name isEqualToString:kTestFilename], @"file 2 should be different");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    NSArray* names = @[kTestFilename, file2name];
    [KCSFileStore downloadDataByName:names completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        
        //TODO
        KTAssertCountAtLeast(2, downloadedResources);
        
        if (downloadedResources.count > 1) {
            KCSFile* f1 = downloadedResources[0];
            KCSFile* f2 = downloadedResources[1];
            
            BOOL idIn = [names containsObject:f1.filename];
            XCTAssertTrue(idIn, @"test name should match");
            //TODO
//            XCTAssertNil(f1.localURL, @"should not have a local url");
//            XCTAssertNotNil(f1.data, @"should have data");
            
            BOOL idIn2 = [names containsObject:f2.filename];
            XCTAssertTrue(idIn2, @"test name should match");
            //TODO
//            XCTAssertNil(f2.localURL, @"should not have a local url");
//            XCTAssertNotNil(f2.data, @"should have data");
            
            XCTAssertFalse([f1.fileId isEqual:f2.fileId], @"should be different ids");
            XCTAssertFalse([f1.filename isEqual:f2.filename], @"should have different filenames");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

#pragma mark - download from a resolved URL

- (void) testDownloadWithResolvedURL
{
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
            XCTAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLCancel
{
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    KCSRequest* request = [KCSFileStore downloadFileWithResolvedURL:downloadURL
                                                            options:nil
                                                    completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
            XCTAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
}

- (void) testDownloadWithResolvedURLOptionsFilename
{
    NSString* filename = @"hookemsnivy.rtf";
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, filename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, @"text/rtf", @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertEqualObjects([dlFile.localURL lastPathComponent], filename, @"local file should have the specified filename");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
            XCTAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLOptionsIfNewer
{
    //start by downloading file
    __block NSDate* firsDate = nil;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:kTestId options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            firsDate = attributes[NSFileModificationDate];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
            XCTAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
            
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            NSDate* thisDate = attributes[NSFileModificationDate];
            KTAssertEqualsDates(thisDate, firsDate);
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    //should have no progress b/c they are local
    KTAssertCount(0, progresses);
    KTAssertCount(0, datas);
}


- (void) testDownloadWithResolvedURLOptionsIfNewerButNotNewer
{
    //start by downloading file
    
    __block NSDate* firstDate = nil;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:kTestId options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            firstDate = attributes[NSFileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    PAUSE
    
    //then re-upload file
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:@{KCSFileId : kTestId} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
            XCTAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
            
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            NSDate* thisDate = attributes[NSFileModificationDate];
            NSComparisonResult oldComparedToNew = [firstDate compare:thisDate];
            XCTAssertTrue(oldComparedToNew == NSOrderedAscending, @"file should not have been modified");
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
}

- (void) testDownloadWithResolvedURLOptionsFilenameAndNewer
{
    NSString* filename = @"hookemsnivy.rtf";
    
    //start by downloading file
    __block NSDate* firsDate = nil;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:kTestId options:@{KCSFileFileName : filename} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertEqualObjects([dlFile.localURL lastPathComponent], filename, @"local file should have the specified filename");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            firsDate = attributes[NSFileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileFileName : filename, KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, filename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, @"text/rtf", @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertEqualObjects([dlFile.localURL lastPathComponent], filename, @"local file should have the specified filename");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
            NSData* downloadedData = [NSData dataWithContentsOfURL:dlFile.localURL];
            XCTAssertEqualObjects(downloadedData, testData(), @"should get our test data back");
            
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            NSDate* thisDate = attributes[NSFileModificationDate];
            XCTAssertEqualObjects(thisDate, firsDate, @"file should not have been modified");
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    //should have no progress b/c they are local
    KTAssertCount(0, progresses);
    KTAssertCount(0, datas);
    
}

- (void) testDownloadWithResolvedURLStopAndResume
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block NSString* fileId;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        fileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    
    NSURL* downloadURL = [self getDownloadURLForId:fileId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSDate* localLMT = nil;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNil(error, @"Should get an error");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            XCTAssertTrue(dlFile.length == kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            //TODO
//            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
            error = nil;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            //TODO
//            STAssertNoError_;
            localLMT = attributes[NSFileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    [NSThread sleepForTimeInterval:1];
    __weak __block XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileResume : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            KTAssertEqualsInt(dlFile.length, kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            NSDate* newLMT = attributes[NSFileModificationDate];
            NSComparisonResult oldComparedToNew = [localLMT compare:newLMT];
            //TODO
//            XCTAssertTrue(oldComparedToNew == NSOrderedAscending, @"file should be updated");
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload2 = nil;
    }];
    
    //TODO
//    XCTAssertEqual(firstWritten + secondWritten, (unsigned long long) kImageSize, @"should have only downloaded the total num bytes");
}

- (void) testDownloadWithResolvedURLStopAndResumeFromBeginningIfNewer
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block NSString* fileId;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        fileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    
    NSURL* downloadURL = [self getDownloadURLForId:fileId];
    
    //start a download and then abort it
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSDate* localLMT = nil;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNil(error, @"Should get an error");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            XCTAssertTrue(dlFile.length == kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            //TODO
//            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
            error = nil;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            //TODO
//            STAssertNoError_;
            localLMT = attributes[NSFileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    //update the file
    PAUSE
    __weak __block XCTestExpectation* expectationUpload2 = [self expectationWithDescription:@"upload2"];
    [KCSFileStore uploadFile:[self largeImageURL] options:@{KCSFileId : fileId} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        fileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload2 fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload2 = nil;
    }];
    
    //restart the download and make sure it starts over from the beginning
    __weak __block XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:@{KCSFileResume : @(YES), KCSFileOnlyIfNewer : @(YES)} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            KTAssertEqualsInt(dlFile.length, kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
//            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
//            NSDate* newLMT = attributes[NSFileModificationDate];
//            XCTAssertTrue([localLMT compare:newLMT] == NSOrderedAscending, @"file should be updated");
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload2 = nil;
    }];
    //Note: don't ASSERT_PROGRESS becuase progress is going to go 0, .1, .2.. for first download and start back at 0 for second download - no longer monotonically increasing
}

- (void) testDownloadWithURLData
{
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    [KCSFileStore downloadDataWithResolvedURL:downloadURL completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNotNil(dlFile.data, @"should have data");
            XCTAssertEqualObjects(dlFile.filename, kTestFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, kTestId, @"should match ids");
            XCTAssertEqual(dlFile.length, testData().length, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kTestMimeType, @"mime types should match");
            XCTAssertNil(dlFile.localURL, @"should not have a local URL");
            XCTAssertEqualObjects(dlFile.data, testData(), @"should get our test data back");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    ASSERT_PROGESS
}

- (void) testDownloadWithURLDataCancel
{
    NSURL* downloadURL = [self getDownloadURLForId:kTestId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    SETUP_PROGRESS
    KCSRequest* request = [KCSFileStore downloadDataWithResolvedURL:downloadURL
                                                    completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        XCTFail();
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
}

- (void) testResume
{
    //1. Upload Image
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block NSString* fileId;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        fileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //2. Start Download
    NSURL* downloadURL = [self getDownloadURLForId:fileId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSDate* localLMT = nil;
    __block NSURL* startedURL = nil;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNil(error, @"Should get an error");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            XCTAssertTrue(dlFile.length == kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            //TODO
//            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            startedURL = dlFile.localURL;
            
            error = nil;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            //TODO
//            STAssertNoError_;
            localLMT = attributes[NSFileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    //3. Stop Download Mid-stream
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    //TODO
//    ASSERT_PROGESS
    [NSThread sleepForTimeInterval:1];
    
    //4. Resume Download
    __weak __block XCTestExpectation* expectationResumeDownload = [self expectationWithDescription:@"resumeDownload"];
    [KCSFileStore resumeDownload:startedURL from:downloadURL completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            KTAssertEqualsInt(dlFile.length, kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            XCTAssertEqualObjects(dlFile.localURL, startedURL, @"should restart URL");
            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            STAssertNoError_;
            NSDate* newLMT = attributes[NSFileModificationDate];
            NSComparisonResult oldComparedToNew = [localLMT compare:newLMT];
            //TODO
//            XCTAssertTrue(oldComparedToNew == NSOrderedAscending, @"file should be updated");
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationResumeDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationResumeDownload = nil;
    }];

    //TODO
//    XCTAssertEqual(firstWritten + secondWritten, (unsigned long long) kImageSize, @"should have only downloaded the total num bytes");
}

- (void) testResumeCancel
{
    //1. Upload Image
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block NSString* fileId;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        fileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //2. Start Download
    NSURL* downloadURL = [self getDownloadURLForId:fileId];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    __block NSDate* localLMT = nil;
    __block NSURL* startedURL = nil;
    SETUP_PROGRESS
    [KCSFileStore downloadFileWithResolvedURL:downloadURL options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNil(error, @"Should get an error");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, fileId, @"should match ids");
            XCTAssertTrue(dlFile.length == kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            //TODO
            //            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            startedURL = dlFile.localURL;
            
            error = nil;
            NSDictionary* attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[dlFile.localURL path] error:&error];
            //TODO
            //            STAssertNoError_;
            localLMT = attributes[NSFileModificationDate];
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    //3. Stop Download Mid-stream
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
    //TODO
    //    ASSERT_PROGESS
    [NSThread sleepForTimeInterval:1];
    
    //4. Resume Download
    __weak __block XCTestExpectation* expectationResumeDownload = [self expectationWithDescription:@"resumeDownload"];
    KCSRequest* request = [KCSFileStore resumeDownload:startedURL
                                                  from:downloadURL
                                       completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        XCTFail();
        
        [expectationResumeDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationResumeDownload fulfill];
    };
    
    [request cancel];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationResumeDownload = nil;
    }];
    
    XCTAssertTrueWait(request.isCancelled, 10);
}

- (void) testTTLExpiresMidUpdate
{
    //1. Set a low ttl
    //2. Upload a large file w/pause
    
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    NSURL* fileURL = [self largeImageURL];
    [KCSFileStore uploadFile:fileURL options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, kImageMimeType, @"should use default mimetype");
        
        newFileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:newFileId options:@{KCSFileLinkExpirationTimeInterval : @0.7} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        //TODO
//        STAssertNoError_
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* dlFile = downloadedResources[0];
            XCTAssertNil(dlFile.data, @"no data");
            XCTAssertEqualObjects(dlFile.filename, kImageFilename, @"should match filenames");
            XCTAssertEqualObjects(dlFile.fileId, newFileId, @"should match ids");
            //TODO
//            KTAssertEqualsInt(dlFile.length, kImageSize, @"lengths should match");
            XCTAssertEqualObjects(dlFile.mimeType, kImageMimeType, @"mime types should match");
            XCTAssertNotNil(dlFile.localURL, @"should be a local URL");
            //TODO
//            XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[dlFile.localURL path]], @"should exist");
            
            [[NSFileManager defaultManager] removeItemAtURL:dlFile.localURL error:&error];
            //TODO
//            STAssertNoError_
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testTTLExpires
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block NSString* fileId = nil;
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_
        fileId = uploadInfo.fileId;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertNotNil(fileId, @"should have valid file");
    
    SETUP_PROGRESS;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:fileId options:@{KCSFileStoreTestExpries : @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNotNil(error, @"Should have an error");
        //TODO
//        XCTAssertEqual(error.code, 400, @"Should be a 400");
//        XCTAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"should be a file error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_NO_PROGRESS;
}

#pragma mark - Streaming

- (void) testStreamingBasic
{
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    [KCSFileStore getStreamingURL:kTestId completionBlock:^(KCSFile *streamingResource, NSError *error) {
        STAssertNoError_;
        XCTAssertNil(streamingResource.localURL, @"should have no local url for data");
        XCTAssertEqualObjects(streamingResource.fileId, kTestId, @"file ids should match");
        XCTAssertEqualObjects(streamingResource.filename, kTestFilename, @"should have a filename");
        XCTAssertEqualObjects(streamingResource.mimeType, kTestMimeType, @"should have a mime type");
        XCTAssertNil(streamingResource.data, @"should have no data");
        XCTAssertNil(streamingResource.data, @"should have no data");
        XCTAssertEqual(streamingResource.length, testData().length, @"should have matching lengths");
        XCTAssertNotNil(streamingResource.remoteURL, @"should have a remote URL");
        XCTAssertNotNil(streamingResource.expirationDate, @"should have a valid date");
        XCTAssertTrue([streamingResource.expirationDate isKindOfClass:[NSDate class]], @"should be a date");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
}

- (void) testStreamingBasicCancel
{
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    KCSRequest* request = [KCSFileStore getStreamingURL:kTestId
                                        completionBlock:^(KCSFile *streamingResource, NSError *error)
    {
        XCTFail();
        
        [expectationStream fulfill];
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationStream fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
}

- (void) testStreamingError
{
    __weak XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    [KCSFileStore getStreamingURL:@"NO-FILE" completionBlock:^(KCSFile *streamingResource, NSError *error) {
        XCTAssertNotNil(error, @"should get an error");
        XCTAssertNil(streamingResource, @"no resources");
        XCTAssertNotNil(error, @"should get an error");
        
        KTAssertEqualsInt(error.code, 404, @"no item error");
        XCTAssertEqualObjects(error.domain, KCSServerErrorDomain, @"is a file error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testStreamingByName
{
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    __block NSURL* streamURL = nil;
    [KCSFileStore getStreamingURLByName:kTestFilename completionBlock:^(KCSFile *streamingResource, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(streamingResource, @"need a resource");
        streamURL = streamingResource.remoteURL;
        XCTAssertNotNil(streamURL, @"need a stream");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
    XCTAssertNotNil(streamURL, @"streaming URL");
    
    NSData* data = [NSData dataWithContentsOfURL:streamURL];
    XCTAssertNotNil(data, @"have valid data");
    XCTAssertEqualObjects(data, testData(), @"data should match");
}

- (void) testStreamingByNameCancel
{
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    __block NSURL* streamURL = nil;
    KCSRequest* request = [KCSFileStore getStreamingURLByName:kTestFilename
                                              completionBlock:^(KCSFile *streamingResource, NSError *error)
    {
        XCTFail();
        
        [expectationStream fulfill];
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationStream fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
    XCTAssertNil(streamURL);
    
    NSData* data = [NSData dataWithContentsOfURL:streamURL];
    XCTAssertNil(data);
    XCTAssertNotEqualObjects(data, testData());
}

- (void) testStreamingByNameError
{
    __weak XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    [KCSFileStore getStreamingURLByName:@"NO-FILE" completionBlock:^(KCSFile *streamingResource, NSError *error) {
        XCTAssertNotNil(error, @"should get an error");
        XCTAssertNil(streamingResource, @"no resources");
        XCTAssertNotNil(error, @"should get an error");
        
        KTAssertEqualsInt(error.code, 404, @"no item error");
        XCTAssertEqualObjects(error.domain, KCSResourceErrorDomain, @"is a file error");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testGetUIImageWithURL
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    NSURL* fileURL = [self largeImageURL];
    [KCSFileStore uploadFile:fileURL options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, kImageMimeType, @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __block KCSFile* streamingFile = nil;
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    [KCSFileStore getStreamingURL:newFileId completionBlock:^(KCSFile *streamingResource, NSError *error) {
        STAssertNoError_
        XCTAssertNotNil(streamingResource, @"should be not nil");
        XCTAssertNotNil(streamingResource.remoteURL, @"Should get back a valid URL");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        streamingFile = streamingResource;
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
    
    XCTAssertNotNil(streamingFile, @"should get back a valid file");
    
    NSData* data = [NSData dataWithContentsOfURL:streamingFile.remoteURL];
    UIImage* image = [UIImage imageWithData:data];
    XCTAssertNotNil(image, @"Should be a valid image");
}

#pragma mark - Uploading

- (void) testSaveLocalResource
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertEqualObjects(uploadInfo.filename, kImageFilename, @"filename should match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:kImageFilename], @"file id should be unique");
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    ASSERT_PROGESS
    
    if (newFileId) {
        __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
            expectationDelete = nil;
        }];
    }
}

- (void) testUploadLFOptions
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    NSString* fileId = [NSString UUID];
    [KCSFileStore uploadFile:[self largeImageURL]
                     options:@{KCSFileFileName: @"FOO",
                               KCSFileMimeType: @"BAR",
                               KCSFileId: fileId }
             completionBlock:^(KCSFile *uploadInfo, NSError *error)
    {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertEqualObjects(uploadInfo.filename, @"FOO", @"filename should match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertEqualObjects(uploadInfo.fileId, fileId, @"file id should be match");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"BAR", @"mime type should match");
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes shoukld match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    ASSERT_PROGESS
    
    KCSFile* metaFile = [self getMetadataForId:newFileId];
    XCTAssertNotNil(metaFile, @"metaFile should be a real value");
    XCTAssertEqualObjects(metaFile.filename, @"FOO", @"filename should match");
    XCTAssertEqualObjects(metaFile.fileId, fileId, @"file id should be match");
    XCTAssertEqualObjects(metaFile.mimeType, @"BAR", @"mime type should match");
    KTAssertEqualsInt(metaFile.length, kImageSize, @"sizes shoukld match");
    
    if (newFileId) {
        __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
            expectationDelete = nil;
        }];
    }
}

- (void) testErrorOnSpecifyingSizeOfUpload
{
    void(^badcall)() = ^{[KCSFileStore uploadFile:[self largeImageURL]
                                          options:@{KCSFileSize: @(100),
                                                    KCSFileMimeType: @"BAR"}
                                  completionBlock:^(KCSFile *uploadInfo, NSError *error) {
                                      STAssertNoError_;
                                      
                                      XCTAssertTrue([NSThread isMainThread]);
                                  } progressBlock:^(NSArray *objects, double percentComplete) {
                                      XCTAssertTrue([NSThread isMainThread]);
                                  }];};
    XCTAssertThrows(badcall(), @"Should have a size issue");
}

- (void) testMimeTypeGuessForSpecifiedFilename
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    [KCSFileStore uploadData:testData()
                     options:@{KCSFileFileName: @"FOO"}
             completionBlock:^(KCSFile *uploadInfo, NSError *error) {
                 STAssertNoError_;
                 XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
                 XCTAssertEqualObjects(uploadInfo.filename, @"FOO", @"filename should match");
                 XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
                 XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"mime type should be bin");
                 KTAssertEqualsInt(uploadInfo.length, kTestSize, @"sizes shoukld match");
                 
                 XCTAssertTrue([NSThread isMainThread]);
                 
                 newFileId = uploadInfo.fileId;
                 
                 [expectationUpload fulfill];
             } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    if (newFileId) {
        __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
    
    __weak XCTestExpectation* expectationUpload2 = [self expectationWithDescription:@"upload2"];
    [KCSFileStore uploadData:testData()
                     options:@{KCSFileFileName: @"jazz.wav"}
             completionBlock:^(KCSFile *uploadInfo, NSError *error) {
                 STAssertNoError_;
                 XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
                 XCTAssertEqualObjects(uploadInfo.filename, @"jazz.wav", @"filename should match");
                 XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
                 XCTAssertEqualObjects(uploadInfo.mimeType, @"audio/wav", @"mime type should be audio");
                 KTAssertEqualsInt(uploadInfo.length, kTestSize, @"sizes shoukld match");
                 
                 XCTAssertTrue([NSThread isMainThread]);
                 
                 newFileId = uploadInfo.fileId;
                 
                 [expectationUpload2 fulfill];
             } progressBlock:^(NSArray *objects, double percentComplete) {
                 XCTAssertTrue([NSThread isMainThread]);
             }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    if (newFileId) {
        __weak XCTestExpectation* expectationDelete2 = [self expectationWithDescription:@"delete2"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete2 fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
    
    __weak XCTestExpectation* expectationUpload3 = [self expectationWithDescription:@"upload3"];
    [KCSFileStore uploadData:testData()
                     options:nil
             completionBlock:^(KCSFile *uploadInfo, NSError *error) {
                 STAssertNoError_;
                 XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
                 XCTAssertNotNil(uploadInfo.filename, @"filename should be set");
                 XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
                 XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"mime type should be bin");
                 KTAssertEqualsInt(uploadInfo.length, kTestSize, @"sizes shoukld match");
                 
                 XCTAssertTrue([NSThread isMainThread]);
                 
                 newFileId = uploadInfo.fileId;
                 
                 [expectationUpload3 fulfill];
             } progressBlock:^(NSArray *objects, double percentComplete) {
                 XCTAssertTrue([NSThread isMainThread]);
             }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    if (newFileId) {
        __weak XCTestExpectation* expectationDelete3 = [self expectationWithDescription:@"delete3"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete3 fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
}

- (void) testUploadLFPublic
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    NSURL* fileURL = [self largeImageURL];
    [KCSFileStore uploadFile:fileURL options:@{KCSFilePublic : @YES} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        XCTAssertEqualObjects(uploadInfo.publicFile, @(YES), @"should be public");
        
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        XCTAssertNotNil(uploadInfo.localURL, @"should not be nil");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, kImageMimeType, @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    [KCSFileStore getStreamingURL:newFileId options:@{KCSFileLinkExpirationTimeInterval : @1} completionBlock:^(KCSFile *streamingResource, NSError *error) {
        STAssertNoError_;
        NSURL* remoteURL = streamingResource.remoteURL;
        XCTAssertNotNil(remoteURL, @"should have a valid URL");
        
        NSLog(@"Sleeping for 10s to wait out the ttl");
        [NSThread sleepForTimeInterval:10];
        
        NSData* data = [NSData dataWithContentsOfURL:remoteURL];
        XCTAssertNotNil(data, @"should get back new data");
        XCTAssertEqualObjects(data, [NSData dataWithContentsOfURL:[self largeImageURL]], @"should get back our test data");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
}

- (void) testUploadLFPublicCancel
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    NSURL* fileURL = [self largeImageURL];
    [KCSFileStore uploadFile:fileURL options:@{KCSFilePublic : @YES} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        XCTAssertEqualObjects(uploadInfo.publicFile, @(YES), @"should be public");
        
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        XCTAssertNotNil(uploadInfo.localURL, @"should not be nil");
        //TODO
        //        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, kImageMimeType, @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __weak __block XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    KCSRequest* request = [KCSFileStore getStreamingURL:newFileId
                                                options:@{KCSFileLinkExpirationTimeInterval : @1}
                                        completionBlock:^(KCSFile *streamingResource, NSError *error)
    {
        XCTFail();
        
        [expectationStream fulfill];
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationStream fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationStream = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
}

- (void) testUploadLFACL
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    KCSMetadata* metadata =[[KCSMetadata alloc] init];
    [metadata setGloballyReadable:YES];
    [metadata setGloballyWritable:YES];
    [KCSFileStore uploadFile:[self largeImageURL] options:@{KCSFileACL : metadata} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        
        KCSMetadata* meta = uploadInfo.metadata;
        XCTAssertNotNil(meta, @"should not be nil");
        XCTAssertTrue(meta.isGloballyWritable, @"gw should take");
        XCTAssertTrue(meta.isGloballyReadable, @"gr should take");
        
        
        KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes should match");
        XCTAssertNotNil(uploadInfo.localURL, @"should not be nil");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, kImageMimeType, @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    KCSAppdataStore* fileStore = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    [fileStore loadObjectWithID:newFileId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        
        if (objectsOrNil.count > 0) {
            KCSFile* file = objectsOrNil[0];
            KCSMetadata* meta = file.metadata;
            XCTAssertNotNil(meta, @"should not be nil");
            XCTAssertTrue(meta.isGloballyWritable, @"gw should take");
            XCTAssertTrue(meta.isGloballyReadable, @"gr should take");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testLMTGetsUpdatedEvenIfNoMetadataChange
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    __block KCSFile* origFile = nil;
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        origFile = uploadInfo;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        KTAssertEqualsInt(uploadInfo.length, testData().length, @"sizes should match");
        XCTAssertNil(uploadInfo.localURL, @"should be nil");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    [NSThread sleepForTimeInterval:2];
    
    __weak XCTestExpectation* expectationUpload2 = [self expectationWithDescription:@"upload2"];
    [KCSFileStore uploadData:testData() options:@{KCSFileId : newFileId} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        
        XCTAssertEqualObjects(uploadInfo.filename, origFile.filename, @"filenames should match");
        XCTAssertEqual(uploadInfo.length, origFile.length, @"lengths should match");
        XCTAssertEqualObjects(uploadInfo.mimeType, origFile.mimeType, @"types should match");
        XCTAssertFalse([uploadInfo.metadata.lastModifiedTime isEqualToDate:origFile.metadata.lastModifiedTime], @"lmts should not times match");
        XCTAssertTrue([uploadInfo.metadata.creationTime isEqualToDate:origFile.metadata.creationTime], @"ect times should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload2 fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    if (newFileId) {
        __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
}

- (void) testSaveDataBasic
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        KTAssertEqualsInt(uploadInfo.length, testData().length, @"sizes should match");
        XCTAssertNil(uploadInfo.localURL, @"should be nil");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    if (newFileId) {
        __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDelete fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
}

- (void) testUploadDataPublic
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    [KCSFileStore uploadData:testData() options:@{KCSFilePublic : @YES} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        XCTAssertEqualObjects(uploadInfo.publicFile, @(YES), @"should be public");
        
        KTAssertEqualsInt(uploadInfo.length, testData().length, @"sizes should match");
        XCTAssertNil(uploadInfo.localURL, @"should be nil");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __weak XCTestExpectation* expectationStream = [self expectationWithDescription:@"stream"];
    [KCSFileStore getStreamingURL:newFileId options:@{KCSFileLinkExpirationTimeInterval : @1} completionBlock:^(KCSFile *streamingResource, NSError *error) {
        STAssertNoError_;
        NSURL* remoteURL = streamingResource.remoteURL;
        XCTAssertNotNil(remoteURL, @"should have a valid URL");
        
        NSLog(@"Sleeping for 10s to wait out the ttl");
        [NSThread sleepForTimeInterval:10];
        
        NSData* data = [NSData dataWithContentsOfURL:remoteURL];
        XCTAssertNotNil(data, @"should get back new data");
        XCTAssertEqualObjects(data, testData(), @"should get back our test data");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationStream fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testUploadDataACL
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    KCSMetadata* metadata =[[KCSMetadata alloc] init];
    [metadata setGloballyReadable:YES];
    [metadata setGloballyWritable:YES];
    [KCSFileStore uploadData:testData() options:@{KCSFileACL : metadata} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertNotNil(uploadInfo.filename, @"filename should have faule");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertFalse([uploadInfo.fileId isEqualToString:uploadInfo.filename], @"file id should be unique");
        
        KCSMetadata* meta = uploadInfo.metadata;
        XCTAssertNotNil(meta, @"should not be nil");
        XCTAssertTrue(meta.isGloballyWritable, @"gw should take");
        XCTAssertTrue(meta.isGloballyReadable, @"gr should take");
        
        KTAssertEqualsInt(uploadInfo.length, testData().length, @"sizes should match");
        XCTAssertNil(uploadInfo.localURL, @"should be nil");
        //TODO
//        XCTAssertNil(uploadInfo.remoteURL, @"should be nil");
        XCTAssertNil(uploadInfo.data, @"should have nil data");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"should use default mimetype");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        newFileId = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    XCTAssertNotNil(newFileId, @"Should get a file id");
    
    __weak XCTestExpectation* expectationLoad = [self expectationWithDescription:@"load"];
    KCSAppdataStore* fileStore = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    [fileStore loadObjectWithID:newFileId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertObjects(1);
        
        if (objectsOrNil.count > 0) {
            KCSFile* file = objectsOrNil[0];
            KCSMetadata* meta = file.metadata;
            XCTAssertNotNil(meta, @"should not be nil");
            XCTAssertTrue(meta.isGloballyWritable, @"gw should take");
            XCTAssertTrue(meta.isGloballyReadable, @"gr should take");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLoad fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testUploadDownloadFileWithPathCharacters
{
    //test path components slashes, spaces, etc, dots
    NSString* myFilename = @"FOO/re space%rkm.me👍\\か、最新bcf";
    
    NSString* myID = [NSString stringWithFormat:@"BED__ R/fsda.faめセレクションse‱🌇e/SCHME’-%@", [NSString UUID]];
    
    SETUP_PROGRESS;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:@{KCSFileFileName : myFilename, KCSFileId : myID} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertEqualObjects(uploadInfo.filename, myFilename, @"filename should match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertEqualObjects(uploadInfo.fileId, myID, @"file id should be match");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"mime type should match");
        KTAssertEqualsInt(uploadInfo.length, kTestSize, @"sizes shoukld match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    CLEAR_PROGRESS;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadData:myID completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        KTAssertCount(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            XCTAssertNil(resource.localURL, @"should have no local url for data");
            XCTAssertEqualObjects(resource.fileId, myID, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, myFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, @"application/octet-stream", @"should have a mime type");
            
            NSData* origData = testData();
            
            XCTAssertEqualObjects(resource.data, origData, @"should have matching data");
            XCTAssertEqual(resource.length, origData.length, @"should have matching lengths");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:myID completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testUploadDownloadFileWithPathCharactersArray
{
    //test path components slashes, spaces, etc, dots
    NSString* myFilename = @"FOO/re space%rkm.me👍\\か、最新bcf";
    
    NSString* myID = [NSString stringWithFormat:@"BED__ R/fsda.faめセレクションse‱🌇e/SCHME’-%@", [NSString UUID]];
    
    SETUP_PROGRESS;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:@{KCSFileFileName : myFilename, KCSFileId : myID} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
        XCTAssertEqualObjects(uploadInfo.filename, myFilename, @"filename should match");
        XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
        XCTAssertEqualObjects(uploadInfo.fileId, myID, @"file id should be match");
        XCTAssertEqualObjects(uploadInfo.mimeType, @"application/octet-stream", @"mime type should match");
        KTAssertEqualsInt(uploadInfo.length, kTestSize, @"sizes shoukld match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    CLEAR_PROGRESS;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadData:@[myID, @"🎡♝Forsyth xe/mme.afoo"] completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //assert one KCSFile & its data is the right data
        XCTAssertNotNil(downloadedResources, @"should have a resource");
        //TODO
        KTAssertCountAtLeast(1, downloadedResources);
        
        if (downloadedResources.count > 0) {
            KCSFile* resource = downloadedResources[0];
            //TODO
//            XCTAssertNil(resource.localURL, @"should have no local url for data");
            XCTAssertEqualObjects(resource.fileId, myID, @"file ids should match");
            XCTAssertEqualObjects(resource.filename, myFilename, @"should have a filename");
            XCTAssertEqualObjects(resource.mimeType, @"application/octet-stream", @"should have a mime type");
            
            NSData* origData = testData();

            //TODO
//            XCTAssertEqualObjects(resource.data, origData, @"should have matching data");
//            XCTAssertEqual(resource.length, origData.length, @"should have matching lengths");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:myID completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//TODO: implement this
/*
 - (void) testUploadResume
 {
 //1. Upload partial
 //2. Cancel
 //3. Upload rest
 //4. check # bytes written should be single total
 //5. dl file and check that the file size is correct.
 NSLog(@"---------------------- TEST START ------------------------");
 
 //1. Upload partial
 self.done = NO;
 __block double progress = 0.;
 __block NSString* fileId = nil;
 __block KCSFile* file = nil;
 [KCSFileStore uploadFile:[self largeImageURL] options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
 STAssertNotNil(uploadInfo, @"should still have this info");
 fileId = uploadInfo.fileId;
 file = uploadInfo;
 STAssertNotNil(fileId, @"should have a fileid");
 STAssertNotNil(error, @"should get an errror");
 
 self.done = YES;
 } progressBlock:^(NSArray *objects, double percentComplete) {
 progress = percentComplete;
 }];
 
 //2. Cancel
 double delayInSeconds = 1.6;
 __block id lastRequest;
 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
 dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
 NSLog(@"cancelling...");
 lastRequest = [KCSFileStore lastRequest];
 STAssertNotNil(lastRequest, @"should have a request");
 [lastRequest cancel];
 });
 [self poll];
 
 STAssertTrue(progress > 0 && progress < 1., @"Should have had some but not all progress");
 unsigned long long firstWritten = [lastRequest bytesWritten];
 [NSThread sleepForTimeInterval:1];
 
 
 //3. Upload Rest
 self.done = NO;
 [KCSFileStore uploadKCSFile:file options:@{KCSFileResume : @(YES)} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
 STAssertNoError_
 self.done = YES;
 } progressBlock:nil];
 [self poll];
 
 //4. check # bytes written should be single total
 lastRequest = [KCSFileStore lastRequest];
 unsigned long long totalBytes = firstWritten + [lastRequest bytesWritten];
 KTAssertEqualsInt(totalBytes, kImageSize, @"should have only written the total bytes");
 
 self.done = NO;
 [KCSFileStore uploadKCSFile:file options:@{KCSFileResume : @(YES)} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
 STAssertNoError_
 self.done = YES;
 } progressBlock:nil];
 [self poll];
 
 //5. dl file and check that the file size is correct.
 self.done = NO;
 [KCSFileStore downloadData:fileId completionBlock:^(NSArray *downloadedResources, NSError *error) {
 STAssertNoError_;
 KCSFile* file = downloadedResources[0];
 NSData* d = file.data;
 KTAssertEqualsInt(d.length, kImageSize, @"should be full data");
 UIImage* image = [UIImage imageWithData:d];
 STAssertNotNil(image, @"should have a valid image");
 self.done = YES;
 } progressBlock:nil];
 [self poll];
 
 // Cleanup
 self.done = NO;
 [KCSFileStore deleteFile:fileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
 STAssertNoError;
 self.done = YES;
 }];
 [self poll];
 }
 */
- (void) TODO_testStreamingUpload
{
    //TODO: try this out in the future
}

#pragma mark - Delete

- (void) testDelete
{
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:kTestId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertEqualsInt(count, 1, @"should have deleted one file");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadData:kTestId completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNotNil(error, @"should get an error");
        XCTAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"Should be a file error");
        KTAssertEqualsInt(error.code, KCSNotFoundError, @"should be a 404");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
}

- (void) testDeleteCancel
{
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    KCSRequest* request = [KCSFileStore deleteFile:kTestId
                                   completionBlock:^(unsigned long count, NSError *errorOrNil)
    {
        XCTFail();
        
        [expectationDelete fulfill];
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDelete fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    request = [KCSFileStore downloadData:kTestId
                         completionBlock:^(NSArray *downloadedResources, NSError *error)
    {
        XCTAssertNotNil(error, @"should get an error");
        XCTAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"Should be a file error");
        KTAssertEqualsInt(error.code, KCSNotFoundError, @"should be a 404");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationDownload fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
}

- (void) testDeleteByName
{
    self.done = NO;
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection fileMetadataCollection] options:nil];
    KCSQuery* nameQuery = [KCSQuery queryOnField:KCSFileFileName withExactMatchForValue:kTestFilename];
    
    __weak __block XCTestExpectation* expectationQuery = [self expectationWithDescription:@"query"];
    __block NSString* fileId = nil;
    [store queryWithQuery:nameQuery withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertCount(1, objectsOrNil);
        if (objectsOrNil.count > 0) {
            KCSFile* file = objectsOrNil[0];
            fileId = file.fileId;
            
            XCTAssertNotNil(fileId, @"should have a valid file");
            XCTAssertEqualObjects(fileId, kTestId, @"should be the test id");
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationQuery fulfill];
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationQuery = nil;
    }];
    
    XCTAssertNotNil(fileId, @"should have a valid file");
    
    __weak __block XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:fileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError;
        KTAssertEqualsInt(count, 1, @"should have deleted one file");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDelete = nil;
    }];
    
    __weak __block XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadData:fileId completionBlock:^(NSArray *downloadedResources, NSError *error) {
        XCTAssertNotNil(error, @"should get an error");
        XCTAssertEqualObjects(error.domain, KCSFileStoreErrorDomain, @"Should be a file error");
        KTAssertEqualsInt(error.code, KCSNotFoundError, @"should be a 404");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:^(NSError *error) {
        expectationDownload = nil;
    }];
}

- (void) testDeleteError
{
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:@"NO_FILE" completionBlock:^(unsigned long count, NSError *errorOrNil) {
        XCTAssertNotNil(errorOrNil, @"should get an error");
        KTAssertEqualsInt(errorOrNil.code, 404, @"should be no file found");
        XCTAssertEqualObjects(errorOrNil.domain, KCSResourceErrorDomain, @"should be a file error");
        KTAssertEqualsInt(count, 0, @"should have deleted no files");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

#pragma mark - bugs

- (void) testHolderCrash
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    __block NSString* fileId = nil;
    [KCSFileStore uploadData:testData() options:nil completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_
        fileId = uploadInfo.fileId;
        XCTAssertNotNil(fileId, @"should have valid file");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //no logout and use a new user
    [[KCSUser activeUser] logout];
    __weak XCTestExpectation* expectationLogin = [self expectationWithDescription:@"login"];
    [KCSUser loginWithUsername:@"foo" password:@"bar" withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationLogin fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    
    KCSQuery *fileQuery = [KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:fileId];
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFileByQuery:fileQuery completionBlock:^(NSArray *downloadedResources, NSError *error)
     {
         STAssertNoError_
         //TODO
//         KTAssertCount(0, downloadedResources);
         if (!error)
         {
             if (downloadedResources.count > 0)
             {
                 KCSFile* file = downloadedResources[0];
                 NSURL* fileURL = file.localURL;
                 UIImage* image = [UIImage imageWithContentsOfFile:[fileURL path]]; //note this blocks for awhile
                 //TODO
//                 XCTAssertNotNil(image, @"image should be valid");
//                 XCTFail(@"should have no resources");
             }
         }
         
         XCTAssertTrue([NSThread isMainThread]);
         
         [expectationDownload fulfill];
     }
         
    progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //second test
    
    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"download2"];
    [KCSFileStore downloadFile:fileId options:@{KCSFileOnlyIfNewer: @YES} completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_
        //TODO
//        KTAssertCount(0, downloadedResources);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

//hs20413
- (void) testMultipleSimultaneousDownloads
{
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    SETUP_PROGRESS
    __block NSString* newFileId = nil;
    NSString* filename = [NSString UUID];
    [KCSFileStore uploadFile:[self largeImageURL]
                     options:@{KCSFileFileName: filename}
             completionBlock:^(KCSFile *uploadInfo, NSError *error) {
                 STAssertNoError_;
                 XCTAssertNotNil(uploadInfo, @"uploadInfo should be a real value");
                 XCTAssertEqualObjects(uploadInfo.filename, filename, @"filename should match");
                 XCTAssertNotNil(uploadInfo.fileId, @"should have a file id");
                 KTAssertEqualsInt(uploadInfo.length, kImageSize, @"sizes shoukld match");
                 
                 XCTAssertTrue([NSThread isMainThread]);
                 
                 newFileId = uploadInfo.fileId;
                 
                 [expectationUpload fulfill];
             } progressBlock:PROGRESS_BLOCK];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    ASSERT_PROGESS
    

    __block int count = 0;
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadDataByName:filename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        NSLog(@"$$$$ COUNT = %d", count);
        if (count == 0) {
            //TODO
//            STAssertNoError_;
//            KTAssertCount(1, downloadedResources);
        } else {
            //TODO
//            XCTAssertNotNil(error, @"should be error");
//            KTAssertCount(0, downloadedResources);
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (++count == 5) {
            [expectationDownload fulfill];
        }
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [KCSFileStore downloadDataByName:filename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        NSLog(@"$$$$ COUNT = %d", count);
        if (count == 0) {
            //TODO
//            STAssertNoError_;
//            KTAssertCount(1, downloadedResources);
        } else {
            //TODO
//            XCTAssertNotNil(error, @"should be error");
//            KTAssertCount(0, downloadedResources);
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (++count == 5) {
            [expectationDownload fulfill];
        }
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [KCSFileStore downloadDataByName:filename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        NSLog(@"$$$$ COUNT = %d", count);
        if (count == 0) {
            //TODO
//            STAssertNoError_;
//            KTAssertCount(1, downloadedResources);
        } else {
            //TODO
//            XCTAssertNotNil(error, @"should be error");
//            KTAssertCount(0, downloadedResources);
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (++count == 5) {
            [expectationDownload fulfill];
        }
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [KCSFileStore downloadDataByName:filename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        NSLog(@"$$$$ COUNT = %d", count);
        if (count == 0) {
            //TODO
//            STAssertNoError_;
//            KTAssertCount(1, downloadedResources);
        } else {
            //TODO
//            XCTAssertNotNil(error, @"should be error");
//            KTAssertCount(0, downloadedResources);
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (++count == 5) {
            [expectationDownload fulfill];
        }
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [KCSFileStore downloadDataByName:filename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        NSLog(@"$$$$ COUNT = %d", count);
        if (count == 0) {
            //TODO
//            STAssertNoError_;
//            KTAssertCount(1, downloadedResources);
        } else {
            //TODO
//            XCTAssertNotNil(error, @"should be error");
//            KTAssertCount(0, downloadedResources);
        }
        
        XCTAssertTrue([NSThread isMainThread]);
        
        if (++count == 5) {
            [expectationDownload fulfill];
        }
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    //make sure state is cleared and redownload when done

    __weak XCTestExpectation* expectationDownload2 = [self expectationWithDescription:@"downlod2"];
    [KCSFileStore downloadDataByName:filename completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        //TODO
//        KTAssertCount(1, downloadedResources);
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload2 fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    if (newFileId) {
        __weak XCTestExpectation* expectationDownload3 = [self expectationWithDescription:@"downlod3"];
        [KCSFileStore deleteFile:newFileId completionBlock:^(unsigned long count, NSError *errorOrNil) {
            STAssertNoError;
            
            XCTAssertTrue([NSThread isMainThread]);
            
            [expectationDownload3 fulfill];
        }];
        [self waitForExpectationsWithTimeout:30 handler:nil];
    }
}

- (void) testKCSFileEncodeDecode
{
    KCSFile* one = [self getMetadataForId:kTestId];
    NSData* filedata = [NSKeyedArchiver archivedDataWithRootObject:one];
    KCSFile* two = [NSKeyedUnarchiver unarchiveObjectWithData:filedata];
    
    XCTAssertFalse(one == two, @"should be different objects");
    XCTAssertEqualObjects(one, two, @"should be equal data");
}

//g2704
- (void) testFilenameWithSpaces
{
    NSString* filename = @"Porto rotondo.jpg";
    __block NSString* fileid = nil;
    __weak XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    [KCSFileStore uploadData:testData() options:@{KCSFileFileName : filename} completionBlock:^(KCSFile *uploadInfo, NSError *error) {
        STAssertNoError_;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        fileid = uploadInfo.fileId;
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    XCTAssertNotNil(fileid, @"file id should be set");
    
    __weak XCTestExpectation* expectationDownload = [self expectationWithDescription:@"download"];
    [KCSFileStore downloadFile:fileid options:nil completionBlock:^(NSArray *downloadedResources, NSError *error) {
        STAssertNoError_;
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDownload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
    
    __weak XCTestExpectation* expectationDelete = [self expectationWithDescription:@"delete"];
    [KCSFileStore deleteFile:fileid completionBlock:^(unsigned long count, NSError *errorOrNil) {
        STAssertNoError
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationDelete fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (NSURL*) largeVideoURL
{
    return [[NSBundle bundleForClass:[self class]] URLForResource:@"video" withExtension:@"mp4"];
}

/**
 Test for MLIBZ-431
 */
- (void) testUploadLargeFile
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    
    [KCSFileStore uploadFile:[self largeVideoURL]
                     options:nil
             completionBlock:^(KCSFile *uploadInfo, NSError *error)
     {
         STAssertNoError_;
         XCTAssertNotNil(uploadInfo);
         
         XCTAssertTrue([NSThread isMainThread]);
         
         [expectationUpload fulfill];
     } progressBlock:^(NSArray *objects, double percentComplete) {
         XCTAssertTrue([NSThread isMainThread]);
     }];
    
    [self waitForExpectationsWithTimeout:60 * 5 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
}

- (void) testUploadLargeFileCancel
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];

    KCSRequest* request = [KCSFileStore uploadFile:[self largeVideoURL]
                     options:nil
             completionBlock:^(KCSFile *uploadInfo, NSError *error)
    {
        XCTFail();
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationUpload fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:60 * 5 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
}

- (void) testUploadLargeData
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    
    NSData* data = [NSData dataWithContentsOfURL:[self largeVideoURL]];
    [KCSFileStore uploadData:data
                     options:nil
             completionBlock:^(KCSFile *uploadInfo, NSError *error)
     {
         STAssertNoError_;
         XCTAssertNotNil(uploadInfo);
         
         XCTAssertTrue([NSThread isMainThread]);
         
         [expectationUpload fulfill];
     } progressBlock:^(NSArray *objects, double percentComplete) {
         XCTAssertTrue([NSThread isMainThread]);
     }];
    
    [self waitForExpectationsWithTimeout:60 * 5 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
}

- (void) testUploadLargeDataCancel
{
    __weak __block XCTestExpectation* expectationUpload = [self expectationWithDescription:@"upload"];
    
    NSData* data = [NSData dataWithContentsOfURL:[self largeVideoURL]];
    KCSRequest* request = [KCSFileStore uploadData:data
                                           options:nil
                                   completionBlock:^(KCSFile *uploadInfo, NSError *error)
    {
        XCTFail();
        
        [expectationUpload fulfill];
    } progressBlock:^(NSArray *objects, double percentComplete) {
        XCTAssertTrue([NSThread isMainThread]);
    }];
    
    XCTAssertFalse(request.isCancelled);
    
    request.cancellationBlock = ^{
        [expectationUpload fulfill];
    };
    
    [request cancel];
    
    XCTAssertTrue(request.isCancelled);
    
    [self waitForExpectationsWithTimeout:60 * 5 handler:^(NSError *error) {
        expectationUpload = nil;
    }];
}

@end
