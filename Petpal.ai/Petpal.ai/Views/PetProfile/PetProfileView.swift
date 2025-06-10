import SwiftUI

struct PetProfileView: View {
    @State private var petName: String = ""
    @State private var petAge: String = ""
    @State private var petSpecies: String = ""
    @State private var petBreed: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pet Information")) {
                    TextField("Pet Name", text: $petName)
                    TextField("Age", text: $petAge)
                        .keyboardType(.numberPad)
                    TextField("Species", text: $petSpecies)
                    TextField("Breed", text: $petBreed)
                }
                Button(action: {
                    savePetProfile()
                }) {
                    Text("Save Profile")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Create Pet Profile")
        }
    }

    func savePetProfile() {
        let petData = [
            "name": petName,
            "age": petAge,
            "species": petSpecies,
            "breed": petBreed
        ]
        // TODO: Send to backend via API
        print("Saving pet profile: \(petData)")
    }
}

struct PetProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PetProfileView()
    }
}
