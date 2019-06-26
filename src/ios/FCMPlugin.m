#include <sys/types.h>
#include <sys/sysctl.h>

#import "AppDelegate+FCMPlugin.h"

#import <Cordova/CDV.h>
#import "FCMPlugin.h"
#import "Firebase.h"
#import "FIROptions.h"
#import "FIRApp.h"
#import "FirebaseInstanceID.h"

@interface FCMPlugin () {}

@end

@implementation FCMPlugin

static BOOL notificatorReceptorReady = NO;
static BOOL appInForeground = YES;

// @property (readwrite, copy, nonatomic, nullable) NSString *APIKey;
// @property (readwrite, copy, nonatomic) NSString *_Nonnull bundleID;
// @property (readwrite, copy, nonatomic, nullable) NSString *projectID;
// @property (readwrite, copy, nonatomic) NSString *_Nonnull googleAppID;
// @property (readwrite, copy, nonatomic) NSString *_Nonnull GCMSenderID;

static NSString *notificationCallback = @"FCMPlugin.onNotificationReceived";
static NSString *tokenRefreshCallback = @"FCMPlugin.onTokenRefreshReceived";
static FCMPlugin *fcmPluginInstance;

+ (FCMPlugin *) fcmPlugin {
    
    return fcmPluginInstance;
}

- (void) ready:(CDVInvokedUrlCommand *)command
{
    NSLog(@"Cordova view ready");
    fcmPluginInstance = self;
    [self.commandDelegate runInBackground:^{
        
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
    
}



// GET TOKEN //
- (void) getToken:(CDVInvokedUrlCommand *)command
{
    NSLog(@"get Token");
    NSString* iosProjectId = [command.arguments objectAtIndex:0];
    NSString* secondProjectId = [command.arguments objectAtIndex:1];
    
    NSString* secondAppId = "1"+secondProjectId+":ios:"+iosProjectId;
    NSLog(@"iosProjectId: %@ \n", iosProjectId);
    NSLog(@"secondProjectId: %@ \n", secondProjectId);
    NSLog(@"secondAppId: %@ \n", secondAppId);
    
    // FIROptions *options = [[FIROptions alloc] initWithGoogleAppID:secondAppId];
    //     if (options == nil) {
    //        return;
    //     }
    
    //    [[FIRInstanceID instanceID] instanceIDWithHandler:^(FIRInstanceIDResult * _Nullable result,
    //                                             NSError * _Nullable error) {
    //     if (error != nil) {
    //          NSLog(@"Error fetching remote instance ID: %@", error);
    //     } else {
    //          NSLog(@"Remote instance ID token: %@", result.token);
    //          self.token = result.token
    //     }
    //     }];
    
  NSLog(@"First App count: %d \n", [FIRApp allAps].count);
    
    //FIRApp configureWithName: "secoundApp" configureWithOptions:options];
    //FIRApp *app2 = [FIRApp appNamed:  "secoundApp"];
    
    
    // NSString* token = ""
    // NSString* tokenSecondApp = ""
    
    
    
    // [[FIRInstanceID instanceID] instanceIDWithHandler:^(FIRInstanceIDResult * _Nullable result,
    //                                             NSError * _Nullable error) {
    //     if (error != nil) {
    //          NSLog(@"Error fetching remote instance ID: %@", error);
    //     } else {
    //          NSLog(@"Remote instance ID token: %@", result.token);
    //          self.tokenSecondApp = result.token
    //     }
    //     }];
    
    
    [self.commandDelegate runInBackground:^{
        NSString* token = [[FIRInstanceID instanceID] token];
        NSLog(@"Token: " + token);
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:token];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

// UN/SUBSCRIBE TOPIC //
- (void) subscribeToTopic:(CDVInvokedUrlCommand *)command
{
    NSString* topic = [command.arguments objectAtIndex:0];
    NSLog(@"subscribe To Topic %@", topic);
    [self.commandDelegate runInBackground:^{
        if(topic != nil)[[FIRMessaging messaging] subscribeToTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:topic];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) unsubscribeFromTopic:(CDVInvokedUrlCommand *)command
{
    NSString* topic = [command.arguments objectAtIndex:0];
    NSLog(@"unsubscribe From Topic %@", topic);
    [self.commandDelegate runInBackground:^{
        if(topic != nil)[[FIRMessaging messaging] unsubscribeFromTopic:[NSString stringWithFormat:@"/topics/%@", topic]];
        CDVPluginResult* pluginResult = nil;
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:topic];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void) registerNotification:(CDVInvokedUrlCommand *)command
{
    NSLog(@"view registered for notifications");
    
    notificatorReceptorReady = YES;
    NSData* lastPush = [AppDelegate getLastPush];
    if (lastPush != nil) {
        [FCMPlugin.fcmPlugin notifyOfMessage:lastPush];
    }
    
    CDVPluginResult* pluginResult = nil;
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void) notifyOfMessage:(NSData *)payload
{
    NSString *JSONString = [[NSString alloc] initWithBytes:[payload bytes] length:[payload length] encoding:NSUTF8StringEncoding];
    NSString * notifyJS = [NSString stringWithFormat:@"%@(%@);", notificationCallback, JSONString];
    NSLog(@"stringByEvaluatingJavaScriptFromString %@", notifyJS);
    
    if ([self.webView respondsToSelector:@selector(stringByEvaluatingJavaScriptFromString:)]) {
        [(UIWebView *)self.webView stringByEvaluatingJavaScriptFromString:notifyJS];
    } else {
        [self.webViewEngine evaluateJavaScript:notifyJS completionHandler:nil];
    }
}

-(void) notifyOfTokenRefresh:(NSString *)token
{
    NSString * notifyJS = [NSString stringWithFormat:@"%@('%@');", tokenRefreshCallback, token];
    NSLog(@"stringByEvaluatingJavaScriptFromString %@", notifyJS);
    
    if ([self.webView respondsToSelector:@selector(stringByEvaluatingJavaScriptFromString:)]) {
        [(UIWebView *)self.webView stringByEvaluatingJavaScriptFromString:notifyJS];
    } else {
        [self.webViewEngine evaluateJavaScript:notifyJS completionHandler:nil];
    }
}

-(void) appEnterBackground
{
    NSLog(@"Set state background");
    appInForeground = NO;
}

-(void) appEnterForeground
{
    NSLog(@"Set state foreground");
    NSData* lastPush = [AppDelegate getLastPush];
    if (lastPush != nil) {
        [FCMPlugin.fcmPlugin notifyOfMessage:lastPush];
    }
    appInForeground = YES;
}

@end

