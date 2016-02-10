//
//  MADResponse.m
//  HttpServer
//
//  Created by Mariia Cherniuk on 09.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import "MADResponse.h"
#include "MADRequest.h"

static NSDictionary *mimeTypes = nil;

@implementation MADResponse

+ (NSDictionary *)sharedMIMETypes {
    if (mimeTypes == nil) {
        mimeTypes = [self convertMIMETypes];
    }
    return mimeTypes;
}

+ (NSDictionary *)convertMIMETypes {
    NSString* bundle = [[NSBundle mainBundle] resourcePath];
    NSString *filePath = [bundle stringByAppendingPathComponent:@"mime.types"];
    NSData *mimeTypesData = [NSData dataWithContentsOfFile:filePath];
    
    return [NSJSONSerialization JSONObjectWithData:mimeTypesData
                                           options:NSJSONReadingAllowFragments
                                             error:nil];
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _responseLine = nil;
        _messageHeaders = nil;
        _responseBody = nil;
    }
    
    return self;
}

- (NSString *)responseToString {
    NSMutableString *strResponse = [[NSMutableString alloc] init];
    
    if (_responseLine.count == 2) {
        [strResponse appendString:[NSString stringWithFormat:
                                   @"%@ %@", _responseLine[@"httpVersion"], _responseLine[@"statusCode"]]];
    } else if (_responseLine.count == 1) {
        [strResponse appendString:[NSString stringWithFormat:@"%@", _responseLine[@"statusCode"]]];
    }
    [strResponse appendString:@"\n"];
    
    if (_messageHeaders != nil) {
        [_messageHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
            [strResponse appendString:[NSString stringWithFormat:@"%@: %@\n", key, obj]];
        }];
    }
    
    if (_responseBody != nil) {
        [strResponse appendString:_responseBody];
    }
    
    return strResponse;
}

- (NSString *)responseLineToString {
    NSMutableString *strResponse = [[NSMutableString alloc] init];
    
    if (_responseLine.count == 2) {
        [strResponse appendString:[NSString stringWithFormat:
                                   @"%@ %@", _responseLine[@"httpVersion"], _responseLine[@"statusCode"]]];
    } else if (_responseLine.count == 1) {
        [strResponse appendString:[NSString stringWithFormat:@"%@", _responseLine[@"statusCode"]]];
    }
    [strResponse appendString:@"\n"];
    
    return strResponse;
}

- (NSString *)messageHeadersToString {
    NSMutableString *strResponse = [[NSMutableString alloc] init];

    if (_messageHeaders != nil) {
        [_messageHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
            [strResponse appendString:[NSString stringWithFormat:@"%@: %@\n", key, obj]];
        }];
    }
    
    return strResponse;
}

- (NSData *)createResponseData:(MADRequest *)request {
    NSString* bundle = [[NSBundle mainBundle] resourcePath];
    NSString *filePath = [bundle stringByAppendingPathComponent:
                          [NSString stringWithFormat:@"/resource/%@", request.requestLine[@"URI"]]];
//    NSString *uriComponent = [[[[request.requestLine[@"URI"] componentsSeparatedByString:@"/"] lastObject] componentsSeparatedByString:@"."] firstObject];
//    NSString *filePath = [bundle stringByAppendingPathComponent:
//                          [NSString stringWithFormat:@"/resource/%@", uriComponent]];

    NSData *data = nil;
    if (![request.requestLine[@"method"] isEqualToString:@"GET"]) {
        _responseLine = @{
                        @"httpVersion" : request.requestLine[@"httpVersion"],
                        @"statusCode" : @"405 Method Not Allowed",
                        };
    } else if ([request.requestLine[@"method"] isEqualToString:@"GET"]) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            _responseLine = @{
                            @"httpVersion" : request.requestLine[@"httpVersion"],
                            @"statusCode" : @"404 Not Found",
                            };
        } else {
            _responseLine = @{
                            @"httpVersion" : request.requestLine[@"httpVersion"],
                            @"statusCode" : @"200 OK",
                            };
            data = [NSData dataWithContentsOfFile:filePath];
            
            NSArray *filenameExtension = [request.requestLine[@"URI"] componentsSeparatedByString:@"."];
            NSString *contentType = [MADResponse sharedMIMETypes][filenameExtension[1]];
            
            if (contentType == nil) {
                contentType = @"application/octet-stream";
            }
            
            NSDate *currentDate = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            
            [dateFormatter setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss zzz"];
            
            _messageHeaders = @{
                             @"Connection" : @"close",
                             @"Content-Length" : [NSNumber numberWithUnsignedLong:[data length]],
                             @"Content-Type" : contentType,
                             @"Date" : [dateFormatter stringFromDate:currentDate],
                             };
        }
        _responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@", [self responseToString]);
    }
    return data;
}

@end
