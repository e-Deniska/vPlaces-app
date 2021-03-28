//
//  VPLPlaceViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import MediaPlayer;

#import "VPLPlaceViewController.h"
#import "DPHueLight.h"
#import "VPLSoundManager.h"

@interface VPLPlaceViewController()

@property (weak, nonatomic) IBOutlet VPLAnimatedImageView *animatedImageView;
@property (nonatomic, assign) BOOL connectionErrorMessageShown;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) MPVolumeView *volumeView;

- (IBAction)toggleMute:(UIButton *)sender;

@property (nonatomic, assign, getter = isMuted) BOOL muted;

@property (strong, nonatomic) UIWindow *secondWindow;

@end

@implementation VPLPlaceViewController

//-(BOOL)prefersStatusBarHidden
//{
//    return YES;
//}
//
//-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation
//{
//    return UIStatusBarAnimationFade;
//}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

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
    self.doneButton.layer.masksToBounds = NO;
    self.doneButton.layer.shadowOffset = CGSizeZero;
    self.doneButton.layer.shadowOpacity = 1.0f;
    self.doneButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.doneButton.layer.shadowRadius = 2.0f;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hueConnectionFailed:)
                                                 name:VPLHueConnectionDidFailNotificaiton
                                               object:nil];
}

-(void)hueConnectionFailed:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.connectionErrorMessageShown)
        {
            self.connectionErrorMessageShown = YES;
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Connection to Hue failed title]",
                                                                  @"Failed to send command to hue title")
                                        message:NSLocalizedString(@"[Connection to Hue failed message]",
                                                                  @"Try reconnecting message")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                              otherButtonTitles:nil] show];
        }
    });
}

-(void)fadeInControls
{
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.doneButton.alpha = 1.0f;
                         self.volumeView.alpha = 1.0f;
                         self.muteButton.alpha = 1.0f;
                     }];
}

-(void)fadeOutControls
{
    [UIView animateWithDuration:0.2f
                     animations:^{
                         self.doneButton.alpha = 0.0f;
                         self.volumeView.alpha = 0.0f;
                         self.muteButton.alpha = 0.0f;
                     }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    MPVolumeView *volumeView = [VPLSoundManager sharedManager].volumeView;
    volumeView.frame = CGRectMake(10.0f + 56.0f,
                                  self.view.bounds.size.height - 40.0f,
                                  self.view.bounds.size.width - 30.0f - 56.0f,
                                  20.0f);
    volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    volumeView.translatesAutoresizingMaskIntoConstraints = YES;
    [self.view addSubview:volumeView];
    volumeView.layer.masksToBounds = NO;
    volumeView.layer.shadowOffset = CGSizeZero;
    volumeView.layer.shadowOpacity = 0.8f;
    volumeView.layer.shadowColor = [UIColor blackColor].CGColor;
    volumeView.layer.shadowRadius = 2.0f;
    self.volumeView = volumeView;

    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(10.0f,
                                                                  self.view.bounds.size.height - 44.0f - 10.0f,
                                                                  56.0f,
                                                                  50.0f)];
    button.contentEdgeInsets = UIEdgeInsetsMake(10.0f, 10.0f, 10.0f, 10.0f);
    button.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    button.translatesAutoresizingMaskIntoConstraints = YES;
    
    [self.view addSubview:button];
    self.muteButton = button;
    
    self.muteButton.layer.masksToBounds = NO;
    self.muteButton.layer.shadowOffset = CGSizeZero;
    self.muteButton.layer.shadowOpacity = 1.0f;
    self.muteButton.layer.shadowColor = [UIColor blackColor].CGColor;
    self.muteButton.layer.shadowRadius = 2.0f;
    
    [self.muteButton addTarget:self action:@selector(toggleMute:) forControlEvents:UIControlEventTouchUpInside];
    [self updateMuteButtonImage];
    
    self.doneButton.alpha = 0.0f;
    self.volumeView.alpha = 0.0f;
    self.muteButton.alpha = 0.0f;
    
    NSArray *lampNumbers = [NSUserDefaults standardUserDefaults].lampNumbers;
    NSMutableArray *lamps = [NSMutableArray arrayWithCapacity:lampNumbers.count];
    for (DPHueLight *light in self.hue.lights)
    {
        if ([lampNumbers containsObject:light.number])
        {
            [lamps addObject:light];
            light.on = YES;
            [light write];
        }
    }
    DLog(@"using lamps %@", lamps);
    
    if ([UIScreen screens].count > 1)
    {
        UIScreen *secondScreen = [[UIScreen screens] lastObject];
        secondScreen.overscanCompensation = UIScreenOverscanCompensationInsetApplicationFrame;
        DLog(@"modes: %@", secondScreen.availableModes);
        DLog(@"using second screen %@ - %@", secondScreen, NSStringFromCGRect(secondScreen.bounds))
        self.secondWindow = [[UIWindow alloc] initWithFrame:secondScreen.bounds];
        self.secondWindow.screen = secondScreen;
        self.secondWindow.hidden = NO;
        
        VPLAnimatedImageView *imageView = [[VPLAnimatedImageView alloc] initWithFrame:self.secondWindow.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.translatesAutoresizingMaskIntoConstraints = YES;
        imageView.contentMode = UIViewContentModeRedraw;
        [self.secondWindow addSubview:imageView];
        
        [self.animatedImageView animateImage:self.place.coverImage duration:1.0f];
        
        [self.place startPresentingPlaceWithAnimatedImageView:imageView lamps:lamps];
    }
    else
    {
        [self.place startPresentingPlaceWithAnimatedImageView:self.animatedImageView lamps:lamps];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self fadeInControls];
}

#warning Respond to screen connect/disconnect notifications


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.place stopPresentingPlace];
    if (self.secondWindow)
    {
        NSArray *subviews = self.secondWindow.subviews;
        [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
    [self fadeOutControls];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VPLHueConnectionDidFailNotificaiton object:nil];
}

- (IBAction)toggleMute:(UIButton *)sender
{
    self.muted = !self.muted;
    [VPLSoundManager sharedManager].muted = self.muted;
    [self updateMuteButtonImage];
}

-(void)updateMuteButtonImage
{
    UIImage *image = [[UIImage imageNamed:(self.muted ? @"muteOn" : @"muteOff")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.muteButton setImage:image forState:UIControlStateNormal];
}

@end
