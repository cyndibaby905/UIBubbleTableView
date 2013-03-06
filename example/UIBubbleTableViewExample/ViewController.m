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
#import "MessageInputView.h"
#import "NSString+MessagesView.h"
#import "ASIHTTPRequest.h"
#import "NSString+URLEncoding.h"
#define kConversationHistoryDiskPath @"kConversationHistoryDiskPath"

@interface ViewController ()<UITextViewDelegate,NSXMLParserDelegate>
{
    IBOutlet UIBubbleTableView *bubbleTable;
    
    IBOutlet MessageInputView *textField;
    BOOL isStartMessage_;
    NSMutableString *messageData_;
    NSMutableArray *archiveData;
    NSMutableArray *bubbleData;
}
@property (assign, nonatomic) CGFloat previousTextViewContentHeight;
- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)loadConversationHistory;
- (void)addMessageToSession:(NSBubbleData*) data needStore:(BOOL)stored;


@end

@implementation ViewController
@synthesize previousTextViewContentHeight;
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSBubbleData *heyBubble = [NSBubbleData dataWithText:@"Hey, halloween is soon" date:[NSDate dateWithTimeIntervalSinceNow:-300] type:BubbleTypeSomeoneElse];
    heyBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    heyBubble.needArchive = NO;

    NSBubbleData *photoBubble = [NSBubbleData dataWithImage:[UIImage imageNamed:@"halloween.jpg"] date:[NSDate dateWithTimeIntervalSinceNow:-290] type:BubbleTypeSomeoneElse];
    photoBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
    photoBubble.needArchive = NO;
    
    NSBubbleData *replyBubble = [NSBubbleData dataWithText:@"Wow.. Really cool picture out there. iPhone 5 has really nice camera, yeah?" date:[NSDate dateWithTimeIntervalSinceNow:-5] type:BubbleTypeMine];
    replyBubble.avatar = nil;
    replyBubble.needArchive = NO;
    
    if (![self readFromDisk]) {
        bubbleData = [[NSMutableArray alloc] initWithObjects:heyBubble,photoBubble,replyBubble, nil];
        archiveData = [[NSMutableArray alloc] init];
    }
    else {
        archiveData = [[NSMutableArray alloc] initWithArray:bubbleData];
    }
    
    
    
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
    
    
    [bubbleTable reloadData];
    
    textField.textView.delegate = self;
    textField.textView.returnKeyType = UIReturnKeyDone;
    [textField.sendButton addTarget:self action:@selector(sayPressed:) forControlEvents:UIControlEventTouchUpInside];
    
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

- (void)loadConversationHistory {
    
}

- (void)addMessageToSession:(NSBubbleData*) data needStore:(BOOL)stored {
    [bubbleData addObject:data];
    [bubbleTable reloadData];
    if (stored) {
        data.needArchive = YES;
        [archiveData addObject:data];
        [self writeToDisk];
    }else {
        data.needArchive = NO;

    }
}

- (BOOL)writeToDisk;
{
       
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc]
                                 initForWritingWithMutableData:data];
    [archiver encodeObject:archiveData forKey:kConversationHistoryDiskPath];
    [archiver finishEncoding];
    return [data writeToFile:[self diskPath] atomically:YES];
}

- (NSString *)diskPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    return [path stringByAppendingPathComponent:kConversationHistoryDiskPath];
}


- (BOOL)readFromDisk
{
    NSString *path = [self diskPath];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        return NO;
    }
    
    NSData *data = [[NSMutableData alloc]
                    initWithContentsOfFile:[self diskPath]];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc]
                                     initForReadingWithData:data];
    NSArray *array = [unarchiver decodeObjectForKey:kConversationHistoryDiskPath];
    [unarchiver finishDecoding];
    
    bubbleData = [[NSMutableArray alloc] initWithArray:array];
    return YES;
}






- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) || (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
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

#pragma mark - Text view delegate
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [textView becomeFirstResponder];
    self.previousTextViewContentHeight = textView.contentSize.height;
    [self scrollToBottomAnimated:YES];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self sayPressed:nil];
        return NO;
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text trimWhitespace].length) {
        textField.sendButton.enabled = YES;
    }
    else {
        textField.sendButton.enabled = NO;
    }
    CGFloat maxHeight = [MessageInputView maxHeight];
    CGFloat textViewContentHeight = textView.contentSize.height;
    CGFloat changeInHeight = textViewContentHeight - self.previousTextViewContentHeight;
    
    changeInHeight = (textViewContentHeight + changeInHeight >= maxHeight) ? 0.0f : changeInHeight;
    
    if(changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f animations:^{
            
            UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 0.0f, bubbleTable.contentInset.bottom + changeInHeight, 0.0f);
            bubbleTable.contentInset = insets;
            bubbleTable.scrollIndicatorInsets = insets;
            
            [self scrollToBottomAnimated:NO];
            
            CGRect inputViewFrame = textField.frame;
            textField.frame = CGRectMake(0.0f,
                                              inputViewFrame.origin.y - changeInHeight,
                                              inputViewFrame.size.width,
                                              inputViewFrame.size.height + changeInHeight);
        } completion:^(BOOL finished) {
            
        }];
        
        self.previousTextViewContentHeight = MIN(textViewContentHeight, maxHeight);
    }
    
    textField.sendButton.enabled = ([textView.text trimWhitespace].length > 0);
}


