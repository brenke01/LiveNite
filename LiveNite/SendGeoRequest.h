
#import <Foundation/Foundation.h>

@interface SendGeoRequest : NSObject

@property (nonatomic, strong) NSMutableData *data;

- (void) someMethod;

- (void)sendRequest:(NSDictionary *)requestDictionary;

@end
