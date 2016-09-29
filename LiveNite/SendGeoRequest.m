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


- (void)sendRequest:(CLLocationCoordinate2D)location arg2:(double)radius {
    
    NSDictionary *requestDictionary = @{@"action" : @"query-radius",
                          @"request" : @{
                                  @"lat" : [NSNumber numberWithDouble:location.latitude],
                                  @"lng" : [NSNumber numberWithDouble:location.longitude],
                                  @"radiusInMeter" : [NSNumber numberWithDouble:radius]
                                  }
                          };
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
        NSDictionary *resultDictionary = [NSJSONSerialization JSONObjectWithData:self.data
                                                                         options:kNilOptions
                                                                           error:nil];
        self.resultDict = resultDictionary;

    }
    
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSDictionary *resultDictionary = [NSJSONSerialization JSONObjectWithData:self.data
                                                                     options:kNilOptions
                                                                       error:nil];
    NSLog(@"Response:\n%@", resultDictionary);
    

}


@end
