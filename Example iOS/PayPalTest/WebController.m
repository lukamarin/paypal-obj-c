//
//  WebController.m
//  PayPalTest
//
//  Created by Rafael Castro on 10/30/14.
//  Copyright (c) 2014 HummingBird. All rights reserved.
//

#import "WebController.h"
#import "PayPal.h"

@interface WebController () <UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@end

@implementation WebController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.webView.delegate = self;
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //String -> URL
    NSURL *url = [NSURL URLWithString:self.url_string];
    
    //URL Request Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    //Load the request in the UIWebView.
    [self.webView loadRequest:requestObj];
    
    [self.spinner startAnimating];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.spinner startAnimating];
}
- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.spinner stopAnimating];
    [[PayPal sharedInstance] setCurrentURL:webView.request.URL.absoluteString];
}
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.spinner stopAnimating];
}



@end
