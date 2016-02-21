//
//  SocketEngineSpec.h
//  SocketIO
//
//  Created by Robert Gross on 2/21/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

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
