//
//  VPLPlacesViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import AVFoundation;

#import "VPLPlacesViewController.h"
#import "DPHue.h"
#import "VPLDiscoveryViewController.h"
#import "VPLPlaceCell.h"
#import "VPLInfoCell.h"
#import "VPLPlace.h"
#import "VPLPlaceViewController.h"
#import "VPLSettingsViewController.h"
#import "VPLSoundManager.h"
#import "VPLPlaceManager.h"
#import "VPLPlaceInfo+Accessors.h"
#import "VPLPlaceText+Accessors.h"

#define kVPLHueConnectionFailedTag  1001
#define kVPLBundlePlacesDownloadTag 1002
#define kVPLPlaceDownloadTag        1003

@interface VPLPlacesViewController() <VPLDiscoveryViewControllerDelegate, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DPHue *hue;

@property (nonatomic, strong) NSArray *localPlaces;
@property (nonatomic, strong) NSArray *availablePlaces;
@property (nonatomic, strong) VPLPlaceInfo *placeToDownload;

@property (nonatomic, assign) BOOL shouldReconnect;
@property (nonatomic, assign) BOOL smallScreen;

@property (nonatomic, assign) BOOL editMode;
@property (nonatomic, strong) NSMutableSet *selectedIndexPaths;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *deleteButton;

@property (nonatomic, readonly) dispatch_queue_t removeQueue;

@end

@implementation VPLPlacesViewController

#pragma mark - Remove place background queue

-(dispatch_queue_t)removeQueue
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t _removeQueue;
    dispatch_once(&onceToken, ^{
        _removeQueue = dispatch_queue_create("com.tazetdinov.vplaces.remove", DISPATCH_QUEUE_SERIAL);
    });
    return _removeQueue;
}

#pragma mark - View controller style

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return UIStatusBarAnimationFade;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskAll;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - Unwind segues


-(IBAction)dismissPlace:(UIStoryboardSegue*)segue
{
}

-(IBAction)dismissSettings:(UIStoryboardSegue*)segue
{
    
}

-(IBAction)dismissSettingsAndDeleteLocalPlaces:(UIStoryboardSegue*)segue
{
    dispatch_async(self.removeQueue, ^{
        NSArray *places = [VPLPlaceManager manager].places;
        for (VPLPlace *place in places)
        {
            [[VPLPlaceManager manager] removePlace:place];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [VPLPlaceInfo removeAllPlacesInContext:[NSManagedObjectContext sharedContext]];
            [[NSManagedObjectContext sharedContext] save];
            [NSUserDefaults standardUserDefaults].lastBundlePlaceListUpdate = nil;
            [self updatePlacesInfo];
            [self updateBundlePlacesList];
        });
    });
}

-(IBAction)dismissSettingsAndReconnect:(UIStoryboardSegue*)segue
{
    self.hue = nil;
    self.shouldReconnect = YES;
}

#pragma mark - View lifecycle


