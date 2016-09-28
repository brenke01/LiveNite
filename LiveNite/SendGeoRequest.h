
#import <Foundation/Foundation.h>

- (void)sendRequest:(NSDictionary *)requestDictionary {
    NSLog(@"Request:\n%@", requestDictionary);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:AWSElasticBeanstalkEndpoint]
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

@interface SendGeoRequest : NSObject

@property (nonatomic, strong) NSMutableData *data;

- (void) someMethod;

@end
