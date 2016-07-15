//
//  PayPal.m
//  PayPalTest
//
//  Created by Rafael Castro on 10/30/14.
//  Copyright (c) 2014 HummingBird. All rights reserved.
//

/*
 
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.
 
*/

#import "PayPal.h"

#define END_POINT_SANDBOX @"https://api-3t.sandbox.paypal.com/nvp"
#define END_POINT_PRODUCTION @"https://api-3t.paypal.com/nvp"
#define TOKEN_KEY @"PAYPAL_TOKEN"
#define BILLING_ID_KEY @"PAYPAL_BILLIND_ID"


@interface PayPal () <NSURLConnectionDelegate>
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSString *token;
@property (nonatomic, assign) requestType requestType;
@end

@implementation PayPal

+ (id)sharedInstance
{
    static PayPal *paypal = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        paypal = [[self alloc] init];
    });
    return paypal;
}

-(NSString *)endPointURL
{
    return self.sandbox == YES?END_POINT_SANDBOX:END_POINT_PRODUCTION;
}
-(NSString *)redirectURL
{
    return [NSString stringWithFormat:@"https://www.sandbox.paypal.com/br/cgi-bin/webscr?cmd=_express-checkout-mobile&useraction=commit&token=%@",self.token];
}

#pragma mark - Verify Parameters

-(void)verifySetCheckoutParameters
{
    NSAssert(self.returnURL,@"Miss RETURN URL parameter");
    NSAssert(self.cancelURL,@"Miss CANCEL URL parameter");
    [self verifyReferenceTransactionParameters];
}
-(void)verifyReferenceTransactionParameters
{
    NSAssert(self.user,@"Miss USER parameter");
    NSAssert(self.password, @"Miss PASSWORD parameter");
    NSAssert(self.signature,@"Miss SIGNATURE parameter");
}

#pragma mark - NSUserDefault

+(NSString *)token
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:TOKEN_KEY];
}
-(void)saveToken:(NSString *)paypal_token
{
    [[NSUserDefaults standardUserDefaults] setObject:paypal_token forKey:TOKEN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)removeToken
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TOKEN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
+(NSString *)billingID
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:BILLING_ID_KEY];
}
-(void)saveBillingID:(NSString *)billingID
{
    [[NSUserDefaults standardUserDefaults] setObject:billingID forKey:BILLING_ID_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)removeBillingID
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:BILLING_ID_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
-(void)resetCredentials
{
    [self removeToken];
    [self removeBillingID];
}

#pragma mark - SetCheckoutExpress

-(void)requestSetCheckoutExpress
{
    [self verifySetCheckoutParameters];
    NSString *url_string = [self endPointURL];
    NSString *parameters = [self NVPSetCheckout];
    [self startConnectionWithURL:url_string parameters:parameters tag:requestTypeSetCheckout];
}

#pragma mark - BillingAgreement

-(void)requestBillingAgreement
{
    NSString *url_string = [self endPointURL];
    NSString *parameters = [self NVPBillingAgreement];
    [self startConnectionWithURL:url_string parameters:parameters tag:requestTypeBillingAgreement];
}

#pragma mark - ReferenceTransaction


-(void)requestReferenceTransaction
{
    [self verifyReferenceTransactionParameters];
    NSString *url_string = [self endPointURL];
    NSString *parameters = [self NVPReferenceTransaction];
    [self startConnectionWithURL:url_string parameters:parameters tag:requestTypeReferenceTransaction];
}
-(BOOL)isReferenceTransactionEnabled
{
    NSString *billingID = [PayPal billingID];
    return billingID&&![billingID isEqualToString:@""]?YES:NO;
}

#pragma mark - NVP

-(NSString *)NVPFromDictionary:(NSDictionary *)dic
{
    NSString *parameters = @"";
    for (NSString *key in dic) {
        NSString *value = [dic objectForKey:key];
        parameters = [NSString stringWithFormat:@"%@%@=%@&",parameters,key,value];
    }
    parameters = [NSString stringWithFormat:@"%@",[parameters substringToIndex:parameters.length-1]];
    return parameters;
}
-(NSString *)NVPSetCheckout
{
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                        self.user,@"USER",
                        self.signature,@"SIGNATURE",
                        self.password,@"PWD",
                        @"SetExpressCheckout",@"METHOD",
                        @"114.0",@"VERSION",
                        @"MerchantInitiatedBillingSingleAgreement",@"L_BILLINGTYPE0",
                        @"Descricao de regras da compra recursiva", @"L_BILLINGAGREEMENTDESCRIPTION0",
//                        'HDRIMG' => 'https://loja.com/header-image.png',
//                        'LOCALECODE' => 'pt_BR'
                        self.returnURL,@"RETURNURL",
                        self.cancelURL,@"CANCELURL", nil];
    
    [dic addEntriesFromDictionary:self.payment];
    for (NSDictionary *product in self.products) {
        [dic addEntriesFromDictionary:product];
    }
    return [self NVPFromDictionary:dic];
}
-(NSString *)NVPBillingAgreement
{
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                         self.user,@"USER",
                         self.signature,@"SIGNATURE",
                         self.password,@"PWD",
                         @"CreateBillingAgreement",@"METHOD",
                         @"114.0",@"VERSION",
                         self.token,@"TOKEN", nil];
    return [self NVPFromDictionary:dic];
}
-(NSString *)NVPReferenceTransaction
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         self.user,@"USER",
                         self.signature,@"SIGNATURE",
                         self.password,@"PWD",
                         @"DoReferenceTransaction",@"METHOD",
                         @"114.0",@"VERSION",
                         [PayPal billingID],@"REFERENCEID", nil];
    [dic addEntriesFromDictionary:self.payment];
    return [self NVPFromDictionary:dic];
}


