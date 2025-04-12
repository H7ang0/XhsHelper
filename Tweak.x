#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XHSHelperViewController.h"

@interface XYVFVideoDownloaderManager : NSObject
- (void)setDisableWatermark:(BOOL)disable;
- (BOOL)disableWatermark;
- (void)download:(id)arg1 noteId:(id)arg2;
- (void)videoWithVideoPath:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo;
@end

@interface XYPHMediaSaveConfig : NSObject
- (void)setDisableSave:(BOOL)disable;
- (BOOL)disableSave;
- (void)setDisableWatermark:(BOOL)disable;
- (BOOL)disableWatermark;
- (void)setDisableWeiboCover:(BOOL)disable;
@end

@interface XYNoteEditModel : NSObject
- (void)setDisableWatermarkWhenSavingAlbum:(BOOL)disable;
- (BOOL)disableWatermarkWhenSavingAlbum;
@end

@interface XYPhotosUIKit_PhotosLivePhotoHandler : NSObject
- (void)composeLivePhotoWithImagePath:(NSString *)imagePath videoPath:(NSString *)videoPath completion:(id)completion;
- (void)requestLivePhotoWithAsset:(id)asset completion:(id)completion;
@end

@interface XYLivePhotoWatermarkManager : NSObject
- (NSURL *)livePhotoWatermarkURL:(id)arg1 livePhotoId:(id)arg2;
- (void)saveLivePhoto:(id)livePhoto livePhotoUrl:(NSURL *)url index:(NSInteger)index;
@end

@interface XYTabBar : UITabBar
- (void)layoutSubviews;
@end

@interface XYMHomeNaviBar : UIView
- (void)layoutSubviews;
- (void)setTitle:(NSString *)title;
@end

@interface UILabel (Text)
- (void)setText:(NSString *)text;
- (NSString *)text;
@end

@interface XYPHSettingViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
- (void)trackCellClick:(id)cell;
@end

// 声明外部变量
extern BOOL gWatermarkEnabled;
extern BOOL gSaveEnabled;
extern BOOL gHidePublishButton;
extern BOOL gHideMessageButton;
extern BOOL gHideHotButton;
extern BOOL gCustomTextEnabled;
extern BOOL gLivePhotoWatermarkEnabled;
extern NSMutableDictionary *gCustomTextRules;
// 自动回复变量
extern BOOL gAutoReplyEnabled;
extern NSString *gAutoReplyText;
extern BOOL gCommentAutoReplyEnabled;
extern NSString *gCommentAutoReplyText;

static NSArray<UIWindow *> *XHSHelperGetAllWindows(void) {
    NSArray<UIWindow *> *windows = nil;
    
    if (@available(iOS 15.0, *)) {
        NSMutableArray<UIWindow *> *allWindows = [NSMutableArray array];
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                [allWindows addObjectsFromArray:windowScene.windows];
            }
        }
        windows = [allWindows copy];
    } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
        windows = [UIApplication sharedApplication].windows;
        #pragma clang diagnostic pop
    }
    
    return windows;
}

%group VideoProcessing
%hook XYVFVideoDownloaderManager

- (void)setDisableWatermark:(BOOL)disable {
    if (gWatermarkEnabled) {
        %orig(YES);
    } else {
        %orig(disable);
    }
}

- (BOOL)disableWatermark {
    if (gWatermarkEnabled) {
        return YES;
    }
    return %orig;
}

- (void)download:(id)arg1 noteId:(id)arg2 {
    if (gWatermarkEnabled) {
        [self setDisableWatermark:YES];
    }
    %orig;
}

%end

%hook XYPHMediaSaveConfig

- (void)setDisableSave:(BOOL)disable {
    if (gSaveEnabled) {
        %orig(NO);
    } else {
        %orig(disable);
    }
}

- (BOOL)disableSave {
    if (gSaveEnabled) {
        return NO;
    }
    return %orig;
}

- (void)setDisableWatermark:(BOOL)disable {
    if (gWatermarkEnabled) {
        %orig(YES);
    } else {
        %orig(disable);
    }
}

- (BOOL)disableWatermark {
    if (gWatermarkEnabled) {
        return YES;
    }
    return %orig;
}

- (void)setDisableWeiboCover:(BOOL)disable {
    if (gWatermarkEnabled) {
        %orig(YES);
    } else {
        %orig(disable);
    }
}

%end

%hook XYNoteEditModel

