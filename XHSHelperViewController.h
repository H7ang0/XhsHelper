#import <UIKit/UIKit.h>

@interface XHSHelperViewController : UIViewController

// 单例方法
+ (instancetype)sharedInstance;

@end

// 声明全局变量
extern BOOL gWatermarkEnabled;
extern BOOL gSaveEnabled;

// TabBar控制变量
extern BOOL gHidePublishButton;
extern BOOL gHideMessageButton;
extern BOOL gHideHotButton;

// 自定义文字控制变量
extern BOOL gCustomTextEnabled;
extern NSMutableDictionary *gCustomTextRules;

// LivePhoto去水印控制变量
extern BOOL gLivePhotoWatermarkEnabled;

// 自动回复功能控制变量
extern BOOL gAutoReplyEnabled;
extern NSString *gAutoReplyText;
extern BOOL gCommentAutoReplyEnabled;
extern NSString *gCommentAutoReplyText;
