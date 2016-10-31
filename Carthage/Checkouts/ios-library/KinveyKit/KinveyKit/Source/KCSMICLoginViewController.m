//
//  KCSMICViewController.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#if TARGET_OS_IOS

#import "KCSMICLoginViewController.h"
@import WebKit;
#import "KinveyUser+Private.h"

@interface KCSMICLoginViewController () <UIWebViewDelegate, WKNavigationDelegate>

@property (nonatomic, copy) NSString* redirectURI;
@property (nonatomic, copy) KCSUserCompletionBlock completionBlock;
@property (nonatomic, assign) NSTimeInterval timeout;

@property (nonatomic, weak) UIView* webView;
@property (nonatomic, assign) BOOL forceUIWebView;
@property (nonatomic, weak) UIActivityIndicatorView* activityIndicatorView;

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation KCSMICLoginViewController

-(instancetype)initWithRedirectURI:(NSString *)redirectURI
               withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    self = [self initWithRedirectURI:redirectURI
                             timeout:-1
                 withCompletionBlock:completionBlock];
    return self;
}

-(instancetype)initWithRedirectURI:(NSString*)redirectURI
                           timeout:(NSTimeInterval)timeout
               withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    self = [super init];
    if (self) {
        _redirectURI = redirectURI;
        _timeout = timeout;
        _completionBlock = completionBlock;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Class clazz = NSClassFromString(@"WKWebView");
    if (clazz && !self.forceUIWebView) {
        WKWebView* webView = [[WKWebView alloc] init];
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        webView.navigationDelegate = self;
        [self.view addSubview:webView];
        self.webView = webView;
    } else {
        UIWebView* webView = [[UIWebView alloc] init];
        webView.translatesAutoresizingMaskIntoConstraints = NO;
        webView.delegate = self;
        [self.view addSubview:webView];
        self.webView = webView;
    }
    
    self.webView.accessibilityIdentifier = @"Web View";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" X "
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(closeViewControllerUserInteractionCancel:)];
    
    UIBarButtonItem* refreshPageBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                          target:self
                                                                                          action:@selector(refreshPage:)];
    
    self.navigationItem.rightBarButtonItem = refreshPageBarButtonItem;
    
    NSDictionary* views = NSDictionaryOfVariableBindings(_webView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    
    UIActivityIndicatorView* activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    activityIndicatorView.hidesWhenStopped = YES;
    activityIndicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    activityIndicatorView.layer.cornerRadius = 8;
    activityIndicatorView.layer.masksToBounds = YES;
    CGRect rect = CGRectInset(activityIndicatorView.bounds, -8, -8);
    activityIndicatorView.bounds = CGRectMake(0, 0, rect.size.width, rect.size.height);
    [self.view insertSubview:activityIndicatorView aboveSubview:self.webView];
    self.activityIndicatorView = activityIndicatorView;
    
    [activityIndicatorView addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.f
                                                                       constant:activityIndicatorView.bounds.size.width]];
    
    [activityIndicatorView addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeNotAnAttribute
                                                                     multiplier:1.f
                                                                       constant:activityIndicatorView.bounds.size.height]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.f
                                                           constant:0.f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:activityIndicatorView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.f
                                                           constant:0.f]];
}

-(void)closeViewControllerUserInteractionCancel:(id)sender
{
    [self closeViewController:sender
              userInteraction:KCSUserInteractionCancel];
}

-(void)closeViewControllerUserInteractionTimeout:(id)sender
{
    [self closeViewController:sender
              userInteraction:KCSUserInteractionTimeout];
}

-(void)closeViewController:(id)sender
           userInteraction:(KCSUserActionResult)userActionResult
{
    [self closeViewController:sender
                   completion:^
    {
        if (self.completionBlock) {
            self.completionBlock(nil, nil, userActionResult);
        }
    }];
}

-(void)closeViewController:(id)sender
                completion:(void(^)(void))completion
{
    if (self.timer && self.timer.isValid) {
        [self.timer invalidate];
    }
    [self dismissViewControllerAnimated:YES
                             completion:completion];
}

-(void)refreshPage:(id)sender
{
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [(UIWebView*)self.webView reload];
    } else {
        [(WKWebView*)self.webView reload];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSURL* url = [KCSUser URLforLoginWithMICRedirectURI:self.redirectURI client:self.client];
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    if ([self.webView isKindOfClass:[UIWebView class]]) {
        [(UIWebView*)self.webView loadRequest:request];
    } else {
        [(WKWebView*)self.webView loadRequest:request];
    }

    if (self.timeout > 0) {
        if (self.timer && self.timer.isValid) {
            [self.timer invalidate];
        }
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeout
                                                      target:self
                                                    selector:@selector(closeViewControllerUserInteractionTimeout:)
                                                    userInfo:nil
                                                     repeats:NO];
    }
}

-(void)parseMICURL:(NSURL*)url
{
    [self.activityIndicatorView startAnimating];
    
    [KCSUser setMICApiVersion:self.micApiVersion];
    [KCSUser parseMICRedirectURI:self.redirectURI
                          forURL:url
                          client:self.client
             withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result)
     {
         [self.activityIndicatorView stopAnimating];
         
         if (user) {
             [self closeViewController:nil completion:nil];
         }
         
         if (self.completionBlock) {
             self.completionBlock(user, errorOrNil, result);
         }
     }];
}

-(void)failWithError:(NSError*)error
{
    NSURL* url = error.userInfo[NSURLErrorFailingURLErrorKey];
    if (!url || ![KCSUser isValidMICRedirectURI:self.redirectURI
                                         forURL:url])
    {
        [self.activityIndicatorView stopAnimating];
        
        [self closeViewController:nil
                       completion:^
        {
            if (self.completionBlock) {
                self.completionBlock(nil, error, KCSUserNoInformation);
            }
        }];
    }
}

#pragma mark - UIWebViewDelegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* url = request.URL;
    
    if ([KCSUser isValidMICRedirectURI:self.redirectURI
                                forURL:url])
    {
        [self parseMICURL:url];
        
        return NO;
    }
    
    return YES;
}

-(void)webViewDidStartLoad:(UIWebView *)webView
{
    [self.activityIndicatorView startAnimating];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self failWithError:error];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString* body = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerText"];
    [self handleError:body];
    
    [self.activityIndicatorView stopAnimating];
}

#pragma mark - WKNavigationDelegate

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL* url = navigationAction.request.URL;
    
    if ([KCSUser isValidMICRedirectURI:self.redirectURI
                                forURL:url])
    {
        [self parseMICURL:url];
        
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    decisionHandler(WKNavigationActionPolicyAllow);
}

-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [self.activityIndicatorView startAnimating];
}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self failWithError:error];
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    [self failWithError:error];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [webView evaluateJavaScript:@"document.body.innerText" completionHandler:^(id _Nullable body, NSError * _Nullable error) {
        [self handleError:body];
    }];
    
    [self.activityIndicatorView stopAnimating];
}

-(void)handleError:(NSString*)body {
    if ([body isKindOfClass:[NSString class]]) {
        NSData* data = [(NSString*) body dataUsingEncoding:NSUTF8StringEncoding];
        if (data) {
            NSError* error = nil;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:0
                                                                   error:&error];
            if (!error && json && [json isKindOfClass:[NSDictionary class]] && [json[@"error"] isKindOfClass:[NSString class]]) {
                [self failWithError:[__KNVError buildUnknownJsonError:json]];
            }
        }
    }
}

@end

#endif