-(void)viewDidLoad
{
    [super viewDidLoad];
    self.shouldReconnect = YES;
//    self.places = @[ [VPLPlace forestPlace], [VPLPlace campfirePlace], [VPLPlace thunderstormPlace],
//                     [VPLPlace cityPlace] /*, [VPLPlace hauntedPlace] */ ];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                                           error:NULL];
    
    self.selectedIndexPaths = [NSMutableSet set];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        UIImage *background = [UIImage imageNamed:@"placesBackground"];
        self.collectionView.backgroundView = [[UIImageView alloc] initWithImage:background];
    }
    else
    {
        UIImage *background = [UIImage imageNamed:@"placesBackgroundPad"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.collectionView.frame];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.image = background;
        self.collectionView.backgroundView = imageView;
        
    }
    
    if (self.view.bounds.size.height <= 480.0f)
    {
        self.smallScreen = YES;
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        layout.itemSize = CGSizeMake(248.0f, 372.0f);
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(hueConnectionFailed:)
                                                 name:VPLHueConnectionDidFailNotificaiton
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(soundManagerFailed:)
                                                 name:VPLSoundManagerDidFailNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contextUpdated:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterForeground:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(placeDownloaded:)
                                                 name:VPLPlaceDownloadedNotification
                                               object:nil];
    [self updatePlacesInfo];
    if ([NSUserDefaults standardUserDefaults].bundlePlacesOffered)
    {
        [self updateBundlePlacesList];
    }
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                        duration:(NSTimeInterval)duration
{
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
    {
//        layout.sectionInset = UIEdgeInsetsMake(80.0f, 30.0f, 80.0f, 30.0f);
//        layout.sectionInset = UIEdgeInsetsMake(170.0f, 70.0f, 170.0f, 70.0f);
        layout.itemSize = CGSizeMake(285.0f, 400.0f);
    }
    else
    {
//        layout.sectionInset = UIEdgeInsetsMake(100.0f, 30.0f, 100.0f, 30.0f);
        layout.sectionInset = UIEdgeInsetsMake(80.0f, 70.0f, 80.0f, 70.0f);
//        layout.itemSize = CGSizeMake(275.0f, 275.0f);
    }
    layout.itemSize = CGSizeMake(285.0f, 400.0f);
    layout.sectionInset = UIEdgeInsetsMake(80.0f, 70.0f, 80.0f, 70.0f);
}

#warning Add proper item size for iPad

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:VPLHueConnectionDidFailNotificaiton
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:VPLSoundManagerDidFailNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:VPLPlaceDownloadedNotification
                                                  object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ((!self.hue) && (self.shouldReconnect))
    {
        [self performSegueWithIdentifier:@"DiscoverHues" sender:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"DiscoverHues"])
    {
        VPLDiscoveryViewController *vc = (VPLDiscoveryViewController *)[segue.destinationViewController topViewController];
        vc.delegate = self;
    }
    else if ([segue.identifier isEqualToString:@"ShowSettings"])
    {
        VPLSettingsViewController *vc = (VPLSettingsViewController *)[segue.destinationViewController topViewController];
        vc.hue = self.hue;
    }
    else if ([segue.identifier isEqualToString:@"ShowPlace"])
    {
        VPLPlaceViewController *vc = segue.destinationViewController;
        vc.transitioningDelegate = self;
        //        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        NSIndexPath *indexPath = sender;
        vc.place = self.localPlaces[indexPath.row];
        vc.hue = self.hue;
    }
}

#pragma mark - Notifications

-(void)placeDownloaded:(NSNotification*)notification
{
    [self updatePlacesInfo];
}

-(void)enterForeground:(NSNotification*)notification
{
    if ([NSUserDefaults standardUserDefaults].bundlePlacesOffered)
    {
        [self updateBundlePlacesList];
    }
}

-(void)hueConnectionFailed:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Connection to Hue failed title]",
                                                              @"Connection to Hue failed title")
                                    message:NSLocalizedString(@"[Connection to Hue failed message]",
                                                              @"Connection to Hue failed message")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                          otherButtonTitles:nil] show];
        self.hue = nil;
        
    });
}

-(void)soundManagerFailed:(NSNotification*)notification
{
    NSString *message;
    if (notification.userInfo)
    {
        message = [NSString stringWithFormat:NSLocalizedString(@"[Problems playing sound %@]",
                                                               @"Sound manager error format"),
                   notification.userInfo[kVPLSoundManagerErrorKey]];
    }
    else
    {
        message = NSLocalizedString(@"[General problem playing sound]", @"Sound manager general error");
    }
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Could not play sound title]",
                                                          @"Sound manager failed title")
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                      otherButtonTitles:nil] show];
}

-(void)contextUpdated:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *visibleCells = self.collectionView.visibleCells;
        for (VPLInfoCell *cell in visibleCells)
        {
            if ([cell isKindOfClass:[VPLInfoCell class]])
            {
                VPLPlaceInfo *info = [VPLPlaceInfo existingPlaceInfoWithUID:cell.placeIdentifier
                                                                  inContext:[NSManagedObjectContext sharedContext]];
                if (info.totalSize)
                {
                    cell.progressHidden = NO;
                    cell.downloadProgress = (float)((double)info.downloadedSize / (double)info.totalSize);
                }
                else
                {
                    cell.progressHidden = YES;
                }
            }
        }
    });
}

