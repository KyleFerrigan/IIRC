//
//  ChatView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-12.
//

import SwiftUI

struct ChatView: View {
	//Import Var
	@ObservedObject var client: IRCClient
	var channel : String
	var nickname : String
	
	//Local Vars
	@State private var messageInput = ""
	
    var body: some View {
		VStack {
			ScrollViewReader { scrollView in
				List {
					ForEach($client.messages, id: \.self) { message in
						Text(message.wrappedValue)
					}
				}
			}
			Section {
				HStack {
					TextField("Message", text: $messageInput)
						.disableAutocorrection(true)
						.textFieldStyle(RoundedBorderTextFieldStyle())
					Button("Send", action: sendMessage)
				}
			}
			.padding(.horizontal)
			.padding(.bottom)
		}
    }
	func sendMessage() {
		client.sendChatMessage(messageInput, to: channel)
		client.messages.append((self.nickname + ": " + self.messageInput)) // So you can see your own messages
		messageInput = ""
	}
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
		@State var blank = ""
		ChatView(client: IRCClient() , channel: blank, nickname: "Tester")
    }
}
