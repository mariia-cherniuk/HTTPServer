//
//  MADHTTPServer.h
//  HttpServer
//
//  Created by Mariia Cherniuk on 02.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MADTCPConnection;

@interface MADHTTPServer : NSObject

@property (copy, nonatomic, readwrite) NSString *host;
@property (assign, nonatomic, readwrite) NSInteger port;

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port;

- (void)start;
- (void)stop;

- (void)cancelConnection:(MADTCPConnection *)connection;
- (NSDictionary *)getHttpConfiguration;

@end


@interface MADInvalidPortException : NSException
@end


@interface MADSocketException : NSException
@end

