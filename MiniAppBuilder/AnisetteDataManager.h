//
//  AnisetteDataManager.h
//


#import <Foundation/Foundation.h>

@class ALTAnisetteData;

NS_ASSUME_NONNULL_BEGIN

@interface AnisetteDataManager : NSObject

@property (class, nonatomic, readonly) AnisetteDataManager *shared;

- (ALTAnisetteData *)requestAnisetteData;

@end

NS_ASSUME_NONNULL_END