#pragma mark - Parse Methods

-(void)parseSetCheckout:(NSString *)str
{
    NSString *token = nil;
    NSString *ack = nil;
    NSMutableArray *errors = [[NSMutableArray alloc] init];
    
    //PARSE NVP
    NSArray *parameters = [str componentsSeparatedByString:@"&"];
    for (NSString *parameter in parameters) {
        NSLog(@"%@",parameter);
        
        NSArray *split = [parameter componentsSeparatedByString:@"="];
        NSString *key = (NSString *)split[0];
        NSString *value = (NSString *)split[1];
        if ([key isEqualToString:@"TOKEN"]) {
            token = value;
        }
        if ([key isEqualToString:@"ACK"]&&[value isEqualToString:@"Success"]) {
            ack = value;
        }
        if ([key rangeOfString:@"L_ERRORCODE"].location != NSNotFound) {
            [errors addObject:value];
        }
    }
    NSLog(@"\n\n");
    
    if (ack && token) {
        self.token = token;
        if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didReceiveRedirectURL:)]) {
            [self.delegate paypal:self didReceiveRedirectURL:[self redirectURL]];
        }
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didReceiveFail:request:)]) {
            [self.delegate paypal:self didReceiveFail:errors request:self.requestType];
        }
    }
}
-(void)parseBillingAgreement:(NSString *)str
{
    NSString *billingID = nil;
    NSString *ack = nil;
    NSMutableArray *errors = [[NSMutableArray alloc] init];

    
    //PARSE NVP
    NSArray *parameters = [str componentsSeparatedByString:@"&"];
    for (NSString *parameter in parameters) {
        NSLog(@"%@",parameter);
        
        NSArray *split = [parameter componentsSeparatedByString:@"="];
        NSString *key = (NSString *)split[0];
        NSString *value = (NSString *)split[1];
        if ([key isEqualToString:@"BILLINGAGREEMENTID"]) {
            billingID = value;
        }
        if ([key isEqualToString:@"ACK"]&&[value isEqualToString:@"Success"]) {
            ack = value;
        }
        if ([key rangeOfString:@"L_ERRORCODE"].location != NSNotFound) {
            [errors addObject:value];
        }
    }
    NSLog(@"\n\n");
    
    if (ack && billingID) {
        [self saveBillingID:billingID];
        if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didReceiveBillingID:)]) {
            [self.delegate paypal:self didReceiveBillingID:billingID];
        }
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didReceiveFail:request:)]) {
            [self.delegate paypal:self didReceiveFail:errors request:self.requestType];
        }
    }
}
-(void)parseReferenceTransaction:(NSString *)str
{
    NSString *paymentStatus = nil;
    NSString *transactionID = nil;
    NSString *ack = nil;
    NSMutableArray *errors = [[NSMutableArray alloc] init];

    
    //PARSE NVP
    NSArray *parameters = [str componentsSeparatedByString:@"&"];
    for (NSString *parameter in parameters) {
        NSLog(@"%@",parameter);
        
        NSArray *split = [parameter componentsSeparatedByString:@"="];
        NSString *key = (NSString *)split[0];
        NSString *value = (NSString *)split[1];
        if ([key isEqualToString:@"PAYMENTSTATUS"]) {
            paymentStatus = value;
        }
        if ([key isEqualToString:@"TRANSACTIONID"]) {
            transactionID = value;
        }
        if ([key isEqualToString:@"ACK"]&&[value isEqualToString:@"Success"]) {
            ack = value;
        }
        if ([key rangeOfString:@"L_ERRORCODE"].location != NSNotFound) {
            [errors addObject:value];
        }
    }
    NSLog(@"\n\n");
    
    if (ack)
        [self.delegate paypal:self didReceiveTransactionID:transactionID status:paymentStatus];
    else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didReceiveFail:request:)]) {
            [self.delegate paypal:self didReceiveFail:errors request:self.requestType];
        }
    }
}

