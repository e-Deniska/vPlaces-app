//
//  VPLSettingsViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 16.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLSettingsViewController.h"
#import "VPLLampSelectViewController.h"
#import "VPLPlaceManager.h"

@interface VPLSettingsViewController() <VPLLampSelectViewControllerDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITableViewCell *chooseLightsCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellularAccessCell;

@end

@implementation VPLSettingsViewController

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
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSUInteger numberOfLamps = [NSUserDefaults standardUserDefaults].lampNumbers.count;
    if (numberOfLamps)
    {
        self.chooseLightsCell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"[%ld lamps]",
                                                                                                  @"N lamps"),
                                                      numberOfLamps];
    }
    else
    {
        self.chooseLightsCell.detailTextLabel.text = NSLocalizedString(@"[no lamps]", @"No lamps are selected");
    }
    self.cellularAccessCell.accessoryType = [VPLPlaceManager manager].allowCellularAccess ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"ChooseLamps"])
    {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
        return (self.hue != nil);
    }
    else
    {
        return YES;
    }
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

-(void)lampSelectViewControllerDidSave:(VPLLampSelectViewController *)sender
{
    [self.navigationController popToViewController:self animated:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 2)
    {
        [VPLPlaceManager manager].allowCellularAccess = ![VPLPlaceManager manager].allowCellularAccess;
        self.cellularAccessCell.accessoryType = [VPLPlaceManager manager].allowCellularAccess ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (indexPath.section == 3)
    {
        [[[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"[Delete all local places]",
                                                                @"Delete all local places question")
                                     delegate:self
                            cancelButtonTitle:NSLocalizedString(@"[Cancel]", @"Cancel button title")
                       destructiveButtonTitle:NSLocalizedString(@"[Delete]", @"Delete button title")
                            otherButtonTitles:nil] showInView:self.view];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [self performSegueWithIdentifier:@"DismissSettingsAndDeleteLocalPlaces" sender:self];
    }
}

@end
