import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = ""
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    var useCelsius = true
    
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUI()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    @IBAction func onDegreesTypeSwitch(_ sender: UISwitch) {
        useCelsius = sender.isOn
        updateUI()
    }

    //MARK: - Networking
    /***************************************************************/
    private func getWeatherData(params: [String: String]) {
        var allParams = ["appid": APP_ID]
        allParams.merge(params) { (_, new) in new }
        
        Alamofire.request(WEATHER_URL, method: .get, parameters: allParams).responseJSON {
            (response) in
            if response.result.isSuccess {
                let weatherJSON: JSON = JSON(response.result.value!)
                self.updateWeatherData(json: weatherJSON)
            } else {
                print("Error: \(response.result.error!)")
                self.cityLabel.text = "Connection issues"
            }
        }
    }
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
    private func updateWeatherData(json: JSON) {
        let city = json["name"].stringValue
        self.weatherDataModel.city = city
        
        if let temp = json["main"]["temp"].double {
            self.weatherDataModel.temperature = temp
        } else {
            self.weatherDataModel.city = "City not found"
        }
        
        if let condition = json["weather"][0]["id"].int {
            self.weatherDataModel.condition = condition
            self.weatherDataModel.updateWeatherIcon(condition: condition)
        }
        
        updateUI()
    }
    
    private func convertFromKelvin(kelvin: Double) -> Double {
        let celsius = kelvin - 273.15
        return useCelsius ? celsius : celsius * (9/5) + 32
    }
    
    
    //MARK: - UI Updates
    /***************************************************************/
    private func updateUI() {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = "\(Int(convertFromKelvin(kelvin: weatherDataModel.temperature)))°"

        if weatherDataModel.weatherIconName != "" {
            weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
        }
    }
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        
        if location.horizontalAccuracy > 0 {
            locationManager.stopUpdatingLocation()
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            
            getWeatherData(params: ["lat": String(lat), "lon": String(lon)])
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        cityLabel.text = "Location unavailable"
        print(error)
    }
    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    func userEnteredANewCityName(city: String) {
        getWeatherData(params: ["q": city])
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let changeCityVC = segue.destination as! ChangeCityViewController
            changeCityVC.delegate = self
        }
    }
}