#pragma mark - UIWebView current URL Tracking

//Verify if url string is RETURN_URL or CANCEL_URL
-(void)setCurrentURL:(NSString *)url_string
{
    if ([url_string rangeOfString:self.cancelURL].location != NSNotFound)
        [self.delegate paypal:self didFinishWebView:NO];
    
    if ([url_string rangeOfString:self.returnURL].location != NSNotFound){
        [self saveToken:self.token];
        if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didReceiveExpressCheckoutToken:)])
            [self.delegate paypal:self didReceiveExpressCheckoutToken:self.token];
        [self.delegate paypal:self didFinishWebView:YES];
        [self requestBillingAgreement];
    }
}

#pragma mark - Connection

-(void)startConnectionWithURL:(NSString *)url_string parameters:(NSString *)parameters tag:(NSInteger)tag
{
    self.requestType = tag;
    
    //Set start request flag
    if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didStartRequest:)]) {
        [self.delegate paypal:self didStartRequest:self.requestType];
    }
    
    //Start Connections
    NSURL *url = [NSURL URLWithString:url_string];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString *length = [NSString stringWithFormat:@"%ld", (unsigned long)[parameters length]];
    [request addValue:length forHTTPHeaderField:@"Content-Length"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody: [parameters dataUsingEncoding:NSUTF8StringEncoding]];
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}
-(void)fetchedQuery:(NSData *)data
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didFinishRequest:)]) {
        [self.delegate paypal:self didFinishRequest:self.requestType];
    }
    if (data == nil){
        NSLog(@"Failed to get data from Paypal!");
        return;
    }
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"\n\nServer Response");
    
    switch (self.requestType) {
        case requestTypeSetCheckout:
            [self parseSetCheckout:str];
            break;
        case requestTypeBillingAgreement:
            [self parseBillingAgreement:str];
            break;
        case requestTypeReferenceTransaction:
            [self parseReferenceTransaction:str];
            break;
        default:
            break;
    }
}


#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.data = [[NSMutableData alloc] init];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.data appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    [self fetchedQuery:self.data];
    self.data = nil;
    self.connection = nil;
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(paypal:didFinishRequest:)]) {
        [self.delegate paypal:self didFinishRequest:self.requestType];
    }

    NSLog(@"Connection Error. \n Description = %@ \n Reason = %@",error.localizedDescription,error.localizedFailureReason);
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Erro"
                                                      message:@"Verify your Internet Connection"
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    [message show];
    self.data = nil;
    self.connection = nil;
}


@end