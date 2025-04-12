#import "XHSHelperViewController.h"


BOOL gWatermarkEnabled = YES;
BOOL gSaveEnabled = YES;
BOOL gHidePublishButton = NO;
BOOL gHideMessageButton = NO;
BOOL gHideHotButton = NO;
BOOL gCustomTextEnabled = NO;
BOOL gLivePhotoWatermarkEnabled = YES;
BOOL gAutoReplyEnabled = NO;
NSString *gAutoReplyText = @"感谢私信，我稍后会回复你。"; //错误的后面会修
BOOL gCommentAutoReplyEnabled = NO;
NSString *gCommentAutoReplyText = @"感谢评论，已看到。";
NSMutableDictionary *gCustomTextRules;
static XHSHelperViewController *sharedInstance = nil;

@interface XHSHelperViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIVisualEffectView *containerView;
@property (nonatomic, strong) UISwitch *watermarkSwitch;
@property (nonatomic, strong) UISwitch *saveSwitch;
@property (nonatomic, strong) UISwitch *livePhotoWatermarkSwitch;
@property (nonatomic, strong) UISwitch *autoReplySwitch;
@property (nonatomic, strong) UISwitch *commentAutoReplySwitch;
@property (nonatomic, strong) NSMutableArray *sectionExpanded;
@end

@implementation XHSHelperViewController

#pragma mark - 单例方法
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - 初始化
- (instancetype)init {
    self = [super init];
    if (self) {
        self.title = @"小红书助手";
        
        // 设置模态样式
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        if (@available(iOS 13.0, *)) {
            self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        }
        
        // 初始化分组展开状态 - 只有2个分组，默认都展开
        self.sectionExpanded = [NSMutableArray arrayWithObjects:@YES, @YES, nil];
        
        [self loadUserDefaults];
    }
    return self;
}


- (void)loadUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // 加载设置状态
    if ([defaults objectForKey:@"XHSHelperWatermarkEnabled"] != nil) {
        gWatermarkEnabled = [defaults boolForKey:@"XHSHelperWatermarkEnabled"];
    }
    
    if ([defaults objectForKey:@"XHSHelperSaveEnabled"] != nil) {
        gSaveEnabled = [defaults boolForKey:@"XHSHelperSaveEnabled"];
    }
    
    if ([defaults objectForKey:@"XHSHelperLivePhotoWatermarkEnabled"] != nil) {
        gLivePhotoWatermarkEnabled = [defaults boolForKey:@"XHSHelperLivePhotoWatermarkEnabled"];
    }
    
    // 加载自动回复设置
    if ([defaults objectForKey:@"XHSHelperAutoReplyEnabled"] != nil) {
        gAutoReplyEnabled = [defaults boolForKey:@"XHSHelperAutoReplyEnabled"];
    }
    
    if ([defaults objectForKey:@"XHSHelperAutoReplyText"] != nil) {
        gAutoReplyText = [defaults stringForKey:@"XHSHelperAutoReplyText"];
    }
    
    if ([defaults objectForKey:@"XHSHelperCommentAutoReplyEnabled"] != nil) {
        gCommentAutoReplyEnabled = [defaults boolForKey:@"XHSHelperCommentAutoReplyEnabled"];
    }
    
    if ([defaults objectForKey:@"XHSHelperCommentAutoReplyText"] != nil) {
        gCommentAutoReplyText = [defaults stringForKey:@"XHSHelperCommentAutoReplyText"];
    }
}


- (void)saveUserDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:gWatermarkEnabled forKey:@"XHSHelperWatermarkEnabled"];
    [defaults setBool:gSaveEnabled forKey:@"XHSHelperSaveEnabled"];
    [defaults setBool:gLivePhotoWatermarkEnabled forKey:@"XHSHelperLivePhotoWatermarkEnabled"];
    
    // 自动回复有问题后面修
    [defaults setBool:gAutoReplyEnabled forKey:@"XHSHelperAutoReplyEnabled"];
    [defaults setObject:gAutoReplyText forKey:@"XHSHelperAutoReplyText"];
    [defaults setBool:gCommentAutoReplyEnabled forKey:@"XHSHelperCommentAutoReplyEnabled"];
    [defaults setObject:gCommentAutoReplyText forKey:@"XHSHelperCommentAutoReplyText"];
    
    [defaults synchronize];
}

