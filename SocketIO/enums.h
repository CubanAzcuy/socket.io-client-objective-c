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

typedef NS_OPTIONS(NSUInteger, SocketIOClientStatus) {
    SocketIOClientStatusNotConnected,
    SocketIOClientStatusClosed,
    SocketIOClientStatusConnecting,
    SocketIOClientStatusConnected,
    SocketIOClientStatusReconnecting
};

typedef NS_OPTIONS(NSUInteger, InternalErrorCode) {
    // 0-999 WebSocket status codes not used
    InternalErrorCodeOutputStreamWriteError  = 1
};


typedef enum {
    SocketEnginePacketTypeOpen,
    SocketEnginePacketTypeClose,
    SocketEnginePacketTypePing,
    SocketEnginePacketTypePong,
    SocketEnginePacketTypeMessage,
    SocketEnginePacketTypeUpgrade,
    SocketEnginePacketTypeNoop
}SocketEnginePacketType;

typedef void (^onAckCallbackBlock)(NSArray *);

