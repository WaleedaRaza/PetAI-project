import SwiftUI

// MARK: - Models
struct PetAIUser {
    var id: Int
    var email: String
    var pets: [PetAIPet]
    var badges: [String]
    var streak: Int
    var notificationPreferences: [String: Bool]
}

struct PetAIPet: Identifiable {
    let id = UUID()
    var name: String
    var species: String
    var breed: String
    var age: Int
    var personality: String
    var foodSource: String
    var favoritePark: String?
    var leashSource: String?
    var litterType: String?
    var waterProducts: String?
    var customMetrics: [CustomMetric]
    var favorites: [FavoriteProduct]
    var sharedFields: [String]
}

struct PetAIPost: Identifiable, Codable {
    let id = UUID()
    var title: String
    var description: String
    var timestamp: Date
    var user: String
    var petType: String
    var hasImage: Bool
    var source: String
    var subreddit: String?
    var permalink: String?
    var isRedditPost: Bool
    
    // Custom initializer for manual creation
    init(title: String, description: String, timestamp: Date, user: String, petType: String, hasImage: Bool, source: String, subreddit: String? = nil, permalink: String? = nil, isRedditPost: Bool = false) {
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.user = user
        self.petType = petType
        self.hasImage = hasImage
        self.source = source
        self.subreddit = subreddit
        self.permalink = permalink
        self.isRedditPost = isRedditPost
    }
    
    enum CodingKeys: String, CodingKey {
        case title
        case description = "selftext"
        case timestamp = "created_utc"
        case user = "author"
        case petType
        case hasImage
        case source
        case subreddit
        case permalink
        case isRedditPost
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        let timestampSeconds = try container.decodeIfPresent(Double.self, forKey: .timestamp) ?? 0
        timestamp = Date(timeIntervalSince1970: timestampSeconds)
        user = try container.decodeIfPresent(String.self, forKey: .user) ?? "Unknown"
        petType = try container.decodeIfPresent(String.self, forKey: .petType) ?? "General"
        hasImage = try container.decodeIfPresent(Bool.self, forKey: .hasImage) ?? false
        source = try container.decodeIfPresent(String.self, forKey: .source) ?? "Reddit"
        subreddit = try container.decodeIfPresent(String.self, forKey: .subreddit)
        permalink = try container.decodeIfPresent(String.self, forKey: .permalink)
        isRedditPost = try container.decodeIfPresent(Bool.self, forKey: .isRedditPost) ?? false
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(timestamp.timeIntervalSince1970, forKey: .timestamp)
        try container.encode(user, forKey: .user)
        try container.encode(petType, forKey: .petType)
        try container.encode(hasImage, forKey: .hasImage)
        try container.encode(source, forKey: .source)
        try container.encodeIfPresent(subreddit, forKey: .subreddit)
        try container.encodeIfPresent(permalink, forKey: .permalink)
        try container.encode(isRedditPost, forKey: .isRedditPost)
    }
}

struct TrackingMetric: Identifiable {
    let id = UUID()
    var name: String
    var value: String
    var timestamp: Date
}

struct CustomMetric: Identifiable {
    let id = UUID()
    var name: String
    var frequency: String
    var details: String
    var notify: Bool
    var dateRange: String?
}

struct FavoriteProduct: Identifiable {
    let id = UUID()
    var name: String
    var source: String
    var link: String
}

struct Product: Identifiable {
    let id = UUID()
    var name: String
    var price: Double
    var source: String
}

// MARK: - APIService
struct PetAIAPIService {
    private let baseURL = "http://localhost:3000"
    
    func fetchPosts(petType: String, query: String? = nil) async throws -> [PetAIPost] {
        var urlString = "\(baseURL)/api/forum/search?petType=\(petType.lowercased().addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        if let query = query, !query.isEmpty {
            urlString += "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // Log the raw JSON response
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON Response: \(jsonString)")
        } else {
            print("Could not convert data to string")
        }
        
