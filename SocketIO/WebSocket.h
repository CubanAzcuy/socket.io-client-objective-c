//
//  WebSocket.h
//  SocketIO
//
//  Created by Robert Gross on 2/18/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

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