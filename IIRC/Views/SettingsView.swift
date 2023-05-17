//
//  SettingsView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-17.
//

import SwiftUI

struct SettingsView: View {
	// MARK: - Variables
	@AppStorage("Show Server Messages") var showServerMessages: Bool = false
	@AppStorage("Default Nickname") var defaultNickname: String = ""
	@AppStorage("Keep Chat History") var keepChatHistory: Bool = false
	
	// MARK: - Body
    var body: some View {
		List{
			Toggle(isOn: $showServerMessages){
				Text("Show Server Connection Messages")
			}
			Toggle(isOn: $keepChatHistory){
				Text("Keep Chat History")
			}
			TextField(text: $defaultNickname){
				Text("Default Nickname")
			}
		}
			.navigationTitle("Settings")
			.navigationBarTitleDisplayMode(.inline)
    }
}
// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
