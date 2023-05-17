//
//  ContentView.swift
//  IIRC
//
//  Created by Triferrous on 2023-05-11.
//

import SwiftUI

struct MainView: View {

	// MARK: - Body
	var body: some View {
	NavigationView{
			ConnectView()
		
			.toolbar{
				ToolbarItem(placement: .navigationBarTrailing) {
					NavigationLink("Settings", destination: SettingsView())
				}
			}
		.navigationTitle("IIRC")
		.navigationBarTitleDisplayMode(.inline)
		}
	}
}

// MARK: - Preview
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
