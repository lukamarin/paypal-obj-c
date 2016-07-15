//
//  ViewController.m
//  PayPalTest
//
//  Created by Rafael Castro on 10/30/14.
//  Copyright (c) 2014 HummingBird. All rights reserved.
//

#import "ViewController.h"
#import "PayPal.h"
@interface ViewController () <PayPalDelegate>

@property (strong, nonatomic) PayPal *paypal;
@property (nonatomic) float totalValue;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end



@implementation ViewController


-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set Paypal Info
    PayPal *paypal = [PayPal sharedInstance];
    paypal.sandbox = YES;
    paypal.delegate = self;
    
    //Add your CUSTOM PayPal User, Signature and Password
    paypal.user = @"zona-azul-sandbox_api1.gmail.com";
    paypal.signature = @"AFcWxV21C7fd0v3bYYYRCpSSRl31AQthEZp4prYpvpoEnhOhWfdFso14";
    paypal.password = @"TVRM7CW7F5S9XZL9";
}


//
// This method delete All PayPal Credentials
// such as BillingID and Token.
//
- (IBAction)reset:(id)sender
{
    PayPal *paypal = [PayPal sharedInstance];
    [paypal resetCredentials];
    
    [self showAlertText:@"You deleted your credentials with success"
              withTitle:@""];
}


//
// This method do the all paypal transaction process.
// In the fist purchase, it request the Set Express Checkout
// and request user to give permission to Reference Transaction
//
- (IBAction)buy:(id)sender
{
    //Create Fake Product 1
    NSDictionary *product1 = @{@"L_PAYMENTREQUEST_0_NAME0":@"Item A",
                               @"L_PAYMENTREQUEST_0_DESC0":@"Produto A – 110V",
                               @"L_PAYMENTREQUEST_0_AMT0":@"12.00",
                               @"L_PAYMENTREQUEST_0_QTY0":@"1"};
    
    
    //Create Fake Product 2
    NSDictionary *product2 = @{@"L_PAYMENTREQUEST_0_NAME1":@"Item B",
                               @"L_PAYMENTREQUEST_0_DESC1":@"Produto B – 220V",
                               @"L_PAYMENTREQUEST_0_AMT1":@"11.00",
                               @"L_PAYMENTREQUEST_0_QTY1":@"1"};
    //Set total
    self.totalValue = 23.00;
    
    //Add Product to PayPal
    PayPal *paypal = [PayPal sharedInstance];
    paypal.products = @[product1, product2];
    
    //Start the process
    if ([paypal isReferenceTransactionEnabled])
    {
        paypal.payment = [self paymentWithAmount:self.totalValue];
        [paypal requestReferenceTransaction];
    }
    else
    {
        paypal.returnURL = @"http://zona-azul.appspot.com/success";
        paypal.cancelURL = @"http://zona-azul.appspot.com/cancel";
        
        paypal.payment = [self paymentWithAmount:0.00];
        [paypal requestSetCheckoutExpress];
    }
}

#pragma mark - Helpers

-(void)showAlertText:(NSString *)text withTitle:(NSString *)title
{
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:title
                                                      message:text
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    
    [message show];
}
-(NSDictionary *)paymentWithAmount:(NSInteger)AMT
{
    NSDictionary *payment = @{@"AMT":[NSString stringWithFormat:@"%ld.00",(long)AMT],
                              @"CURRENCYCODE":@"BRL",
                              @"PAYMENTACTION":@"SALE"};
    return payment;
}

#pragma mark - PayPalDelegate

// Update UI

-(void)paypal:(PayPal *)paypal didStartRequest:(requestType)requestType
{
    [self.spinner startAnimating];
}
-(void)paypal:(PayPal *)paypal didFinishRequest:(requestType)requestType
{
    [self.spinner stopAnimating];
}

//SetCheckout

-(void)paypal:(PayPal *)paypal didReceiveRedirectURL:(NSString *)url_string
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    WebController *controller = [self.storyboard instantiateViewControllerWithIdentifier:@"Web"];
    controller.url_string = url_string;
    [self.navigationController pushViewController:controller animated:YES];
}
-(void)paypal:(PayPal *)paypal didFinishWebView:(BOOL)success
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    [self.navigationController popViewControllerAnimated:YES];
}
-(void)paypal:(PayPal *)paypal didReceiveExpressCheckoutToken:(NSString *)token
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    
    //Send token to server
    NSLog(@"TOKEN = %@",token);
}

// Billing Agreement

-(void)paypal:(PayPal *)paypal didReceiveBillingID:(NSString *)billingID
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    
    //Store in server
    NSLog(@"BILLING_ID = %@",billingID);
    
    //Do Payment
    paypal.payment = [self paymentWithAmount:self.totalValue];
    [paypal requestReferenceTransaction];
}

// Reference Transaction

-(void)paypal:(PayPal *)paypal didReceiveTransactionID:(NSString *)transactionID status:(NSString *)status
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    
    //Store in server
    NSLog(@"STATUS = %@",status);
    NSLog(@"TRANSACTION ID = %@",transactionID);
    
    //Just for test
    if ([status isEqualToString:@"Completed"])
    {
        [self showAlertText:@"Purchase completed with success" withTitle:@""];
    }
}

// Handle Error

-(void)paypal:(PayPal *)paypal didReceiveFail:(NSArray *)error_codes request:(requestType)requestType
{
    NSLog(@"%s",__PRETTY_FUNCTION__);
    
    for (NSString *error in error_codes)
    {
        
        NSLog(@"ERROR CODE = %@",error);
        NSString *title = [NSString stringWithFormat:@"Error %@", error];
        
        switch ([error integerValue])
        {
            // Client canceled the Billing Agreement
            // It's necessary create a new one
            case 10201:
                [paypal resetCredentials];
                [self buy:nil];
                return;
                
            //Fail to approve transaction
            //Usually it's a credt card problem, just change the card
            case 10417:
            case 10422:
            case 10486:
                [self showAlertText:@"Problems with your credit card. Go to paypal.com and add a new credit card."
                          withTitle:title];
                return;
                
            // Random problem with paypal account
            // Client should contact paypal team
            case 10204:
            case 10507:
                [self showAlertText:@"Problems with your Paypal Account. Contact them to solve the problem."
                          withTitle:title];
                return;
                
            default:
                [self showAlertText:@""
                          withTitle:title];
                break;
        }
    }
}


@end
