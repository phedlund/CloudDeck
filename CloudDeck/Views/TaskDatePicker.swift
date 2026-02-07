//
//  TaskDatePicker.swift
//  CloudDeck
//
//  Created by Peter Hedlund on 2/6/26.
//

import SwiftUI

struct TaskDatePicker: View {
    @Binding var date: Date?
    @State private var showingPicker = false
    @State private var draftDate = Date()

    var body: some View {
        Label {
            HStack {
                if let date = date {
                    Text(date, style: .date)
                        .foregroundColor(.secondary)
                }
                Button {
                    draftDate = date ?? Date()
                    showingPicker.toggle()
                } label: {
                    Image(systemName: date == nil ? "plus" : "ellipsis.circle")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showingPicker) {
                    VStack(spacing: 0) {
                        DatePicker("", selection: $draftDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()

                        Divider()

                        HStack {
                            if date != nil {
                                Button("Clear Date", role: .destructive) {
                                    date = nil
                                    showingPicker = false
                                }
                                .buttonStyle(.bordered)
                            }

                            Spacer()

                            Button("Select") {
                                date = draftDate
                                showingPicker = false
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                    .frame(width: 320)
                    .presentationCompactAdaptation(.popover)
                }
            }
        } icon: {
            Image(systemName: "calendar")
        }
    }
}