#pragma mark - 视图生命周期
- (void)viewDidLoad {
    [super viewDidLoad];
    

    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    
    [self setupVisionProContainer];
    
    [self setupTableView];

    [self setupNavigationBar];

    [self addVersionInfo];
}

#pragma mark - UI 设置
- (void)setupVisionProContainer {
 
    UIBlurEffect *blurEffect;
    if (@available(iOS 13.0, *)) {
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    } else {
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    }

    self.containerView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    CGFloat containerWidth = screenWidth * 0.85; 
    CGFloat containerHeight = screenHeight * 0.7; 

    self.containerView.frame = CGRectMake((screenWidth - containerWidth) / 2, 
                                        (screenHeight - containerHeight) / 2, 
                                        containerWidth, containerHeight);
    
    self.containerView.layer.cornerRadius = 20;
    self.containerView.layer.masksToBounds = YES;
    self.containerView.layer.borderWidth = 0.5;
    self.containerView.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
    
    // 添加到视图
    [self.view addSubview:self.containerView];
    
    // 添加标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, containerWidth, 40)];
    titleLabel.text = @"小红书助手";
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [self.containerView.contentView addSubview:titleLabel];
    
    // 添加副标题
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 60, containerWidth, 20)];
    subtitleLabel.text = @"自定义小红书功能";
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    subtitleLabel.font = [UIFont systemFontOfSize:16];
    subtitleLabel.textColor = [UIColor grayColor];
    [self.containerView.contentView addSubview:subtitleLabel];
    
    // 添加分割线
    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(containerWidth * 0.1, 90, containerWidth * 0.8, 1)];
    divider.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    [self.containerView.contentView addSubview:divider];
    
    // 添加关闭按钮 - 移到右上角
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(containerWidth - 50, 15, 30, 30);
    closeButton.layer.cornerRadius = 15;
    
    if (@available(iOS 13.0, *)) {
        [closeButton setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
        closeButton.tintColor = [UIColor systemGrayColor];
    } else {
        [closeButton setTitle:@"×" forState:UIControlStateNormal];
        closeButton.titleLabel.font = [UIFont systemFontOfSize:20];
    }
    
    [closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView.contentView addSubview:closeButton];
}

- (void)setupNavigationBar {
    // 隐藏导航栏，因为我们使用自定义UI
    self.navigationController.navigationBarHidden = YES;
}

- (void)setupTableView {
    // 获取容器大小
    CGFloat containerWidth = self.containerView.frame.size.width;
    CGFloat containerHeight = self.containerView.frame.size.height;
    
    // 创建表格视图，适应容器大小
    CGRect tableFrame = CGRectMake(10, 100, containerWidth - 20, containerHeight - 170);
    self.tableView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStyleInsetGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, 0);
    
    // 设置适应性
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    // iOS 15+ 移除额外的单元格分隔符
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0.0f;
    }
    
    // 设置表格视图背景透明
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    // 添加到容器视图
    [self.containerView.contentView addSubview:self.tableView];
    
    // 注册单元格
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SwitchCell"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"AboutCell"];
}

- (void)addVersionInfo {
    CGFloat containerWidth = self.containerView.frame.size.width;
    CGFloat containerHeight = self.containerView.frame.size.height;
    
    // 添加版本信息
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, containerHeight - 30, containerWidth, 20)];
    versionLabel.text = @"v1.0.0 © 2025 H7ang0";
    versionLabel.textAlignment = NSTextAlignmentCenter;
    versionLabel.textColor = [UIColor grayColor];
    versionLabel.font = [UIFont systemFontOfSize:12];
    [self.containerView.contentView addSubview:versionLabel];
}

