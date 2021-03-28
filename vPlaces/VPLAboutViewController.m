//
//  VPLAboutViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 17.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

@import MessageUI;

#import "VPLAboutViewController.h"
#import "VPLHTLMDisplayViewController.h"

@interface VPLAboutViewController() <MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITableViewCell *versionCell;

@end

#define kVPLAppURL     @"https://itunes.apple.com/us/app/vplaces/id775595912"
#define kVPLvPhotosURL @"https://itunes.apple.com/us/app/vphotos/id825757469"

@implementation VPLAboutViewController

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
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    self.versionCell.detailTextLabel.text = versionString;

}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case 0:
        {
            switch (indexPath.row)
            {
                case 0:
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
            }
            break;
        }
            
        case 1:
        {
            // open App Store link
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kVPLAppURL]];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
            
        case 2:
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kVPLvPhotosURL]];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
            
        case 3:
        {
            switch (indexPath.row)
            {
                case 0:
                {
                    // e-mail
                    if ([MFMailComposeViewController canSendMail])
                    {
                        MFMailComposeViewController *mcvc = [[MFMailComposeViewController alloc] init];
                        [mcvc setToRecipients:@[ @"Danis Tazetdinov <d.tazetdinov@me.com>" ]];
                        [mcvc setSubject:NSLocalizedString(@"[Message from vPlaces user]", @"Mail subject title")];
                        mcvc.mailComposeDelegate = self;
                        [self presentViewController:mcvc animated:YES completion:NULL];
                    }
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }
                    
                case 1:
                {
                    // blog
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://easyplace.wordpress.com"]];
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }
                    
                case 2:
                {
                    // twitter
                    NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=edeniska"];
                    if ([[UIApplication sharedApplication] canOpenURL:twitterURL])
                    {
                        [[UIApplication sharedApplication] openURL:twitterURL];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://twitter.com/edeniska"]];
                    }
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }
                    
                case 3:
                {
                    // linkedin
                    NSURL *linkedInURL = [NSURL URLWithString:@"linkedin://profile/88342148"];
                    if ([[UIApplication sharedApplication] canOpenURL:linkedInURL])
                    {
                        [[UIApplication sharedApplication] openURL:linkedInURL];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.linkedin.com/in/dtazetdinov"]];
                    }
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }
                    
                case 4:
                {
                    // facebook
                    NSURL *fbURL = [NSURL URLWithString:@"fb://profile/dtazetdinov"];
                    if ([[UIApplication sharedApplication] canOpenURL:fbURL])
                    {
                        [[UIApplication sharedApplication] openURL:fbURL];
                    }
                    else
                    {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.facebook.com/dtazetdinov"]];
                    }
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    break;
                }
                    
                default:
                    break;
            }
            break;
        }
    }
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowAcknowledgements"])
    {
        VPLHTLMDisplayViewController *vc = segue.destinationViewController;
        vc.url = [[NSBundle mainBundle] URLForResource:@"acknowledgements" withExtension:@"html"];
    }
}

-(IBAction)share:(id)sender
{
    NSArray *shareInfo = @[ NSLocalizedString(@"[vPlaces app description]", @"vPlaces app description"),
                            [UIImage imageNamed:@"vPlacesIcon"],
                            [NSURL URLWithString:kVPLAppURL] ];
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:shareInfo
                                                                      applicationActivities:nil];
    avc.excludedActivityTypes = @[ UIActivityTypePrint, UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypePostToFlickr, UIActivityTypePostToVimeo ];
    [self presentViewController:avc animated:YES completion:NULL];
}

-(void)mailComposeController:(MFMailComposeViewController *)controller
         didFinishWithResult:(MFMailComposeResult)result
                       error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