- (void)setDisableWatermarkWhenSavingAlbum:(BOOL)disable {
    if (gWatermarkEnabled) {
        %orig(YES);
    } else {
        %orig(disable);
    }
}

- (BOOL)disableWatermarkWhenSavingAlbum {
    if (gWatermarkEnabled) {
        return YES;
    }
    return %orig;
}

%end

%hook XYPhotosUIKit_PhotosLivePhotoHandler

- (void)composeLivePhotoWithImagePath:(NSString *)imagePath videoPath:(NSString *)videoPath completion:(id)completion {
    NSLog(@"[XHSNOWatermark] LivePhoto合成: 图片=%@, 视频=%@", imagePath, videoPath);
    
  
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:videoPath]) {
        NSLog(@"[XHSNOWatermark] LivePhoto视频文件存在: %@", videoPath);
        
    
        objc_setAssociatedObject(self, "originalVideoPath", videoPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, "originalImagePath", imagePath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    %orig;
}


- (void)requestLivePhotoWithAsset:(id)asset completion:(id)completion {
    NSLog(@"[XHSNOWatermark] LivePhoto请求Asset: %@", asset);
    
    if (gLivePhotoWatermarkEnabled && completion) {
        // 创建自定义completion处理器
        id originalCompletion = completion;
        id customCompletion = ^(id livePhoto, NSDictionary *info) {
            NSLog(@"[XHSNOWatermark] LivePhoto请求完成: %@", livePhoto);
            // 调用原始completion
            ((void (^)(id, NSDictionary *))originalCompletion)(livePhoto, info);
        };
        
       
        %orig(asset, customCompletion);
        return;
    }
    
    %orig;
}

%end
%end

%group UICustomization
%hook XYTabBar

- (void)layoutSubviews {
    %orig;
    
    NSArray *subviews = self.subviews;
    
    for (UIView *view in subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
            UILabel *label = nil;
            
            for (UIView *subview in view.subviews) {
                if ([subview isKindOfClass:[UILabel class]]) {
                    label = (UILabel *)subview;
                }
            }
            
            NSString *buttonText = label.text;
            NSString *viewDescription = view.description;
            
            BOOL isPublishButton = NO;
            BOOL isMessageButton = NO;
            BOOL isHotButton = NO;
            
            if (buttonText) {
                if ([buttonText isEqualToString:@"发布"] || [buttonText containsString:@"发布"]) {
                    isPublishButton = YES;
                } else if ([buttonText isEqualToString:@"消息"] || [buttonText containsString:@"消息"]) {
                    isMessageButton = YES;
                } else if ([buttonText isEqualToString:@"热门"] || [buttonText containsString:@"热门"] || 
                           [buttonText isEqualToString:@"发现"] || [buttonText containsString:@"发现"]) {
                    isHotButton = YES;
                }
            }
            
            if (viewDescription) {
                if ([viewDescription containsString:@"发布"] || [viewDescription containsString:@"publish"]) {
                    isPublishButton = YES;
                } else if ([viewDescription containsString:@"消息"] || [viewDescription containsString:@"message"]) {
                    isMessageButton = YES;
                } else if ([viewDescription containsString:@"热门"] || [viewDescription containsString:@"hot"] || 
                           [viewDescription containsString:@"发现"] || [viewDescription containsString:@"discover"]) {
                    isHotButton = YES;
                }
            }
            
            if (isPublishButton) {
                view.hidden = gHidePublishButton;
                view.userInteractionEnabled = !gHidePublishButton;
                view.alpha = gHidePublishButton ? 0.0 : 1.0;
            } else if (isMessageButton) {
                view.hidden = gHideMessageButton;
                view.userInteractionEnabled = !gHideMessageButton;
                view.alpha = gHideMessageButton ? 0.0 : 1.0;
            } else if (isHotButton) {
                view.hidden = gHideHotButton;
                view.userInteractionEnabled = !gHideHotButton;
                view.alpha = gHideHotButton ? 0.0 : 1.0;
            }
        }
    }
}

%end
%end

%group SettingsMenu
%hook XYPHSettingViewController