#pragma mark - 表格视图数据源和代理
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;  // 1.媒体增强功能 2.自动回复功能 3.关于
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // 如果分组未展开，则不显示行
    if (![self.sectionExpanded[section] boolValue]) {
        return 0;
    }
    
    if (section == 0) {
        return 3;  // 视频无水印+LivePhoto无水印+强制保存
    } else if (section == 1) {
        return 2;  // 私信自动回复+评论自动回复
    } else {
        return 1;  // 关于
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        // 设置单元格内容
        if (indexPath.row == 0) {
            [self configWatermarkCell:cell];
        } else if (indexPath.row == 1) {
            [self configLivePhotoWatermarkCell:cell];
        } else {
            [self configSaveCell:cell];
        }
        
        return cell;
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        if (indexPath.row == 0) {
            [self configAutoReplyCell:cell];
        } else {
            [self configCommentAutoReplyCell:cell];
        }
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AboutCell" forIndexPath:indexPath];
        cell.textLabel.text = @"关于小红书助手";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.backgroundColor = [UIColor clearColor];
        
        // 设置图标
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"info.circle"];
            cell.imageView.tintColor = [UIColor systemBlueColor];
        }
        
        return cell;
    }
}

// 自定义分组标题视图
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // 创建分组标题容器视图
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 50)];
    headerView.backgroundColor = [UIColor clearColor];
    
    // 添加标题标签
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, tableView.frame.size.width - 60, 30)];
    titleLabel.font = [UIFont boldSystemFontOfSize:16];
    
    // 设置标题文本
    if (section == 0) {
        titleLabel.text = @"媒体增强功能";
    } else if (section == 1) {
        titleLabel.text = @"自动回复功能";
    } else {
        titleLabel.text = @"关于与支持";
    }
    
    [headerView addSubview:titleLabel];
    
    // 添加展开/折叠指示器
    UIImageView *indicatorView = [[UIImageView alloc] initWithFrame:CGRectMake(tableView.frame.size.width - 35, 17, 15, 15)];
    if (@available(iOS 13.0, *)) {
        NSString *imageName = [self.sectionExpanded[section] boolValue] ? @"chevron.down" : @"chevron.right";
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:13 weight:UIImageSymbolWeightRegular];
        indicatorView.image = [[UIImage systemImageNamed:imageName] imageWithConfiguration:config];
        indicatorView.tintColor = [UIColor systemGrayColor];
        indicatorView.contentMode = UIViewContentModeScaleAspectFit;
    } else {
        // iOS 13以下可以使用自定义图片或文本
        indicatorView.backgroundColor = [UIColor clearColor];
    }
    [headerView addSubview:indicatorView];
    
    // 添加点击手势
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerTapped:)];
    [headerView addGestureRecognizer:tapGesture];
    headerView.tag = section; // 用于在点击时识别是哪个分组
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // 如果分组已展开，则显示底部说明
    if ([self.sectionExpanded[section] boolValue]) {
        return 40;
    }
    return 1; // 最小高度
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    // 如果分组未展开，返回空视图
    if (![self.sectionExpanded[section] boolValue]) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
    footerView.backgroundColor = [UIColor clearColor];
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, tableView.frame.size.width - 30, 30)];
    footerLabel.font = [UIFont systemFontOfSize:12];
    footerLabel.textColor = [UIColor grayColor];
    footerLabel.numberOfLines = 0;
    
    if (section == 0) {
        footerLabel.text = @"移除视频和实况图片水印，允许保存受限制内容";
    } else if (section == 1) {
        footerLabel.text = @"自动回复私信和评论，节省时间";
    } else {
        footerLabel.text = @"© 2023-2024 H7ang0";
    }
    
    [footerView addSubview:footerLabel];
    return footerView;
}

