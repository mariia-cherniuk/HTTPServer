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
//        dispatch_source_t sigHandler = dispatch_source_create(DISPATCH_SOURCE_TYPE_SIGNAL, SIGKILL, 0, dispatch_get_main_queue());
//        dispatch_source_set_event_handler(sigHandler, ^{
//            CFRunLoopStop(CFRunLoopGetMain());
//        });
//        dispatch_resume(sigHandler);
//        

        NSDictionary *httpConf = [[[MADHTTPServer alloc] init] getHttpConfiguration];
        MADHTTPServer *server = [[MADHTTPServer alloc] initWithHost:httpConf[@"address"] port:[httpConf[@"port"] integerValue]];
        
        NSLog(@"server start");
        [server start];        
    }
    
    return 0;
}
