//
//  AnisetteDataManager.m
//


#import "AnisetteDataManager.h"

#import <dlfcn.h>

#import "ALTAnisetteData.h"
#import "AOSUtilities.h"


@import AppKit;

@interface AKAppleIDSession : NSObject
- (id)appleIDHeadersForRequest:(id)arg1;
@end

@interface AKDevice
+ (AKDevice *)currentDevice;
- (NSString *)uniqueDeviceIdentifier;
- (nullable NSString *)serialNumber;
- (NSString *)serverFriendlyDescription;
@end

@interface AnisetteDataManager ()

@property (nonatomic, readonly) NSISO8601DateFormatter *dateFormatter;

@end


@implementation AnisetteDataManager

+ (instancetype)shared
{
    static AnisetteDataManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    
    return _instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _dateFormatter = [[NSISO8601DateFormatter alloc] init];
    }
    
    return self;
}

+ (void)initialize
{
    [[AnisetteDataManager shared] start];
}

- (void)start
{
    dlopen("/System/Library/PrivateFrameworks/AOSKit.framework/AOSKit", RTLD_NOW);
    dlopen("/System/Library/PrivateFrameworks/AuthKit.framework/AuthKit", RTLD_NOW);
}

- (NSString *)getDeviceDescription {
    AKDevice *device = [NSClassFromString(@"AKDevice") currentDevice];
    NSString *deviceDescription = [device serverFriendlyDescription];
    NSRange range = [deviceDescription.lowercaseString rangeOfString:@"(null)"];
    if (range.location == NSNotFound) {
        return deviceDescription;
    }
    
    NSMutableString *adjustedDescription = [NSMutableString stringWithString:[deviceDescription substringToIndex:range.location]];
    [adjustedDescription appendString:@"(com.apple.dt.Xcode/3594.4.19)>"];
    
    return adjustedDescription;
}

- (ALTAnisetteData *)requestAnisetteData
{
    NSString *clientTime = [self.dateFormatter stringFromDate:[NSDate date]];
    NSDate *date = [self.dateFormatter dateFromString: clientTime];
    NSDictionary *info = (NSDictionary *)[AOSUtilities retrieveOTPHeadersForDSID:@"-2"];
    NSString *machineID = [info objectForKey: @"X-Apple-MD-M"];
    NSString *oneTimePassword = [info objectForKey: @"X-Apple-MD"];
    NSString *localUserID = @"";
    NSString *deviceDescription = [self getDeviceDescription];
    unsigned long long routingInfo = 17106176;
    NSString *machineUDID = [AOSUtilities machineUDID];
    NSString *machineSerialNumber = [AOSUtilities machineSerialNumber];
    
    ALTAnisetteData *anisetteData = [[NSClassFromString(@"ALTAnisetteData") alloc] initWithMachineID: machineID
                                                                                     oneTimePassword: oneTimePassword
                                                                                         localUserID: localUserID
                                                                                         routingInfo: routingInfo
                                                                              deviceUniqueIdentifier: machineUDID
                                                                                  deviceSerialNumber: machineSerialNumber
                                                                                   deviceDescription: deviceDescription
                                                                                                date: date
                                                                                              locale:[NSLocale currentLocale]
                                                                                            timeZone:[NSTimeZone localTimeZone]];
    
    return anisetteData;
}

@end