- (void)viewDidLoad {
    %orig;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.tableView) {
            [self.tableView reloadData];
        }
    });
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger originalRows = %orig;
    if (section == 0) {
        return originalRows + 1;
    }
    return originalRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        static NSString *cellID = @"XHSHelperCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
        
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.backgroundColor = [UIColor clearColor];
            
            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            }
        }
        
        cell.textLabel.text = @"小红书助手";
        
        UIImage *starImage = [UIImage imageNamed:@"star_icon"];
        
        if (!starImage) {
            if (@available(iOS 13.0, *)) {
                UIImage *systemImage = [UIImage systemImageNamed:@"star.fill"];
                if (systemImage) {
                    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:25 weight:UIImageSymbolWeightRegular];
                    starImage = [systemImage imageByApplyingSymbolConfiguration:config];
                }
            }
        }
        
        if (starImage) {
            if (@available(iOS 13.0, *)) {
                cell.imageView.tintColor = [UIColor systemPinkColor];
            } else {
                cell.imageView.tintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.5 alpha:1.0];
            }
            
            cell.imageView.image = starImage;
            cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
        
        return cell;
    }
    
    return %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0 && indexPath.row == 0) {
        XHSHelperViewController *helperVC = [objc_getClass("XHSHelperViewController") sharedInstance];
        [self presentViewController:helperVC animated:YES completion:nil];
        return;
    }
    
    %orig;
}

%end
%end

%group LivePhotoProcessing
%hook XYLivePhotoCache

// 存储LivePhoto到缓存时移除水印
- (void)storeLivePhoto:(id)livePhoto forKey:(NSString *)key toDisk:(BOOL)toDisk completion:(id)completion {
    if (gLivePhotoWatermarkEnabled) {
        NSLog(@"[XHSNOWatermark] 拦截LivePhoto存储: key: %@", key);
        
        // 检查livePhoto对象类型
        NSString *className = NSStringFromClass([livePhoto class]);
        NSLog(@"[XHSNOWatermark] LivePhoto对象类型: %@", className);
        
        // 尝试获取LivePhoto的资源URL
        if ([livePhoto respondsToSelector:@selector(imageURL)]) {
            NSURL *imageURL = [livePhoto performSelector:@selector(imageURL)];
            NSLog(@"[XHSNOWatermark] LivePhoto图片URL: %@", imageURL);
        }
        
        if ([livePhoto respondsToSelector:@selector(videoURL)]) {
            NSURL *videoURL = [livePhoto performSelector:@selector(videoURL)];
            NSLog(@"[XHSNOWatermark] LivePhoto视频URL: %@", videoURL);
            
            // 如果视频URL包含水印参数，尝试移除
            if (videoURL && [videoURL.absoluteString containsString:@"watermark"]) {
                NSString *cleanURLString = [videoURL.absoluteString stringByReplacingOccurrencesOfString:@"watermark=1" withString:@"watermark=0"];
                cleanURLString = [cleanURLString stringByReplacingOccurrencesOfString:@"&logo=1" withString:@"&logo=0"];
                NSURL *cleanURL = [NSURL URLWithString:cleanURLString];
                
                // 使用KVC设置无水印URL
                @try {
                    [livePhoto setValue:cleanURL forKey:@"videoURL"];
                    NSLog(@"[XHSNOWatermark] 成功移除LivePhoto视频水印URL");
                } @catch (NSException *e) {
                    NSLog(@"[XHSNOWatermark] 移除LivePhoto视频水印URL失败: %@", e);
                }
            }
        }
        
        // 处理本地文件移除水印
        if ([livePhoto respondsToSelector:@selector(resourceFileURLs)]) {
            NSArray *resourceURLs = [livePhoto performSelector:@selector(resourceFileURLs)];
            NSLog(@"[XHSNOWatermark] LivePhoto资源文件URLs: %@", resourceURLs);
            
            // 处理每个资源文件
            for (NSURL *url in resourceURLs) {
                if ([url.pathExtension.lowercaseString isEqualToString:@"mov"] ||
                    [url.pathExtension.lowercaseString isEqualToString:@"mp4"]) {
                    NSLog(@"[XHSNOWatermark] 处理LivePhoto视频文件: %@", url);
                    // 这里可以添加视频处理代码移除水印
                }
            }
        }
    }
    
    %orig;
}

