//
//  SocketIOClient.m
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

#import "SocketIOClient.h"
#import "SocketAckManager.h"


@interface SocketIOClient()
@property (readwrite, assign) id<SocketEngineSpec> engine;
@property (readwrite, assign) SocketIOClientStatus status;
@property (readwrite, assign) NSInteger currentAck;
@property (readwrite, assign) NSInteger reconnectAttempts;
@property (readwrite, assign) dispatch_queue_t handleQueue;

@property NSInteger currentReconnectAttempt;
@property NSTimer* reconnectTimer;
@property SocketAckManager *ackHandlers;
@property NSArray *handlers;
@property SocketAnyEvent *anyHandler;
@property NSArray *waitingData;

@end

@implementation SocketIOClient
static dispatch_queue_t emitQueue;
static NSString* logType;
static dispatch_queue_t parseQueue;

-(void)internalInit{
    _ackHandlers = [[SocketAckManager alloc] init];
_currentReconnectAttempt = 0;
    _handleQueue = dispatch_get_main_queue();
    _forceNew = NO;
    _nsp = @"/";
    _reconnects = YES;
    _reconnectWait = 10;
    _handlers = [@[] mutableCopy];
}
+ (void) initialize {
    if (self == [SocketIOClient class]) {
        parseQueue = dispatch_queue_create("com.socketio.parseQueue", DISPATCH_QUEUE_SERIAL);
        logType = @"SocketIOClient";
        emitQueue = dispatch_queue_create("com.socketio.emitQueue", DISPATCH_QUEUE_SERIAL);
    }
}
@end
