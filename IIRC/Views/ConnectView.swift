//
//  ConnectView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-12.
//

import SwiftUI

struct ConnectView: View {
	@Binding var server : String
	@Binding var port : String
	@Binding var nickname : String
	@Binding var channel : String
	@Binding var isConnected: Bool
	@ObservedObject var client: IRCClient
	
	@State var isFormFilled = false
	
    var body: some View {
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
				
				Button("Connect", action:{
					self.connect()
					self.isConnected = true
					
				})
				.foregroundColor(isFormFilled ? .blue : .gray)
				.disabled(!isFormFilled)
				
			}
		}
    }
	private func updateFormFilled() {
		isFormFilled = !server.isEmpty && !port.isEmpty && !nickname.isEmpty && !channel.isEmpty
	}
	
	
	
	func connect() {
		guard let portUInt = UInt16(port) else { return }
		client.connect(host: server, port: portUInt, nickname: nickname, channel: channel)
	}
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
		@State var blank = ""
		@State var isConnected = false
		ConnectView(server: $blank, port: $blank, nickname: $blank, channel: $blank, isConnected: $isConnected, client: IRCClient())
    }
}
