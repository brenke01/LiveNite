
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>

@interface SendGeoRequest : NSObject

@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSDictionary *resultDict;

- (void) someMethod;

- (void)sendRequest:(CLLocationCoordinate2D)location arg2:(double)radius ;

@end
