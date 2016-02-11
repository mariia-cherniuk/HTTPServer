//
//  MADTCPConnection.m
//  HttpServer
//
//  Created by Mariia Cherniuk on 05.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//
#import "MADTCPConnection.h"
#import "MADHTTPServer.h"
#import "MADRequest.h"
#import "MADResponse.h"

@interface MADTCPConnection ()

@property (retain, nonatomic, readonly) MADRequest *request;
@property (retain, nonatomic, readonly) MADResponse *response;

@property (retain, nonatomic, readwrite) NSMutableString *inputBuffer;

@end


@interface MADTCPConnection () <NSStreamDelegate>

@end

@implementation MADTCPConnection

- (instancetype)initWithReadStream:(NSInputStream *)readStream
                       writeStream:(NSOutputStream *)writeStream {
    self = [super init];
    
    if (self) {
        _readStream = readStream;
        _writeStream = writeStream;
        _request = [[MADRequest alloc] init];;
        _response = [[MADResponse alloc] init];;
        _inputBuffer = [[NSMutableString alloc] init];
    }
    
    return self;
}

- (void)openConnection {
    for (NSStream *stream in @[_readStream, _writeStream]) {
        stream.delegate = self;
        [stream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [stream open];
    }
}

- (void)closeStream {
    for (NSStream *stream in @[_writeStream, _readStream]) {
        [stream close];
        [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    }
    _readStream = nil;
    _writeStream = nil;
}

- (void)closeReadStream {
    [_readStream close];
    [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _readStream = nil;
}

- (void)closeWriteStream {
    [_writeStream close];
    [_writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    _writeStream = nil;
}

#pragma mark - NSStreamDelegate

- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    if (eventCode == NSStreamEventOpenCompleted) {
        if ([aStream isKindOfClass:[NSOutputStream class]]) {
            printf("The open outputStream has completed successfully.\n");
        } else {
            printf("The open inputStream has completed successfully.\n");
        }
    } else if (eventCode == NSStreamEventHasBytesAvailable) {
        if (aStream == _readStream) {
            uint8_t buf[BUFSIZ];
            NSInteger len = [_readStream read:buf maxLength:BUFSIZ];
            
            if(len > 0) {
                NSData *data = [[NSData alloc] initWithBytes:buf length:len];

                [_inputBuffer appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                
                if ([_inputBuffer isEqualToString:@"disconnect\r\n"]) {
                    [self.server cancelConnection:self];
                } else if (_inputBuffer.length >= 4) {
                    NSString *subStr = [_inputBuffer substringFromIndex:_inputBuffer.length - 4];
                
                    if ([subStr isEqualToString:@"\r\n\r\n"]) {
                        _request = [_request transformDataToRequest:_inputBuffer];
                        
                        NSData *responseData = [_response transformRequestToResponse:_request];
                        const void *bytes = [responseData bytes];
                        
                        NSLog(@"_writeStream.hasSpaceAvailable = %hhd", _writeStream.hasSpaceAvailable);
                        
                        NSLog(@"writeStream.streamStatus = %lu", (unsigned long)_writeStream.streamStatus);
                        NSInteger res = [_writeStream write:bytes maxLength:responseData.length];
                        NSLog(@"%ld", res);
                        NSLog(@"_writeStream.streamStatus = %lu", (unsigned long)_writeStream.streamStatus);
                        NSLog(@"_writeStream.streamError = %@", _writeStream.streamError);
                        NSLog(@"%@", [_response responseLineToString]);
                        
//                        UInt8 *buf = (UInt8 *)[responseData bytes];
//                        CFIndex bufLen = (CFIndex)strlen((const char *)buf);
//
//                        CFIndex bytesWritten = CFWriteStreamWrite((CFWriteStreamRef)_writeStream, buf, (CFIndex)bufLen);
//                        if (bytesWritten < 0) {
//                            CFStreamError error = CFWriteStreamGetError((CFWriteStreamRef)_writeStream);
//                        }


                        [self.server cancelConnection:self];
                        _inputBuffer = nil;
                        _response = nil;
                        _request = nil;
                    }
                }
            } else {
                printf("Failed reading data from stream.");
            }
        }
    } else if (eventCode == NSStreamEventHasSpaceAvailable) {
        if (aStream == _writeStream) {
            NSLog(@"The stream can accept bytes for writing.");
        } else {
            printf("Failed writing data to stream.");
        }
    } else if (eventCode == NSStreamEventErrorOccurred) {
        NSError *error = [aStream streamError];
        
        NSLog(@"%@", error);
        [self.server cancelConnection:self];
    } else if (eventCode == NSStreamEventEndEncountered) {
        [self.server cancelConnection:self];
    } else if (eventCode == NSStreamEventNone) {
        NSLog(@"No event has occurred.");
    }
}

@end
