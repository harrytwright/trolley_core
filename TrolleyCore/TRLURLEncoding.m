//
//  TRLURLEncoding.m
//  TrolleyCore
//
//  Created by Harry Wright on 23.08.17.
//  Copyright © 2017 Off-Piste. All rights reserved.
//

#import "TRLURLEncoding.h"
#import "TRLLogger.h"
#import "NSArray+Map.h"
#import "TRLURLQueryParameters.h"
#import <TrolleyCore/TrolleyCore-Swift.h>

@implementation TRLURLEncoding

+ (TRLURLEncoding *)defaultTRLURLEncoding {
    return [[TRLURLEncoding alloc] init];
}

+ (TRLURLEncoding *)methodDependent {
    return [[TRLURLEncoding alloc] init];
}

+ (TRLURLEncoding *)queryString {
    return [[TRLURLEncoding alloc] initWithDestination:TRLURLEncodingDestinationQueryString];
}

- (instancetype)init {
    return [self initWithDestination:TRLURLEncodingDestinationMethodDependent];
}

- (instancetype)initWithDestination:(TRLURLEncodingDestination)destination {
    self = [super init];
    if (self) {
        self->_destination = destination;
    }

    return self;
}

- (NSURLRequest *)encode:(NSURLRequest *)request
                    with:(NSDictionary *)parameters
                   error:(NSError * _Nullable __autoreleasing *)error {
    NSMutableURLRequest *mutableRequest = request.mutableCopy;
    if (parameters) {
        NSString *method = (mutableRequest.HTTPMethod) ? mutableRequest.HTTPMethod : @"GET";
        if ([self encodesParametersInURLWithMethod:method]) {
            NSURL *url = mutableRequest.URL;
            if (url) {
                NSURLComponents *comp = [[NSURLComponents alloc] initWithURL:url
                                                     resolvingAgainstBaseURL:YES];
                if (comp || parameters.count != 0) {
                    NSString *newQuery;
                    NSString *oldQuery = comp.percentEncodedQuery;
                    if (oldQuery) {
                        newQuery = [NSString stringWithFormat:@"%@&%@",
                                    oldQuery, [self query:parameters]];
                    } else {
                        newQuery = [NSString stringWithFormat:@"%@",
                                    [self query:parameters]];
                    }

                    comp.percentEncodedQuery = newQuery;
                    mutableRequest.URL = comp.URL;
                }
            } else {
                *error = [TRLError parameterEncodingFailedWithReason:@"Missing URL"];
                return nil;
            }
        } else {
            if ([mutableRequest valueForHTTPHeaderField:@"Content-Type"] == nil) {
                [mutableRequest setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
            }

            mutableRequest.HTTPBody = [[self query:parameters]
                                         dataUsingEncoding:kCFStringEncodingUTF8
                                         allowLossyConversion:NO];
        }
        return mutableRequest;
    }
    return request;
}

- (NSArray<TRLURLQueryParameters *>*)queryComponentsFromKey:(NSString *)key value:(id)value {
    NSMutableArray<TRLURLQueryParameters *>* comps = [NSMutableArray array];
    TRLURLQueryParameters *param;

    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary<NSString *, id> *dict = (NSDictionary<NSString *, id> *)value;
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString *nestedKey, id obj, BOOL *stop) {
            NSString *newKey = [NSString stringWithFormat:@"%@[%@]", key, nestedKey];
            [comps addObjectsFromArray:[self queryComponentsFromKey:newKey value:obj]];
        }];
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)value;
        for (id obj in array) {
            NSString *newKey = [NSString stringWithFormat:@"%@[]", key];
            [comps addObjectsFromArray:[self queryComponentsFromKey:newKey value:obj]];
        }
    } else if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *number = (NSNumber *)value;
        if(nsnumber_is_like_bool(number)) {
            param = [[TRLURLQueryParameters alloc]
                     initWithField:[self escape:key]
                     value:[self escape:(number.boolValue ? @"1" : @"2")]];

        } else {
            NSString *strValue = [NSString stringWithFormat:@"%@", number];
            param = [[TRLURLQueryParameters alloc]
                     initWithField:[self escape:key]
                     value:[self escape:strValue]];
        }
    } else {
        param = [[TRLURLQueryParameters alloc]
                 initWithField:[self escape:key]
                 value:[self escape:[value description]]];
    }

    [comps addObject:param];
    return [[NSArray alloc] initWithArray:comps];
}

- (NSString *)escape:(NSString *)string {
    NSString *generalDelimitersToEncode = @":#[]@";
    NSString *subDelimitersToEncode = @"!$&'()*+,;=";

    NSMutableCharacterSet *allowedCharacterSet = [NSCharacterSet.URLQueryAllowedCharacterSet mutableCopy];
    [allowedCharacterSet removeCharactersInString:[NSString stringWithFormat:@"%@%@",
                                                   generalDelimitersToEncode, subDelimitersToEncode]];

    NSString *escape;
    escape = ([string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet]) ? [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet] : string;
    return escape;
}

- (NSString *)query:(NSDictionary *)parameters {
    NSMutableArray *comp = [[NSMutableArray alloc] init];

    // Works the way through the parameters
    // and passes each value to -[queryComponentsFromKey:value:]
    // which in return returns an array of TRLURLQueryParameters.
    for (NSString *key in [parameters.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) { return obj1 < obj2; }]) {
        id value = parameters[key];
        [comp addObjectsFromArray:[self queryComponentsFromKey:key value:value]];
    }

    // This map functions looks at all the objects
    // and then tuns them into key=value and joins them with &
    return [[comp mapObjectsUsingBlock:^id(id obj, NSUInteger idx) {
        return [(TRLURLQueryParameters *) obj URLEncodedStringValue];
    }] componentsJoinedByString:@"&"];
}

- (BOOL)encodesParametersInURLWithMethod:(NSString *)method {
    switch (self.destination) {
        case TRLURLEncodingDestinationQueryString: return YES;
        default: break;
    }

    if ([method isEqualToString:@"GET"] || [method isEqualToString:@"HEAD"] || [method isEqualToString:@"DELETE"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
