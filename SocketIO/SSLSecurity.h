//
//  SSLSecurity.h
//  SocketIO
//
//  Created by Robert Gross on 2/18/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSLSecurity : NSObject
@property BOOL validatedDN;
@property BOOL isReady;
@property BOOL usePublicKeys;
@property NSArray *pubKeys;
@property NSArray *certificates;

-(BOOL)isValid:(SecTrustRef)trust domain:(NSString*)domain;
@end
