//
//  WebSocket.m
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

#import "WebSocket.h"
#import "SSLCipherSuiteObject.h"
#import "SSLSecurity.h"
#import "WSResponse.h"

@interface WebSocket()
@property (nonatomic, strong) NSArray *optionalProtocols;
@property (nonatomic, strong) NSMutableArray *inputQueue;
@property (nonatomic) BOOL didDisconnect;
@property (nonatomic) BOOL connected;
@property (nonatomic) BOOL isCreated;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic) BOOL certValidated;
@property (nonatomic, strong) NSOperationQueue *writeQueue;
@property (nonatomic) dispatch_queue_t queue;
@property (nonatomic, strong) NSLock *mutex;
@property (nonatomic) BOOL readyToWrite;
@property (nonatomic, strong) SSLSecurity *security;
@property (nonatomic, strong) NSData *fragBuffer;
@property (nonatomic, strong) NSMutableArray *readStack; //WSResponse
@end

@implementation WebSocket
//Constant Values.

static dispatch_queue_t _sharedWorkQueue;

NSString *headerWSUpgradeName     = @"Upgrade";
NSString *headerWSUpgradeValue    = @"websocket";
NSString *headerWSHostName        = @"Host";
NSString *headerWSConnectionName  = @"Connection";
NSString *headerWSConnectionValue = @"Upgrade";
NSString *headerWSProtocolName    = @"Sec-WebSocket-Protocol";
NSString *headerWSVersionName     = @"Sec-WebSocket-Version";
NSString *headerWSVersionValue    = @"13";
NSString *headerWSKeyName         = @"Sec-WebSocket-Key";
NSString *headerOriginName        = @"Origin";
NSString *headerWSAcceptName      = @"Sec-WebSocket-Accept";
NSInteger BUFFER_MAX              = 4096;
NSUInteger FinMask          = 0x80;
NSUInteger OpCodeMask       = 0x0F;
NSUInteger RSVMask          = 0x70;
NSUInteger MaskMask         = 0x80;
NSUInteger PayloadLenMask   = 0x7F;
NSInteger MaxFrameSize       = 32;

-(id)init{
    self = [super init];
    if(self){
        [self initalize];
    }
    return self;
}

-(id)initWithNSURL:(NSURL *)url protocols:(NSArray *)protocols {
    self = [super init];
    if(self) {
        [self initalize];
        _url = url;
        _origin = url.absoluteString;
        _writeQueue.maxConcurrentOperationCount = 1;
        _optionalProtocols = protocols;
    }
    return self;
}

+ (void) initialize {
    if (self == [WebSocket class]) {
        _sharedWorkQueue = dispatch_queue_create("com.vluxe.starscream.websocket", DISPATCH_QUEUE_SERIAL);
    }
}

-(void)initalize{
    _writeQueue = [[NSOperationQueue alloc] init];
    _queue = dispatch_get_main_queue();
    _mutex = [[NSLock alloc] init];

}

///Connect to the websocket server on a background thread
-(void)connect {
    if(_isCreated){
        return;
    }
    _didDisconnect = false;
    _isCreated = true;
    [self createHTTPRequest];
    _isCreated = false;
}

/**
 Disconnect from the server. I send a Close control frame to the server, then expect the server to respond with a Close control frame and close the socket from its end. I notify my delegate once the socket has been closed.
 
 If you supply a non-nil `forceTimeout`, I wait at most that long (in seconds) for the server to close the socket. After the timeout expires, I close the socket and notify my delegate.
 
 If you supply a zero (or negative) `forceTimeout`, I immediately close the socket (without sending a Close control frame) and notify my delegate.
 
 - Parameter forceTimeout: Maximum time to wait for the server to close the socket.
 */

-(void)disconnect:(NSTimeInterval *)forceTimeout {
    if(!forceTimeout){
        [self writeError:CloseCodeNormal];
        return;
    }
    if(forceTimeout > 0){
        long seconds = (long)lround(*forceTimeout); // Since modulo operator (%) below needs int or long
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self disconnectStream:nil];
        });
    } else{
        [self disconnectStream:nil];
    }
    
}

