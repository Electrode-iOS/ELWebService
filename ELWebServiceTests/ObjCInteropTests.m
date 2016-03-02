//
//  ObjCInteropTests.m
//  ELWebService
//
//  Created by Angelo Di Paolo on 2/2/16.
//  Copyright © 2016 WalmartLabs. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ELWebService.h"
#import "ELWebServiceTests-Swift.h"

@interface ObjCInteropTests : XCTestCase

@end

@implementation ObjCInteropTests

// MARK: - ServiceTask tests

- (NSHTTPURLResponse *)mockResponse {
    return [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"foo"] statusCode:200 HTTPVersion:nil headerFields:nil];
}

- (void)test_responseObjC_handlerGetsCalled {
    XCTestExpectation *expectation = [self expectationWithDescription:@"response handler is called"];
    WebService *service = [[WebService alloc] initWithBaseURLString:@"foo"];
    ServiceTask *task = [service GET:@"bar"];
    [task responseObjC:^ObjCHandlerResult *(NSData *data, NSURLResponse *response) {
        [expectation fulfill];
        return nil;
    }];
    
    [task injectResponse:[self mockResponse] data:nil error:nil];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_updateUIObjC_receivesHandlerResult {
    XCTestExpectation *expectation = [self expectationWithDescription:@"updateUI handler is called"];
    WebService *service = [[WebService alloc] initWithBaseURLString:@"foo"];
    ServiceTask *task = [service GET:@"bar"];
    NSString *mockValue = @"12345";
    [task responseObjC:^ObjCHandlerResult *(NSData *data, NSURLResponse *response) {
        return [ObjCHandlerResult resultWithValue:mockValue];
    }];
    
    [task updateUIObjC:^(id value) {
        XCTAssertTrue([value isKindOfClass:[NSString class]]);
        XCTAssertEqual(value, mockValue);
        [expectation fulfill];
    }];
    
    [task injectResponse:[self mockResponse] data:nil error:nil];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_responseJSONObjC_receivesHandlerResult {
    XCTestExpectation *expectation = [self expectationWithDescription:@"updateUI handler is called"];
    WebService *service = [[WebService alloc] initWithBaseURLString:@"foo"];
    ServiceTask *task = [service GET:@"bar"];
    [task responseJSONObjC:^ObjCHandlerResult *(id json) {
        NSDictionary *dictionary = json;
        XCTAssertTrue([dictionary isKindOfClass:[NSDictionary class]]);
        XCTAssertTrue([dictionary[@"foo"] isEqualToString:@"bar"]);
        [expectation fulfill];
        return nil;
    }];
    
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"foo"] statusCode:200 HTTPVersion:nil headerFields:nil];
    
    [task injectResponse:response data:[NSData mockJSONData] error:nil];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_responseError_calledWhenReturningErrorFromResponseHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"error handler is called"];
    WebService *service = [[WebService alloc] initWithBaseURLString:@"foo"];
    ServiceTask *task = [service GET:@"bar"];
    NSError *mockError = [[NSError alloc] initWithDomain:@"domain" code:500 userInfo:nil];
    [task responseObjC:^ObjCHandlerResult *(NSData *data, NSURLResponse *response) {
        return [ObjCHandlerResult resultWithError:mockError];
    }];
    [task responseErrorObjC:^(NSError * error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, mockError.domain);
        XCTAssertEqual(error.code, mockError.code);
        [expectation fulfill];
    }];
    
    [task injectResponse:[self mockResponse] data:nil error:nil];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)test_updateErrorUI_calledWhenReturningErrorFromResponseHandler {
    XCTestExpectation *expectation = [self expectationWithDescription:@"error handler is called"];
    WebService *service = [[WebService alloc] initWithBaseURLString:@"foo"];
    ServiceTask *task = [service GET:@"bar"];
    NSError *mockError = [[NSError alloc] initWithDomain:@"domain" code:500 userInfo:nil];
    [task responseObjC:^ObjCHandlerResult *(NSData *data, NSURLResponse *response) {
        return [ObjCHandlerResult resultWithError:mockError];
    }];
    [task updateErrorUIObjC:^(NSError * error) {
        XCTAssertNotNil(error);
        XCTAssertEqual(error.domain, mockError.domain);
        XCTAssertEqual(error.code, mockError.code);
        [expectation fulfill];
    }];

    [task injectResponse:[self mockResponse] data:nil error:nil];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
