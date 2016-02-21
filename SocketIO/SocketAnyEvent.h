//
//  SocketAnyEvent.h
//  SocketIO
//
//  Created by Robert Gross on 2/21/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SocketAnyEvent : NSObject
@property NSString *event;
@property NSArray *items;
@end
