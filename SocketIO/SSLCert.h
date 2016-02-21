//
//  SSLCert.h
//  SocketIO
//
//  Created by Robert Gross on 2/18/16.
//  Copyright © 2016 Bluefletch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SSLCert : NSObject
@property NSData* certData;
@property SecKeyRef key;
@end
