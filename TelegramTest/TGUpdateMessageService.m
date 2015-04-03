
#import "TGUpdateMessageService.h"

#import <MTProtoKit/MTIncomingMessage.h>

#import <MTProtoKit/MTProto.h>
#import <MTProtoKit/MTQueue.h>

#import "TGProccessUpdates.h"
#import "NSData+Extensions.h"
@interface TGUpdateMessageService ()
{
    MTQueue *_queue;
    
    int _sessionToken;
    bool _holdUpdates;
    
    bool _scheduledMessageProcessing;
    NSMutableArray *_messagesToProcess;
    
    bool _isNetworkAvailable;
    bool _isConnected;
    bool _isUpdatingConnectionContext;
    bool _isPerformingServiceTasks;
    TGProccessUpdates *_updateProccessor;
}

@end

@implementation TGUpdateMessageService

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _messagesToProcess = [[NSMutableArray alloc] init];
        _updateProccessor = [[TGProccessUpdates alloc] init];
    }
    return self;
}

-(void)drop {
    [_updateProccessor drop];
}

- (void)update {
    [_updateProccessor updateDifference];
}

- (TGProccessUpdates *)proccessor {
    return _updateProccessor;
}

- (void)reset:(bool)clearMessages
{
    _sessionToken++;
    _holdUpdates = false;
    
    if (clearMessages)
    {
        _scheduledMessageProcessing = false;
        _messagesToProcess = [[NSMutableArray alloc] init];
    }
    
    [_updateProccessor updateDifference];
}



- (void)mtProtoWillAddService:(MTProto *)mtProto
{
    _queue = [mtProto messageServiceQueue];
}

- (void)mtProtoNetworkAvailabilityChanged:(MTProto *)__unused mtProto isNetworkAvailable:(bool)isNetworkAvailable
{
    _isNetworkAvailable = isNetworkAvailable;
    
    [self updateHoldUpdates];
}

- (void)mtProtoConnectionStateChanged:(MTProto *)__unused mtProto isConnected:(bool)isConnected
{
    _isConnected = isConnected;
    [self updateHoldUpdates];
}

- (void)mtProtoConnectionContextUpdateStateChanged:(MTProto *)__unused mtProto isUpdatingConnectionContext:(bool)isUpdatingConnectionContext
{
    _isUpdatingConnectionContext = isUpdatingConnectionContext;
    
    [self updateHoldUpdates];
}

- (void)mtProtoServiceTasksStateChanged:(MTProto *)__unused mtProto isPerformingServiceTasks:(bool)isPerformingServiceTasks
{
    _isPerformingServiceTasks = isPerformingServiceTasks;
    
    [self updateHoldUpdates];
}

- (void)updateHoldUpdates
{
    bool holdUpdates = (!_isConnected) || _isUpdatingConnectionContext || _isPerformingServiceTasks;
    
    if (_holdUpdates != holdUpdates)
    {
        _holdUpdates = holdUpdates;
        
        if (!_holdUpdates)
        {
            _scheduledMessageProcessing = false;
            [self addMessageToQueueAndScheduleProcessing:nil];
        }
    }
}

- (void)mtProtoDidChangeSession:(MTProto *)__unused mtProto
{
    [self reset:true];
}

- (void)mtProtoServerDidChangeSession:(MTProto *)__unused mtProto firstValidMessageId:(int64_t)__unused firstValidMessageId otherValidMessageIds:(NSArray *)__unused otherValidMessageIds
{
    [self reset:false];
}

- (void)mtProto:(MTProto *)__unused mtProto receivedMessage:(MTIncomingMessage *)incomingMessage
{
    if ([incomingMessage.body isKindOfClass:[TLUpdates class]])
        [self addMessageToQueueAndScheduleProcessing:incomingMessage];
    

    if([incomingMessage.body isKindOfClass:[TL_rpc_result class]]) {
        
        
        if([[incomingMessage.body result] isKindOfClass:[TL_messages_sentMessage class]] ||
           [[incomingMessage.body result] isKindOfClass:[TL_gzip_packed class]] ||
           [[incomingMessage.body result] isKindOfClass:[TL_messages_affectedHistory class]] ||
           [[incomingMessage.body result] isKindOfClass:[TL_updates class]])
                [self addMessageToQueueAndScheduleProcessing:incomingMessage];
    }
}

- (void)addMessageToQueueAndScheduleProcessing:(MTIncomingMessage *)message
{
    if (message != nil)
        [_messagesToProcess addObject:message];
    
    if (!_scheduledMessageProcessing && !_holdUpdates)
    {
        _scheduledMessageProcessing = true;
        
        int currentSessionToken = _sessionToken;
        dispatch_async(_queue.nativeQueue, ^
        {
            _scheduledMessageProcessing = false;
            
            if (currentSessionToken != _sessionToken)
                return;
            
            NSArray *messages = [[NSArray alloc] initWithArray:_messagesToProcess];
            [_messagesToProcess removeAllObjects];
            [self processMessages:messages];
        });
    }
}

- (void)processMessages:(NSArray *)messages
{
    for (MTIncomingMessage *incomingMessage in messages)
    {
        [self processMessage:incomingMessage];
    }
    
}

- (void)processMessage:(MTIncomingMessage *)incomingMessage
{
    if([incomingMessage.body isKindOfClass:[TL_rpc_result class]]) {
        TL_rpc_result *rpc = incomingMessage.body;
        if([[rpc result] isKindOfClass:[TL_gzip_packed class]]) {
            rpc.result = [TLClassStore deserialize:[[rpc.result packed_data] gzipInflate]];
        }
        
        if([[rpc result] isKindOfClass:[TL_messages_sentMessage class]] ||
           [[rpc result] isKindOfClass:[TL_messages_affectedHistory class]] ||
           [[rpc result] isKindOfClass:[TL_updates class]] )
            [_updateProccessor addUpdate:[rpc result]];
    } else {
        [_updateProccessor addUpdate:[incomingMessage body]];
    }
}


@end
