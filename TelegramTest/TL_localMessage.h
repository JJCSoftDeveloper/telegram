//
//  TL_localMessage.h
//  Telegram P-Edition
//
//  Created by keepcoder on 10.02.14.
//  Copyright (c) 2014 keepcoder. All rights reserved.
//

#import "MTProto.h"
#import "TL_conversation.h"
#import "TGMessageHole.h"
#import "TGMessageGroupHole.h"
@interface TL_localMessage : TL_message

typedef enum {
    MessageOutStateSend = 0,
    MessageOutStateSent = 1,
    MessageOutStateError = 2
} MessageOutState;

+(TL_localMessage *)createWithN_id:(int)n_id flags:(int)flags from_id:(int)from_id to_id:(TLPeer *)to_id fwd_from:(TLMessageFwdHeader *)fwd_from reply_to_msg_id:(int)reply_to_msg_id date:(int)date message:(NSString *)message media:(TLMessageMedia *)media fakeId:(int)fakeId randomId:(long)randomId reply_markup:(TLReplyMarkup *)reply_markup entities:(NSMutableArray *)entities views:(int)views via_bot_id:(int)via_bot_id edit_date:(int)edit_date isViewed:(BOOL)isViewed state:(DeliveryState)state;

+(TL_localMessage *)createWithN_id:(int)n_id flags:(int)flags from_id:(int)from_id to_id:(TLPeer *)to_id fwd_from:(TLMessageFwdHeader *)fwd_from reply_to_msg_id:(int)reply_to_msg_id date:(int)date message:(NSString *)message media:(TLMessageMedia *)media fakeId:(int)fakeId randomId:(long)randomId reply_markup:(TLReplyMarkup *)reply_markup entities:(NSMutableArray *)entities views:(int)views via_bot_id:(int)via_bot_id edit_date:(int)edit_date state:(DeliveryState)state pts:(int)pts isViewed:(BOOL)isViewed;


@property (nonatomic,assign) int fakeId;
@property (nonatomic,assign) long randomId;
@property (nonatomic,assign) int pts;
@property (nonatomic,assign) DeliveryState dstate;

@property (nonatomic,assign,getter=isViewed) BOOL viewed;
@property (nonatomic,copy) dispatch_block_t didChangedDeliveryState;


@property (nonatomic,assign) int fwd_from_id_old;
@property (nonatomic,strong) TLPeer *fwd_from_id_old_object;
@property (nonatomic,assign) int fwd_date_old;

@property (nonatomic,assign,getter=isInvalidate) BOOL invalidate;

@property (nonatomic,strong) TGMessageHole *hole;

@property (nonatomic,strong) TLUser *via_bot_user;



-(NSUserNotification *)userNotification;
@property (nonatomic, strong) TL_localMessage *replyMessage;

-(void)save:(BOOL)updateConversation;
-(void)saveViews;

-(BOOL)canEdit;
-(BOOL)canDeleteForAll;
+(TL_localMessage *)convertReceivedMessage:(TLMessage *)msg;
+(void)convertReceivedMessages:(NSMutableArray *)messages;

-(long)channelMsgId;
long channelMsgId(int msg_id, int peer_id);
-(int)peer_id;
-(TLPeer *)peer;
-(TLChat *)chat;
-(BOOL)isImportantMessage;
-(BOOL)isChannelMessage;
-(BOOL)n_out;
-(BOOL)unread;
-(BOOL)readedContent;
-(BOOL)isMentioned;

-(BOOL)isFake;

-(id)fwdObject;

- (TL_conversation *)conversation;
-(int)filterType;

-(TLUser *)fromUser;


@end