        // Check HTTP status code
        if let httpResponse = response as? HTTPURLResponse {
            switch httpResponse.statusCode {
            case 400:
                throw NSError(domain: NSURLErrorDomain, code: -1011, userInfo: [NSLocalizedDescriptionKey: "Invalid search query. Please use pet-related terms like 'tank' or 'health'."])
            case 500:
                throw NSError(domain: NSURLErrorDomain, code: -1011, userInfo: [NSLocalizedDescriptionKey: "Server error. Please try again later."])
            case 200:
                break
            default:
                throw URLError(.badServerResponse)
            }
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            let posts = try decoder.decode([PetAIPost].self, from: data)
            return posts
        } catch {
            print("JSON Decoding Error: \(error)")
            throw error
        }
    }
}

// MARK: - Main App
@main
struct PetAIApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    @State private var isLoggedIn = false
    @State private var user = PetAIUser(id: 0, email: "", pets: [], badges: [], streak: 0, notificationPreferences: [:])
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoggedIn {
                    MainTabView(user: $user)
                } else {
                    WelcomeView(isLoggedIn: $isLoggedIn, user: $user)
                }
            }
            .background(isDarkMode ? Color.black : Color.white)
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    @Binding var isLoggedIn: Bool
    @Binding var user: PetAIUser
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignup = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Petpal.ai")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                Button("Login") {
                    user.email = email
                    user.badges.append("First Login")
                    user.streak += 1
                    isLoggedIn = true
                }
                .buttonStyle(RoundedButtonStyle())
                .disabled(email.isEmpty || password.isEmpty)
                Button("Sign Up") { showingSignup = true }
                    .foregroundColor(.accentColor)
                HStack {
                    Button("Google") { /* Google login */ }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: .red))
                    Button("Apple") { /* Apple login */ }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: isDarkMode ? .gray : .black))
                }
            }
            .padding()
            .background(isDarkMode ? Color.black : Color.white)
            .sheet(isPresented: $showingSignup) {
                SignupView(isLoggedIn: $isLoggedIn, user: $user)
            }
        }
    }
}