// 从缓存读取LivePhoto时确保无水印
- (void)livePhotoFromDiskCacheForKey:(NSString *)key completion:(id)completion {
    if (gLivePhotoWatermarkEnabled && completion) {
        NSLog(@"[XHSNOWatermark] 读取LivePhoto: key: %@", key);
        
        // 创建自定义completion处理器
        id originalCompletion = completion;
        id customCompletion = ^(id livePhoto, NSDictionary *info) {
            if (livePhoto) {
                NSLog(@"[XHSNOWatermark] 处理缓存中的LivePhoto对象");
                
                // 检测水印并尝试移除
                if ([livePhoto respondsToSelector:@selector(videoURL)]) {
                    NSURL *videoURL = [livePhoto performSelector:@selector(videoURL)];
                    if (videoURL && [videoURL.absoluteString containsString:@"watermark"]) {
                        NSString *cleanURLString = [videoURL.absoluteString stringByReplacingOccurrencesOfString:@"watermark=1" withString:@"watermark=0"];
                        @try {
                            [livePhoto setValue:[NSURL URLWithString:cleanURLString] forKey:@"videoURL"];
                            NSLog(@"[XHSNOWatermark] 成功移除缓存LivePhoto水印");
                        } @catch (NSException *e) {
                            NSLog(@"[XHSNOWatermark] 移除缓存LivePhoto水印失败: %@", e);
                        }
                    }
                }
            }
            
            // 调用原始completion
            ((void (^)(id, NSDictionary *))originalCompletion)(livePhoto, info);
        };
        
        // 使用自定义completion调用原始方法
        %orig(key, customCompletion);
        return;
    }
    
    %orig;
}

// 获取缓存路径并记录信息
- (NSString *)cachePathForKey:(NSString *)key {
    NSString *path = %orig;
    
    if (gLivePhotoWatermarkEnabled) {
        // 仅记录实况照片相关的缓存路径
        if ([path containsString:@"livephoto"] || 
            [key containsString:@"livephoto"] || 
            [key containsString:@"live"]) {
            NSLog(@"[XHSNOWatermark] LivePhoto缓存路径: %@ 对应key: %@", path, key);
            
            // 检查文件是否存在
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:path]) {
                NSDictionary *attrs = [fileManager attributesOfItemAtPath:path error:nil];
                NSLog(@"[XHSNOWatermark] LivePhoto文件大小: %@ bytes", attrs[NSFileSize]);
            }
        }
    }
    
    return path;
}

// 处理LivePhoto合成操作
- (void)storeLivePhotoToMemory:(id)livePhoto forKey:(NSString *)key {
    if (gLivePhotoWatermarkEnabled) {
        NSLog(@"[XHSNOWatermark] 存储LivePhoto到内存: key: %@", key);
        // 与storeLivePhoto:forKey:toDisk:completion:类似的水印处理
    }
    
    %orig;
}

// 检查LivePhoto是否存在
- (BOOL)diskLivePhotoExistsWithKey:(NSString *)key {
    BOOL exists = %orig;
    
    if (gLivePhotoWatermarkEnabled) {
        NSLog(@"[XHSNOWatermark] 检查LivePhoto是否存在: key: %@ 结果: %@", key, exists ? @"是" : @"否");
    }
    
    return exists;
}

%end

%hook PHLivePhoto
+ (void)requestLivePhotoWithResourceFileURLs:(NSArray<NSURL *> *)fileURLs placeholderImage:(UIImage *)image targetSize:(CGSize)targetSize contentMode:(int)contentMode resultHandler:(id)resultHandler {
    NSLog(@"[XHSNOWatermark] 系统LivePhoto创建请求: %@", fileURLs);
    
    if (fileURLs.count >= 2) {
        NSLog(@"[XHSNOWatermark] 图片URL: %@", fileURLs[0]);
        NSLog(@"[XHSNOWatermark] 视频URL: %@", fileURLs[1]);
    }
    
    %orig;
}
%end

%end

%group AutoReply

// Hook私信发送类
%hook XYMessageUIKit.XYChatTableBaseViewModel

// 监听新消息添加
- (void)appendMessageAndCellViewModelWith:(id)message {
    %orig;
    
    if (gAutoReplyEnabled) {
        // 判断是否是对方发送的消息，如果是则自动回复
        BOOL isIncomingMessage = NO;
        
        if ([message respondsToSelector:@selector(isIncomingMessage)]) {
            isIncomingMessage = [(NSObject *)message performSelector:@selector(isIncomingMessage)];
        } else if ([message respondsToSelector:@selector(direction)] && 
                  [[(NSObject *)message performSelector:@selector(direction)] intValue] == 2) {
            // 根据direction判断是否是接收的消息
            isIncomingMessage = YES;
        }
        
        if (isIncomingMessage) {
            // 延迟2秒发送自动回复
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"[XHSHelper] 准备发送私信自动回复: %@", gAutoReplyText);
                
                // 构造回复消息并发送
                if ([self respondsToSelector:@selector(sendTextMessage:)]) {
                    [self performSelector:@selector(sendTextMessage:) withObject:gAutoReplyText];
                } else if ([self respondsToSelector:@selector(sendText:)]) {
                    [self performSelector:@selector(sendText:) withObject:gAutoReplyText];
                }
            });
        }
    }
}