- (void)scrollToBottomAnimated:(BOOL)animated
{
    if (bubbleTable.contentSize.height >  bubbleTable.bounds.size.height) {
        CGPoint bottomOffset = CGPointMake(0, bubbleTable.contentSize.height - bubbleTable.bounds.size.height);
        [bubbleTable setContentOffset:bottomOffset animated:animated];
    }
    
}

#pragma mark - Keyboard events

- (void)keyboardWillShow:(NSNotification*)aNotification
{
    
    CGRect keyboardRect = [[aNotification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	UIViewAnimationCurve curve = [[aNotification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
	[UIView setAnimationCurve:curve];
    
    
    
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = textField.frame;
        frame.origin.y = self.view.frame.size.height - keyboardRect.size.height - frame.size.height;
        textField.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height = self.view.frame.size.height - textField.frame.size.height - keyboardRect.size.height;
        
        bubbleTable.frame = frame;
    }];
    
    
    
    
}

- (void)keyboardDidHide:(NSNotification*)aNotification {
    
}

- (void)keyboardDidShow:(NSNotification*)aNotification {
   
}



- (void)keyboardWillHide:(NSNotification*)aNotification
{
    
	UIViewAnimationCurve curve = [[aNotification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[aNotification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    
    
	[UIView setAnimationCurve:curve];
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = textField.frame;
        frame.size.height = 40.f;
        frame.origin.y = self.view.frame.size.height - frame.size.height;
        textField.frame = frame;
        
        frame = bubbleTable.frame;
        frame.size.height = self.view.frame.size.height -textField.frame.size.height;
        bubbleTable.frame = frame;
        
    }];
    
    
}

#pragma mark - Actions

- (IBAction)sayPressed:(id)sender
{
    NSString *inputtedData = [textField.textView.text trimWhitespace];
    if (inputtedData.length) {
        [self scrollToBottomAnimated:YES];
        textField.sendButton.enabled = NO;
        bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
        
        NSBubbleData *sayBubble = [NSBubbleData dataWithText:inputtedData date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeMine];
        bubbleTable.typingBubble = NSBubbleTypingTypeSomebody;
        [self addMessageToSession:sayBubble needStore:YES];
        

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.pandorabots.com/pandora/talk-xml?botid=9e6134cc8e345ec6&input=%@",[inputtedData encodedURLParameterString]]];
        
        textField.textView.text = @"";
        [textField.textView resignFirstResponder];
        
        __weak ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
        [request setCompletionBlock:^{
            // Use when fetching text data
            // Use when fetching binary data
            NSData *responseData = [request responseData];
            
            NSXMLParser *parser = [[NSXMLParser alloc] initWithData:responseData];
            [parser setDelegate:self];
            isStartMessage_ = NO;
            BOOL result = [parser parse];
            if (!result) {
                NSBubbleData *sayBubble = [NSBubbleData dataWithText:[[parser parserError] localizedDescription] date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeSomeoneElse];
                sayBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
                bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
                [self addMessageToSession:sayBubble needStore:NO];
                [self scrollToBottomAnimated:YES];
            }
            
        }];
        [request setFailedBlock:^{
            NSError *error = [request error];
            NSBubbleData *sayBubble = [NSBubbleData dataWithText:[error localizedDescription] date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeSomeoneElse];
            sayBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
            bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
            [self addMessageToSession:sayBubble needStore:NO];
            [self scrollToBottomAnimated:YES];
            
        }];
        [request startAsynchronous];
    }
    else {
        [textField.textView resignFirstResponder];
    }
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSLog(@"start Element %@",elementName);
    if ([elementName isEqualToString:@"that"] || [elementName isEqualToString:@"message"]) {
        isStartMessage_ = YES;
        messageData_ = [[NSMutableString alloc] init];

    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    NSLog(@"end Element %@",elementName);
    if ([elementName isEqualToString:@"that"] || [elementName isEqualToString:@"message"]) {
        isStartMessage_ = NO;
        NSBubbleData *sayBubble = [NSBubbleData dataWithText:messageData_ date:[NSDate dateWithTimeIntervalSinceNow:0] type:BubbleTypeSomeoneElse];
        sayBubble.avatar = [UIImage imageNamed:@"avatar1.png"];
        bubbleTable.typingBubble = NSBubbleTypingTypeNobody;
        [self addMessageToSession:sayBubble needStore:YES];
        [self scrollToBottomAnimated:YES];
        
    }}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    NSLog(@"string:%@",string);
    if (isStartMessage_) {
        [messageData_ appendString:string];
    }

}
@end
