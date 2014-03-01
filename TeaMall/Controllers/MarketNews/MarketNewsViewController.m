//
//  MarketNewsViewController.m
//  TeaMall
//
//  Created by Carl on 14-1-10.
//  Copyright (c) 2014年 helloworld. All rights reserved.
//

#import "MarketNewsViewController.h"
#import "UIViewController+AKTabBarController.h"
#import "UINavigationBar+Custom.h"
#import "CycleScrollView.h"
#import "NewsDetailViewController.h"
#import "MBProgressHUD.h"
#import "HttpService.h"
#import "MarketNews.h"
#import "SDWebImageManager.h"
#import "MarketNewRoundView.h"
@interface MarketNewsViewController ()<CycleScrollViewDelegate>
{
    NSArray * topAdViewInfo ;
    NSArray * downAdViewInfo ;
    
    //
    NSString * identifier;
    NSString * contentIdentifier;
}
@property (strong ,nonatomic) CycleScrollView * scrollView;
@end

@implementation MarketNewsViewController
@synthesize scrollView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect rect = self.contentScrollView.frame;
    if(![OSHelper iPhone5])
    {
        rect.size.height = 207;
        [self.contentScrollView setFrame:rect];
    }

    [self initializationInterface];
   

    [self showTopAdvertisementImage];
    [self getDownAdvertisementImage];
//    [self configureContentScrollView];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.view bringSubviewToFront:self.contentScrollView];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Private method
-(void)initializationInterface
{
    self.title = @"市场资讯";
    //[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"顶栏"]];
    
    
    CGRect tempScrollViewRect = CGRectMake(0, 0, 320, self.adScrolllView.frame.size.height);
    NSArray * tempArray = @[[UIImage imageNamed:@"广告1"],[UIImage imageNamed:@"广告1"],[UIImage imageNamed:@"整桶（选中状态）"]];
    scrollView = [[CycleScrollView alloc]initWithFrame:tempScrollViewRect
                                        cycleDirection:CycleDirectionLandscape
                                              pictures:tempArray
                                            autoScroll:YES];
    CGRect pageControlRect = scrollView.pageControl.frame;
    pageControlRect.origin.x = 260;
    scrollView.pageControl.frame = pageControlRect;
    scrollView.delegate = self;
    identifier          = @"URL";
    contentIdentifier   = @"Image";
    [scrollView setIdentifier:identifier andContentIdenifier:contentIdentifier];
    [self.adScrolllView addSubview:scrollView.pageControl];
    [self.adScrolllView addSubview:scrollView];
}


-(void)showTopAdvertisementImage
{
    __weak MarketNewsViewController * weakSelf = self;
    //读取图片
    [[HttpService sharedInstance]getMarketNewsTopWithCompletionBlock:^(id object) {
        if (object) {
            topAdViewInfo = object;
            [weakSelf downloadTopImage];
        }
    } failureBlock:^(NSError *error, NSString *responseString) {
        ;
    }];
}

-(void)downloadTopImage
{
    __block NSMutableArray * imageArray = [NSMutableArray array];
//    MarketNews * obj = [topAdViewInfo objectAtIndex:0];
//    _scrollItemTitle.text = obj.title;
    
    for (int i =0 ;i<[topAdViewInfo count];i++) {
        MarketNews * obj = [topAdViewInfo objectAtIndex:i];
        @autoreleasepool {
            __weak MarketNewsViewController * weakSelf = self;
            NSURL * imageURL = [NSURL URLWithString:obj.image];
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager downloadWithURL:imageURL options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                ;
            } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                if (image)
                {
                    NSLog(@"%@",[imageURL absoluteString]);
                    NSDictionary * info = @{identifier: obj.hw_id,contentIdentifier:image};
                    [imageArray addObject:info];
                    [weakSelf.scrollView updateImageArrayWithImageArray:imageArray];
                    [weakSelf.scrollView refreshScrollView];
                }
            }];
        }
    }
}

-(void)getDownAdvertisementImage
{
//    [self placeHolderImage];
    
    __weak MarketNewsViewController * weakSelf =self;
    [[HttpService sharedInstance]getMarketNewsWithCompletionBlock:^(id object) {
        if ([object count]) {
            downAdViewInfo = object;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf downloadDownImage];
            });
            
        }
    } failureBlock:^(NSError *error, NSString *responseString) {
        ;
    }];
}

