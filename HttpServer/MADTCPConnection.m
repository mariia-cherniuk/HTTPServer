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
@property (retain, nonatomic, readwrite) NSData *responseData;
@property (assign, nonatomic, readwrite) NSInteger byteIndex;
@property (assign, nonatomic, readwrite) BOOL headerSent;

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
        _request = [[MADRequest alloc] init];
        _response = [[MADResponse alloc] init];
        _inputBuffer = [[NSMutableString alloc] init];
    }
    
    return self;
}

- (void)openReadStream {
    if (_readStream.streamStatus != NSStreamStatusOpening || _readStream.streamStatus != NSStreamStatusOpen) {
        _readStream.delegate = self;
        [_readStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_readStream open];
    }
}

- (void)openWriteStream {
    if (_writeStream.streamStatus != NSStreamStatusOpening || _writeStream.streamStatus != NSStreamStatusOpen) {
        _writeStream.delegate = self;
        [_writeStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [_writeStream open];
    }
}

- (void)closeStreams {
    for (NSStream *stream in @[_writeStream, _readStream]) {
        if (stream.streamStatus != NSStreamStatusClosed) {
            [stream close];
            [stream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        }
    }
    _readStream = nil;
    _writeStream = nil;
}

- (void)closeReadStream {
    if (_readStream.streamStatus != NSStreamStatusClosed) {
        [_readStream close];
        [_readStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _readStream = nil;
    }
}

- (void)closeWriteStream {
    if (_writeStream.streamStatus != NSStreamStatusClosed) {
        [_writeStream close];
        [_writeStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        _writeStream = nil;
    }
}

- (void)sendResposeData {
    uint8_t *readBytes = (uint8_t *)[_responseData bytes];
    
    readBytes += _byteIndex;
    
    NSInteger data_len = [_responseData length];
    NSInteger len = ((data_len - _byteIndex >= 1024) ? 1024 : (data_len - _byteIndex));
    uint8_t buf[len];
    
    (void)memcpy(buf, readBytes, len);
    len = [_writeStream write:(const uint8_t *)buf maxLength:len];
    _byteIndex += len;
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
                if ([_inputBuffer isEqualToString:[NSString stringWithFormat:@"%d", SIGINT]]) {
                    [self.server cancelConnection:self];
                }
                
                if (_inputBuffer.length >= 4) {
                    if ([[_inputBuffer substringFromIndex:_inputBuffer.length - 4] isEqualToString:@"\r\n\r\n"]) {
                        if ([_request parseRequestString:_inputBuffer]) {
                            self.responseData = [_response transformRequestToResponse:_request];
                        } else {
                            self.responseData = [_response transformRequestToResponse:nil];
                        }
                        [self openWriteStream];
                    }
                }
            } else {
                printf("Failed reading data from stream.");
            }
        }
    } else if (eventCode == NSStreamEventHasSpaceAvailable) {
        if (aStream == _writeStream) {
            NSLog(@"The stream can accept bytes for writing.");
            if (_responseData != nil || _response.responseError == YES) {
                if (self.headerSent == NO) {
                    [self sendResposeData];
                    if (_byteIndex >= _responseData.length) {
                        _byteIndex = 0;
                        self.headerSent = YES;
                        self.responseData = _response.responseBody;
                    }
                } else if (self.headerSent == YES && _byteIndex < _responseData.length) {
                    [self sendResposeData];
                } else {
                    [self.server cancelConnection:self];
                }
            }
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
