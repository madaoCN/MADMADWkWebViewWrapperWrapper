//
//  ViewController.m
//  MADWkWebViewWrapper
//
//  Created by 梁宪松 on 2018/1/14.
//  Copyright © 2018年 madao. All rights reserved.
//

#import "ViewController.h"
#import "MADWebView.h"

@interface ViewController ()<MADWebViewDelegate>

/**
 主tableView
 */
@property (nonatomic, strong) MADWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    CGRect frame = self.view.bounds;
    frame.origin.y += 64;
    self.webView.frame = frame;
    [self.webView loadURL:[NSURL URLWithString:@"https://www.jianshu.com/u/00be556128d1"]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Getter
- (MADWebView *)webView
{
    if (!_webView) {
        _webView = [[MADWebView alloc] initWithFrame:CGRectZero];
        _webView.delegate = self;
    }
    return _webView;
}
@end

#pragma mark - MADWebViewDelegate
@implementation ViewController(MADWebViewDelegate)
- (void)MADWebView:(MADWebView *)webview title:(NSString *)title
{
    self.title = title;
}

//- (BOOL)MADWebView:(MADWebView *)webview shouldMapURLRequest:(NSURLRequest *)request
//{
//    if (([request.HTTPMethod isEqualToString:@"GET"] ||
//         [request.HTTPMethod isEqualToString:@"get"])) {
//        return YES;
//    }
//    return NO;
//}
//
//- (NSURLRequest *)MADWebView:(MADWebView *)webview mapURLRequest:(NSURLRequest *)request
//{
//    NSMutableURLRequest *mRequest = [request mutableCopy];
//    // 对请求进行拦截自定义，注意：POST请求如果拦截将会丢失请求体
//    return mRequest;
//}
@end