%end

// Hook评论回复类
%hook XYNoteBasic.CommentService

// 监听评论发布
- (void)publishComment:(id)comment completion:(id)completion {
    %orig;
    
    if (gCommentAutoReplyEnabled) {
        // 判断是否是对方的评论
        BOOL isOtherComment = NO;
        
        if ([comment respondsToSelector:@selector(isUserComment)] &&
            ![(NSObject *)comment performSelector:@selector(isUserComment)]) {
            isOtherComment = YES;
        } else if ([comment respondsToSelector:@selector(userId)] && 
                  [comment performSelector:@selector(userId)] != nil) {
            // 检查评论用户ID是否不是当前用户
            id currentUserId = nil;
            if ([NSClassFromString(@"XYUserModel") respondsToSelector:@selector(currentUserId)]) {
                currentUserId = [NSClassFromString(@"XYUserModel") performSelector:@selector(currentUserId)];
            }
            
            if (currentUserId && ![[comment performSelector:@selector(userId)] isEqual:currentUserId]) {
                isOtherComment = YES;
            }
        }
        
        if (isOtherComment) {
            // 延迟3秒回复评论
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"[XHSHelper] 准备发送评论自动回复: %@", gCommentAutoReplyText);
                
                if ([self respondsToSelector:@selector(replyComment:withContent:completion:)]) {
                    [self performSelector:@selector(replyComment:withContent:completion:) 
                              withObject:comment 
                              withObject:gCommentAutoReplyText 
                              withObject:nil];
                }
            });
        }
    }
}

%end

%end

%ctor {
    @autoreleasepool {
        NSLog(@"[XHSNOWatermark] 小红书助手插件已加载，版本1.0");
        
        gWatermarkEnabled = YES;
        gSaveEnabled = YES;
        gLivePhotoWatermarkEnabled = YES;
        
        if (!gCustomTextRules) {
            gCustomTextRules = [NSMutableDictionary dictionary];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults objectForKey:@"XHSHelperWatermarkEnabled"] != nil) {
            gWatermarkEnabled = [defaults boolForKey:@"XHSHelperWatermarkEnabled"];
        }
        
        if ([defaults objectForKey:@"XHSHelperSaveEnabled"] != nil) {
            gSaveEnabled = [defaults boolForKey:@"XHSHelperSaveEnabled"];
        }
        
        if ([defaults objectForKey:@"XHSHelperLivePhotoWatermarkEnabled"] != nil) {
            gLivePhotoWatermarkEnabled = [defaults boolForKey:@"XHSHelperLivePhotoWatermarkEnabled"];
        }
        
        if ([defaults objectForKey:@"XHSHelperCustomTextEnabled"] != nil) {
            gCustomTextEnabled = [defaults boolForKey:@"XHSHelperCustomTextEnabled"];
        }
        
        NSDictionary *savedRules = [defaults objectForKey:@"XHSHelperCustomTextRules"];
        if (savedRules) {
            gCustomTextRules = [savedRules mutableCopy];
        }
        
        [[NSNotificationCenter defaultCenter] addObserverForName:@"XHSHelperTabBarSettingsChanged" 
                                                        object:nil 
                                                         queue:[NSOperationQueue mainQueue] 
                                                    usingBlock:^(NSNotification *note) {
            NSArray<UIWindow *> *windows = XHSHelperGetAllWindows();
            for (UIWindow *window in windows) {
                for (UIView *view in window.subviews) {
                    if ([view isKindOfClass:NSClassFromString(@"XYTabBar")]) {
                        [view setNeedsLayout];
                        [view layoutIfNeeded];
                    }
                }
            }
        }];
        
        %init(VideoProcessing);
        %init(UICustomization);
        %init(SettingsMenu);
        %init(LivePhotoProcessing);
        %init(AutoReply);
    }
}
