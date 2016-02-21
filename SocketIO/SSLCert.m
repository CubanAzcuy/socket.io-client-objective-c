//
//  SSLCert.m
//  SocketIO
//
//  Created by Robert Gross on 2/18/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import "SSLCert.h"

@implementation SSLCert

/**
 Designated init for certificates
 
 - parameter data: is the binary data of the certificate
 
 - returns: a representation security object to be used with
 */
-(id)initWithCert:(NSData *)data {
    self = [super init];
    if(self) {
        _certData = data;
    }
    return self;
}

/**
 Designated init for public keys
 
 - parameter key: is the public key to be used
 
 - returns: a representation security object to be used with
 */
-(id)initWithSecKeyRef:(SecKeyRef)key {
    self = [super init];
    if(self) {
        _key = key;
    }
    return self;
}

@end