#pragma mark - Actions

-(IBAction)toggleEditMode:(id)sender
{
    [self.selectedIndexPaths removeAllObjects];
    if (self.editMode)
    {
        [self.navigationController setToolbarHidden:YES animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                               target:self
                                                                                               action:@selector(toggleEditMode:)];
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
    else
    {
        
        [self.navigationController setToolbarHidden:NO animated:YES];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                               target:self
                                                                                               action:@selector(toggleEditMode:)];
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.deleteButton.enabled = NO;
    }
    self.editMode = !self.editMode;
    [self.collectionView performBatchUpdates:^{
        [self.collectionView.collectionViewLayout invalidateLayout];
        [self.collectionView setCollectionViewLayout:self.collectionView.collectionViewLayout animated:YES];
//        [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
        NSArray *cells = self.collectionView.visibleCells;
        for (VPLPlaceCell *cell in cells)
        {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
            if (indexPath.row < self.localPlaces.count)
            {
                cell.selectionMarkHidden = !self.editMode;
                cell.marked = NO;//[self.selectedIndexPaths containsObject:indexPath];
            }
        }
    }
                                  completion:NULL];
}

-(IBAction)removeSelectedPlaces:(id)sender
{
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"[Delete %ld places]",
                                                                   @"Delete places title"),
                       self.selectedIndexPaths.count];
    [[[UIActionSheet alloc] initWithTitle:title
                                 delegate:self
                        cancelButtonTitle:NSLocalizedString(@"[Cancel]", @"Cancel button title")
                   destructiveButtonTitle:NSLocalizedString(@"[Delete]", @"Delete button title")
                        otherButtonTitles:nil] showInView:self.view];
}

-(IBAction)settingsButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"ShowSettings" sender:nil];
}

-(IBAction)reconnectButtonTapped:(id)sender
{
    [self performSegueWithIdentifier:@"DiscoverHues" sender:nil];
}

#pragma mark - Discovery view controller delegate

-(void)discoveryViewController:(VPLDiscoveryViewController *)sender didConnectToHue:(DPHue *)hue
{
    self.hue = hue;
    self.shouldReconnect = NO;
    [self dismissViewControllerAnimated:YES completion:^{
        [self offerDownloadBundlePlaces];
    }];
}

-(void)discoveryViewControllerDidFail:(VPLDiscoveryViewController *)sender
{
    self.shouldReconnect = NO;
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Hue not found title]", @"Hue not found title")
                                                            message:NSLocalizedString(@"[Hue not found message]", @"Hue not found message")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                                                  otherButtonTitles:nil];
        alertView.tag = kVPLHueConnectionFailedTag;
        [alertView show];
    }];
}

-(void)discoveryViewControllerDidCancel:(VPLDiscoveryViewController *)sender
{
    self.shouldReconnect = NO;
    [self dismissViewControllerAnimated:YES completion:^{
        [self offerDownloadBundlePlaces];
    }];
}

#pragma mark - Collection view data source and delegate


