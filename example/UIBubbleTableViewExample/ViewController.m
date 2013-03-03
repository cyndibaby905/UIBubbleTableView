//
//  ViewController.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

// 
// Images used in this example by Petr Kratochvil released into public domain
// http://www.publicdomainpictures.net/view-image.php?image=9806
// http://www.publicdomainpictures.net/view-image.php?image=1358
//

#import "ViewController.h"
#import "UIBubbleTableView.h"
#import "UIBubbleTableViewDataSource.h"
#import "NSBubbleData.h"

@interface ViewController ()
{
    IBOutlet UIBubbleTableView *bubbleTable;
    IBOutlet UIView *textInputView;
    IBOutlet UITextField *textField;

    NSMutableArray *bubbleData;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBubbleData *heyBubble = [NSBubbleData dataWithText:@"Hey, halloween is soon" date:[NSDate dateWithTimeIntervalSinceNow:-300] type:BubbleTypeSomeoneElse];
    heyBubble.avatar = [UIImage imageNamed:@"avatar1.png"];

    NSBubbleData *photoBubble = [NSBubbleData dataWithImage:[UIImage imageNamed:@"halloween.jpg"] date:[NSDate dateWithTimeIntervalSinceNow:-290] type:BubbleTypeSomeoneElse];
    photoBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    
    NSBubbleData *replyBubble = [NSBubbleData dataWithText:@"Wow.. Really cool picture out there. iPhone 5 has really nice camera, yeah?" date:[NSDate dateWithTimeIntervalSinceNow:-5] type:BubbleTypeMine];
    replyBubble.avatar = nil;
    
    bubbleData = [[NSMutableArray alloc] initWithObjects:heyBubble, photoBubble, replyBubble, nil];
    bubbleTable.bubbleDataSource = self;
    
    // The line below sets the snap interval in seconds. This defines how the bubbles will be grouped in time.
    // Interval of 120 means that if the next messages comes in 2 minutes since the last message, it will be added into the same group.
    // Groups are delimited with header which contains date and time for the first message in the group.
    
    bubbleTable.snapInterval = 120;
    
    // The line below enables avatar support. Avatar can be specified for each bubble with .avatar property of NSBubbleData.
    // Avatars are enabled for the whole table at once. If particular NSBubbleData misses the avatar, a default placeholder will be set (missingAvatar.png)
    
    bubbleTable.showAvatars = YES;
    
    // Uncomment the line below to add "Now typing" bubble
    // Possible values are
    //    - NSBubbleTypingTypeSomebody - shows "now typing" bubble on the left
    //    - NSBubbleTypingTypeMe - shows "now typing" bubble on the right
    //    - NSBubbleTypingTypeNone - no "now typing" bubble
    
    bubbleTable.typingBubble = NSBubbleTypingTypeSomebody;
    
    [bubbleTable reloadData];
    
    // Keyboard events
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
    
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - UIBubbleTableViewDataSource implementation

- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView
{
    return [bubbleData count];
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row
{
    return [bubbleData objectAtIndex:row];
}

#pragma mark - Keyboard events

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    
    CGRect keyboardRect = [[aNotification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	UIViewAnimationCurve curve = [[aNotification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
	[UIView setAnimationCurve:curve];
    
    
    
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = textInputView.frame;
        frame.origin.y = self.view.frame.size.height - keyboardRect.size.height - frame.size.height;
        textInputView.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height = self.view.frame.size.height - textInputView.frame.size.height - keyboardRect.size.height;
        
        bubbleTable.frame = frame;
    }];
    
    
    
    
}

- (void)keyboardDidHide:(NSNotification*)aNotification {
    CGPoint bottomOffset = CGPointMake(0, bubbleTable.contentSize.height - bubbleTable.bounds.size.height);
    [bubbleTable setContentOffset:bottomOffset animated:YES];
}

- (void)keyboardDidShow:(NSNotification*)aNotification {
    CGPoint bottomOffset = CGPointMake(0, bubbleTable.contentSize.height - bubbleTable.bounds.size.height);
    [bubbleTable setContentOffset:bottomOffset animated:YES];
}



- (void)keyboardWillHide:(NSNotification*)aNotification
{
    
	UIViewAnimationCurve curve = [[aNotification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    
    
	[UIView setAnimationCurve:curve];
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = textInputView.frame;
        frame.origin.y = self.view.frame.size.height - frame.size.height;
        textInputView.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height = self.view.frame.size.height -textInputView.frame.size.height;
        bubbleTable.frame = frame;
        
    }];
    
    
    
    
    
    
    
    
    
    
}

#pragma mark - Actions

- (IBAction)sayPressed:(id)sender
{
    bubbleTable.typingBubble = NSBubbleTypingTypeNobody;

    NSBubbleData *sayBubble = [NSBubbleData dataWithText:textField.text date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeMine];
    [bubbleData addObject:sayBubble];
    [bubbleTable reloadData];
    
    textField.text = @"";
    [textField resignFirstResponder];
}

@end
