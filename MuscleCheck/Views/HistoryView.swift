import SwiftUI
import SwiftData

struct HistoryView: View {
  @State private var showPicker = false
  
  let entries: [MuscleEntry]
  @StateObject private var viewModel: HistoryViewModel
    
  init(entries: [MuscleEntry]) {
    self.entries = entries
    _viewModel = StateObject(wrappedValue: HistoryViewModel.create(with: entries))
  }
  
  var body: some View {
    List {
      ForEach(viewModel.groupedEntries.keys.sorted(), id: \.self) { muscleName in
        Section(header: Text(muscleName).font(.headline)) {
          ForEach(viewModel.groupedEntries[muscleName] ?? [], id: \.self) { entry in
            Text(entry.dateCreated.formatted(date: .abbreviated, time: .omitted))
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Button {
          showPicker = true
        } label: {
          Text("Week \(viewModel.weekOf(viewModel.selectedDate)): \(viewModel.weekRangeString(for: viewModel.selectedDate))")
            .font(.headline.bold())
            .foregroundColor(Color("PrimaryButtonColor"))
        }
      }
    }
    .sheet(isPresented: $showPicker) {
      VStack {
        DatePicker("Selecciona una semana", selection: $viewModel.selectedDate, displayedComponents: .date)
          .datePickerStyle(.graphical)
          .padding()
        Button("Done") {
          showPicker = false
        }
        .padding()
      }
    }
  }
}
