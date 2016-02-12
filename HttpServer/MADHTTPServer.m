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
#import <stdlib.h>
#define MAX_PORT 65535
#define MIN_PORT 0

#define GWS_DCHECK(__CONDITION__) \
do { \
if (!(__CONDITION__)) {\
exit(EXIT_SUCCESS); \
} \
} while (0)

static BOOL _running;

@interface MADHTTPServer ()

@property (assign, nonatomic, readonly) CFSocketRef ipv4Socket;
@property (retain, nonatomic, readwrite) NSMutableSet *connections;

- (void) acceptConnection:(CFSocketNativeHandle)handle;

@end

void AcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    MADHTTPServer *server = (__bridge MADHTTPServer *)info;
    // For an accept callback, data is a pointer to CFSocketNativeHandle
    CFSocketNativeHandle handle = *(CFSocketNativeHandle *)data;
    
    [server acceptConnection:handle];
}

static void _SignalHandler(int signal) {
    _running = NO;
    if (signal == SIGINT) {
        printf("Goodbye, cruel world.\n");
        return;
    }
}

static void _ExecuteMainThreadRunLoopSources() {
    SInt32 result;
    do {
        result = CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.0, true);
    } while (result == kCFRunLoopRunHandledSource);
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
        _connections = [NSMutableSet new];
    }
    
    return self;
}

- (void)run {
    GWS_DCHECK([NSThread isMainThread]);
     _running = YES;
    void (*termHandler)(int) = signal(SIGTERM, _SignalHandler);
    void (*intHandler)(int) = signal(SIGINT, _SignalHandler);
    
    if ((termHandler != SIG_ERR) && (intHandler != SIG_ERR)) {
            while (_running) {
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, true);
            }
        [self stop];

        _ExecuteMainThreadRunLoopSources();
        signal(SIGINT, intHandler);
        signal(SIGTERM, termHandler);
    }
}

- (void)start {
    [self openSocket];
    [self listen];
    [self run];
}

- (void)stop {
    CFSocketInvalidate(_ipv4Socket);
    CFRelease(_ipv4Socket);
    _ipv4Socket = nil;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)cancelConnection:(MADTCPConnection *)connection {
    [connection closeStreams];
    [_connections removeObject:connection];
}

- (void)openSocket {
    CFSocketContext socketContext = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    
    _ipv4Socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, &AcceptCallBack, &socketContext);
    
    if (!_ipv4Socket) {
        @throw [[MADSocketException alloc] initWithName:@"MADSocketException"
                                                  reason:@"Unable to create socket."
                                                userInfo:nil];
    }

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
        [connection openReadStream];
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
        [httpConf setValue:subArray[1] forKey:subArray[0]];
    }
    
    return httpConf;
}

@end


@implementation MADInvalidPortException
@end


@implementation MADSocketException
@end

