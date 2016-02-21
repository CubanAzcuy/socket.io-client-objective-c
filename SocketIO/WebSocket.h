//
//  WebSocket.h
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
#import "enums.h"

@protocol WebSocketDelegate;
@protocol WebSocketPongDelegate;

typedef void (^onDisconnectBlock)(NSError *);
typedef void (^onConnectBlock)(void);
typedef void (^onPongBlock)(void);
typedef void (^onText)(NSString *);
typedef void (^onData)(NSData *);

static NSString *ErrorDomain = @"WebSocket";

@interface WebSocket : NSObject <NSStreamDelegate>
@property (nonatomic, weak) id<WebSocketDelegate> delegate;
@property (nonatomic, weak) id<WebSocketPongDelegate> pongDelegate;
@property (nonatomic, strong) NSString *origin;
@property (nonatomic, strong) NSDictionary *headers;
@property (nonatomic) BOOL voipEnabled;
@property (nonatomic) BOOL selfSignedSSL;
@property (nonatomic, strong) NSArray *enabledSSLCipherSuites;
@property (nonatomic, copy) onDisconnectBlock onDisconnect;
@property (nonatomic, copy) onConnectBlock onConnect;
@property (nonatomic, copy) onPongBlock onPong;
@property (nonatomic, copy) onText onText;
@property (nonatomic, copy) onData onData;


-(BOOL)isConnected;

+(dispatch_queue_t)sharedWorkQueue;

+ (void)writeUint16:(uint8_t *)buffer offset:(int)offset value:(NSUInteger)value;
@end

@protocol WebSocketDelegate

-(void) websocketDidConnect:(WebSocket *)socket;
-(void) websocketDidDisconnect:(WebSocket *)socket error:(NSError *)error;
-(void) websocketDidReceiveMessage:(WebSocket *)socket string:(NSString *)string;
-(void) websocketDidReceiveData:(WebSocket *)socket data:(NSData *)data;

@end

@protocol WebSocketPongDelegate
-(void) websocketDidReceivePong:(WebSocket *)socket;
@end