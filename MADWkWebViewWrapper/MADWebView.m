//
//  MADWebView.m
//  MADTeacher
//
//  Created by 梁宪松 on 2018/1/10.
//  Copyright © 2018年 madao. All rights reserved.
//

#import "MADWebView.h"

static void *kWkWebViewContext = &kWkWebViewContext;

static const NSString *kURLProtocolHandledKey = @"URLProtocolHandledKey";
static const NSString * kObserveTitleKey = @"title";


#define kDeepGreen [UIColor colorWithRed:77.0 / 255.0 green:176.0 / 255.0 blue:122.0 / 255.0 alpha:1.0f]

@interface MADWebView()
{
    NSString *_webTitle;

    struct {
        unsigned int didTitle                :1;
        unsigned int didshouldStartLoad      :1;
        unsigned int didStartLoad            :1;
        unsigned int didFinishLoad           :1;
        unsigned int didFailToLoad           :1;
        unsigned int mapURLRequest           :1;
        unsigned int shouldMapURLRequest     :1;
    } _delegateFlags; //将代理对象是否能响应相关协议方法缓存在结构体中
    
    NSURLRequest *_loadingRequest;
}

@property (nonatomic, strong, readwrite) UIProgressView *progressView;
@property (nonatomic, strong) NSURL *URLToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;

@end

@implementation MADWebView

- (instancetype)init
{
    NSAssert(1, @"use \"initWithFrame\" instead");
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    // 设置初始数据
    _progressTrackTintColor = [UIColor colorWithWhite:1.0f alpha:0.0f];
    _progressTintColor = kDeepGreen;
    
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self setNavigationDelegate:self];
    [self setUIDelegate:self];
    [self setMultipleTouchEnabled:YES];
    [self setAutoresizesSubviews:YES];
    [self.scrollView setAlwaysBounceVertical:YES];
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:kWkWebViewContext];
    [self addObserver:self forKeyPath:kObserveTitleKey options:NSKeyValueObservingOptionNew context:kWkWebViewContext];
    
    [self addSubview:self.progressView];
    self.progressView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
}

#pragma mark - Public
- (void)loadURL:(nullable NSString *)url
{
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }
    
    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }
    
    if (url) {
        [self loadRequest:[[NSURLRequest alloc] initWithURL:url]];
    }
}

#pragma mark - engine
- (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL {
    
    //若需要限制只允许某些前缀的scheme通过请求，则取消下述注释，并在数组内添加自己需要放行的前缀
    //    NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https",@"file"]];
    //    return ![validSchemes containsObject:URL.scheme];
    return !URL;
}

- (void)launchExternalAppWithURL:(NSURL *)URL {
    self.URLToLaunchWithPermission = URL;
    self.externalAppPermissionAlertView.title = @"跳转通知";
    self.externalAppPermissionAlertView.message = [NSString stringWithFormat:@"即将跳转链接:%@", URL.absoluteString];
    if (![self.externalAppPermissionAlertView isVisible]) {
        [self.externalAppPermissionAlertView show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == self.externalAppPermissionAlertView) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:self.URLToLaunchWithPermission];
        }
        self.URLToLaunchWithPermission = nil;
    }
}