///write a string to the websocket. This sends it as a text frame.
-(void)writeString:(NSString *)str{
    if(!_connected) {
        return;
    }
    [self dequeueWrite:[str dataUsingEncoding:NSUTF8StringEncoding] code:OpCodeTextFrame];
}

///write binary data to the websocket. This sends it as a binary frame.
-(void)writeData:(NSData *)data {
    if(!_connected) {
        return;
    }
    [self dequeueWrite:data code:OpCodeBinaryFrame];
}

//write a   ping   to the websocket. This sends it as a  control frame.
//yodel a   sound  to the planet.    This sends it as an astroid. http://youtu.be/Eu5ZJELRiJ8?t=42s
-(void)writePing:(NSData *)data {
    if(!_connected) {
        return;
    }
    [self dequeueWrite:data code:OpCodePing];
}

//private method that starts the connection
-(void)createHTTPRequest {
    CFHTTPMessageRef request = CFHTTPMessageCreateRequest(kCFAllocatorDefault, CFSTR("GET"), (__bridge CFURLRef) _url, kCFHTTPVersion1_1);
    NSNumber *port = _url.port;
    if (_url.port) {
        if([@[@"wss", @"https"] containsObject:_url.scheme]){
            port = @(443);
        } else {
            port = @(80);
        }
    }
    
    [self addHeader:request key:headerWSUpgradeName value:headerWSUpgradeValue];
    [self addHeader:request key:headerWSConnectionName value:headerWSConnectionValue];
    
    
    if(_optionalProtocols){
        [self addHeader:request key:headerWSProtocolName value:[_optionalProtocols componentsJoinedByString:@","]];
    }
    
    [self addHeader:request key:headerWSVersionName value:headerWSVersionValue];
    [self addHeader:request key:headerWSKeyName value:[self generateWebSocketKey]];
    
    if (_origin) {
        [self addHeader:request key:headerOriginName value:_origin];
    }
    
    NSString *hostName = [NSString stringWithFormat:@"%@:%@",_url.host,port];
    [self addHeader:request key:headerWSHostName value:hostName];

    for (NSString *key in [_headers allKeys]) {
        [self addHeader:request key:key value:_headers[key]];
    }
    
    CFDataRef cfHTTPMessage = CFHTTPMessageCopySerializedMessage(request);
    
    if (cfHTTPMessage) {
        [self initStreamsWithData:(__bridge NSData *)(cfHTTPMessage) port:[port unsignedIntegerValue]];
    }
}

//Add a header to the CFHTTPMessage by using the NSString bridges to CFString
-(void)addHeader:(CFHTTPMessageRef)urlRequest key:(NSString *)key value:(NSString *)val {
    CFHTTPMessageSetHeaderFieldValue(urlRequest, (__bridge CFStringRef _Nonnull)(key), (__bridge CFStringRef _Nullable)(val));
}

//generate a websocket key as needed in rfc
-(NSString *)generateWebSocketKey {
    NSMutableString *key = [@"" mutableCopy];
    NSInteger seed = 16;
    for (int i =0; i < seed; i++) {
        [key appendString:[self stringWithUnicode:(97 + arc4random_uniform(25))]];
    }
    NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSString *baseKey = [data base64EncodedStringWithOptions:0];
    return baseKey;
}

