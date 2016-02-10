//
//  MADResponse.h
//  HttpServer
//
//  Created by Mariia Cherniuk on 09.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MADRequest;

@interface MADResponse : NSObject

@property (retain, nonatomic, readwrite) NSDictionary *responseLine;
@property (retain, nonatomic, readwrite) NSDictionary *messageHeaders;
@property (copy, nonatomic, readwrite) NSString *responseBody;

+ (NSDictionary *)sharedMIMETypes;

- (NSData *)createResponseData:(MADRequest *)request;
- (NSString *)responseLineToString;
- (NSString *)messageHeadersToString;


@end