-(void)downloadDownImage
{
    NSUInteger width = 140;
    NSUInteger height = 90;
    NSUInteger gap    = 14;
    for (int i =0 ;i<[downAdViewInfo count];i++) {
        MarketNews * obj = [downAdViewInfo objectAtIndex:i];
        MarketNewRoundView * view = [[MarketNewRoundView alloc]initWithFrame:CGRectMake(gap+(width+gap)*(i%2), gap+(height+gap)*(i/2), width, height)];
        [view configureContentImage:[NSURL URLWithString:obj.image] description:obj.title];
        view.tag = i;
        //点击动作事件
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(gotoNewsInfoContrller:)];
        [view addGestureRecognizer:tap];
        tap = nil;
        [self.contentScrollView addSubview:view];
        view = nil;
    }
    [self.contentScrollView setContentSize:CGSizeMake(320, 350)];
}


-(void)placeHolderImage
{
    NSUInteger width = 140;
    NSUInteger height = 90;
    NSUInteger gap    = 14;
    for (int i =0 ;i<6;i++) {
       
        MarketNewRoundView * view = [[MarketNewRoundView alloc]initWithFrame:CGRectMake(gap+(width+gap)*(i%2), gap+(height+gap)*(i/2), width, height)];
        //        [view configureContentImage:[NSURL URLWithString:@"http://teamall880.sinaapp.com/uploads/13912751465426.jpg"] description:@"hello"];
        [view configureContentImage:nil description:@"加载中"];
        
        //点击动作事件
        [self.contentScrollView addSubview:view];
        view = nil;
    }
    [self.contentScrollView setContentSize:CGSizeMake(320, 350)];
}
-(void)gotoNewsInfoContrller:(UITapGestureRecognizer *)tap
{
    MarketNewRoundView * view = (MarketNewRoundView*)tap.view;
    NSLog(@"%d",view.tag);
    UIImage * image = view.imageView.image;
    MarketNews * object = [downAdViewInfo objectAtIndex:view.tag];
    NewsDetailViewController * viewController = [[NewsDetailViewController alloc]initWithNibName:@"NewsDetailViewController" bundle:nil];
    [viewController setPoster:image];
    [viewController setNews:object];
    [self push:viewController];
    viewController = nil;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)tabImageName
{
	return @"市场资讯-图标（黑）";
}

- (NSString *)tabTitle
{
	return nil;
}

-(void)configureContentScrollView
{
    NSUInteger width = 140;
    NSUInteger height = 90;
    NSUInteger gap    = 14;
    for (int i =0; i<6; i++) {
        MarketNewRoundView * view = [[MarketNewRoundView alloc]initWithFrame:CGRectMake(gap+(width+gap)*(i%2), gap+(height+gap)*(i/2), width, height)];
        [view configureContentImage:nil description:@"hello"];
        [self.contentScrollView addSubview:view];
    }
    [self.contentScrollView setContentSize:CGSizeMake(320, 350)];
}
#pragma mark - CycleView delegate
-(void)cycleScrollViewDelegate:(CycleScrollView *)cycleScrollView didSelectImageView:(NSDictionary *)info
{
    for (MarketNews * object in topAdViewInfo) {
        if ([object.hw_id isEqualToString:[info valueForKey:identifier]]) {
            NewsDetailViewController * viewController = [[NewsDetailViewController alloc]initWithNibName:@"NewsDetailViewController" bundle:nil];
            [viewController setPoster:[info valueForKey:contentIdentifier]];
            [viewController setNews:object];
            [self push:viewController];
        }
    }
}


- (void)cycleScrollViewDelegate:(CycleScrollView *)cycleScrollView didScrollImageView:(int)index
{
    NSInteger scrollItemNum = index -1;
    if (index > [topAdViewInfo count]) {
        scrollItemNum = [topAdViewInfo count] -1;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        MarketNews * obj = [topAdViewInfo objectAtIndex:scrollItemNum];
        _scrollItemTitle.text = obj.title;
    });
    
}
@end