#pragma mark - Estimated Progress KVO (WKWebView)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.estimatedProgress animated:animated];
        
        if(self.estimatedProgress >= 1.0f) {
            // 移除进度条
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }else if ([keyPath isEqualToString:kObserveTitleKey]){
        if (_delegateFlags.didTitle) {
            [self.delegate MADWebView:self title:self.title];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Layout
- (void)layoutSubviews
{
    [super layoutSubviews];
    self.progressView.frame = CGRectMake(0,
                                         0,
                                         CGRectGetWidth(self.frame),
                                         40);
}

#pragma mark - Setter
-(void)setProgressTintColor:(UIColor *)progressTintColor
{
    _progressTintColor = progressTintColor;
    [self.progressView setTintColor:_progressTintColor];
}

- (void)setProgressTrackTintColor:(UIColor *)progressTrackTintColor
{
    _progressTintColor = progressTrackTintColor;
    [self.progressView setTrackTintColor:_progressTrackTintColor];
}

- (void)setDelegate:(id<MADWebViewDelegate>)delegate
{
    _delegate = delegate;
    _delegateFlags.didTitle = [delegate respondsToSelector:@selector(MADWebView:title:)];
    _delegateFlags.didshouldStartLoad = [delegate respondsToSelector:@selector(MADWebView:shouldStartLoadWithURL:)];
    _delegateFlags.didStartLoad = [delegate respondsToSelector:@selector(MADWebViewDidStartLoad:)];
    _delegateFlags.didFinishLoad = [delegate respondsToSelector:@selector(MADWebView:didFinishLoadingURL:)];
    _delegateFlags.didFailToLoad = [delegate respondsToSelector:@selector(MADWebView:didFailToLoadURL:error:)];
    _delegateFlags.mapURLRequest = [delegate respondsToSelector:@selector(MADWebView:mapURLRequest:)];
    _delegateFlags.shouldMapURLRequest = [delegate respondsToSelector:@selector(MADWebView:shouldMapURLRequest:)];

}

#pragma mark - Getter
- (UIProgressView *)progressView
{
    if (!_progressView) {
        // 进度条
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [_progressView setTrackTintColor:_progressTrackTintColor];
        [_progressView setTintColor:_progressTintColor];
    }
    return _progressView;
}

- (UIAlertView *)externalAppPermissionAlertView
{
    if (!_externalAppPermissionAlertView) {
        _externalAppPermissionAlertView = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"前往", nil];
    }
    return _externalAppPermissionAlertView;
}

#pragma mark - Dealloc

- (void)dealloc {
    [self setDelegate:nil];
    [self setNavigationDelegate:nil];
    [self setUIDelegate:nil];
    [self removeObserver:self forKeyPath:kObserveTitleKey context:kWkWebViewContext];
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) context:kWkWebViewContext];
}


@end

#pragma mark - WKWebViewDelegate

@implementation MADWebView(WKUIDelegate)

// 创建webView
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

@end


@implementation MADWebView(WKNavigationDelegate)
// 页面开始加载
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (_delegateFlags.didStartLoad) {
        [self.delegate MADWebViewDidStartLoad:self];
    }
}

// 页面加载完毕
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (_delegateFlags.didFinishLoad) {
        [self.delegate MADWebView:self didFinishLoadingURL:self.URL];
    }
}

// 页面加载失败
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if (_delegateFlags.didFailToLoad) {
        [self.delegate MADWebView:self didFailToLoadURL:self.URL error:error];
    }
}

// 页面跳转失败
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if (_delegateFlags.didFailToLoad) {
        [self.delegate MADWebView:self didFailToLoadURL:self.URL error:error];
    }
}

// 接收到数据是否允许跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *URL = navigationAction.request.URL;
    if(![self externalAppRequiredToOpenURL:URL]) {
        if(!navigationAction.targetFrame) {
            [self loadRequest:[NSURLRequest requestWithURL:URL]];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        // 判断是否可以加载请求
        BOOL allow = [self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
        if (!allow) {
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        if ([NSURLProtocol propertyForKey:kURLProtocolHandledKey inRequest:navigationAction.request]) {
            // 防止无限循环，并且加载一次请求 (加载入口在此处)
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }
        // hook request
        if (_delegateFlags.shouldMapURLRequest && _delegateFlags.mapURLRequest) {
            // 判断是否需要hook请求
            BOOL shouldMap = [self.delegate MADWebView:self shouldMapURLRequest:navigationAction.request];
            if (shouldMap) {
                // 如果需要hook请求，那么加载map之后的请求
                NSURLRequest *request = [self.delegate MADWebView:self mapURLRequest:navigationAction.request];
                if (request) {
                    // 防止无限循环
                    [NSURLProtocol setProperty:@YES forKey:kURLProtocolHandledKey inRequest:request];
                    [self loadRequest:request];
                    decisionHandler(WKNavigationActionPolicyCancel);
                    return;
                }
                // 没有返回对应请求，加载原请求
            }
        }
    } else if ([[UIApplication sharedApplication] canOpenURL:URL]) {
        [self launchExternalAppWithURL:URL];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}



- (BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType {
    
    if (_delegateFlags.didshouldStartLoad) {
        return [self.delegate MADWebView:self shouldStartLoadWithURLRequest:request];
    }
    return YES;
}
@end
