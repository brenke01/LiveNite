//
//  SendGeoRequest.m
//  LiveNite
//
//  Created by Kevin  on 9/26/16.
//  Copyright © 2016 LiveNite. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "SendGeoRequest.h"
#import "AWSConstants.h"



@implementation SendGeoRequest



- (void) someMethod {
    NSLog(@"SomeMethod Ran");
}


- (void)sendRequest:(NSDictionary *)requestDictionary {
    NSLog(@"Request:\n%@", requestDictionary);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://livenitegeohash-env.us-east-1.elasticbeanstalk.com"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:120.0];
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:requestDictionary
                                                       options:kNilOptions
                                                         error:nil];
    request.HTTPMethod = @"POST";
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (conn) {
        self.data = [NSMutableData data];
        NSLog(self.data);
    }
}

@end
