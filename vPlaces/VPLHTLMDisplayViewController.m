//
//  VPLHTLMDisplayViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 17.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLHTLMDisplayViewController.h"

@interface VPLHTLMDisplayViewController() <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;

@end

@implementation VPLHTLMDisplayViewController

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

-(BOOL)webView:(UIWebView *)webView
shouldStartLoadWithRequest:(NSURLRequest *)request
navigationType:(UIWebViewNavigationType)navigationType
{
    if (navigationType == UIWebViewNavigationTypeLinkClicked)
    {
        if ([[UIApplication sharedApplication] canOpenURL:request.URL])
        {
            [[UIApplication sharedApplication] openURL:request.URL];
        }
        return NO;
    }
    
    return YES;
}

@end
