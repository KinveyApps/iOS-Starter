//
//  MasterViewController.m
//  BookshelfObjC
//
//  Created by Victor Barros on 2016-03-03.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "Book.h"
@import Kinvey;
@import SVProgressHUD;

@interface MasterViewController () <UISearchBarDelegate>

@property NSMutableArray<Book*> *books;
@property Book* selectedBook;
@property (nonatomic, strong) KNVDataStore<Book*>* store;

@end

@implementation MasterViewController

-(KNVDataStore<Book *> *)store
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _store = [KNVDataStore getInstance:KNVDataStoreTypeSync
                                  forClass:[Book class]];
    });
    return _store;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewBook:)];
    self.navigationItem.rightBarButtonItem = addButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    NSLog(@"%@", self.store);
}

-(void)reloadData
{
    [self reloadData:@""];
}

-(void)reloadData:(NSString*)searchText
{
    [SVProgressHUD show];
    KNVQuery* query;
    if (![searchText isEqualToString:@""]) {
        query = [[KNVQuery alloc] initWithFormat:@"title CONTAINS[c] %@"
                                   argumentArray:@[searchText]];
    } else {
        query = nil;
    }
    [self.store find:query
   completionHandler:^(NSArray<Book *> * _Nullable books, NSError * _Nullable error)
    {
        [SVProgressHUD dismiss];
        if (books) {
            self.books = books.mutableCopy;
            if (self.refreshControl.refreshing) {
                [self.refreshControl endRefreshing];
            }
            [self.tableView reloadData];
        }
    }];
}

//func reloadData(searchText: String = "") {
//    SVProgressHUD.show()
//    var query: Query
//    if (searchText != "") {
//        query = Query(format: "title CONTAINS[c] %@", searchText)
//    } else {
//        query = Query()
//    }
//    store.find(query) { (books, error) -> Void in
//        SVProgressHUD.dismiss()
//        if let books = books {
//            self.books = books
//            if self.refreshControl?.refreshing ?? false {
//                self.refreshControl?.endRefreshing()
//            }
//            self.tableView.reloadData()
//        }
//    }
//}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewBook:(id)sender {
    self.selectedBook = [[Book alloc] init];
    [self performSegueWithIdentifier:@"showDetail" sender:sender];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *index = [self.tableView indexPathForSelectedRow];
        if (index) {
            self.selectedBook = self.books[index.row];
        }
        DetailViewController *controller = (DetailViewController *)[[segue destinationViewController] topViewController];
        controller.book = self.selectedBook;
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        controller.navigationItem.leftItemsSupplementBackButton = YES;
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.books.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    Book *book = self.books[indexPath.row];
    cell.textLabel.text = book.title;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Book* book = self.books[indexPath.row];
        @try {
            [SVProgressHUD show];
            [self.store remove:book
             completionHandler:^(NSUInteger count, NSError * _Nullable error)
            {
                [SVProgressHUD dismiss];
                if (count > 0) {
                    [self.books removeObjectAtIndex:indexPath.row];
                    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                }
            }];
        } @catch (NSException *exception) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:exception.reason
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [self presentViewController:alert
                               animated:YES
                             completion:nil];
        }
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

- (IBAction)unwindToMasterView:(UIStoryboardSegue*)segue
{
    [self reloadData];
}

- (IBAction)refresh:(id)sender
{
    [self reloadData];
}

- (IBAction)pull:(id)sender
{
    [SVProgressHUD show];
    
    [self.store pull:^(NSArray<Book*>* books, NSError* error) {
        [SVProgressHUD dismiss];
        if (books) {
            self.books = books.mutableCopy;
        }
        [self.tableView reloadData];
    }];
}

- (IBAction)push:(id)sender
{
    [SVProgressHUD show];
    
    [self.store push:^(NSUInteger count, NSError* error) {
        [SVProgressHUD dismiss];
        [self reloadData];
    }];
}

- (IBAction)purge:(id)sender
{
    [SVProgressHUD show];
    
    //Discard all local changes
    [self.store purge:^(NSUInteger count, NSError* error) {
        [SVProgressHUD dismiss];
        [self reloadData];
    }];
}

- (IBAction)sync:(id)sender
{
    [SVProgressHUD show];
    
    //Sync with the backend.
    //This will push all local changes to the backend, then
    //pull changes from the backend to the app.
    [self.store sync:^(NSUInteger count, NSArray<Book*>* books, NSError* error) {
        [SVProgressHUD dismiss];
        self.books = books.mutableCopy;
        [self.tableView reloadData];
    }];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self reloadData:searchText];
}

@end