// 处理分组点击事件
- (void)headerTapped:(UITapGestureRecognizer *)gesture {
    NSInteger section = gesture.view.tag;
    
    // 切换展开状态
    self.sectionExpanded[section] = @(![self.sectionExpanded[section] boolValue]);
    
    // 刷新表格视图
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)configWatermarkCell:(UITableViewCell *)cell {
    // 设置标题和样式
    cell.textLabel.text = @"视频无水印";
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 设置详细描述
    cell.detailTextLabel.text = @"从小红书下载视频时移除水印";
    
    // 设置图标
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:@"video"];
        cell.imageView.tintColor = [UIColor systemBlueColor];
    }
    
    // 添加开关
    UISwitch *watermarkSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    watermarkSwitch.on = gWatermarkEnabled;
    [watermarkSwitch addTarget:self action:@selector(watermarkSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = watermarkSwitch;
    self.watermarkSwitch = watermarkSwitch;
}

- (void)configLivePhotoWatermarkCell:(UITableViewCell *)cell {
    // 设置标题和样式
    cell.textLabel.text = @"LivePhoto无水印";
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 设置图标 (优化LivePhoto图标)
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:@"livephoto"];
        cell.imageView.tintColor = [UIColor systemPinkColor];
    }
    
    // 添加开关
    UISwitch *livePhotoWatermarkSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    livePhotoWatermarkSwitch.on = gLivePhotoWatermarkEnabled;
    [livePhotoWatermarkSwitch addTarget:self action:@selector(livePhotoWatermarkSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = livePhotoWatermarkSwitch;
    self.livePhotoWatermarkSwitch = livePhotoWatermarkSwitch;
}

- (void)configSaveCell:(UITableViewCell *)cell {
    // 设置标题和样式
    cell.textLabel.text = @"强制保存视频";
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 设置详细描述
    cell.detailTextLabel.text = @"允许保存所有视频到相册";
    
    // 设置图标
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:@"square.and.arrow.down"];
        cell.imageView.tintColor = [UIColor systemBlueColor];
    }
    
    // 添加开关
    UISwitch *saveSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    saveSwitch.on = gSaveEnabled;
    [saveSwitch addTarget:self action:@selector(saveSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = saveSwitch;
    self.saveSwitch = saveSwitch;
}

- (void)configAutoReplyCell:(UITableViewCell *)cell {
    // 设置标题和样式
    cell.textLabel.text = @"私信自动回复";
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 设置详细描述
    cell.detailTextLabel.text = @"点击设置自动回复内容";
    
    // 设置图标
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:@"message"];
        cell.imageView.tintColor = [UIColor systemBlueColor];
    }
    
    // 添加开关
    UISwitch *autoReplySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    autoReplySwitch.on = gAutoReplyEnabled;
    [autoReplySwitch addTarget:self action:@selector(autoReplySwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = autoReplySwitch;
    self.autoReplySwitch = autoReplySwitch;
}

- (void)configCommentAutoReplyCell:(UITableViewCell *)cell {
    // 设置标题和样式
    cell.textLabel.text = @"评论自动回复";
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    
    // 设置详细描述
    cell.detailTextLabel.text = @"点击设置自动回复内容";
    
    // 设置图标
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:@"text.bubble"];
        cell.imageView.tintColor = [UIColor systemPinkColor];
    }
    
    // 添加开关
    UISwitch *commentAutoReplySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    commentAutoReplySwitch.on = gCommentAutoReplyEnabled;
    [commentAutoReplySwitch addTarget:self action:@selector(commentAutoReplySwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = commentAutoReplySwitch;
    self.commentAutoReplySwitch = commentAutoReplySwitch;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"媒体增强功能";
    } else if (section == 1) {
        return @"自动回复功能";
    } else {
        return @"关于与支持";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"移除视频和实况图片水印，允许保存受限制内容";
    } else if (section == 1) {
        return @"自动回复私信和评论，节省时间";
    } else {
        return @"© 2023-2024 H7ang0 保留所有权利";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // 点击私信自动回复
    if (indexPath.section == 1 && indexPath.row == 0) {
        [self showAutoReplySettingAlert];
    }
    // 点击评论自动回复
    else if (indexPath.section == 1 && indexPath.row == 1) {
        [self showCommentAutoReplySettingAlert];
    }
    // 点击关于小红书助手
    else if (indexPath.section == 2 && indexPath.row == 0) {
        [self showAboutAlert];
    }
}

#pragma mark - 按钮操作
- (void)closeButtonTapped {
    // 保存设置
    [self updateWatermarkSettings];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)watermarkSwitchChanged:(UISwitch *)sender {
    gWatermarkEnabled = sender.isOn;
    [self updateWatermarkSettings];
        
    [self showToastWithMessage:gWatermarkEnabled ? @"已开启视频无水印功能" : @"已关闭视频无水印功能"];
}

- (void)saveSwitchChanged:(UISwitch *)sender {
    gSaveEnabled = sender.isOn;
    [self updateWatermarkSettings];

    [self showToastWithMessage:gSaveEnabled ? @"已开启强制保存功能" : @"已关闭强制保存功能"];
}

- (void)livePhotoWatermarkSwitchChanged:(UISwitch *)sender {
    gLivePhotoWatermarkEnabled = sender.isOn;
    [self updateWatermarkSettings];

    [self showToastWithMessage:gLivePhotoWatermarkEnabled ? @"已开启LivePhoto无水印功能" : @"已关闭LivePhoto无水印功能"];
    
    NSLog(@"[XHSNOWatermark] LivePhoto去水印功能状态: %@", gLivePhotoWatermarkEnabled ? @"开启" : @"关闭");
}

- (void)autoReplySwitchChanged:(UISwitch *)sender {
    gAutoReplyEnabled = sender.isOn;
    [self updateWatermarkSettings];

    [self showToastWithMessage:gAutoReplyEnabled ? @"已开启私信自动回复功能" : @"已关闭私信自动回复功能"];
}

- (void)commentAutoReplySwitchChanged:(UISwitch *)sender {
    gCommentAutoReplyEnabled = sender.isOn;
    [self updateWatermarkSettings];

    [self showToastWithMessage:gCommentAutoReplyEnabled ? @"已开启评论自动回复功能" : @"已关闭评论自动回复功能"];
}

- (void)showAboutAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"关于小红书助手"
                                                                   message:@"小红书助手是一个增强小红书体验的工具，让您可以下载无水印视频和图片，并支持强制保存到相册。\n\n此插件仅供学习交流使用，请勿用于商业目的。"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAutoReplySettingAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置私信自动回复内容"
                                                                   message:@"请输入收到私信时的自动回复内容"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = gAutoReplyText;
        textField.placeholder = @"请输入回复内容";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            gAutoReplyText = textField.text;
            [self updateWatermarkSettings];
            [self showToastWithMessage:@"私信自动回复内容已保存"];
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showCommentAutoReplySettingAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置评论自动回复内容"
                                                                   message:@"请输入收到评论时的自动回复内容"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = gCommentAutoReplyText;
        textField.placeholder = @"请输入回复内容";
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = alert.textFields.firstObject;
        if (textField.text.length > 0) {
            gCommentAutoReplyText = textField.text;
            [self updateWatermarkSettings];
            [self showToastWithMessage:@"评论自动回复内容已保存"];
        }
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:saveAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - 工具方法
- (void)showToastWithMessage:(NSString *)message {
    UILabel *toastLabel = [[UILabel alloc] init];
    toastLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    toastLabel.textColor = [UIColor whiteColor];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.font = [UIFont systemFontOfSize:14];
    toastLabel.text = message;
    toastLabel.alpha = 0;
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds = YES;
    [self.containerView.contentView addSubview:toastLabel];
    toastLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [toastLabel.centerXAnchor constraintEqualToAnchor:self.containerView.contentView.centerXAnchor],
        [toastLabel.bottomAnchor constraintEqualToAnchor:self.containerView.contentView.bottomAnchor constant:-80],
        [toastLabel.widthAnchor constraintLessThanOrEqualToConstant:300],
        [toastLabel.heightAnchor constraintGreaterThanOrEqualToConstant:40]
    ]];
    

    toastLabel.layoutMargins = UIEdgeInsetsMake(10, 20, 10, 20);
    
    [UIView animateWithDuration:0.3 animations:^{
        toastLabel.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.5 options:0 animations:^{
            toastLabel.alpha = 0;
        } completion:^(BOOL finished) {
            [toastLabel removeFromSuperview];
        }];
    }];
}

#pragma mark - 设置更新
- (void)updateWatermarkSettings {
    NSLog(@"[XHSNOWatermark] 设置已更新: 视频无水印=%@, LivePhoto无水印=%@, 保存功能=%@, 私信自动回复=%@, 评论自动回复=%@", 
          gWatermarkEnabled ? @"开启" : @"关闭",
          gLivePhotoWatermarkEnabled ? @"开启" : @"关闭",
          gSaveEnabled ? @"开启" : @"关闭",
          gAutoReplyEnabled ? @"开启" : @"关闭",
          gCommentAutoReplyEnabled ? @"开启" : @"关闭");
    

    [self saveUserDefaults];
}

@end