-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.localPlaces.count + self.availablePlaces.count + 1;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.localPlaces.count)
    {
        VPLPlaceCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PlaceCell"
                                                                       forIndexPath:indexPath];
        
        VPLPlace *place = self.localPlaces[indexPath.row];
        cell.title.text = place.title;
        cell.details.text = place.detailedInfo;
        
        cell.backgroundImage.image = place.coverImage;
        [cell.title sizeToFit];
        [cell.details sizeToFit];
        cell.selectionMarkHidden = !self.editMode;
        cell.marked = [self.selectedIndexPaths containsObject:indexPath];
        return cell;
    }
    else if (indexPath.row < (self.localPlaces.count + self.availablePlaces.count))
    {
        VPLInfoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"InfoCell"
                                                                      forIndexPath:indexPath];
        
        VPLPlaceInfo *placeInfo = self.availablePlaces[indexPath.row - self.localPlaces.count];
        cell.title.text = placeInfo.defaultText.title;
        cell.details.text = placeInfo.defaultText.details;
        cell.placeIdentifier = placeInfo.uid;
        if (placeInfo.totalSize)
        {
            cell.progressHidden = NO;
            cell.downloadProgress = (float)((double)placeInfo.downloadedSize / (double)placeInfo.totalSize);
        }
        else
        {
            cell.progressHidden = YES;
        }
        
        [cell.title sizeToFit];
        [cell.details sizeToFit];
        
        return cell;
    }
    else
    {
        if (!(self.localPlaces.count + self.availablePlaces.count))
        {
            return [collectionView dequeueReusableCellWithReuseIdentifier:@"LoadingCell"
                                                             forIndexPath:indexPath];
        }
        else
        {
            return [collectionView dequeueReusableCellWithReuseIdentifier:@"PromoCell"
                                                             forIndexPath:indexPath];
        }
    }
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editMode)
    {
        if (indexPath.row < self.localPlaces.count)
        {
            if ([self.selectedIndexPaths containsObject:indexPath])
            {
                [self.selectedIndexPaths removeObject:indexPath];
            }
            else
            {
                [self.selectedIndexPaths addObject:indexPath];
            }
            VPLPlaceCell *cell = (VPLPlaceCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            cell.marked = [self.selectedIndexPaths containsObject:indexPath];
            self.deleteButton.enabled = (self.selectedIndexPaths.count > 0);
        }
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    else
    {
        if (indexPath.row < self.localPlaces.count)
        {
            [self performSegueWithIdentifier:@"ShowPlace" sender:indexPath];
        }
        else if (indexPath.row < (self.localPlaces.count + self.availablePlaces.count))
        {
            VPLPlaceInfo *placeInfo = self.availablePlaces[indexPath.row - self.localPlaces.count];
            if (!placeInfo.totalSize)
            {
                self.placeToDownload = placeInfo;
                NSString *message;
                if (placeInfo.reportedSize)
                {
                    message = [NSString stringWithFormat:NSLocalizedString(@"[Download place %@, size %@]",
                                                                           @"Download place question"),
                               placeInfo.defaultText.title,
                               [NSByteCountFormatter stringFromByteCount:placeInfo.reportedSize
                                                              countStyle:NSByteCountFormatterCountStyleFile]];
                    
                    
                }
                else
                {
                    message = [NSString stringWithFormat:NSLocalizedString(@"[Download place %@]",
                                                                           @"Download place question"),
                               placeInfo.defaultText.title];
                }
                [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:placeInfo.defaultText.title
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"[Cancel]",
                                                                                              @"Cancel button title")
                                                          otherButtonTitles:NSLocalizedString(@"[Download]",
                                                                                              @"Download button title"), nil];
                alertView.tag = kVPLPlaceDownloadTag;
                [alertView show];
            }
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        else
        {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark - Transition animation

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                   presentingController:(UIViewController *)presenting
                                                                       sourceController:(UIViewController *)source
{
    return self;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return self;
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.4f;
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *source = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *dest = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    BOOL forwardAnimation = NO;
    CGFloat heightOffset = 34.0f;
    
    if (([source isKindOfClass:[UINavigationController class]]) || (source == self))
    {
        forwardAnimation = YES;
        [transitionContext.containerView addSubview:source.view];
        [transitionContext.containerView addSubview:dest.view];
    }
    else
    {
        [transitionContext.containerView addSubview:dest.view];
        [transitionContext.containerView addSubview:source.view];
    }
    
    NSIndexPath *indexPath = [[self.collectionView indexPathsForVisibleItems] firstObject];
    
    VPLPlaceCell *cell = (VPLPlaceCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
//    CGPoint animationCenter = [transitionContext.containerView convertPoint:cell.center
//                                                                   fromView:cell];
    
    //    CGPoint sourceCenter = source.view.center;
    CGPoint destCenter = transitionContext.containerView.center;
    CGPoint animationCenter = transitionContext.containerView.center;
    
    if (forwardAnimation)
    {
        // forward animation
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            dest.view.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
        }
        else
        {
            dest.view.transform = CGAffineTransformMakeScale(0.77f, 0.77f);
        }
        
        animationCenter.y += heightOffset;
        dest.view.center = animationCenter;
        dest.view.alpha = 0.0f;
        cell.alpha = 1.0f;
        
        [UIView animateWithDuration:0.1f
                         animations:^{
                             dest.view.alpha = 1.0f;
                         }];
    }
    else
    {
        if (!self.smallScreen)
        {
            dest.view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        }
        dest.view.alpha = 0.5f;
        cell.alpha = 1.0f;
        destCenter.y += heightOffset;
        [UIView animateWithDuration:0.1f
                              delay:0.3f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             source.view.alpha = 0.0f;
                         }
                         completion:NULL];
    }
    source.view.clipsToBounds = YES;
    dest.view.clipsToBounds = YES;
    
    /*
    if (!forwardAnimation)
    {
        [UIView animateWithDuration:0.2f
                              delay:0.2f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             source.view.alpha = 0.0f;
                         }
                         completion:NULL];
    }
     */
    
    [UIView animateWithDuration:0.4f
                     animations:^{
                         dest.view.transform = CGAffineTransformIdentity;
                         
                         if (forwardAnimation)
                         {
                             if (!self.smallScreen)
                             {
                                 source.view.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
                             }
                             source.view.center = destCenter;
                             dest.view.center = destCenter;
                         }
                         else
                         {
                             if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                             {
                                 source.view.transform = CGAffineTransformMakeScale(0.2f, 0.2f);
                             }
                             else
                             {
                                 source.view.transform = CGAffineTransformMakeScale(0.77f, 0.77f);
                             }
                             source.view.center = destCenter;
                             dest.view.alpha = 1.0f;
                         }
                         
                     }
                     completion:^(BOOL finished) {
                         [source.view removeFromSuperview];
                         source.view.layer.affineTransform = CGAffineTransformIdentity;
                         //cell.alpha = 1.0f;
                         [transitionContext completeTransition:YES];
                     }];
    
}

#pragma mark - Place management methods

-(void)updateBundlePlacesList
{
    [[VPLPlaceManager manager] updateRemotePlacesListWithCompletion:^(BOOL success) {
        if (success)
        {
            [self updatePlacesInfo];
        }
        else
        {
            if (![VPLPlaceInfo numberOfPlacesInContext:[NSManagedObjectContext sharedContext]])
            {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Download place failed title]",
                                                                      @"Download place failed title")
                                            message:NSLocalizedString(@"[Download places failed]",
                                                                      @"Download places failed")
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                                  otherButtonTitles:nil] show];
            }
        }
    }];
}

