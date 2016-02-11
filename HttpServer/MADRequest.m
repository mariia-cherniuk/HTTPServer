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

- (instancetype)transformDataToRequest:(NSString *)data {
    NSArray *component = [data componentsSeparatedByString:@"\r\n"];
    
    self = [self transformRequestLine:data component:component];
    if (!self) {
        self = [self transformMessageHeaders:component];
    }

    return self;
}

- (instancetype)transformRequestLine:(NSString *)data component:(NSArray *)component {
    NSMutableArray *requestLineArr = (NSMutableArray *)[component[0] componentsSeparatedByString:@" "];
    
    if (requestLineArr.count != 3) {
        return nil;
    }
    requestLineArr[1] = [self transformURI:requestLineArr];
    
    _requestLine = @{
                     @"method" : requestLineArr[0],
                     @"URI" : requestLineArr[1],
                     @"httpVersion" : requestLineArr[2],
                     };
    
    return self;
}

- (NSString *)transformURI:(NSMutableArray *)requestLineArr {
//   if the last character '/'
    if ([[requestLineArr[1] substringFromIndex:[requestLineArr[1] length] - 1] isEqualToString:@"/"]) {
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
//    get search fileName
    NSRange range2 = [requestLineArr[1] rangeOfString:@"/" options:NSBackwardsSearch];
    if (range2.location != NSNotFound) {
        NSString *uri = [requestLineArr[1] substringFromIndex:range2.location];
        [requestLineArr replaceObjectAtIndex:1 withObject:uri];
    }
    
    return requestLineArr[1];
}

- (instancetype)transformMessageHeaders:(NSArray *)component {
    NSMutableDictionary *messageHeadersDic = [NSMutableDictionary new];
    
    for (NSInteger i = 1; i < component.count; i++) {
        if (![component[i] isEqualToString:@""]) {
            NSRange range = [component[i] rangeOfString:@": "];
            
            if (range.location != NSNotFound) {
                NSString *key = [component[i] substringToIndex:range.location];
                NSString *value = [component[i] substringFromIndex:range.location + 1];
                messageHeadersDic[key] = value;
            } else {
                return nil;
            }
        }
    }
    
    if (messageHeadersDic.count != 0) {
        _messageHeaders = messageHeadersDic;
    }
    
    return self;
}

- (NSString *)description {
    return [[super description] stringByAppendingString:[NSString stringWithFormat:@"%@ %@", _requestLine, _messageHeaders]];
}

@end
