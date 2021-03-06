//
//  TRLNetwork_Private.h
//  TRLNetwork
//
//  Created by Harry Wright on 13.09.17.
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

#import "TRLNetwork.h"
#import "TNTUtils.h"

#import "TRLNetworkBlocks.h"

#import "TRLNetworkConnection.h"

@class TRLParsedURL, TRLRequest, TRLRetryHelper, TRLNetworkManager;

typedef enum {
    ConnectionStateDisconnected,
//    ConnectionStateGettingToken,
    ConnectionStateConnecting,
//    ConnectionStateAuthenticating,
    ConnectionStateConnected
} ConnectionState;

@protocol TRLURLParameterEncoding;

NS_ASSUME_NONNULL_BEGIN

extern void trl_handle_for_reachabilty(id reach, TRLNetwork *network);

@interface TRLNetwork () <TRLNetworkConnectionDelegate> {
    TRLRetryHelper *_retryHelper;
}

/**
 The internal
 */
@property (strong, readonly) TRLParsedURL* parsedURL;

@property (weak, readonly) TRLNetworkManager *manager;

@property (strong, nullable) trl_on_connect onConnect;

@property (strong, nullable) trl_on_disconnect onDisconnect;

/**
 Method to create a TRLNetwork instance with the URL for the
 API calls.
 
 @warning Never to be called externally

 @param url The Base URL for all network calls, this will never be mutated from here.
 @return A TRLNetwork instance
 */
- (instancetype)initWithURLString:(NSString *)url manager:(TRLNetworkManager *)manager;

/**
 Method to create a TRLRequest instance with the requred URL parts.

 @param path        The path you wish to append
 @param parameters  The Parmeters for the URL Request, can be set to NULL.
 @param encoding    A TRLURLParameterEncoding conforming class
 @param headers     The HTTPHeaders for the request
 @return            A TRLRequest instance.
 */
- (TRLRequest *)get:(NSString *)path
         parameters:(Parameters *_Nullable)parameters
           encoding:(id<TRLURLParameterEncoding>)encoding
            headers:(HTTPHeaders *_Nullable)headers;

#pragma mark - Realtime

@property (assign, readonly) ConnectionState connectionState;

- (void)open;

- (BOOL)connected;

- (BOOL)canSendWrites;

- (BOOL)shouldReconnect;

- (void)send:(NSDictionary *)data secure:(BOOL)secure;

#pragma mark Delegate Methods
- (void)onDataMessage:(TRLNetworkConnection *)trlNetworkConnection
          withMessage:(NSDictionary *)message;

- (void)onDisconnect:(TRLNetworkConnection *)trlNetworkConnection
          withReason:(TRLDisconnectReason)reason;

- (void)onKill:(TRLNetworkConnection *)trlNetworkConnection
    withReason:(NSString *)reason;

- (void)onReady:(TRLNetworkConnection *)trlNetworkConnection;

@end

NS_ASSUME_NONNULL_END
