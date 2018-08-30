import UIKit

// Need this so that the channels (NSMutableOrderedSet) will only display unique channels
//extension TCHChannelDescriptor {
//    override open func isEqual(_ object: Any?) -> Bool {
//        switch object {
//        case let descriptor as TCHChannelDescriptor:
//            return sid.lowercased() == descriptor.sid.lowercased() && friendlyName.lowercased() == descriptor.friendlyName.lowercased()
//        case let channel as TCHChannel:
//            return sid.lowercased() == channel.sid.lowercased() && friendlyName.lowercased() == channel.friendlyName.lowercased()
//        default:
//            print("ERROR: Could not cast")
//            return false
//        }
//    }
//}
//
//extension TCHChannel {
//    override open func isEqual(_ object: Any?) -> Bool {
//        switch object {
//        case let descriptor as TCHChannelDescriptor:
//            return sid.lowercased() == descriptor.sid.lowercased() && friendlyName.lowercased() == descriptor.friendlyName.lowercased()
//        case let channel as TCHChannel:
//            return sid.lowercased() == channel.sid.lowercased() && friendlyName.lowercased() == channel.friendlyName.lowercased()
//        default:
//            print("ERROR: Could not cast")
//            return false
//        }
//    }
//}

class ChannelAccessManager: NSObject {
    static let sharedManager = ChannelAccessManager()
    
    static let defaultChannelUniqueName = "general"
    static let defaultChannelName = "General Channel"
    
    weak var delegate: MenuViewController? // TODO: Refactor
    
    var channelManager = ChannelManager()
    
    //    var channels: NSMutableOrderedSet? // TCHChannelDescriptor type  & TCHChannel ???
    
    var channelsList: TCHChannels?
    var generalChannel: TCHChannel!
    
    override init() {
        super.init()
        //        channels = NSMutableOrderedSet()
    }
    
    // MARK: - General channel
    
    func joinGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
        
        let uniqueName = ChannelAccessManager.defaultChannelUniqueName
        if let channelsList = self.channelsList {
            channelsList.channel(withSidOrUniqueName: uniqueName) { result, channel in
                self.generalChannel = channel
                
                if self.generalChannel != nil {
                    self.joinGeneralChatRoomWithUniqueName(name: nil, completion: completion)
                } else {
                    self.createGeneralChatRoomWithCompletion { succeeded in
                        if (succeeded) {
                            self.joinGeneralChatRoomWithUniqueName(name: uniqueName, completion: completion)
                            return
                        }
                        
                        completion(false)
                    }
                }
            }
        }
    }
    
    func joinGeneralChatRoomWithUniqueName(name: String?, completion: @escaping (Bool) -> Void) {
        generalChannel.join { result in
            if ((result?.isSuccessful())! && name != nil) {
                self.setGeneralChatRoomUniqueNameWithCompletion(completion: completion)
                return
            }
            completion((result?.isSuccessful())!)
        }
    }
    
    func createGeneralChatRoomWithCompletion(completion: @escaping (Bool) -> Void) {
        let channelName = ChannelAccessManager.defaultChannelName
        let options:[NSObject : AnyObject] = [
            TCHChannelOptionFriendlyName as NSObject: channelName as AnyObject,
            TCHChannelOptionType as NSObject: TCHChannelType.public.rawValue as AnyObject
        ]
        channelsList!.createChannel(options: options) { result, channel in
            if (result?.isSuccessful())! {
                self.generalChannel = channel
            }
            completion((result?.isSuccessful())!)
        }
    }
    
    func setGeneralChatRoomUniqueNameWithCompletion(completion:@escaping (Bool) -> Void) {
        generalChannel.setUniqueName(ChannelAccessManager.defaultChannelUniqueName) { result in
            completion((result?.isSuccessful())!)
        }
    }
    
    // MARK: - Populate channels
    
    //    private func hasChannelSid(sid: String) -> Bool {
    //        return channels?.contains(where: { channelOrDescriptor in
    //            switch channelOrDescriptor {
    //            case let descriptor as TCHChannelDescriptor:
    //                return sid == descriptor.sid
    //            case let channel as TCHChannel:
    //                return sid == channel.sid
    //            default:
    //                print("MAJOR ERROR. Can't cast")
    //                return false
    //            }
    //        }) ?? false
    //    }
    //
    func populateChannels() {
        
        channelManager.resetChannels()
        //        channels = NSMutableOrderedSet()
        
        channelsList?.userChannelDescriptors { [weak self] result, paginator in
            
            paginator!.items().forEach {
                
                self?.channelManager.add($0) {
                    if self?.delegate != nil {
                        self?.delegate!.reloadChannelList()
                    }
                    
                }
            }
        }
        
        channelsList?.publicChannelDescriptors { [weak self] result, paginator in
            paginator!.items().forEach {
                
                self?.channelManager.add($0) {
                    
                    if self?.delegate != nil {
                        self?.delegate!.reloadChannelList()
                    }
                    
                }
            }
        }
    }
    
    //    func sortChannels() {
    //        let sortSelector = #selector(NSString.localizedCaseInsensitiveCompare(_:))
    //        let descriptor = NSSortDescriptor(key: "friendlyName", ascending: true, selector: sortSelector)
    //        channels!.sort(using: [descriptor])
    //    }
    //
    // MARK: - Create channel
    
    func createChannelWithName(name: String, completion: @escaping (Bool, TCHChannel?) -> Void) {
        if (name == ChannelAccessManager.defaultChannelName) {
            completion(false, nil)
            return
        }
        
        let channelOptions:[NSObject : AnyObject] = [
            TCHChannelOptionFriendlyName as NSObject: name as AnyObject,
            TCHChannelOptionType as NSObject: TCHChannelType.public.rawValue as AnyObject
        ]
        UIApplication.shared.isNetworkActivityIndicatorVisible = true;
        self.channelsList?.createChannel(options: channelOptions) { result, channel in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false;
            completion((result?.isSuccessful())!, channel)
        }
    }
}

// MARK: - TwilioChatClientDelegate
extension ChannelAccessManager : TwilioChatClientDelegate {
    func chatClient(_ client: TwilioChatClient!, channelAdded channel: TCHChannel!) {
        DispatchQueue.main.async {
            
            self.channelManager.add(channel)
        
//            if self.channels != nil {
//                self.channels!.add(channel)
//                self.sortChannels()
//            }
            self.delegate?.chatClient(client, channelAdded: channel)
        }
    }
    
    func chatClient(_ client: TwilioChatClient!, channelChanged channel: TCHChannel!) {
        self.delegate?.chatClient(client, channelChanged: channel)
    }
    
    func chatClient(_ client: TwilioChatClient!, channelDeleted channel: TCHChannel!) {
        DispatchQueue.main.async {
//            if self.channels != nil {
//                self.channels?.remove(channel)
//            }
            self.channelManager.remove(channel)
            self.delegate?.chatClient(client, channelDeleted: channel)
        }
    }
    
    func chatClient(_ client: TwilioChatClient!, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
    }
}

