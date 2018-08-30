//
//  ChannelManager.swift
//  twiliochat
//
//  Created by TSD064 on 2018-07-20.
//  Copyright © 2018 Twilio. All rights reserved.
//

import Foundation

class ChannelManager {

    private var channels = [TCHChannel]()
    
//    private var channelDescriptors = [TCHChannelDescriptor]()
    
    func resetChannels() {
        channels = []
    }
    
    func numberOfChannels() -> Int {
        return channels.count
    }
    
    func channel(index: Int) -> TCHChannel? {
        guard index < channels.count else {
            return nil
        }
        
        return channels[index]
    }

    func sortChannels() {
        channels.sort { (left, right) -> Bool in
            
            guard left.dateUpdated != "" else {
                print("Channel with name \(left.friendlyName) has no updated updated as da†e")
                return false
            }
            
            return left.dateUpdatedAsDate >= right.dateUpdatedAsDate
        }
    }
    
    func remove(_ channel: TCHChannel) {
        let i = channels.index {
            channel.sid == $0.sid
        }
        
        if let i = i {
            channels.remove(at: i)
        }
    }
    
    func add(_ channel: TCHChannel) {
        if !channels.contains(channel) {
            
            if channel.friendlyName == "another channel" {
                print("added!~~~~~")
            }
            
            channels.append(channel)
            sortChannels()
        }
    }
    
    // TODO: add channelDescriptors
    
    func add(_ channelDescriptor: TCHChannelDescriptor, completion: @escaping () -> ()) {
        let doesChannelsContainSid = channels.contains(where: {
            $0.sid == channelDescriptor.sid
        })

        guard !doesChannelsContainSid else { return }
        
        channelDescriptor.channel { [weak self] (result, channel) in
            guard let channel = channel, result?.isSuccessful() ?? false else {
                print("Could not find channel for sid \(channelDescriptor.sid), friendlyName \(channelDescriptor.friendlyName)")
                return
            }
            
            self?.channels.append(channel)
            self?.sortChannels()
            
            completion()
        }
    }
}

//protocol HasFriendlyName {
//    var friendlyName: String! { get }
//}
//
//extension TCHChannel: HasFriendlyName {}
//extension TCHChannelDescriptor: HasFriendlyName {}
