//
//  SocketEngineSpec.h
//  SocketIO
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "SocketEngineClient.h"
#import "enums.h"

@protocol SocketEngineSpec <NSObject>
@property (weak) id<SocketEngineClient> client;
@property BOOL closed;
@property BOOL connected;
@property NSDictionary *connectParams;
@property BOOL doubleEncodeUTF8;
@property NSArray *cookies;//[NSHTTPCookie]?
@property NSDictionary *extraHeaders; // [String: String]?
@property BOOL fastUpgrade;
@property BOOL forcePolling;
@property BOOL forceWebsockets;
@property dispatch_queue_t parseQueue;
@property NSTimer* pingTimer;
@property BOOL polling;
@property BOOL probing;
@property dispatch_queue_t emitQueue;
@property dispatch_queue_t handleQueue;
@property NSString *sid;
@property NSString *socketPath;
@property NSURL *urlPolling;
@property NSURL *urlWebSocket;
@property BOOL websocket;

//init(client: SocketEngineClient, url: NSURL, options: NSDictionary?)

-(void)close:(NSString *)reason;
-(void)didError:(NSString *)error;
-(void)doFastUpgrade;
-(void)flushWaitingForPostToWebSocket;
-(void)open;
-(void)parseEngineData:(NSData *)data;
-(void)parseEngineMessage:(NSString *)message fromPolling:(BOOL)fromPolling;
-(void)write:(NSString *)message withType:(SocketEnginePacketType)type withData:(NSArray *)data;
@end
