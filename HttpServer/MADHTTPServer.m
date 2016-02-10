//
//  MADHTTPServer.m
//  HttpServer
//
//  Created by Mariia Cherniuk on 02.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import "MADHTTPServer.h"
#import "MADTCPConnection.h"
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#define MAX_PORT 65535
#define MIN_PORT 0

@interface MADHTTPServer ()

@property (assign, nonatomic, readonly) CFSocketRef ipv4Socket;
@property (retain, nonatomic) NSMutableSet *connections;

- (void) acceptConnection:(CFSocketNativeHandle)handle;

@end

void AcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    MADHTTPServer *server = (__bridge MADHTTPServer *)info;
    // For an accept callback, data is a pointer to CFSocketNativeHandle
    CFSocketNativeHandle handle = *(CFSocketNativeHandle *)data;
    
    [server acceptConnection:handle];
}

@implementation MADHTTPServer

- (instancetype)initWithHost:(NSString *)host port:(NSInteger)port {
    self = [super init];
    
    if (self) {
        if (port > MAX_PORT || port < MIN_PORT) {
            @throw [[MADInvalidPortException alloc] initWithName:@"MADInvalidPortException"
                                                           reason:@"65535 <= port value >= 0"
                                                         userInfo:nil];
        }
        _ipv4Socket = nil;
        _host = host;
        _port = port;
        _running = NO;
        _connections = [NSMutableSet new];
    }
    
    return self;
}

- (void)start {
    [self openSocket];
    [self listen];
    _running = YES;
}

- (void)stop {
    CFSocketInvalidate(_ipv4Socket);
    CFRelease(_ipv4Socket);
    _running = NO;
    _ipv4Socket = nil;
}

- (void)cancelConnection:(MADTCPConnection *)connection {
    [connection closeStream];
    [_connections removeObject:connection];
}

- (void)openSocket {
//    Create a Socket(TCP IPv4)
    CFSocketContext socketContext = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    _ipv4Socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, &AcceptCallBack, &socketContext);
    
    if (!_ipv4Socket) {
        @throw [[MADSocketException alloc] initWithName:@"MADSocketException"
                                                  reason:@"Unable to create socket."
                                                userInfo:nil];
    }
//    встановлюю порт і адресу, які збираюсь слухати
    struct sockaddr_in socketAddress;
    memset(&socketAddress, 0, sizeof(socketAddress));
    socketAddress.sin_len = sizeof(socketAddress);
    socketAddress.sin_family = AF_INET;
    socketAddress.sin_port = htons(_port);
    socketAddress.sin_addr.s_addr = htonl(INADDR_ANY);
    
    CFDataRef addressData = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&socketAddress, sizeof(socketAddress));

    if (CFSocketSetAddress(_ipv4Socket, addressData) != kCFSocketSuccess) {
        @throw [[MADSocketException alloc] initWithName:@"MADSocketException"
                                                  reason:@"Unable to bind socket to address."
                                                userInfo:nil];
    }
    CFRelease(addressData);
}

- (void)listen {
    CFRunLoopSourceRef socketSource = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _ipv4Socket, 0);
    
    CFRunLoopAddSource(CFRunLoopGetCurrent(), socketSource, kCFRunLoopCommonModes);
    CFRelease(socketSource);
}

- (void) acceptConnection:(CFSocketNativeHandle)handle {
    CFReadStreamRef read;
    CFWriteStreamRef write;
    
    CFStreamCreatePairWithSocket(NULL, handle, &read, &write);
    
    if (read && write) {
        CFReadStreamSetProperty(read, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        CFWriteStreamSetProperty(write, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
        
        NSOutputStream *writeStream = (__bridge NSOutputStream *) write;
        NSInputStream *readStream = (__bridge NSInputStream *) read;
        MADTCPConnection *connection = [[MADTCPConnection alloc] initWithReadStream:readStream
                                                                        writeStream:writeStream];
        connection.server = self;
        [connection openConnection];
        [_connections addObject:connection];
    } else {
        close(handle);
    }
    
    if (read) {
        CFRelease(read);
    }
    if (write) {
        CFRelease(write);
    }
}

//- (void)startResponse {
//    CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1);
//    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (CFStringRef)@"text/plain");
//    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Connection", (CFStringRef)@"close");
////    CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length",
////                                     (CFStringRef)[NSString stringWithFormat:@"%ld", [fileData length]]);
//    CFDataRef headerData = CFHTTPMessageCopySerializedMessage(response);
//}

- (NSDictionary *)getHttpConfiguration {
    NSString *filepath = [[NSBundle mainBundle] pathForResource:@"http" ofType:@"conf"];
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error reading file: %@", error.localizedDescription);
    }
    
    NSArray *listArray = [fileContents componentsSeparatedByString:@"\n"];
    NSMutableDictionary *httpConf = [NSMutableDictionary new];
    
    for (int i = 0; i < listArray.count; i++) {
        NSArray *subArray = [listArray[i] componentsSeparatedByString:@" "];
        NSLog(@"%@", subArray);
        [httpConf setValue:subArray[1] forKey:subArray[0]];
    }
    
    return httpConf;
}

@end


@implementation MADInvalidPortException
@end


@implementation MADNotOpetWriteStreamException
@end


@implementation MADSocketException
@end

