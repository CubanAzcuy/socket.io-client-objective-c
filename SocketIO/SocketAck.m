//
//  SocketAck.m
//  SocketIO
//
//  Created by Robert Gross on 2/21/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import "SocketAck.h"

@implementation SocketAck

-(NSUInteger)hashValue{
    return [_ack hash];
}
@end


#warning not implemented
//private func <(lhs: SocketAck, rhs: SocketAck) -> Bool {
//    return lhs.ack < rhs.ack
//}
//
//private func ==(lhs: SocketAck, rhs: SocketAck) -> Bool {
//    return lhs.ack == rhs.ack
//}