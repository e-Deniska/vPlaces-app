//
//  VPLLampSelectViewController.m
//  vPlaces
//
//  Created by Danis Tazetdinov on 12.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import "VPLLampSelectViewController.h"
#import "DPHueLight.h"

@interface VPLLampSelectViewController()

@property (nonatomic, strong) NSArray *lamps;
@property (nonatomic, strong) NSMutableArray *selectedNumbers;

@end

@implementation VPLLampSelectViewController

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
    self.lamps = [self.hue.lights sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"number"
                                                                                               ascending:YES] ]];
    self.selectedNumbers = [[NSUserDefaults standardUserDefaults].lampNumbers mutableCopy];
    if (!self.selectedNumbers)
    {
        self.selectedNumbers = [NSMutableArray array];
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.lamps.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *lampCell = [tableView dequeueReusableCellWithIdentifier:@"LampCell"
                                                                forIndexPath:indexPath];
    DPHueLight *lamp = self.lamps[indexPath.row];
    lampCell.textLabel.text = lamp.name;
    
    NSMutableString *details = [NSMutableString string];
    [details appendString:lamp.modelid];

    if (lamp.reachable)
    {
        [details appendString:NSLocalizedString(@"[, reachable]", @"Reachable flag")];
        if (lamp.on)
        {
            [details appendString:NSLocalizedString(@"[, on]", @"on flag")];
        }
        else
        {
            [details appendString:NSLocalizedString(@"[, off]", @"off flag")];
        }
    }
    else
    {
        [details appendString:NSLocalizedString(@"[, not reachable]", @"not reachable flag")];
    }
    
    lampCell.detailTextLabel.text = details;
    
    lampCell.accessoryType = ([self.selectedNumbers containsObject:lamp.number]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
    
    return lampCell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *lampCell = [tableView cellForRowAtIndexPath:indexPath];
    DPHueLight *lamp = self.lamps[indexPath.row];
    
    if ([self.selectedNumbers containsObject:lamp.number])
    {
        [self.selectedNumbers removeObject:lamp.number];
        lampCell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        [self.selectedNumbers addObject:lamp.number];
        lampCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(IBAction)saveSelectedLamps:(id)sender
{
    [NSUserDefaults standardUserDefaults].lampNumbers = self.selectedNumbers;
    [self.delegate lampSelectViewControllerDidSave:self];
}

@end
