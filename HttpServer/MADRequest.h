//
//  MADRequest.h
//  HttpServer
//
//  Created by Mariia Cherniuk on 08.02.16.
//  Copyright © 2016 marydort. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MADRequest : NSObject

@property (retain, nonatomic, readwrite) NSDictionary *requestLine;
@property (retain, nonatomic, readwrite) NSDictionary *messageHeaders;

- (BOOL)parseRequestString:(NSString *)data;

@end
