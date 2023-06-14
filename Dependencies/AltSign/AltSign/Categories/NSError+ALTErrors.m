//
//  NSError+ALTError.m
//  AltSign
//

#import "NSError+ALTErrors.h"

NSErrorDomain const AltSignErrorDomain = @"AltSign.Error";
NSErrorDomain const ALTAppleAPIErrorDomain = @"AltStore.AppleDeveloperError";
NSErrorDomain const ALTUnderlyingAppleAPIErrorDomain = @"Apple.APIError";

NSErrorUserInfoKey const ALTSourceFileErrorKey = @"ALTSourceFile";
NSErrorUserInfoKey const ALTSourceLineErrorKey = @"ALTSourceLine";
NSErrorUserInfoKey const ALTAppNameErrorKey = @"appName";

@implementation NSError (ALTError)

+ (void)load
{
    [NSError setUserInfoValueProviderForDomain:AltSignErrorDomain provider:^id _Nullable(NSError * _Nonnull error, NSErrorUserInfoKey  _Nonnull userInfoKey) {
        if ([userInfoKey isEqualToString:NSLocalizedDescriptionKey])
        {
            if ([error altsign_localizedFailure] != nil)
            {
                // Error has localizedFailure, so return nil to construct localizedDescription from it + localizedFailureReason.
                return nil;
            }
            else
            {
                // Otherwise, return failureReason for localizedDescription to avoid system prepending "Operation Failed" message.
                // Do NOT return [error alt_localizedFailureReason], which might be unexpectedly nil if unrecognized error code.
                return error.localizedFailureReason;
            }
        }
        else if ([userInfoKey isEqualToString:NSLocalizedFailureReasonErrorKey])
        {
            // Return failureReason for both keys to prevent prepending "Operation Failed" message to localizedDescription.
            return [error alt_localizedFailureReason];
        }
        
        return nil;
    }];
    
    [NSError setUserInfoValueProviderForDomain:ALTAppleAPIErrorDomain provider:^id _Nullable(NSError * _Nonnull error, NSErrorUserInfoKey  _Nonnull userInfoKey) {
        if ([userInfoKey isEqualToString:NSLocalizedDescriptionKey])
        {
            if ([error altsign_localizedFailure] != nil)
            {
                // Error has localizedFailure, so return nil to construct localizedDescription from it + localizedFailureReason.
                return nil;
            }
            else
            {
                // Otherwise, return failureReason for localizedDescription to avoid system prepending "Operation Failed" message.
                // Do NOT return [error alt_appleapi_localizedFailureReason], which might be unexpectedly nil if unrecognized error code.
                return error.localizedFailureReason;
            }
        }
        else if ([userInfoKey isEqualToString:NSLocalizedFailureReasonErrorKey])
        {
            // Return failureReason for both keys to prevent prepending "Operation Failed" message to localizedDescription.
            return [error alt_appleapi_localizedFailureReason];
        }
        else if ([userInfoKey isEqualToString:NSLocalizedRecoverySuggestionErrorKey])
        {
            return [error alt_appleapi_localizedRecoverySuggestion];
        }
        
        return nil;
    }];
}

- (nullable NSString *)altsign_localizedFailure
{
    // Copied logic from AltStore's NSError+MiniAppBuilder.swift.
    NSString *localizedFailure = self.userInfo[NSLocalizedFailureErrorKey];
    if (localizedFailure != nil)
    {
        return localizedFailure;
    }
        
    id (^provider)(NSError *, NSErrorUserInfoKey) = [NSError userInfoValueProviderForDomain:self.domain];
    if (provider == nil)
    {
        return nil;
    }
        
    localizedFailure = provider(self, NSLocalizedFailureErrorKey);
    return localizedFailure;
}

- (nullable NSString *)alt_localizedFailureReason
{
    switch ((ALTError)self.code)
    {
        case ALTErrorUnknown:
            return NSLocalizedString(@"An unknown error occured.", @"");
            
        case ALTErrorInvalidApp:
            return NSLocalizedString(@"The app is invalid.", @"");
            
        case ALTErrorMissingAppBundle:
            return NSLocalizedString(@"The provided .ipa does not contain an app bundle.", @"");
            
        case ALTErrorMissingInfoPlist:
            return NSLocalizedString(@"The provided app is missing its Info.plist.", @"");
            
        case ALTErrorMissingProvisioningProfile:
            return NSLocalizedString(@"Could not find matching provisioning profile.", @"");
    }
    
    return nil;
}

