//
//  SSLSecurity.m
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

#import "SSLSecurity.h"
#import "SecKey.h"
#import "SSLCert.h"
@import Security;

@implementation SSLSecurity

/**
 Use certs from main app bundle
 
 - parameter usePublicKeys: is to specific if the publicKeys or certificates should be used for SSL pinning validation
 
 - returns: a representation security object to be used with
 */
-(id)init {
    self = [super init];
    if(self){
        NSArray *paths = [[NSBundle mainBundle] pathsForResourcesOfType:@"cer" inDirectory:@"."];
        NSMutableArray *certs = [@[] mutableCopy];
        for (NSString *path in paths) {
            NSData *data = [[NSData alloc] initWithContentsOfFile:path];
            if(data) {
                SSLCert *sslCert = [[SSLCert alloc] init];
                sslCert.certData = data;
                [certs addObject:sslCert];
            }
        }
        [self initialize:false certs:certs];
    }
    
    return self;
}

/**
 Designated init
 
 - parameter keys: is the certificates or public keys to use
 - parameter usePublicKeys: is to specific if the publicKeys or certificates should be used for SSL pinning validation
 
 - returns: a representation security object to be used with
 */
-(id)initWithCert:(NSArray *)certs usePublicKeys:(BOOL)usePublicKeys {
    
    self = [super init];
    
    if(self){
    
        [self initialize:usePublicKeys certs:certs];
    }
    
    return self;
}

- (void)initialize:(BOOL)usePublicKeys certs:(NSArray *)certs {
    _usePublicKeys = usePublicKeys;
    
    if(usePublicKeys) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            NSMutableArray *pubKeys = [@[] mutableCopy];
            for(SSLCert* cert in certs){
                NSData *data = cert.certData;
                if(data && !cert.key){
                    cert.key = [self extractPublicKey:data];
                }
                if(cert.key){
                    SecKey *secKey = [[SecKey alloc] init];
                    secKey.key = cert.key;
                    [pubKeys addObject:secKey];
                }
            }
            _pubKeys = pubKeys;
            _isReady = true;
        });
    } else {
        NSMutableArray *certificates = [@[] mutableCopy];
        for(SSLCert* cert in certs){
            if(cert.certData){
                [certificates addObject:cert.certData];
            }
        }
        _certificates = certificates;
        _isReady = true;
    }
}

/**
 Valid the trust and domain name.
 
 - parameter trust: is the serverTrust to validate
 - parameter domain: is the CN domain to validate
 
 - returns: if the key was successfully validated
 */

-(BOOL)isValid:(SecTrustRef)trust domain:(NSString*)domain{
    
    int tries = 0;
    while(!self.isReady) {
        usleep(1000);
        tries += 1;
        if (tries > 5) {
            return false; //doesn't appear it is going to ever be ready...
        }
    }
    SecPolicyRef policy;
    if (self.validatedDN) {
        policy = SecPolicyCreateSSL(true, (__bridge CFStringRef)domain);
    } else {
        policy = SecPolicyCreateBasicX509();
    }
    SecTrustSetPolicies(trust,policy);
    if (self.usePublicKeys) {
        NSArray *keys = self.pubKeys;
        if (keys) {
            NSArray *serverPubKeys = [self publicKeyChainForTrust:trust];
            for (SecKey *serverKey in serverPubKeys) {
                for(SecKey *localPublicKeys in keys){
                    if(serverKey.key == localPublicKeys.key) {
                        return true;
                    }
                }
            }
        }
    } else {
        if(self.certificates){
            NSArray *certs = self.certificates;
            NSArray *serverCerts = [self certificateChainForTrust:trust];
            NSMutableArray *collection = [@[] mutableCopy];
           
            for(NSData *localCert in certs) {
                CFDataRef localCertData = CFDataCreate(NULL, [localCert bytes], [localCert length]);
                SecCertificateRef secCertRef = SecCertificateCreateWithData(nil, localCertData);
                [collection addObject:(__bridge id)secCertRef];
            }
            
            CFArrayRef collect = (__bridge CFArrayRef)[collection copy];
            SecTrustSetAnchorCertificates(trust,collect);
            SecTrustResultType result = 0;
            SecTrustEvaluate(trust,&result);
            if (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed) {
                int trustedCount = 0;
                for (NSData *serverCert in serverCerts) {
                    for (NSData *localCertData in certs) {
                        if (localCertData == serverCert) {
                            trustedCount += 1;
                            break;
                        }
                    }
                }
                if (trustedCount == serverCerts.count) {
                    return true;
                }
            
            }
        }
    }
    return false;
}

/**
 Get the public key from a certificate data
 
 - parameter data: is the certificate to pull the public key from
 
 - returns: a public key
 */
-(SecKeyRef)extractPublicKey:(NSData *)data{
    CFDataRef localCertData = CFDataCreate(NULL, [data bytes], [data length]);
    SecCertificateRef secCertRef = SecCertificateCreateWithData(nil, localCertData);
    
    if(!secCertRef) {
        return nil;
    }
    return [self extractPublicKeyFromCert:secCertRef policy:SecPolicyCreateBasicX509()];
}

/**
 Get the public key from a certificate
 
 - parameter data: is the certificate to pull the public key from
 
 - returns: a public key
 */

-(SecKeyRef)extractPublicKeyFromCert:(SecCertificateRef)cert policy:(SecPolicyRef)policy {
    SecTrustRef possibleTrust;
    SecTrustCreateWithCertificates(cert, policy, &possibleTrust);
    
    if(!possibleTrust) {
        return nil;
    }
    
    SecTrustResultType result = 0;
    SecTrustEvaluate(possibleTrust, &result);
    return SecTrustCopyPublicKey(possibleTrust);
}

/**
 Get the certificate chain for the trust
 
 - parameter trust: is the trust to lookup the certificate chain for
 
 - returns: the certificate chain for the trust
 */

-(NSArray *)certificateChainForTrust:(SecTrustRef) trust {
    CFIndex count = SecTrustGetCertificateCount(trust);
    NSMutableArray *certs = [@[] mutableCopy];
    
    for (int i = 0; i < count; i++) {
        SecCertificateRef cert = SecTrustGetCertificateAtIndex(trust, i);
        NSData *certData =  (__bridge_transfer NSData*)SecCertificateCopyData(cert);
        [certs addObject:certData];
    }
    
    return certs;
}

/**
 Get the public key chain for the trust
 
 - parameter trust: is the trust to lookup the certificate chain and extract the public keys
 
 - returns: the public keys from the certifcate chain for the trust
 */

-(NSArray *)publicKeyChainForTrust:(SecTrustRef)trust{
    SecPolicyRef policy = SecPolicyCreateBasicX509();
    CFIndex count = SecTrustGetCertificateCount(trust);
    NSMutableArray *keys = [@[] mutableCopy];
    
    for (int i = 0; i < count; i++) {
        SecCertificateRef cert = SecTrustGetCertificateAtIndex(trust, i);
        SecKeyRef keyRef = [self extractPublicKeyFromCert:cert policy:policy];
        SecKey *key = [[SecKey alloc] init];
        key.key = keyRef;
        [keys addObject:key];
    }
    
    return keys;
}
@end
