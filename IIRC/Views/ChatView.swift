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
	//Local Vars
	@State private var messageIn = ""
	
    var body: some View {
		VStack {
			List {
				ForEach($client.messages, id: \.self) { message in
					Text(message.wrappedValue)
				}
			}.padding(.top, 0)
			
			Section {
				HStack {
					TextField("Message", text: $messageIn)
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
		client.sendChatMessage(messageIn, to: channel)
		messageIn = ""
	}
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
		@State var blank = ""
		ChatView(client: IRCClient() , channel: blank)
    }
}