- (nullable NSString *)alt_appleapi_localizedFailureReason
{
    switch ((ALTAppleAPIError)self.code)
    {
        case ALTAppleAPIErrorUnknown:
            return NSLocalizedString(@"An unknown error occured.", @"");
            
        case ALTAppleAPIErrorInvalidParameters:
            return NSLocalizedString(@"The provided parameters are invalid.", @"");
            
        case ALTAppleAPIErrorIncorrectCredentials:
            return NSLocalizedString(@"Your Apple ID or password is incorrect.", @"");
            
        case ALTAppleAPIErrorNoTeams:
            return NSLocalizedString(@"You are not a member of any development teams.", @"");
            
        case ALTAppleAPIErrorAppSpecificPasswordRequired:
            return NSLocalizedString(@"An app-specific password is required. You can create one at appleid.apple.com.", @"");
            
        case ALTAppleAPIErrorInvalidDeviceID:
            return NSLocalizedString(@"This device's UDID is invalid.", @"");
            
        case ALTAppleAPIErrorDeviceAlreadyRegistered:
            return NSLocalizedString(@"This device is already registered with this team.", @"");
            
        case ALTAppleAPIErrorInvalidCertificateRequest:
            return NSLocalizedString(@"The certificate request is invalid.", @"");
            
        case ALTAppleAPIErrorCertificateDoesNotExist:
            return NSLocalizedString(@"There is no certificate with the requested serial number for this team.", @"");
            
        case ALTAppleAPIErrorInvalidAppIDName:
        {
            NSString *appName = self.userInfo[ALTAppNameErrorKey];
            if (appName != nil)
            {
                return [NSString stringWithFormat:NSLocalizedString(@"The name “%@” contains invalid characters.", @""), appName];
            }
            
            return NSLocalizedString(@"The name of this app contains invalid characters.", @"");
        }
            
        case ALTAppleAPIErrorInvalidBundleIdentifier:
            return NSLocalizedString(@"The bundle identifier for this app is invalid.", @"");
            
        case ALTAppleAPIErrorBundleIdentifierUnavailable:
            return NSLocalizedString(@"The bundle identifier for this app has already been registered.", @"");
            
        case ALTAppleAPIErrorAppIDDoesNotExist:
            return NSLocalizedString(@"There is no App ID with the requested identifier on this team.", @"");
            
        case ALTAppleAPIErrorMaximumAppIDLimitReached:
            return NSLocalizedString(@"You may only register 10 App IDs every 7 days.", @"");
            
        case ALTAppleAPIErrorInvalidAppGroup:
            return NSLocalizedString(@"The provided app group is invalid.", @"");
            
        case ALTAppleAPIErrorAppGroupDoesNotExist:
            return NSLocalizedString(@"App group does not exist", @"");
            
        case ALTAppleAPIErrorInvalidProvisioningProfileIdentifier:
            return NSLocalizedString(@"The identifier for the requested provisioning profile is invalid.", @"");
            
        case ALTAppleAPIErrorProvisioningProfileDoesNotExist:
            return NSLocalizedString(@"There is no provisioning profile with the requested identifier on this team.", @"");
            
        case ALTAppleAPIErrorRequiresTwoFactorAuthentication:
            return NSLocalizedString(@"This account requires signing in with two-factor authentication.", @"");
            
        case ALTAppleAPIErrorIncorrectVerificationCode:
            return NSLocalizedString(@"Incorrect verification code.", @"");
            
        case ALTAppleAPIErrorAuthenticationHandshakeFailed:
            return NSLocalizedString(@"Failed to perform authentication handshake with server.", @"");
            
        case ALTAppleAPIErrorInvalidAnisetteData:
            return NSLocalizedString(@"The provided anisette data is invalid.", @"");
    }
    
    return nil;
}

- (nullable NSString *)alt_appleapi_localizedRecoverySuggestion
{
    switch ((ALTAppleAPIError)self.code)
    {
        case ALTAppleAPIErrorIncorrectCredentials:
            return NSLocalizedString(@"Please make sure you entered both your Apple ID and password correctly and try again.", @"");
            
        case ALTAppleAPIErrorInvalidAnisetteData:
        return NSLocalizedString(@"Make sure this computer's date & time matches your iOS device and try again.", @"");            
        default: break;
    }
    
    return nil;
}

@end
