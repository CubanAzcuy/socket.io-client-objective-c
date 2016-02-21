//
//  SocketAck.h
//  SocketIO
//
//  Created by Robert Gross on 2/21/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "enums.h"

@interface SocketAck : NSObject
@property (nonatomic, copy) onAckCallbackBlock callback;
@property (readonly) NSNumber *ack;

-(NSUInteger)hashValue;
@end
