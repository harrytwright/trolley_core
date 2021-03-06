/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <netinet/in.h>

@import CoreFoundation;

#import "Reachability.h"

#import "Log.h"
#import "TrolleyCore-Swift-Fixed.h"

#pragma mark IPv6 Support
//Reachability fully support IPv6.  For full details, see ReadMe.md.


NSString *kReachabilityChangedNotification = @"kNetworkReachabilityChangedNotification";


#pragma mark - Supporting functions

//#define kShouldPrintReachabilityFlags 1

// TODO: Add Logging here!

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char* comment)
{
//#if kShouldPrintReachabilityFlags
    TRLDebugLogger(TRLLoggerServiceCore, "Reachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
          (flags & kSCNetworkReachabilityFlagsIsWWAN)                ? 'W' : '-',
          (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',

          (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
          comment
          )
//#endif
}

NSString * NetworkReachabilityStatus(NetworkStatus status) {
    switch (status) {
        case NotReachable:
            return @"Not Reachable";
        case ReachableViaWWAN:
            return @"Reachable via WWAN";
        case ReachableViaWiFi:
            return @"Reachable via WiFi";
    }
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)
	NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
	NSCAssert([(__bridge NSObject*) info isKindOfClass: [Reachability class]], @"info was wrong class in ReachabilityCallback");

    TRLDebugLogger(TRLLoggerServiceCore,  "%s", __FUNCTION__);

    Reachability* noteObject = (__bridge Reachability *)info;
    NetworkStatus status = noteObject.currentReachabilityStatus;

    // Post a notification to notify the client that the network reachability changed.
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    NSDictionary *userInfo = @{@"Status": NetworkReachabilityStatus(status)};
    [center postNotificationName:kReachabilityChangedNotification object:noteObject userInfo:userInfo];
}

#pragma mark - Reachability implementation

@implementation Reachability {
	SCNetworkReachabilityRef _reachabilityRef;
}

+ (instancetype)reachabilityWithHostName:(NSString *)hostName {
    TRLDebugLogger(TRLLoggerServiceCore, "Creating Reachabilty for: %@", hostName);

	Reachability* returnValue = NULL;
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, hostName.UTF8String);
	if (reachability != NULL) {
		returnValue= [[self alloc] init];
		if (returnValue != NULL) {
			returnValue->_reachabilityRef = reachability;
		} else {
            CFRelease(reachability);
        }
	}
	return returnValue;
}


+ (instancetype)reachabilityWithAddress:(const struct sockaddr *)hostAddress {
    TRLDebugLogger(TRLLoggerServiceCore, "Creating Reachabilty for: %{private}@", hostAddress);

    Reachability* returnValue = NULL;
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, hostAddress);

	if (reachability != NULL) {
		returnValue = [[self alloc] init];
		if (returnValue != NULL) {
			returnValue->_reachabilityRef = reachability;
		} else {
            CFRelease(reachability);
        }
	}
	return returnValue;
}

#pragma mark - Start and stop notifier

- (BOOL)startNotifier {
    TRLDebugLogger(TRLLoggerServiceCore, "Attempting to start notifier");
	BOOL returnValue = NO;
	SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};

	if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context)) {
		if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode)) {
            TRLDebugLogger(TRLLoggerServiceCore, "Starting notifier");
			returnValue = YES;
		}
	}
    
	return returnValue;
}


- (void)stopNotifier {
    TRLDebugLogger(TRLLoggerServiceCore, "Attempting to stop notifier");
	if (_reachabilityRef != NULL) {
    TRLDebugLogger(TRLLoggerServiceCore, "Stopping notifier");
		SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	}
}


- (void)dealloc {
	[self stopNotifier];
	if (_reachabilityRef != NULL) {
		CFRelease(_reachabilityRef);
	}
}


#pragma mark - Network Flag Handling

- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags {
	PrintReachabilityFlags(flags, "networkStatusForFlags");
	if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
		// The target host is not reachable.
		return NotReachable;
	}

    NetworkStatus returnValue = NotReachable;

	if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
		/*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
		returnValue = ReachableViaWiFi;
	}

	if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
        (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = ReachableViaWiFi;
        }
    }

	if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
		/*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
		returnValue = ReachableViaWWAN;
	}
    
	return returnValue;
}


- (BOOL)connectionRequired {
	NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
	SCNetworkReachabilityFlags flags;

	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
		return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
	}

    return NO;
}


- (NetworkStatus)currentReachabilityStatus {
	NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
	NetworkStatus returnValue = NotReachable;
	SCNetworkReachabilityFlags flags;
    
	if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags)) {
        returnValue = [self networkStatusForFlags:flags];
	}
    
	return returnValue;
}

- (NSString *)description {
    return NetworkReachabilityStatus(self.currentReachabilityStatus);
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"%@{status:%@, isConnectionRequired:%@}",
            super.description, self.description, self.connectionRequired ? @"true" : @"false"];
}


@end
