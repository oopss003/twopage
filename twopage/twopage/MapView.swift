import SwiftUI
import NMapsMap
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

struct MapView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var stores: [Store] = []
    @State private var selectedStore: Store?
    @State private var sheetOpen: Bool = false

    var body: some View {
        ZStack {
            // 1. 네이티브 NaverMap
            NaverMapView(stores: $stores,
                         selectedStore: $selectedStore)
                .edgesIgnoringSafeArea(.all)
                // ⭐ onAppear 수정: 번들 ID 출력 + loadStores
                .onAppear {
                    // ⭐ 런타임 번들 ID 출력
                    print("⚠️ Bundle id at runtime:", Bundle.main.bundleIdentifier ?? "nil")
                    loadStores()
                }

            // 2. 내 위치 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if let loc = locationManager.currentLocation {
                            NotificationCenter.default.post(
                                name: .moveToLocation,
                                object: nil,
                                userInfo: ["lat": loc.latitude, "lng": loc.longitude]
                            )
                        } else {
                            locationManager.requestLocationPermission()
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }

            // 3. 하단 드로어(매장 리스트)
            VStack {
                Spacer()
                HandleBar()
                    .onTapGesture { withAnimation { sheetOpen.toggle() } }
                if sheetOpen {
                    StoreListView(stores: stores) { store in
                        selectedStore = store
                        sheetOpen = false
                    }
                    .transition(.move(edge: .bottom))
                }
            }

            // 4. 선택된 매장 Info Card
            if let store = selectedStore {
                InfoCard(store: store) {
                    selectedStore = nil
                }
                .transition(.move(edge: .bottom))
            }

            // 5. 마이페이지 버튼
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        if let url = URL(string: "https://inwave.ai.kr/profile.html") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .moveToLocation)) { note in
            if let ui = note.userInfo,
               let lat = ui["lat"] as? Double,
               let lng = ui["lng"] as? Double {
                NotificationCenter.default.post(
                    name: .centerMap,
                    object: nil,
                    userInfo: ["lat": lat, "lng": lng]
                )
            }
        }
    }

    // ------------------------------------------------------------
    // MARK: Firestore → 매장 로드
    private func loadStores() {
        let db = Firestore.firestore()
        db.collection("stores").getDocuments { snap, err in
            guard let docs = snap?.documents else { return }
            stores = docs.compactMap { d in
                let data = d.data()
                return Store(
                    id: d.documentID,
                    name: data["name"] as? String ?? "",
                    insta: data["insta"] as? String ?? "",
                    desc: data["desc"] as? String ?? "",
                    photoURL: data["photo"] as? String,
                    videoURL: data["vimeo"] as? String,
                    hashtags: data["hashtags"] as? [String] ?? [],
                    tel: data["tel"] as? String ?? "",
                    address: data["address"] as? String ?? "",
                    hours: data["hours"] as? [String: Any] ?? [:],
                    lat: Double("\(data["lat"] ?? "")") ?? 0,
                    lng: Double("\(data["lng"] ?? "")") ?? 0
                )
            }
        }
    }
}

// —————————————————————————————————————————————————————————
// MARK: - NaverMapView (UIViewRepresentable)
struct NaverMapView: UIViewRepresentable {
    @Binding var stores: [Store]
    @Binding var selectedStore: Store?

    func makeUIView(context: Context) -> NMFMapView {
        let mapView = NMFMapView()
        mapView.isZoomGestureEnabled = true
        mapView.addCameraDelegate(delegate: context.coordinator)
        context.coordinator.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: NMFMapView, context: Context) {
        context.coordinator.clearMarkers()
        stores.forEach { store in
            let coord = NMGLatLng(lat: store.lat, lng: store.lng)
            let marker = NMFMarker(position: coord)
            marker.captionText = store.name
            marker.mapView = uiView
            marker.touchHandler = { _ in
                DispatchQueue.main.async { selectedStore = store }
                return true
            }
            context.coordinator.markers.append(marker)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NMFMapViewCameraDelegate {
        var parent: NaverMapView
        weak var mapView: NMFMapView?
        var markers: [NMFMarker] = []

        init(_ parent: NaverMapView) { self.parent = parent }

        func clearMarkers() {
            markers.forEach { $0.mapView = nil }
            markers.removeAll()
        }

        func mapViewCameraIdle(_ mapView: NMFMapView) {}
    }
}

// —————————————————————————————————————————————————————————
// MARK: - HandleBar
struct HandleBar: View {
    var body: some View {
        Capsule()
            .fill(Color.gray.opacity(0.5))
            .frame(width: 40, height: 6)
            .padding(.bottom, 4)
    }
}

// MARK: - StoreListView
struct StoreListView: View {
    let stores: [Store]
    var onSelect: (Store) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(stores) { store in
                    HStack {
                        AsyncImage(url: URL(string: store.photoURL ?? "")) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)

                        VStack(alignment: .leading) {
                            Text(store.name).bold()
                            Text("@\(store.insta)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(radius: 2)
                    .onTapGesture { onSelect(store) }
                }
            }
            .padding()
        }
        .frame(height: UIScreen.main.bounds.height * 0.5)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
    }
}

// MARK: - InfoCard
struct InfoCard: View {
    let store: Store
    var onClose: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding([.top, .horizontal])

            HStack(spacing: 12) {
                AsyncImage(url: URL(string: store.photoURL ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 96, height: 96)
                .cornerRadius(14)

                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name).bold()
                    Text(store.hashtags.first.map { "#\($0)" } ?? "")
                        .font(.caption)
                    Text(store.tel).font(.caption2)
                }
                Spacer()
            }
            .padding()

            if let video = store.videoURL,
               let url = URL(string: "\(video)?autoplay=1") {
                Link("▶︎ 동영상 재생", destination: url)
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding()
        .transition(.move(edge: .bottom))
    }
}

// MARK: - LocationManager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocationCoordinate2D?
    private let mgr = CLLocationManager()

    override init() {
        super.init()
        mgr.delegate = self
        mgr.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocationPermission() {
        mgr.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse { mgr.requestLocation() }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last?.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error:", error)
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let moveToLocation = Self("moveToLocation")
    static let centerMap      = Self("centerMap")
}

// MARK: - RoundedCorner Shape
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    MapView()
}
