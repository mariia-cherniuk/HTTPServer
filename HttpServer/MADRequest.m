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

- (void)transformDataToRequest:(NSString *)data {
    NSArray *component = [data componentsSeparatedByString:@"\r\n"];
    
    //init _request.requestLine
    NSMutableArray *requestLineArr = (NSMutableArray *)[component[0] componentsSeparatedByString:@" "];
    
    if ([[requestLineArr[1] substringFromIndex:[requestLineArr[1] length] - 1] isEqualToString:@"/"]) {
        NSMutableString *uri = [NSMutableString stringWithString:requestLineArr[1]];
        [uri appendString:@"index.html"];
        [requestLineArr replaceObjectAtIndex:1 withObject:uri];
    }
    _requestLine = @{
                     @"method" : requestLineArr[0],
                     @"URI" : requestLineArr[1],
                     @"httpVersion" : requestLineArr[2],
                     };
    
    //init _request.messageHeaders
    NSMutableDictionary *messageHeadersDic = [NSMutableDictionary new];
    
    for (NSInteger i = 1; i < component.count; i++) {
        if (![component[i] isEqualToString:@""]) {
            NSRange range = [component[i] rangeOfString:@": "];
            
            if (range.location != NSNotFound) {
                NSString *key = [component[i] substringToIndex:range.location];
                NSString *value = [component[i] substringFromIndex:range.location + 1];
                messageHeadersDic[key] = value;
            }
        }
    }
    if (messageHeadersDic.count != 0) {
        _messageHeaders = messageHeadersDic;
    }
}

- (NSString *)description {
    return [[super description] stringByAppendingString:[NSString stringWithFormat:@"%@ %@", _requestLine, _messageHeaders]];
}

@end
