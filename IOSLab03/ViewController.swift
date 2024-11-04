//
//  ViewController.swift
//  IOSLab03
//
//  Created by Dharshini Gokul on 2024-11-03.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherConditionImage: UIImageView!
    
    @IBOutlet weak var temperatureLabel: UILabel!
    
    @IBOutlet weak var LocationLabel: UILabel!
    
    @IBOutlet weak var tempToggle: UISwitch!
    
    @IBOutlet weak var wetherConditionLabel: UILabel!
    
    
    var currentWeather: Weather?
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        displayImage(name: "cloud.sun.rain", colors: [.systemCyan, .systemOrange])
        
        // Set up location manager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        searchTextField.delegate = self
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: textField.text)
        return true
    }
    
    private func displayImage(name: String, colors: [UIColor]) {
        let config = UIImage.SymbolConfiguration(paletteColors: colors)
        weatherConditionImage.preferredSymbolConfiguration = config
        weatherConditionImage.image = UIImage(systemName: name)
    }
    
    @IBAction func onLocationTapped(_ sender: UIButton) {
        locationManager.requestLocation()
    }
    
    @IBAction func onSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    @IBAction func onToggleSwitch(_ sender: UISwitch) {
        displayTemp(isFahrenheit: sender.isOn)
    }
    
    private func displayTemp(isFahrenheit: Bool) {
        guard let weather = currentWeather else { return }
        
        if isFahrenheit {
            temperatureLabel.text = "\(weather.temp_f) °F"
        } else {
            temperatureLabel.text = "\(weather.temp_c) °C"
        }
    }
    
    private func loadWeather(search: String?) {
        guard let search = search else { return }
        guard let url = getURL(query: search) else {
            print("Could not get URL")
            return
        }
        fetchWeatherData(from: url)
    }
    
    private func loadWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        guard let url = getURL(query: "\(latitude),\(longitude)") else {
            print("Could not get URL")
            return
        }
        fetchWeatherData(from: url)
    }
    
    private func fetchWeatherData(from url: URL) {
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            guard error == nil, let data = data else {
                print("Error: \(error?.localizedDescription ?? "No error description")")
                return
            }
            if let weatherResponse = self.parseJson(data: data) {
                DispatchQueue.main.async {
                    self.LocationLabel.text = weatherResponse.location.name
                    self.currentWeather = weatherResponse.current
                    self.displayTemp(isFahrenheit: self.tempToggle.isOn)
                    self.wetherConditionLabel.text = weatherResponse.current.condition.text
                    self.updateWeatherImage(conditionCode: weatherResponse.current.condition.code)
                }
            }
        }
        dataTask.resume()
    }

    private func getURL(query: String) -> URL? {
        
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "efe5c9ad056a42c6a89200316240311"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        print(url)
        
        return URL(string: url)
    }
    
    private func parseJson(data: Data) -> WeatherResponse? {
        //decode the data
        let decoder = JSONDecoder()
        
        var weather: WeatherResponse?
        do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error Decoding")
        }
        return weather
    }
    
    private func updateWeatherImage(conditionCode: Int) {
        var symbolName: String
        var colors: [UIColor]
        
        switch conditionCode {
        case 1000:
            symbolName = "sun.max"
            colors = [.systemYellow, .systemOrange]
        case 1003:
            symbolName = "cloud.sun"
            colors = [.systemCyan, .systemYellow]
        case 1006:
            symbolName = "cloud"
            colors = [.systemCyan, .systemCyan]
        case 1009:
            symbolName = "smoke"
            colors = [.systemCyan, .systemCyan]
        case 1030:
            symbolName = "cloud.fog"
            colors = [.systemCyan, .systemCyan]
        case 1063:
            symbolName = "cloud.rain"
            colors = [.systemCyan, .systemCyan]
        case 1066:
            symbolName = "cloud.snow"
            colors = [.systemCyan, .systemTeal]
        case 1069:
            symbolName = "cloud.sleet"
            colors = [.systemTeal, .systemCyan]
        case 1087:
            symbolName = "cloud.bolt"
            colors = [.systemYellow, .systemCyan]
        default:
            symbolName = "cloud"
            colors = [.systemCyan, .systemCyan]
        }
        
        displayImage(name: symbolName, colors: colors)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            loadWeather(latitude: latitude, longitude: longitude)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                print("Location services are denied.")
            case .locationUnknown:
                print("Location data is currently unavailable.")
            default:
                print("An unknown error occurred.")
            }
        }
    }
}

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let condition: WeatherCondition
}

struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}
