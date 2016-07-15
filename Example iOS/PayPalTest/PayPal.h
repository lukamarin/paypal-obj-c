//
//  PayPal.h
//  PayPalTest
//
//  Created by Rafael Castro on 10/30/14.
//  Copyright (c) 2014 HummingBird. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PayPalDelegate;


@interface PayPal : NSObject

@property (assign, nonatomic) id <PayPalDelegate> delegate;
@property (assign, nonatomic) BOOL sandbox;
@property (strong, nonatomic) NSString *signature;
@property (strong, nonatomic) NSString *password;
@property (strong, nonatomic) NSString *user;
@property (strong, nonatomic) NSString *returnURL;
@property (strong, nonatomic) NSString *cancelURL;
@property (strong, nonatomic) NSArray *products;
@property (strong, nonatomic) NSDictionary *payment;

+(id)sharedInstance;
+(NSString *)token;
+(NSString *)billingID;
-(void)resetCredentials;
-(void)requestSetCheckoutExpress;
-(void)requestBillingAgreement;
-(void)requestReferenceTransaction;
-(void)setCurrentURL:(NSString *)url_string;
-(BOOL)isReferenceTransactionEnabled;

@end

//Request Type
typedef NS_ENUM(NSInteger, requestType)
{
    requestTypeSetCheckout,
    requestTypeBillingAgreement,
    requestTypeReferenceTransaction
};

//Paypal Protocol
@protocol PayPalDelegate <NSObject>
-(void)paypal:(PayPal *)paypal didStartRequest:(requestType)requestType;
-(void)paypal:(PayPal *)paypal didFinishRequest:(requestType)requestType;
-(void)paypal:(PayPal *)paypal didFinishWebView:(BOOL)success;
-(void)paypal:(PayPal *)paypal didReceiveExpressCheckoutToken:(NSString *)token;
-(void)paypal:(PayPal *)paypal didReceiveRedirectURL:(NSString *)url_string;
-(void)paypal:(PayPal *)paypal didReceiveBillingID:(NSString *)billingID;
-(void)paypal:(PayPal *)paypal didReceiveTransactionID:(NSString *)transactionID status:(NSString *)status;
-(void)paypal:(PayPal *)paypal didReceiveFail:(NSArray *)error_codes request:(requestType)requestType;
@end
