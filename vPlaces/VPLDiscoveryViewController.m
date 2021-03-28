//
//  VPLDiscoveryViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLDiscoveryViewController.h"
#import "DPHue.h"
#import "DPHueDiscover.h"
#import "VPLLampSelectViewController.h"

@interface VPLDiscoveryViewController() <DPHueDiscoverDelegate, VPLLampSelectViewControllerDelegate>

@property (nonatomic, strong) DPHueDiscover *discover;

@property (nonatomic, strong) DPHue *hue;

@property (nonatomic, weak) IBOutlet UIImageView *hubImage;
@property (nonatomic, assign) BOOL arrowShown;
@property (nonatomic, assign) BOOL timerStarted;

@property (nonatomic, strong) NSMutableArray *hosts;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *discoveryProgress;
@property (nonatomic, assign) int discoveryPassed;

@property (nonatomic, strong) NSTimer *animationTimer;

@property (nonatomic, assign) int rotationStage;

@end

#define kVPLDiscoveryDuration 30

@implementation VPLDiscoveryViewController

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
    
    self.hosts = [NSMutableArray array];
    
    self.statusLabel.text = NSLocalizedString(@"[Discovering hubs]", @"Discovering hub label");
    self.discoveryPassed = 0;
    self.discoveryProgress.progress = 0.0f;
    [self discoveryAnimation:nil];
    //[self rotateImage];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.animationTimer invalidate];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.discover)
    {
        self.discover = [[DPHueDiscover alloc] initWithDelegate:self];
        [self.discover discoverForDuration:kVPLDiscoveryDuration withCompletion:^(NSMutableString *log) {
            if ((!self.hosts.count) && (self.view.window))
            {
                // Hue is not found
                [self.delegate discoveryViewControllerDidFail:self];
            }
        }];
    }
}

-(IBAction)cancelTapped:(id)sender
{
    [self.delegate discoveryViewControllerDidCancel:self];
}

-(void)dealloc
{
    DLog(@"dealloced");
}

-(void)rotateImage
{
    CGFloat angle;
    if (self.rotationStage == 0)
    {
        angle = M_PI_2;
        self.rotationStage = 1;
    }
    else if (self.rotationStage == 1)
    {
        angle = M_PI;
        self.rotationStage = 2;
    }
    else if (self.rotationStage == 2)
    {
        angle = M_PI + M_PI_2;
        self.rotationStage = 3;
    }
    else
    {
        angle = 0.0f;
        self.rotationStage = 0;
    }
    [UIView animateWithDuration:1.0f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.hubImage.transform = CGAffineTransformMakeRotation(angle);
                     }
                     completion:NULL];
}

#warning properly handle multiple Hue hubs

-(void)foundHueAt:(NSString *)host discoveryLog:(NSString *)log
{
    [self.animationTimer invalidate];
    [self restoreImage];
    if (![self.hosts containsObject:host])
    {
        [self.hosts addObject:host];
        self.statusLabel.text = NSLocalizedString(@"[Found hub - connecting]", @"Found hub label");
        [self.discover stopDiscovery];
        self.hue = [[DPHue alloc] initWithHueHost:host
                                       clientType:@"vPlaces"
                                         username:[NSUserDefaults standardUserDefaults].appUsername];
        
        [self tryAuthorize];
        // start connecting/validating/so on
    }
}

-(void)tryAuthorize
{
    typeof(self) __weak weakSelf = self;
    [weakSelf .hue registerUsernameWithCompletion:^(DPHue *hue, NSError *error) {
        [weakSelf.hue readWithCompletion:^(DPHue *hue, NSError *err) {
            if (!weakSelf.hue.authenticated)
            {
                if (weakSelf.view.window)
                {
                    weakSelf.statusLabel.text = NSLocalizedString(@"[Press Hue button]",
                                                                  @"Press Hue button label");
                    
                    [weakSelf performSelector:@selector(tryAuthorize) withObject:nil afterDelay:3.0f];
                    if (!weakSelf.timerStarted)
                    {
                        [weakSelf flashTimerFired:nil];
                        weakSelf.timerStarted = YES;
                    }
                }
            }
            else
            {
                weakSelf.statusLabel.text = NSLocalizedString(@"[Connected to Hue]", @"Connected to Hue label");
                if (![[NSUserDefaults standardUserDefaults].hueName isEqualToString:weakSelf.hue.name])
                {
                    [NSUserDefaults standardUserDefaults].hueName = weakSelf.hue.name;
                    [NSUserDefaults standardUserDefaults].lampNumbers = @[];
                }
                
                if (![NSUserDefaults standardUserDefaults].lampNumbers.count)
                {
                    [weakSelf performSegueWithIdentifier:@"ChooseLamps" sender:nil];
                }
                else
                {
                    [weakSelf.delegate discoveryViewController:weakSelf didConnectToHue:weakSelf.hue];
                }
            }
        }];
    }];
}

-(void)restoreImage
{
    [UIView animateWithDuration:0.5f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.hubImage.alpha = 1.0f;
                         self.hubImage.transform = CGAffineTransformIdentity;
                         self.discoveryProgress.alpha = 0.0f;
                     }
                     completion:NULL];
}

-(void)discoveryAnimation:(NSTimer*)timer
{
    if (self.hue)
    {
        [self restoreImage];
    }
    else
    {
        [self rotateImage];
        self.discoveryPassed++;
        self.discoveryProgress.progress = (float)self.discoveryPassed / (float)kVPLDiscoveryDuration;
        [UIView animateWithDuration:0.5f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.hubImage.alpha = 0.3f;
                         }
                         completion:^(BOOL finished) {
                             [UIView animateWithDuration:0.5f
                                                   delay:0.0f
                                                 options:UIViewAnimationOptionCurveLinear
                                              animations:^{
                                                  self.hubImage.alpha = 1.0f;
                                              }
                                              completion:NULL];
                         }];
        [self.animationTimer invalidate];
        self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                               target:self
                                                             selector:@selector(discoveryAnimation:)
                                                             userInfo:nil
                                                              repeats:NO];
    }
}

-(void)flashTimerFired:(NSTimer*)timer
{
    if (self.arrowShown)
    {
        self.hubImage.image = [UIImage imageNamed:@"hub"];
    }
    else
    {
        self.hubImage.image = [UIImage imageNamed:@"hubArrow"];
    }
    self.arrowShown = !self.arrowShown;

    [self.animationTimer invalidate];
    self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f
                                                           target:self
                                                         selector:@selector(flashTimerFired:)
                                                         userInfo:nil
                                                          repeats:NO];
}

-(void)lampSelectViewControllerDidSave:(VPLLampSelectViewController *)sender
{
    [self.delegate discoveryViewController:self didConnectToHue:self.hue];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ChooseLamps"])
    {
        VPLLampSelectViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.hue = self.hue;
    }
}

@end
