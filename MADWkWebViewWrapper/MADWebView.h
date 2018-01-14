//
//  MADWebView.h
//  
//
//  Created by 梁宪松 on 2018/1/10.
//  Copyright © 2018年 madao. All rights reserved.
//

#import <WebKit/WebKit.h>

@class MADWebView;
@protocol MADWebViewDelegate <NSObject>

@optional
/**
 *  webview内容的标题
 */
- (void)MADWebView:(MADWebView *)webview title:(NSString *)title;
/**
 *  webview监听
 */
- (BOOL)MADWebView:(MADWebView *)webview shouldStartLoadWithURLRequest:(NSURLRequest *)request;
/**
 *  webview开始加载
 */
- (void)MADWebViewDidStartLoad:(MADWebView *)webview;
/**
 *  webview 是否需要hook请求
 */
- (BOOL)MADWebView:(MADWebView *)webview shouldMapURLRequest:(NSURLRequest *)request;
/**
 *  webview hook 请求
 */
- (NSURLRequest *)MADWebView:(MADWebView *)webview mapURLRequest:(NSURLRequest *)request;
/**
 *  webview加载完成
 */
- (void)MADWebView:(MADWebView *)webview didFinishLoadingURL:(NSURL *)URL;
/**
 *  webview加载失败
 */
- (void)MADWebView:(MADWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
@end

@interface MADWebView : WKWebView
<WKNavigationDelegate,
WKUIDelegate,
UIWebViewDelegate>


/**
 *  加载时导航栏底部的进度条
 */
@property (nonatomic, strong, readonly) UIProgressView *progressView;
@property (nonatomic, strong) UIColor *progressTintColor;
@property (nonatomic, strong) UIColor *progressTrackTintColor;


/**
 *  YQBIntegrationWebViewDelegate代理
 */
@property (nonatomic, weak) id <MADWebViewDelegate> delegate;

#pragma mark - Public
- (void)loadURL:(nullable NSURL *)url;

@end