-(void)offerDownloadBundlePlaces
{
    if (![NSUserDefaults standardUserDefaults].bundlePlacesOffered)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Download bundle title]",
                                                                                      @"Download bundle title")
                                                            message:NSLocalizedString(@"[Download bundle message]",
                                                                                      @"Download bundle message")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"[Cancel]",
                                                                                      @"Cancel button title")
                                                  otherButtonTitles:NSLocalizedString(@"[Download]",
                                                                                      @"Download button title"), nil];
        alertView.tag = kVPLBundlePlacesDownloadTag;
        [alertView show];
    }
}

-(void)updatePlacesInfo
{
    [[VPLPlaceManager manager] loadLocalPlaces];
    self.localPlaces = [VPLPlaceManager manager].places;
    self.availablePlaces = [VPLPlaceInfo availablePlacesInContext:[NSManagedObjectContext sharedContext]];
    
    [self.collectionView reloadData];
}

-(void)downloadBundledPlaces
{
    [[VPLPlaceManager manager] updateRemotePlacesListWithCompletion:^(BOOL success) {
        if (success)
        {
            [self updatePlacesInfo];
            NSArray *placesAvailable = [VPLPlaceInfo availablePlacesInContext:[NSManagedObjectContext sharedContext]];
            for (VPLPlaceInfo *info in placesAvailable)
            {
                if (!info.totalSize)
                {
                    info.totalSize = MAX(1, info.reportedSize);
                }
                [[VPLPlaceManager manager] downloadPlaceAtURL:info.archiveURL
                                                   identifier:info.uid
                                                   completion:^(BOOL success) {
                                                       if  (success)
                                                       {
                                                           [self updatePlacesInfo];
                                                       }
                                                       else
                                                       {
                                                           NSString *message = [NSString stringWithFormat:NSLocalizedString(@"[Download place %@ failed]",
                                                                                                                            @"Download place failed message"),
                                                                                info.defaultText.title];
                                                           [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Download place failed title]", @"Download place failed title")
                                                                                       message:message
                                                                                      delegate:nil
                                                                             cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                                                                             otherButtonTitles:nil] show];
                                                       }
                                                   }];
            }
            [[NSManagedObjectContext sharedContext] save];
            [self.collectionView reloadItemsAtIndexPaths:self.collectionView.indexPathsForVisibleItems];
        }
        else
        {
            [NSUserDefaults standardUserDefaults].bundlePlacesOffered = NO;
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Download place failed title]",
                                                                  @"Download place failed title")
                                        message:NSLocalizedString(@"[Download places failed]",
                                                                  @"Download places failed")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                              otherButtonTitles:nil] show];
        }
    }];
}

