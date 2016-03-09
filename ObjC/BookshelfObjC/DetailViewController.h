//
//  DetailViewController.h
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Book.h"

@interface DetailViewController : UIViewController

@property (strong, nonatomic) Book* book;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;

@end

