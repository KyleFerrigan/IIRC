//
//  ContentView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//

import SwiftUI

struct ContentView: View {
	@State private var server = ""
	@State private var port = ""
	@State private var nickname = ""
	@State private var channel = ""
	@State private var message = ""
	
	@State private var isFormFilled = false
	
	@ObservedObject private var client = IRCClient()
	
	var body: some View {
		VStack {
				List{
					Section(header: Text("Connection")) {
						TextField("Server", text: $server)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.onChange(of: server) { _ in updateFormFilled() }
						TextField("Port", text: $port)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.keyboardType(.numberPad)
							.onChange(of: port) { _ in updateFormFilled() }
						TextField("Nickname", text: $nickname)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.onChange(of: nickname) { _ in updateFormFilled() }
						TextField("Channel", text: $channel)
							.disableAutocorrection(true)
							.autocapitalization(.none)
							.onChange(of: channel) { _ in updateFormFilled() }
						
						Button("Connect", action: connect)
							.foregroundColor(isFormFilled ? .blue : .gray)
							.disabled(!isFormFilled)
					}
				}
				List {
					ForEach(client.messages, id: \.self) { message in
						Text(message)
					}
				}.padding(.top, 0)
				
				Section {
					HStack {
						TextField("Message", text: $message)
							.disableAutocorrection(true)
							.textFieldStyle(RoundedBorderTextFieldStyle())
						Button("Send", action: sendMessage)
					}
				}
				.padding(.horizontal)
			}
		
	}
	
	private func updateFormFilled() {
		isFormFilled = !server.isEmpty && !port.isEmpty && !nickname.isEmpty && !channel.isEmpty
	}
	
	func sendMessage() {
		client.sendChatMessage(message, to: channel)
		message = ""
	}
	
	func connect() {
		guard let portUInt = UInt16(port) else { return }
		client.connect(host: server, port: portUInt, nickname: nickname, channel: channel)
	}
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