//Start the stream connection and write the data to the output stream
-(void)initStreamsWithData:(NSData *)data port:(NSUInteger)port {
    //higher level API we will cut over to at some point
    //NSStream.getStreamsToHostWithName(url.host, port: url.port.integerValue, inputStream: &inputStream, outputStream: &outputStream)
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStringRef host = (__bridge CFStringRef)(_url.host);
    CFStreamCreatePairWithSocketToHost(nil, host, (UInt32)port, &readStream, &writeStream);
    _inputStream = (__bridge NSInputStream *)(readStream);
    _outputStream = (__bridge NSOutputStream *)(writeStream);
    
    if(!_inputStream || !_outputStream) {
        return;
    }
    _inputStream.delegate = self;
    _outputStream.delegate = self;
    
    if ([@[@"wss", @"https"] containsObject:_url.scheme]) {
        [_inputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        [_outputStream setProperty:NSStreamSocketSecurityLevelNegotiatedSSL forKey:NSStreamSocketSecurityLevelKey];
        
    } else {
        _certValidated = true; //not a https session, so no need to check SSL pinning
    }
    if (_voipEnabled) {
        [_inputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
        [_outputStream setProperty:NSStreamNetworkServiceTypeVoIP forKey:NSStreamNetworkServiceType];
    }
    if (_selfSignedSSL) {
        NSDictionary *settings = @{(id)kCFStreamSSLValidatesCertificateChain:@(NO),(id)kCFStreamSSLPeerName:[NSNull null]};
        [_inputStream setProperty:settings forKey:(NSString *)kCFStreamPropertySSLSettings];
        [_outputStream setProperty:settings forKey:(NSString *)kCFStreamPropertySSLSettings];
    }
    if (_enabledSSLCipherSuites) {
        CFReadStreamRef readStream = (__bridge CFReadStreamRef)_inputStream;
        CFWriteStreamRef writeStream = (__bridge CFWriteStreamRef)_outputStream;
        SSLContextRef  sslContextIn = (SSLContextRef)CFReadStreamCopyProperty(readStream, kCFStreamPropertySSLContext);
        SSLContextRef  sslContextOut =(SSLContextRef)CFWriteStreamCopyProperty(writeStream, kCFStreamPropertySSLContext);
        if(sslContextIn && sslContextOut) {
            SSLCipherSuite *supported = (SSLCipherSuite *)malloc(_enabledSSLCipherSuites.count * sizeof(SSLCipherSuite));
            
            for(int i = 0; i < _enabledSSLCipherSuites.count; i ++){
                supported[i] = ((SSLCipherSuiteObject *)_enabledSSLCipherSuites[i]).suite;
            }
            
            OSStatus resIn = SSLSetEnabledCiphers(sslContextIn, supported, _enabledSSLCipherSuites.count);
            OSStatus resOut = SSLSetEnabledCiphers(sslContextOut, supported, _enabledSSLCipherSuites.count);
            
            if (resIn != errSecSuccess) {
                NSError *error = [self errorWithDetail:@"Error setting ingoing cypher suites" code:resIn];
                [self disconnectStream:error];
                return;
            }
            if (resOut != errSecSuccess) {
                NSError *error = [self errorWithDetail:@"Error setting outgoing cypher suites" code:resOut];
                [self disconnectStream:error];
                return;
            }
        }
    }
    CFReadStreamSetDispatchQueue(readStream, [WebSocket sharedWorkQueue]);
    CFWriteStreamSetDispatchQueue(writeStream, [WebSocket sharedWorkQueue]);
    
    [_inputStream open];
    [_outputStream open];
    
    [_mutex lock];
    _readyToWrite = true;
    [_mutex unlock];
    
    const uint8_t *bytes = (const uint8_t*)[data bytes];
    __block int timeout = 5000000; //wait 5 seconds before giving up
    
    __weak WebSocket *weakSelf = self;
    
    [_writeQueue addOperationWithBlock:^{
        if(!weakSelf) {
            return;
        }
        while (![_outputStream hasSpaceAvailable]) {
            usleep(100);
            timeout = timeout - 100;
            
            if(timeout < 0){
                [weakSelf cleanupStream];
                [weakSelf doDisconnect:[weakSelf errorWithDetail:@"write wait timed out" code:2]];
                return;
            } else if ([_outputStream streamError]){
                return;
            }
            
            [_outputStream write:bytes maxLength:[data length]];
        }
    }];
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {
    
    if(_security){
        if(!_certValidated && (eventCode == NSStreamEventHasBytesAvailable || eventCode == NSStreamEventHasSpaceAvailable)){
            id trust = [aStream propertyForKey:(__bridge NSString *)kCFStreamPropertySSLPeerTrust];
            if(trust){
                id domain = [aStream propertyForKey:(__bridge NSString *)kCFStreamSSLPeerName];
                if([_security isValid:(SecTrustRef)trust domain:(NSString *)domain]){
                    _certValidated = true;
                }
                } else {
                    NSError *error = [self errorWithDetail:@"Invalid SSL certificate" code:1];
                    [self disconnectStream:error];
                    return;
                }
            }
        }
    
    if(eventCode == NSStreamEventHasBytesAvailable) {
        if ([aStream isEqual:_inputStream]) {
            [self processInputStream];
        }
    } else if (eventCode == NSStreamEventErrorOccurred) {
        [self disconnectStream:[aStream streamError]];
    } else if (eventCode == NSStreamEventEndEncountered) {
        [self disconnectStream:nil];
    }
}

//disconnect the stream object
-(void)disconnectStream:(NSError *)error {
    [_writeQueue waitUntilAllOperationsAreFinished];
    [self cleanupStream];
    [self doDisconnect:error];
}

-(void)cleanupStream {
    _outputStream.delegate = nil;
    _inputStream.delegate = nil;
    
    if (_inputStream) {
        CFReadStreamSetDispatchQueue((CFReadStreamRef)_inputStream, nil);
        [_inputStream close];
    }
    if (_outputStream) {
        CFWriteStreamSetDispatchQueue((CFWriteStreamRef)_outputStream, nil);
        [_outputStream close];
    }
    _outputStream = nil;
    _inputStream = nil;
}

///dequeue the incoming input so it is processed in order
-(void)dequeueInput {
    if(!_inputQueue || [_inputQueue count] == 0){
        return;
    }
    
    NSData *data = _inputQueue[0];
    NSData *work;
    if(_fragBuffer) {
        NSMutableData *combine = [_fragBuffer mutableCopy];
        [combine appendData:data];
        work = [combine copy];
        _fragBuffer = nil;
    }
    
    uint8_t *buffer = (uint8_t *)work.bytes;
    NSInteger length = work.length;
    if (!_connected) {
        [self processTCPHandshake:buffer bufferLen:length];
    } else {
        [self processRawMessage:buffer bufferLen:length];
    }
    [_inputQueue removeObject:data];
    [self dequeueInput];
}

//handle checking the inital connection status
-(void)processTCPHandshake:(uint8_t *)buffer bufferLen:(NSInteger)bufferLen {
    NSUInteger code = [self processHTTP:buffer bufferLen:bufferLen];
    switch(code) {
        case 0: {
            _connected = true;
            if(![self canDispatch]){
                return;
            }
            
            __weak WebSocket *weakSelf = self;
            dispatch_async(_queue, ^{
                if(weakSelf) {
                    [weakSelf onConnect];
                    if([weakSelf delegate]) {
                        [[weakSelf delegate] websocketDidConnect:weakSelf];
                    }
                }
            });
            break;
        }
        case -1: {
            _fragBuffer = [[NSData alloc] initWithBytes:buffer length:bufferLen];
            break;
        }
        default:{
            [self doDisconnect:[self errorWithDetail:@"Invalid HTTP upgrade" code:(uint)code]];
            break;
        }
    }
}

///Finds the HTTP Packet in the TCP stream, by looking for the CRLF.
-(NSInteger)processHTTP:(uint8_t *)buffer bufferLen:(NSInteger)bufferLen {
    uint8_t CRLFBytes[4];
    CRLFBytes[0] = (uint8_t)'\r';
    CRLFBytes[1] = (uint8_t)'\n';
    CRLFBytes[2] = (uint8_t)'\r';
    CRLFBytes[3] = (uint8_t)'\r';
    
    NSInteger k = 0;
    NSInteger totalSize = 0;
    
    for(int i = 0; i < bufferLen; i++){
        if(buffer[i] == CRLFBytes[k]){
            k += 1;
            
            if(k == 3){
                totalSize = i + 1;
                break;
            }
        } else {
            k = 0;
        }
    }
    
    if (totalSize > 0) {
        NSUInteger code = [self validateResponse:buffer bufferLen:totalSize];
        if (code != 0) {
            return code;
        }
        totalSize += 1; //skip the last \n
        NSInteger restSize = bufferLen - totalSize;
        if (restSize > 0) {
            [self processRawMessage:(buffer+totalSize) bufferLen:restSize];
        }
        return 0; //success
    }
    return -1; //was unable to find the full TCP header
}

///handles the incoming bytes and sending them to the proper processing method
-(void)processInputStream {
    NSMutableData *buf = [[NSMutableData alloc] initWithCapacity:BUFFER_MAX];
    uint8_t * buffer = (uint8_t*)buf.bytes;
    NSInteger length = [_inputStream read:buffer maxLength:BUFFER_MAX];
    
    if(length < 0) {
        return;
    }
    
    BOOL process = false;
    
    if([_inputQueue count] == 0){
        process = true;
    }
    [_inputQueue addObject:[[NSData alloc] initWithBytes:buffer length:length]];
    
    if (process) {
        [self dequeueInput];
    }
}

///validates the HTTP is a 101 as per the RFC spec
-(NSInteger)validateResponse:(uint8_t *)buffer bufferLen:(NSInteger)bufferLen {
    CFHTTPMessageRef  response = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, false);
    CFHTTPMessageAppendBytes(response, buffer, bufferLen);
    
    NSInteger code = CFHTTPMessageGetResponseStatusCode(response);
    if (code != 101) {
        return code;
    }
    
    CFDictionaryRef cfHeaders = CFHTTPMessageCopyAllHeaderFields(response);
    
    if(cfHeaders) {
        NSDictionary *headers = (__bridge NSDictionary*)cfHeaders;
        NSString *acceptKey = headers[headerWSAcceptName];
        if(acceptKey && [acceptKey length] > 0){
            return 0;
        }
    }
    
    return -1;
}

///write a 16 bit big endian value to a buffer
+ (void)writeUint16:(uint8_t *)buffer offset:(int)offset value:(NSUInteger)value {
    buffer[offset + 0] = (uint8_t)value >> 8;
    buffer[offset + 1] = (uint8_t)value & 0xff;
}

///write a 64 bit big endian value to a buffer
#warning might be 7 for i in 0...7
+ (void)writeUint64:(uint8_t *)buffer offset:(int)offset value:(NSUInteger)value {
    for (int i = 0; i < 8; i++){
        buffer[offset + i] = (uint8_t)((value >> (8* ((uint64_t)(7 - i)))) & 0xff);
    }
}

///read a 16 bit big endian value from a buffer
+(uint16_t)readUint16:(uint8_t *)buffer offset:(NSUInteger)offset {
    uint16_t bufferOffset = buffer[offset + 0] << 8;
    return (bufferOffset | ((uint16_t)buffer[offset + 1]));
}

#warning might be 7 for i in 0...7
///read a 64 bit big endian value from a buffer
+(uint64_t)readUint64:(uint8_t *)buffer offset:(NSUInteger)offset {
    uint64_t value = (uint64_t)0;
    
    for (int i = 0; i < 8; i++){
        value = ((value << 8) | (uint64_t)buffer[offset + i]);
    }
    
    return value;
}

///process the websocket data
-(void)processRawMessage:(uint8_t *)buffer bufferLen:(NSInteger)bufferLen {
    
    WSResponse *response = [_readStack lastObject];
    if(response && bufferLen < 2){
        _fragBuffer = [[NSData alloc] initWithBytes:buffer length:bufferLen];
        return;
    }
    if(response && response.bytesLeft > 0){
        NSInteger len = response.bytesLeft;
        NSInteger extra = bufferLen - response.bytesLeft;
        if(response.bytesLeft > bufferLen){
            len = bufferLen;
            extra = 0;
        }
        response.bytesLeft -= len;
        [[response buffer] appendData:[[NSData alloc] initWithBytes:buffer length:bufferLen]];
        [self processResponse:response];
        NSInteger offset = bufferLen - extra;
        if (extra > 0) {
            [self processRawMessage:(buffer+offset) bufferLen:extra];
        }
        return;
    } else {
        NSUInteger isFin = (FinMask & buffer[0]);
        OpCode receivedOpcode = OpCodeMask & buffer[0];
        NSUInteger isMasked = (MaskMask & buffer[1]);
        NSUInteger payloadLen = (PayloadLenMask & buffer[1]);
        NSUInteger offset = 2;
        if ((isMasked > 0 || (RSVMask & buffer[0]) > 0) && receivedOpcode != OpCodePing) {
            CloseCode errCode = CloseCodeProtocolError;
            [self doDisconnect:[self errorWithDetail:@"masked and rsv data is not currently supported" code:errCode]];
            [self writeError:errCode];
            return;
        }
        OpCode isControlFrame = (receivedOpcode == OpCodeConnectionClose || receivedOpcode == OpCodePing);
        if(!isControlFrame && (receivedOpcode != OpCodeBinaryFrame && receivedOpcode != OpCodeContinueFrame &&
                               receivedOpcode != OpCodeTextFrame && receivedOpcode != OpCodePong)){
            CloseCode errCode = CloseCodeProtocolError;
            NSString *opCode = [[NSString alloc] initWithFormat:@"%lu", (unsigned long)receivedOpcode];
            [self doDisconnect:[self errorWithDetail:opCode code:errCode]];
            [self writeError:errCode];
            return;
        }
        if (isControlFrame && isFin == 0) {
            CloseCode errCode = CloseCodeProtocolError;
            [self doDisconnect:[self errorWithDetail:@"control frames can't be fragmented" code:errCode]];
            [self writeError:errCode];
            return;
        }
        if (receivedOpcode == OpCodeConnectionClose) {
            NSUInteger code = CloseCodeNormal;
            if (payloadLen == 1) {
                code = CloseCodeProtocolError;
            } else if (payloadLen > 1) {
                code = [WebSocket readUint16:buffer offset:offset];
                if (code < 1000 || (code > 1003 && code < 1007) || (code > 1011 && code < 3000)) {
                    code = CloseCodeProtocolError;
                }
                offset += 2;
            }
            if (payloadLen > 2) {
                int len = (int)payloadLen-2;
                if (len > 0) {
                    uint8_t *bytes = buffer+offset;
                    NSString *str = [[NSString alloc] initWithData:[[NSData alloc] initWithBytes:bytes length:len] encoding:NSUTF8StringEncoding];
                    if (!str) {
                        code = CloseCodeProtocolError;
                    }
                }
            }
            [self doDisconnect:[self errorWithDetail:@"connection closed by server" code:(uint)code]];
            [self writeError:code];
            return;
        }
        if ((isControlFrame && payloadLen) > 125) {
            [self writeError:CloseCodeProtocolError];
            return;
        }
        uint64_t dataLength = (uint64_t)payloadLen;
        if (dataLength == 127) {
            dataLength = [WebSocket readUint64:buffer offset:offset];
            offset += sizeof(UInt64);
        } else if (dataLength == 126) {
            dataLength = (uint64_t)[WebSocket readUint16:buffer offset:offset];
            offset += sizeof(UInt16);
        }
        if (bufferLen < offset || ((uint64_t)(bufferLen - offset) < dataLength)) {
            _fragBuffer = [[NSData alloc] initWithBytes:buffer length:bufferLen];
            return;
        }
        NSUInteger len = dataLength;
        if (dataLength > (uint64_t)bufferLen) {
            len = ((uint64_t)(bufferLen-offset));
        }
        NSData *data;
        if (len < 0) {
            len = 0;
            data = [[NSData alloc] init];
        } else {
            data = [[NSData alloc] initWithBytes:buffer length:len];
        }
        
        if (receivedOpcode == OpCodePong) {
            if([self canDispatch]){
                __weak WebSocket *weakSelf = self;
                dispatch_async(_queue, ^{
                    if(weakSelf){
                        [weakSelf onPong];
                        [[weakSelf pongDelegate] websocketDidReceivePong:weakSelf];
                    }
                });
            }
            
            NSInteger step = (NSInteger)(offset+len);
            NSInteger extra = bufferLen-step;
            if (extra > 0) {
                [self processRawMessage:(buffer+step) bufferLen:extra];
            }
            return;
        }
        
        WSResponse *response = [_readStack lastObject];
        if (isControlFrame) {
            response = nil; //don't append pings
        }
        if (isFin == 0 && receivedOpcode == OpCodeContinueFrame && response == nil) {
            CloseCode errCode = CloseCodeProtocolError;
            [self doDisconnect:[self errorWithDetail:@"continue frame before a binary or text frame" code:errCode]];
            [self writeError:errCode];
            return;
        }
        
        BOOL isNew = false;
        
        if (response == nil) {
            if (receivedOpcode == OpCodeContinueFrame)  {
                CloseCode errCode = CloseCodeProtocolError;
                [self doDisconnect:[self errorWithDetail:@"first frame can't be a continue frame" code:errCode]];
                [self writeError:errCode];
                return;
            }
            isNew = true;
            response = [[WSResponse alloc] init];
            response.code = receivedOpcode;
            response.bytesLeft = dataLength;
            response.buffer = [data mutableCopy];
        } else {
            if (receivedOpcode == OpCodeContinueFrame)  {
                response.bytesLeft = dataLength;
            } else {
                CloseCode errCode = CloseCodeProtocolError;
                [self doDisconnect:[self errorWithDetail:@"second and beyond of fragment message must be a continue frame" code:errCode]];
                [self writeError:errCode];
                return;
            }
            [response.buffer appendData:data];
        }
        if (response) {
            response.bytesLeft -= len;
            response.frameCount += 1;
            response.isFin = isFin > 0 ? true : false;
            if (isNew) {
                [_readStack addObject:response];
            }
            [self processResponse:response];
        }
        
        NSInteger step = offset+len;
        NSInteger extra = bufferLen-step;
        if (extra > 0) {
            [self processExtra:(buffer+step) bufferLen:extra];
        }
    }
    
}

///process the extra of a buffer
-(void)processExtra:(uint8_t *)buffer bufferLen:(NSInteger)bufferLen {
    if (bufferLen < 2) {
        _fragBuffer = [[NSData alloc] initWithBytes:buffer length:bufferLen];
    } else {
        [self processRawMessage:buffer bufferLen:bufferLen];
    }
}

///process the finished response of a buffer
-(BOOL)processResponse:(WSResponse *)response {
    if (response.isFin && response.bytesLeft <= 0) {
        if (response.code == OpCodePing) {
            NSData *data = [response.buffer copy]; //local copy so it is perverse for writing
            [self dequeueWrite:data code:OpCodePong];
        } else if (response.code == OpCodeTextFrame) {
            NSString *str = [[NSString alloc] initWithData:response.buffer encoding:NSUTF8StringEncoding];
            if (!str) {
                [self writeError:CloseCodeEncoding];
                return false;
            }
            if ([self canDispatch]) {
                __weak WebSocket *weakSelf = self;
                dispatch_async(_queue, ^{
                    if(weakSelf) {
                        [weakSelf onText](str);
                        [weakSelf.delegate websocketDidReceiveMessage:weakSelf string:str];
                    }
                });
            }
            
        } else if (response.code == OpCodeBinaryFrame) {
            if ([self canDispatch]) {
                __block NSData *data = [response.buffer copy];//local copy so it is perverse for writing
                
                __weak WebSocket *weakSelf = self;
                dispatch_async(_queue, ^{
                    if(weakSelf) {
                        weakSelf.onData(data);
                        [weakSelf.delegate websocketDidReceiveData:weakSelf data:data];
                    }
                });
            }
        }
        [_readStack removeLastObject];
        return true;
    }
    return false;
}

///Create an error
-(NSError*)errorWithDetail:(NSString *)detail code:(uint)code {
    NSDictionary *details = @{NSLocalizedDescriptionKey:detail};
    return [NSError errorWithDomain:ErrorDomain code:(int)code userInfo:details];
}

///write a an error to the socket
-(void)writeError:(NSUInteger)code {
    NSMutableData *buf = [[NSMutableData alloc] initWithCapacity:sizeof(UInt16)];
    uint8_t *buffer = (uint8_t *)buf.bytes;
    [WebSocket writeUint16:buffer offset:0 value:code];
    [self dequeueWrite:[[NSData alloc] initWithBytes:buffer length:sizeof(UInt16)] code:OpCodeConnectionClose];
}

///used to write things to the stream
-(void)dequeueWrite:(NSData *)data code:(OpCode) code {
    __weak WebSocket *weakSelf = self;

    [_writeQueue addOperationWithBlock:^{

        if(!weakSelf) {
            return;
        }
        //stream isn't ready, let's wait
        int offset = 2;
        const uint8_t *bytes = (const uint8_t*)[data bytes];
        NSUInteger dataLength = [data length];
        NSMutableData *frame = [[NSMutableData alloc] initWithCapacity:dataLength + MaxFrameSize];
        uint8_t *buffer = (uint8_t*)[frame mutableBytes];
        buffer[0] = FinMask | code;
        if (dataLength < 126) {
            buffer[1] = [@(dataLength) unsignedCharValue];
        } else if (dataLength <= (int)UINT16_MAX) {
            buffer[1] = 126;
            [WebSocket writeUint16:buffer offset: offset value:(dataLength)];
            offset += sizeof(UInt16);
        } else {
            buffer[1] = 127;
            [WebSocket writeUint64:buffer offset: offset value:(dataLength)];
            offset += sizeof(UInt64);
        }
        buffer[1] |= MaskMask;
        uint8_t *maskKey = (buffer + offset);
        SecRandomCopyBytes(kSecRandomDefault, sizeof(UInt32), maskKey);
        offset += sizeof(UInt32);
        
        for (int i = 0; i < dataLength < i; i++){
            buffer[offset] = bytes[i] ^ maskKey[i % sizeof(UInt32)];
            offset += 1;
        }
        int total = 0;
        while (true) {
            if(!_outputStream){
                return;
            }
            uint8_t *writeBuffer =(uint8_t*)(frame.bytes+total);
            int len = (int)[_outputStream write:writeBuffer maxLength:offset-total];
            if (len < 0) {
   
                NSError *error = [weakSelf errorWithDetail:@"output stream error during write" code:InternalErrorCodeOutputStreamWriteError];
                [weakSelf doDisconnect:error];
                break;
            } else {
                total += len;
            }
            if (total >= offset) {
                break;
            }
        }

    }];
}

///used to preform the disconnect delegate
-(void)doDisconnect:(NSError *)error {
    if(_didDisconnect)
        return;
    _didDisconnect = true;
    _connected = false;
    
    if(![self canDispatch]) {
        return;
    }
    
    __weak WebSocket *weakSelf = self;
    dispatch_async(_queue, ^{
        weakSelf.onDisconnect(error);
        [[weakSelf delegate] websocketDidDisconnect:weakSelf error:error];
    });
}

-(void)dealloc{
    [_mutex lock];
    _readyToWrite = false;
    [_mutex unlock];
    [self cleanupStream];
}

-(NSString *)stringWithUnicode:(NSUInteger)uint {
    unichar utf8char = 0xce91;
    char chars[2];
    int len = 1;
    
    if (utf8char > 127) {
        chars[0] = (utf8char >> 8) & (1 << 8) - 1;
        chars[1] = utf8char & (1 << 8) - 1;
        len = 2;
    } else {
        chars[0] = utf8char;
    }
    
    NSString *string = [[NSString alloc] initWithBytes:chars
                                                length:len
                                              encoding:NSUTF8StringEncoding];
    return string;
}

-(BOOL)canDispatch{
    [_mutex lock];
    BOOL canWork = _readyToWrite;
    [_mutex unlock];
    return canWork;
}

-(BOOL)isConnected{
    return _connected;
}

+(dispatch_queue_t)sharedWorkQueue{
    return _sharedWorkQueue;
}
@end
