//
//  MasterViewController.h
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

@interface MasterViewController : UITableViewController

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

