//
//  DetailViewController.m
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "DetailViewController.h"
@import Kinvey;
@import SVProgressHUD;

@interface DetailViewController ()

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setBook:(Book *)book
{
    _book = book;
    
    // Update the view.
    [self configureView];
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.book) {
        self.titleTextField.text = self.book.title;
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [self.titleTextField becomeFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"save"]) {
        if (self.book == nil) {
            self.book = [[Book alloc] init];
        }
        self.book.title = self.titleTextField.text;
        self.book.publicationDate = [NSDate date];
        
        KNVDataStore<Book*>* store = [KNVDataStore getInstance:KNVDataStoreTypeSync
                                                      forClass:[Book class]];
        [SVProgressHUD show];
        [store save:self.book
  completionHandler:^(Book * _Nullable book, NSError * _Nullable error)
        {
            [SVProgressHUD dismiss];
            if (book) {
                [self performSegueWithIdentifier:identifier sender:sender];
            } else {
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                               message:@"Operation not completed"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [self presentViewController:alert
                                   animated:YES
                                 completion:nil];
            }
        }];
        return NO;
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
