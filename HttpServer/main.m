//
//  main.m
//  HttpServer
//
//  Created by Mariia Cherniuk on 08.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MADHTTPServer.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSDictionary *httpConf = [[[MADHTTPServer alloc] init] getHttpConfiguration];
        MADHTTPServer *server = [[MADHTTPServer alloc] initWithHost:httpConf[@"address"] port:[httpConf[@"port"] integerValue]];
        
        NSLog(@"%hhu", server.isRunning);
        [server start];
        NSLog(@"%hhu", server.isRunning);
        
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}