// MARK: - Signup View
struct SignupView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    @Binding var isLoggedIn: Bool
    @Binding var user: PetAIUser
    @State private var email = ""
    @State private var petName = ""
    @State private var species = "Dog"
    @State private var breed = ""
    @State private var age = ""
    @State private var personality = ""
    @State private var foodSource = ""
    @State private var favoritePark = ""
    @State private var leashSource = ""
    @State private var litterType = ""
    @State private var waterProducts = ""
    @State private var step = 1
    @State private var newPet: PetAIPet?
    
    let petTypes = ["Dog", "Cat", "Turtle", "Bird", "Fish", "Rabbit", "Hamster", "Guinea Pig", "Ferret"]
    
    var body: some View {
        NavigationView {
            Form {
                if step == 1 {
                    Section(header: Text("Your Info").foregroundColor(.primary)) {
                        TextField("Email", text: $email)
                    }
                    Button("Next") { step = 2 }
                        .buttonStyle(RoundedButtonStyle())
                        .disabled(email.isEmpty)
                } else if step == 2 {
                    Section(header: Text("Your Pet").foregroundColor(.primary)) {
                        TextField("Pet Name", text: $petName)
                        Picker("Species", selection: $species) {
                            ForEach(petTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        TextField("Breed", text: $breed)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                        TextField("Personality (e.g., Playful)", text: $personality)
                        TextField("Food Source (e.g., Chewy)", text: $foodSource)
                        if species == "Dog" {
                            TextField("Favorite Park", text: $favoritePark)
                            TextField("Leash Source (e.g., Chewy)", text: $leashSource)
                        } else if species == "Cat" {
                            TextField("Litter Type (e.g., Clumping)", text: $litterType)
                        } else if species == "Turtle" || species == "Fish" {
                            TextField("Water Products (e.g., Filter)", text: $waterProducts)
                        } else if species == "Bird" {
                            TextField("Cage Products (e.g., Perch)", text: $waterProducts)
                        } else if species == "Rabbit" || species == "Hamster" || species == "Guinea Pig" || species == "Ferret" {
                            TextField("Bedding Type (e.g., Pine)", text: $litterType)
                        }
                    }
                    Button("Add Pet") {
                        let pet = PetAIPet(
                            name: petName,
                            species: species,
                            breed: breed,
                            age: Int(age) ?? 0,
                            personality: personality,
                            foodSource: foodSource,
                            favoritePark: species == "Dog" ? favoritePark : nil,
                            leashSource: species == "Dog" ? leashSource : nil,
                            litterType: (species == "Cat" || species == "Rabbit" || species == "Hamster" || species == "Guinea Pig" || species == "Ferret") ? litterType : nil,
                            waterProducts: (species == "Turtle" || species == "Fish" || species == "Bird") ? waterProducts : nil,
                            customMetrics: [],
                            favorites: [],
                            sharedFields: ["name", "species", "age"]
                        )
                        newPet = pet
                        step = 3
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .disabled(petName.isEmpty)
                } else {
                    Section(header: Text("Add Another Pet?").foregroundColor(.primary)) {
                        Text("Added: \(newPet?.name ?? "") (\(newPet?.species ?? ""))")
                    }
                    Button("Add Another") {
                        user.pets.append(newPet!)
                        resetFields()
                        step = 2
                    }
                    .buttonStyle(RoundedButtonStyle())
                    Button("Complete Signup") {
                        user.email = email
                        user.pets.append(newPet!)
                        user.badges.append("New Pet Owner")
                        isLoggedIn = true
                    }
                    .buttonStyle(RoundedButtonStyle())
                }
            }
            .navigationTitle("Sign Up")
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
    
    func resetFields() {
        petName = ""
        species = "Dog"
        breed = ""
        age = ""
        personality = ""
        foodSource = ""
        favoritePark = ""
        leashSource = ""
        litterType = ""
        waterProducts = ""
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var user: PetAIUser
    
    var body: some View {
        TabView {
            FeedView(user: $user)
                .tabItem { Label("Feed", systemImage: "house.fill") }
            AskAIView(user: $user)
                .tabItem { Label("Ask AI", systemImage: "bubble.left.fill") }
            TrackingView(user: $user)
                .tabItem { Label("Tracking", systemImage: "chart.bar.fill") }
            DiscoverView(user: $user)
                .tabItem { Label("Discover", systemImage: "magnifyingglass") }
            ProfileView(user: $user)
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .background(isDarkMode ? Color.black : Color.white)
    }
}

// MARK: - Custom Button Style
struct RoundedButtonStyle: ButtonStyle {
    var backgroundColor: Color = .gray.opacity(0.2)
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(configuration.isPressed ? backgroundColor.opacity(0.8) : backgroundColor)
            .foregroundColor(.primary)
            .font(.system(size: 16, weight: .medium))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Feed View
struct FeedView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var user: PetAIUser
    @State private var posts: [PetAIPost] = []
    @State private var searchText = ""
    @State private var showingAddPost = false
    @State private var showingPetSpotlight = false
    @State private var selectedPetType = "All"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let petTypes = ["All", "Dog", "Cat", "Turtle", "Bird", "Fish", "Rabbit", "Hamster", "Guinea Pig", "Ferret"]
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                Picker("Pet Type", selection: $selectedPetType) {
                    ForEach(petTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                if isLoading {
                    ProgressView()
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                Button("Pet Spotlight") { showingPetSpotlight = true }
                    .buttonStyle(RoundedButtonStyle())
                List {
                    ForEach(posts) { post in
                        NavigationLink(destination: PostDetailView(post: post)) {
                            PostRow(post: post)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await fetchPosts()
                }
            }
            .navigationTitle("Feed")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddPost = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPost) {
                AddPostView(posts: $posts, user: $user)
            }
            .sheet(isPresented: $showingPetSpotlight) {
                PetSpotlightView()
            }
            .background(isDarkMode ? Color.black : Color.white)
            .task {
                await fetchPosts()
            }
            .onChange(of: selectedPetType) { _ in
                Task {
                    await fetchPosts()
                }
            }
            .onChange(of: searchText) { _ in
                Task {
                    await fetchPosts()
                }
            }
        }
    }
    
    func fetchPosts() async {
        isLoading = true
        errorMessage = nil
        do {
            let apiService = PetAIAPIService()
            let fetchedPosts = try await apiService.fetchPosts(petType: selectedPetType, query: searchText)
            posts = fetchedPosts
        } catch let error as NSError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load posts. Please try again."
        }
        isLoading = false
    }
}

// MARK: - Pet Spotlight View
struct PetSpotlightView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pet of the Day")
                .font(.title.bold())
                .foregroundColor(.primary)
            Image(systemName: "pawprint.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
            Text("Meet Max, a playful Labrador!")
                .font(.headline)
                .foregroundColor(.primary)
            Text("Max loves chasing balls and napping in the sun.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("View Profile") { /* Navigate to profile */ }
                .buttonStyle(RoundedButtonStyle())
        }
        .padding()
        .background(isDarkMode ? Color.black : Color.white)
        .cornerRadius(20)
    }
}

// MARK: - Post Row
struct PostRow: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    let post: PetAIPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if post.isRedditPost {
                    Image("reddit")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    Text(post.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(post.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            HStack {
                Text(post.user)
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Text(post.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Text("Source: \(post.source)")
                .font(.caption2)
                .foregroundColor(.gray)
            if post.hasImage {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 100)
            }
        }
        .padding()
        .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

// MARK: - Post Detail View
struct PostDetailView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    let post: PetAIPost
    @State private var comment = ""
    
    // Simulated Reddit replies
    let redditReplies = [
        "Great post! Thanks for sharing.",
        "Have you tried this approach?",
        "I had a similar issue, here’s what worked..."
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    if post.isRedditPost {
                        Image("reddit")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Text(post.title)
                        .font(.title)
                        .foregroundColor(.primary)
                }
                Text("By \(post.user) • \(post.timestamp, style: .relative)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if post.hasImage {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 200)
                }
                Text(post.description)
                    .foregroundColor(.primary)
                if post.isRedditPost, let permalink = post.permalink {
                    Button("View on Reddit") {
                        if let url = URL(string: "https://www.reddit.com\(permalink)") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                }
                Divider()
                Text(post.isRedditPost ? "Reddit Replies" : "Comments")
                    .font(.headline)
                    .foregroundColor(.primary)
                if post.isRedditPost {
                    ForEach(redditReplies, id: \.self) { reply in
                        Text(reply)
                            .padding(.vertical, 5)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(0..<3) { index in
                        Text("Comment \(index + 1): Great post!")
                            .padding(.vertical, 5)
                            .foregroundColor(.secondary)
                    }
                    TextField("Add a comment...", text: $comment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Post Comment") { /* Comment logic */ }
                        .buttonStyle(RoundedButtonStyle())
                    Button("Report Post") { /* Report logic */ }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: .red))
                }
            }
            .padding()
            .background(isDarkMode ? Color.black : Color.white)
        }
        .navigationTitle("Post Details")
        .background(isDarkMode ? Color.black : Color.white)
    }
}

// MARK: - Add Post View
struct AddPostView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var posts: [PetAIPost]
    @Binding var user: PetAIUser
    @State private var title = ""
    @State private var description = ""
    @State private var hasImage = false
    @State private var selectedPetType = "General"
    
    let petTypes = ["General", "Dog", "Cat", "Turtle", "Bird", "Fish", "Rabbit", "Hamster", "Guinea Pig", "Ferret"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Post Details").foregroundColor(.primary)) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Picker("Pet Type", selection: $selectedPetType) {
                        ForEach(petTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    Toggle("Include Image", isOn: $hasImage)
                }
                Button("Add") {
                    if !title.isEmpty && !description.isEmpty {
                        let newPost = PetAIPost(
                            title: title,
                            description: description,
                            timestamp: Date(),
                            user: user.email,
                            petType: selectedPetType,
                            hasImage: hasImage,
                            source: "Petpal Community",
                            isRedditPost: false
                        )
                        posts.append(newPost)
                        title = ""
                        description = ""
                        hasImage = false
                        selectedPetType = "General"
                    }
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .navigationTitle("New Post")
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search pet-related topics...", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// MARK: - Ask AI View
struct AskAIView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var user: PetAIUser
    @State private var question = ""
    @State private var selectedPrompt = "General Query"
    @State private var response = ""
    @State private var isLoading = false
    @State private var savedResponses: [String] = []
    let prompts = ["General Query", "My pet is doing ___", "My pet has these symptoms ___", "What’s best for my pet?"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Picker("Prompt", selection: $selectedPrompt) {
                    ForEach(prompts, id: \.self) { prompt in
                        Text(prompt).tag(prompt)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                .cornerRadius(12)
                
                TextField("Ask away...", text: $question)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Button(action: submitQuery) {
                    Text(isLoading ? "Asking..." : "Ask AI")
                }
                .buttonStyle(RoundedButtonStyle())
                .disabled(question.isEmpty || isLoading)
                
                if isLoading {
                    ProgressView()
                }
                
                if !response.isEmpty {
                    VStack(alignment: .leading) {
                        Text("AI: \(response)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        Button("Save Response") {
                            savedResponses.append(response)
                        }
                        .buttonStyle(RoundedButtonStyle())
                    }
                }
                
                if !savedResponses.isEmpty {
                    Text("Saved Responses")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ForEach(savedResponses, id: \.self) { savedResponse in
                        Text(savedResponse)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                            .cornerRadius(12)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Ask AI")
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
    
    func submitQuery() {
        isLoading = true
        let pet = user.pets.first ?? PetAIPet(name: "Unknown", species: "Unknown", breed: "", age: 0, personality: "", foodSource: "", favoritePark: nil, leashSource: nil, litterType: nil, waterProducts: nil, customMetrics: [], favorites: [], sharedFields: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if selectedPrompt != "General Query" && !question.contains(pet.species.lowercased()) && !question.contains("pet") {
                response = "I’m here to help with pet questions—try asking about \(pet.name) or pets in general!"
            } else {
                response = "For \(pet.name) (\(pet.species), \(pet.age) years old, \(pet.personality)): Here’s some advice based on ‘\(question)’..."
            }
            isLoading = false
        }
    }
}

// MARK: - Tracking View
struct TrackingView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var user: PetAIUser
    @State private var selectedPetIndex = 0
    @State private var showingCustomMetricForm = false
    @State private var metrics: [TrackingMetric] = [
        TrackingMetric(name: "Walk", value: "30 mins", timestamp: Date()),
        TrackingMetric(name: "Sleep", value: "8 hours", timestamp: Date().addingTimeInterval(-86400))
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if !user.pets.isEmpty {
                    Picker("Select Pet", selection: $selectedPetIndex) {
                        ForEach(0..<user.pets.count, id: \.self) { index in
                            Text(user.pets[index].name).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding()
                    
                    let pet = user.pets[selectedPetIndex]
                    List {
                        Section(header: Text("Standard Metrics").foregroundColor(.primary)) {
                            ForEach(metrics) { metric in
                                VStack(alignment: .leading) {
                                    Text(metric.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(metric.value)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text(metric.timestamp, style: .date)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        Section(header: Text("Custom Metrics").foregroundColor(.primary)) {
                            ForEach(pet.customMetrics) { metric in
                                VStack(alignment: .leading) {
                                    Text(metric.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Frequency: \(metric.frequency)")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("Details: \(metric.details)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    if let dateRange = metric.dateRange {
                                        Text("Range: \(dateRange)")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                    }
                                    Toggle("Notify", isOn: Binding(
                                        get: { metric.notify },
                                        set: { newValue in
                                            if let index = pet.customMetrics.firstIndex(where: { $0.id == metric.id }) {
                                                user.pets[selectedPetIndex].customMetrics[index].notify = newValue
                                            }
                                        }
                                    ))
                                }
                            }
                            Button("Add Custom Metric") {
                                showingCustomMetricForm = true
                            }
                            .buttonStyle(RoundedButtonStyle())
                        }
                    }
                    .sheet(isPresented: $showingCustomMetricForm) {
                        CustomMetricView(pet: $user.pets[selectedPetIndex])
                    }
                } else {
                    Text("No pets added yet.")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Tracking")
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
}

// MARK: - Custom Metric View
struct CustomMetricView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var pet: PetAIPet
    @State private var name = ""
    @State private var frequency = "Daily"
    @State private var details = ""
    @State private var notify = false
    @State private var dateRange = "Weekly"
    let frequencies = ["Daily", "Weekly", "Monthly"]
    let dateRanges = ["Weekly", "Monthly", "Yearly"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Metric Details").foregroundColor(.primary)) {
                    TextField("Metric Name (e.g., Weekly Medication)", text: $name)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                    TextField("Details (e.g., Calcium supplement)", text: $details)
                    Toggle("Notify", isOn: $notify)
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(dateRanges, id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                }
                Button("Save Metric") {
                    let newMetric = CustomMetric(name: name, frequency: frequency, details: details, notify: notify, dateRange: dateRange)
                    pet.customMetrics.append(newMetric)
                    name = ""
                    frequency = "Daily"
                    details = ""
                    notify = false
                    dateRange = "Weekly"
                }
                .buttonStyle(RoundedButtonStyle())
                .disabled(name.isEmpty)
            }
            .navigationTitle("Add Custom Metric")
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
}

// MARK: - Discover View
struct DiscoverView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var user: PetAIUser
    @State private var shoppingList: [Product] = [
        Product(name: "Dog Food", price: 29.99, source: "Chewy"),
        Product(name: "Cat Litter", price: 9.99, source: "Chewy"),
        Product(name: "Turtle Filter", price: 19.99, source: "Petco")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Shopping List")
                        .font(.headline)
                        .foregroundColor(.primary)
                    ForEach(shoppingList) { product in
                        HStack {
                            Image(systemName: "cart.fill")
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading) {
                                Text(product.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(String(format: "$%.2f • \(product.source)", product.price))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Buy") { /* Purchase logic */ }
                                .buttonStyle(RoundedButtonStyle())
                        }
                        .padding()
                        .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(isDarkMode ? Color.black : Color.white)
            }
            .navigationTitle("Discover")
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var user: PetAIUser
    @State private var selectedPetIndex = 0
    @State private var showingPetDetail = false
    @State private var showingEmergency = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Profile")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)
                    Text("Email: \(user.email)")
                        .foregroundColor(.primary)
                    Text("Streak: \(user.streak) days")
                        .foregroundColor(.primary)
                    Text("Badges: \(user.badges.joined(separator: ", "))")
                        .foregroundColor(.primary)
                    Divider()
                    Text("Pets")
                        .font(.headline)
                        .foregroundColor(.primary)
                    if !user.pets.isEmpty {
                        Picker("Select Pet", selection: $selectedPetIndex) {
                            ForEach(0..<user.pets.count, id: \.self) { index in
                                Text(user.pets[index].name).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                        PetProfileCard(pet: user.pets[selectedPetIndex], showingDetail: $showingPetDetail)
                    }
                    Button("Emergency Mode") { showingEmergency = true }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: .red))
                    Button(isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode") {
                        isDarkMode.toggle()
                    }
                    .buttonStyle(RoundedButtonStyle())
                    Button("Logout") { /* Logout logic */ }
                        .buttonStyle(RoundedButtonStyle(backgroundColor: .gray))
                }
                .padding()
                .background(isDarkMode ? Color.black : Color.white)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingPetDetail) {
                PetDetailView(pet: $user.pets[selectedPetIndex])
            }
            .sheet(isPresented: $showingEmergency) {
                EmergencyView()
            }
            .background(isDarkMode ? Color.black : Color.white)
        }
    }
}

// MARK: - Pet Profile Card
struct PetProfileCard: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    let pet: PetAIPet
    @Binding var showingDetail: Bool
    
    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(spacing: 20) {
                Text(pet.name)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.accentColor)
                Text("\(pet.species), \(pet.age) years old")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Personality: \(pet.personality)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(isDarkMode ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
            .cornerRadius(20)
        }
    }
}

// MARK: - Pet Detail View
struct PetDetailView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @Binding var pet: PetAIPet
    @State private var newFavoriteName = ""
    @State private var newFavoriteSource = ""
    @State private var newFavoriteLink = ""
    @State private var sharedFields: [String: Bool] = [
        "name": true, "species": true, "age": true, "breed": false,
        "personality": false, "foodSource": false, "favoritePark": false,
        "leashSource": false, "litterType": false, "waterProducts": false
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(pet.name)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                if sharedFields["species"] == true {
                    Text("\(pet.species), \(pet.breed), \(pet.age) years old")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                if sharedFields["personality"] == true {
                    Text("Personality: \(pet.personality)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                if sharedFields["foodSource"] == true {
                    Text("Food Source: \(pet.foodSource)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                if let favoritePark = pet.favoritePark, sharedFields["favoritePark"] == true {
                    Text("Favorite Park: \(favoritePark)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                if let leashSource = pet.leashSource, sharedFields["leashSource"] == true {
                    Text("Leash Source: \(leashSource)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                if let litterType = pet.litterType, sharedFields["litterType"] == true {
                    Text("Litter Type: \(litterType)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                if let waterProducts = pet.waterProducts, sharedFields["waterProducts"] == true {
                    Text("Water Products: \(waterProducts)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                Divider()
                Text("Pet's Favorites")
                    .font(.headline)
                    .foregroundColor(.primary)
                ForEach(pet.favorites) { favorite in
                    Text("\(favorite.name) from \(favorite.source) (\(favorite.link))")
                        .foregroundColor(.primary)
                }
                VStack {
                    TextField("Product Name", text: $newFavoriteName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Source (e.g., Chewy)", text: $newFavoriteSource)
                        .textFieldStyle(.roundedBorder)
                    TextField("Link", text: $newFavoriteLink)
                        .textFieldStyle(.roundedBorder)
                    Button("Add Favorite") {
                        let favorite = FavoriteProduct(name: newFavoriteName, source: newFavoriteSource, link: newFavoriteLink)
                        pet.favorites.append(favorite)
                        newFavoriteName = ""
                        newFavoriteSource = ""
                        newFavoriteLink = ""
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .disabled(newFavoriteName.isEmpty || newFavoriteSource.isEmpty)
                }
                Divider()
                Text("Shared Fields")
                    .font(.headline)
                    .foregroundColor(.primary)
                ForEach(sharedFields.keys.sorted(), id: \.self) { field in
                    Toggle(field.capitalized, isOn: Binding(
                        get: { sharedFields[field] ?? false },
                        set: { sharedFields[field] = $0 }
                    ))
                }
                Button("Save Shared Fields") {
                    pet.sharedFields = sharedFields.filter { $0.value }.map { $0.key }
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .padding()
            .background(isDarkMode ? Color.black : Color.white)
        }
        .navigationTitle("\(pet.name)'s Profile")
        .background(isDarkMode ? Color.black : Color.white)
    }
}

// MARK: - Emergency View
struct EmergencyView: View {
    @AppStorage("isDarkMode") private var isDarkMode = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Emergency Contacts")
                .font(.title.bold())
                .foregroundColor(.primary)
            Button("Call Vet") { /* Call logic */ }
                .buttonStyle(RoundedButtonStyle(backgroundColor: .red))
            Button("Poison Control") { /* Call logic */ }
                .buttonStyle(RoundedButtonStyle(backgroundColor: .red))
            Text("First-Aid Tips")
                .font(.headline)
                .foregroundColor(.primary)
            Text("• Stay calm\n• Check breathing\n• Apply pressure to wounds")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isDarkMode ? Color.black : Color.white)
        .cornerRadius(20)
    }
}
