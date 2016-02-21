//
//  SocketAckManager.h
//  SocketIO
//
//  Created by Robert Gross on 2/21/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "enums.h"

@interface SocketAckManager : NSObject
-(void)addAck:(NSNumber *) ack callback:(onAckCallbackBlock)callback;
-(void)executeAck:(NSNumber *)ack items:(NSArray *)items;
-(void)timeoutAck:(NSNumber *)ack;
@end