-(void)navigateToPlaceWithIdentifier:(NSString*)identifier
{
    [self updatePlacesInfo];
    if (self.view.window)
    {
        // only navigate there, if no active place
        NSInteger index = 0;
        for (VPLPlace *place in self.localPlaces)
        {
            if ([place.identifier isEqualToString:identifier])
            {
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]
                                            atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                    animated:YES];
                return;
            }
            index++;
        }
    }
}



#pragma mark - Action sheet delegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        dispatch_async(self.removeQueue, ^{
        
            for (NSIndexPath *indexPath in self.selectedIndexPaths)
            {
                VPLPlace *place = self.localPlaces[indexPath.row];
                [[VPLPlaceManager manager] removePlace:place];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.selectedIndexPaths removeAllObjects];
                [self updatePlacesInfo];
                [self toggleEditMode:nil];
            });
        });
    }
}

#pragma mark - Alert view delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kVPLHueConnectionFailedTag)
    {
        [self offerDownloadBundlePlaces];
    }
    else if (alertView.tag == kVPLBundlePlacesDownloadTag)
    {
        [NSUserDefaults standardUserDefaults].bundlePlacesOffered = YES;
       if (buttonIndex == alertView.cancelButtonIndex)
       {
           [self updateBundlePlacesList];
       }
        else
       {
           [self downloadBundledPlaces];
       }
        
    }
    else if (alertView.tag == kVPLPlaceDownloadTag)
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            if (!self.placeToDownload.totalSize)
            {
                self.placeToDownload.totalSize = MAX(1, self.placeToDownload.reportedSize);
                [[NSManagedObjectContext sharedContext] save];
            }
            [[VPLPlaceManager manager] downloadPlaceAtURL:self.placeToDownload.archiveURL
                                               identifier:self.placeToDownload.uid
                                               completion:^(BOOL success) {
                                                   if (success)
                                                   {
                                                       [self updatePlacesInfo];
                                                   }
                                                   else
                                                   {
                                                       NSString *message = [NSString stringWithFormat:NSLocalizedString(@"[Download place %@ failed]",
                                                                                                                        @"Download place failed message"),
                                                                            self.placeToDownload.defaultText.title];
                                                       [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"[Download place failed title]", @"Download place failed title")
                                                                                   message:message
                                                                                  delegate:nil
                                                                         cancelButtonTitle:NSLocalizedString(@"[Ok]", @"Ok button title")
                                                                         otherButtonTitles:nil] show];
                                                   }
                                               }];
        }
    }
}


@end
