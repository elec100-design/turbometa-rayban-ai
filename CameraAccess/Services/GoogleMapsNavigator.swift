import Foundation
import CoreLocation
import UIKit

@Observable
final class GoogleMapsNavigator {
    static let shared = GoogleMapsNavigator()
    
    func navigate(to destination: String, from currentLocation: CLLocation? = nil) {
        var urlComponents = URLComponents(string: "comgooglemaps://")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: destination),
            URLQueryItem(name: "directionsmode", value: "driving")
        ]
        
        if let url = urlComponents?.url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // fallback: Apple Maps
            let appleMapsURL = URL(string: "https://maps.apple.com/?q=\(destination.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
            UIApplication.shared.open(appleMapsURL)
        }
    }
    
    func startVoiceNavigation(destination: String) async {
        print("🗺️ 네비게이션 시작: \(destination)")
        navigate(to: destination)
    }
}
