//
//  TRLNetwork.m
//  RequestBuilder
//
//  Created by Harry Wright on 30.08.17.
//  Copyright © 2017 Off-Piste.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "TRLNetwork.h"
#import "TRLNetwork_Private.h"

#import "TRLNetworkConnection.h"

#import "TRLParsedURL.h"

#import "TRLRequest.h"

#import "Log.h"
#import "Trolley.h"
#import "TrolleyCore-Swift-Fixed.h"

@implementation TRLNetwork {
    TRLNetworkConnection *connection;
}

- (NSURL *)url {
    return self.parsedURL.url;
}

- (NSURL *)connectionURL {
    return self.parsedURL.connectionURL;
}

- (NSString *)description {
    return self->_parsedURL.description;
}

- (instancetype)initWithURLString:(NSString *)url {
    self = [super init];
    if (self) {
        TRLDebugLogger(TRLLoggerServiceCore, @"Creating Network for url: @{private}%", url);
        self->_parsedURL = [[TRLParsedURL alloc] initWithURLString:url];
        self->connection = [[TRLNetworkConnection alloc] initWithNetwork:self
                                                        andDispatchQueue:dispatch_get_main_queue()
                                                              deviceUUID:trl_device_uuid_get()];
    }
    return self;
}

- (TRLRequest *)get:(NSString *)path
         parameters:(Parameters *)parameters
           encoding:(id<TRLURLParameterEncoding>)encoding
            headers:(HTTPHeaders *)headers
{
    Parameters *_param = parameters ? parameters : @{}.copy;
    HTTPHeaders *_headers = headers ? headers : @{}.copy;

    NSURL *url = [self.url URLByAppendingPathComponent:path];
    return [[TRLRequest alloc] initWithURL:url.absoluteString
                                    method:HTTPMethodGET
                                parameters:_param
                                  encoding:encoding
                                   headers:_headers];
}

- (void)open {
    [connection open];
}

- (BOOL)canSendWrites {
    return YES;
}

- (BOOL)shouldReconnect {
    return YES;
}

- (BOOL)connected {
    return YES;
}

- (void)onKill:(TRLNetworkConnection *)trlNetworkConnection withReason:(NSString *)reason{
    //
}

- (void)onDisconnect:(TRLNetworkConnection *)trlNetworkConnection withReason:(TRLDisconnectReason)reason {
    
}

- (void)onDataMessage:(TRLNetworkConnection *)trlNetworkConnection withMessage:(NSDictionary *)message {
    //
}

@end
