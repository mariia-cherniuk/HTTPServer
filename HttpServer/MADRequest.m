//
//  MADRequest.m
//  HttpServer
//
//  Created by Mariia Cherniuk on 08.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import "MADRequest.h"

@implementation MADRequest

- (instancetype)init {
    self = [super init];
    
    if (self) {
        _requestLine = nil;
        _messageHeaders = nil;
    }
    
    return self;
}

- (BOOL)parseRequestString:(NSString *)data {
    NSArray *components = [data componentsSeparatedByString:@"\r\n"];
    if (![self parseRequestLineWithComponents:components]) {
        return NO;
    }
    return [self parseMessageHeaders:components];
}

- (BOOL)parseRequestLineWithComponents:(NSArray *)components {
    NSMutableArray *requestLineArr = (NSMutableArray *)[components[0] componentsSeparatedByString:@" "];
    
    if (requestLineArr.count != 3) {
        return NO;
    }
    if ( ![requestLineArr[requestLineArr.count - 1] isEqualToString:@"HTTP/1.1"]) {
        return NO;
    }
    requestLineArr[1] = [self parseURI:requestLineArr];
    if (![[requestLineArr[1] substringToIndex:1] isEqualToString:@"/"]) {
        return NO;
    }
    
    _requestLine = @{
                     @"method" : requestLineArr[0],
                     @"URI" : requestLineArr[1],
                     @"httpVersion" : requestLineArr[2],
                     };
    
    return YES;
}

- (NSString *)parseURI:(NSMutableArray *)requestLineArr {
//   if the last character is '/'
    if (([requestLineArr[1] length] != 0) && [[requestLineArr[1] substringFromIndex:[requestLineArr[1] length] - 1] isEqualToString:@"/"]) {
        NSMutableString *uri = [NSMutableString stringWithString:requestLineArr[1]];
        [uri appendString:@"index.html"];
        [requestLineArr replaceObjectAtIndex:1 withObject:uri];
    }
    
//    if the URI has '?'
    NSRange range1 = [requestLineArr[1] rangeOfString:@"?"];
    if (range1.location != NSNotFound) {
        NSString *uri = [requestLineArr[1] substringToIndex:range1.location];
        [requestLineArr replaceObjectAtIndex:1 withObject:uri];
    }
    
    return requestLineArr[1];
}

- (BOOL)parseMessageHeaders:(NSArray *)component {
    NSMutableDictionary *messageHeadersDic = [NSMutableDictionary new];
    
    for (NSInteger i = 1; i < component.count; i++) {
        if (![component[i] isEqualToString:@""]) {
            NSRange range = [component[i] rangeOfString:@": "];
            
            if (range.location != NSNotFound) {
                NSString *key = [component[i] substringToIndex:range.location];
                NSString *value = [component[i] substringFromIndex:range.location + 1];
                messageHeadersDic[key] = value;
            } else {
                return NO;
            }
        }
    }
    
    if (messageHeadersDic.count != 0) {
        _messageHeaders = messageHeadersDic;
    }
    
    return YES;
}

- (NSString *)requestToString {
    NSMutableString *strRequest = [[NSMutableString alloc] init];
    
    [strRequest appendFormat:@"%@ %@ %@\n", _requestLine[@"method"], _requestLine[@"URI"], _requestLine[@"httpVersion"]];
    
    if (_messageHeaders != nil) {
        [strRequest appendString:@"/n"];
        [_messageHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *obj, BOOL *stop) {
            [strRequest appendString:[NSString stringWithFormat:@"%@: %@\n", key, obj]];
        }];
    }
    
    return strRequest;
}

- (NSString *)description {
    return [[super description] stringByAppendingString:[NSString stringWithFormat:
                                                         @"%@", [self requestToString]]];
}

@end
