//
// Created by Robert Gross on 2/18/16.
// Copyright (c) 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, CloseCode) {
    CloseCodeNormal = 1000,
    CloseCodeGoingAway = 1001,
    CloseCodeProtocolError = 1002,
    CloseCodeProtocolUnhandledType  = 1003,
    // 1004 reserved.
    CloseCodeNoStatusReceived = 1005,
    //1006 reserved.
    CloseCodeEncoding = 1007,
    CloseCodePolicyViolated = 1008,
    CloseCodeMessageTooBig = 1009
};

typedef NS_OPTIONS(NSUInteger, OpCode) {
    OpCodeContinueFrame = 0x0,
    OpCodeTextFrame = 0x1,
    OpCodeBinaryFrame = 0x2,
    //3-7 are reserved.
    OpCodeConnectionClose = 0x8,
    OpCodePing = 0x9,
    OpCodePong = 0xA
    //B-F reserved.
};

typedef NS_OPTIONS(NSUInteger, InternalErrorCode) {
    // 0-999 WebSocket status codes not used
    InternalErrorCodeOutputStreamWriteError  = 1
};
