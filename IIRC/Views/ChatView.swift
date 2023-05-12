//
//  ChatView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-12.
//

import SwiftUI

struct ChatView: View {
	// Import Var
	@ObservedObject var client: IRCClient
	var channel : String
	var nickname : String
	
	// Local Vars
	@State private var messageInput = ""
	@State private var messagesCount = 0
	@State private var isPinnedToBottom = true
	
    var body: some View {
		ScrollViewReader { scrollView in
			List {
				ForEach($client.messages, id: \.self) { message in
					Text(message.wrappedValue)
				}
				.onChange(of: client.messages.count) { _ in
					if client.messages.count > messagesCount && self.isPinnedToBottom {
						messagesCount = client.messages.count
						scrollView.scrollTo(client.messages[client.messages.count - 1], anchor: .center)
					}
				}
			}
			.scrollDismissesKeyboard(.interactively)
		}
		.safeAreaInset(edge: .bottom) {
			TextField("Type Message", text: $messageInput)
			.padding()
			.textFieldStyle(.automatic)
			.background(.ultraThinMaterial)
			.submitLabel(.send)
			.onSubmit {
				sendMessage()
			}
		}
		.toolbar{
			ToolbarItem(placement: .navigationBarTrailing) {
				Button(action:{
					isPinnedToBottom.toggle()
				}){
					Text("Pin")
				}
			}
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
