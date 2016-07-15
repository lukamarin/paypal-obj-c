# paypal-ios
Set Express Checkout and Reference Transaction for iOS

-------
PayPal Developers (https://developer.paypal.com) has an amazing Native SDK for mobile development. 
But you can only add and use it on your project, if users have already a PayPal account. It's ok
for most of countries in the world, but not in Brazil, because there are so many brazilians that don't 
have a PayPal account yet. So if you want to use PayPal in countries such as Brazil, you need to use 
SetExpressCheckout and ReferenceTransaction.

I create the this project to integrate PayPal in one of my App. So, I hope this work help other developers to easily
add PayPal to their iOS App.


1 - Copy PayPal.h and PayPal.m to your project and import PayPal Class to your UIViewController

    #import PayPal.h

2 - Set your PayPay USER, SIGNATURE and PASSWORD

    -(void)viewDidLoad
    {
        [super viewDidLoad];
    
        //Set Paypal Info
        PayPal *paypal = [PayPal sharedInstance];
        paypal.sandbox = YES;
        paypal.delegate = self;
    
        //Add your CUSTOM PayPal User, Signature and Password
        paypal.user = @"ADD_HERE_YOUR_PAYPAL_USER";
        paypal.signature = @"ADD_HERE_YOUR_PAYPAL_SIGNATURE";
        paypal.password = @"ADD_HERE_YOUR_PAYPAL_PASSWORD";
    }


3 - Set Product info, total price and start the proccess

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
            //Add URLs
            paypal.returnURL = @"ADD_HERE_SUCCESS_URL";
            paypal.cancelURL = @"ADD_HERE_CANCEL_URL";
            
            paypal.payment = [self paymentWithAmount:0.00];
            [paypal requestSetCheckoutExpress];
        }
    }
  
4 - Use Delegate Methods to get request status

There is a working example project, so you will be able to test it. It's super simple to use.
I hope you guys enjoy.

Best & Regards
