//
// Created by Robert Gross on 2/18/16.
// Copyright (c) 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "enums.h"


@interface WSResponse : NSObject
@property bool isFin;
@property enum OpCode code;
@property NSInteger bytesLeft;
@property int frameCount;
@property NSMutableData* buffer;
@end