//
//  ContentView.swift
//  Shared
//
//  Created by Steve on 29/12/2021.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @State var getTodayWeatherData = todayWeatherInfo()
    @State var todayMaxTemp = 0
    @State var todayMinTemp = 100
    let weatherIcon = ["Cloudy", "Cold", "Hot", "Raining", "Sunny intervals", "Sunny", "Thunder", "Windy"]
    let weatherIconNumber = [[60, 61, 76, 77, 83, 84, 85], [92, 93], [90, 91], [53, 54, 62, 63, 64], [51, 52, 76], [50, 70, 71, 72, 73, 74, 75], [65], [80, 81, 82]]
    @State var getNineDaysWeatherData = nineDaysWeatherInfo()
    
    @State var manager = CLLocationManager()
    @StateObject var locationManager = LocationManager()
    @State var ShowLocation = ""
    @State var ShowTemperature = 0
    
    let startColor = Color(red: 238/255, green: 231/255, blue: 203/255)
    let middleColor = Color(red: 57/255, green: 61/255, blue: 93/255, opacity: 0.76)
    let endColor = Color(red: 57/255, green: 61/255, blue: 93/255)
    
    var body: some View {
        VStack{
            Spacer()
            HStack {
                Spacer()
                HStack {
                    Button(action: {
                        find_place()
                        get_today_weather()
                        get_nine_days_weather()
                    }) {
                        Image(systemName: "goforward")
                            .font(.largeTitle)
                    }
                    .padding(.trailing, 15)

                }
            }
            HStack{
                VStack(alignment: .leading){
                    HStack {
                        Text(ShowLocation)
                            .font(.largeTitle)
                        Image(systemName: "location.fill")
                            .font(.title2)
                    }
                    Image(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60))
                        .resizable()
                        .frame(width: 200, height: 200)
                    Text(String(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60)))
                        .font(.largeTitle)
                    Text(String(ShowTemperature) + "℃")
                        .font(.title)
                }
                Spacer()
            }
            .padding(.bottom, 50)
            ScrollView(.horizontal) {
                HStack {
                    if getNineDaysWeatherData.weatherForecast?.count ?? 0 > 0 {
                        ForEach (getNineDaysWeatherData.weatherForecast!, id: \.self) { weatherData in
                            VStack(alignment: .leading) {
                                Text(String(date_format(weatherDate: weatherData.forecastDate ?? "20220101")))
                                    .font(.title)
                                Text(String(weatherData.forecastMaxtemp?.value ?? 0) + "℃")
                                    .font(.title2)
                                Text(String(weatherData.forecastMintemp?.value ?? 0) + "℃")
                                    .font(.title2)
                                VStack{
                                    Image(String(get_weather_name(weatherNumber: weatherData.ForecastIcon ?? 60)))
                                    Text(String(get_weather_name(weatherNumber: weatherData.ForecastIcon ?? 60)))
                                }
                            }
                            .padding(.trailing, 15)
                        }
                    }
                }
            }
            Spacer()
        }
        .onAppear(){
            self.manager.delegate = self.locationManager
            find_place()
            get_today_weather()
            get_nine_days_weather()
        }
        .padding(.leading, 20)
        .background(
            LinearGradient(gradient: Gradient(colors: [startColor, middleColor,endColor]), startPoint: .topTrailing, endPoint: .bottomLeading)
        )
        .ignoresSafeArea()
    }
    
    // today weather
    struct todayWeatherInfo: Codable {
        var icon: [Int]?
        var temperature: Temperature?
    }
    
    struct Temperature: Codable {
        var data: [TemperatureData]?
    }
    struct TemperatureData: Codable {
        var place: String?
        var value: Int?
        var unit: String?
    }
    
    func get_today_weather() {
        let address = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=rhrread&lang=en"
        if let url = URL(string: address) {
            // GET
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                else if let response = response as? HTTPURLResponse, let data = data {
                    print("Status code: \(response.statusCode)")
                    let decoder = JSONDecoder()

                    if let todayWeatherData = try? decoder.decode(todayWeatherInfo.self, from: data) {
                        DispatchQueue.main.async{
                            getTodayWeatherData = todayWeatherData
                            mach_temp_location()
                            find_max_min_temp()
                        }
                    }
                }
            }.resume()
        }
    }
    
    //match temperature with user location
    func mach_temp_location() {
        for i in getTodayWeatherData.temperature?.data ?? [] {
            if i.place == ShowLocation {
                ShowTemperature = i.value ?? 0
            }
        }
    }
    
    //find max and min temp
    func find_max_min_temp() {
        let dummy = getTodayWeatherData.temperature?.data ?? []
        for i in 0..<dummy.count {
            if dummy[i].value! > todayMaxTemp {
                todayMaxTemp = dummy[i].value!
            }
            if dummy[i].value! < todayMinTemp {
                todayMinTemp = dummy[i].value!
            }
        }
    }
    
    //weaher number to string
    func get_weather_name(weatherNumber: Int) -> String{
        var output = ""
        var out = false
        for i in 0..<weatherIconNumber.count {
            if out {
                break
            }
            for j in 0..<weatherIconNumber[i].count {
                if weatherIconNumber[i][j] == weatherNumber {
                    output = weatherIcon[i]
                    out = true
                    break
                }
            }
        }
        return output
    }
    
    // nine days weather
    struct nineDaysWeatherInfo: Codable, Hashable {
        var weatherForecast: [nineDaysWeatherData]?
    }
    
    struct nineDaysWeatherData: Codable, Hashable {
        var forecastDate: String?
        var forecastMaxtemp: tempData?
        var forecastMintemp: tempData?
        var ForecastIcon: Int?
    }
    
    struct tempData: Codable, Hashable {
        var value: Int?
        var unit: String?
    }
    
    func get_nine_days_weather() {
        let address = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=fnd&lang=tc"
        if let url = URL(string: address) {
            // GET
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                else if let response = response as? HTTPURLResponse, let data = data {
                    print("Status code: \(response.statusCode)")
                    let decoder = JSONDecoder()

                    if let nineDaysWeatherData = try? decoder.decode(nineDaysWeatherInfo.self, from: data) {
                        DispatchQueue.main.async{
                            getNineDaysWeatherData = nineDaysWeatherData
                        }
                    }
                }
            }.resume()
        }
    }
    
    func date_format(weatherDate: String) -> String{
        let today_m = "0" + String(Calendar.current.component(.month, from: Date()))
        let today_d = "0" + String(Calendar.current.component(.day, from: Date()))
        let dummy = weatherDate.suffix(4)
        let m = dummy.prefix(2)
        let d = dummy.suffix(2)
        var output = ""
        if (today_m == m) && (today_d == d) {
            output = "Today"
        }else{
            output = String(d + "/" + m)
        }
        
        return output
    }
    
    struct locationInfo: Codable {
        var data: [locationData]?
    }
    
    struct locationData: Codable {
        var place: String?
        var longitude: Double?
        var latitude: Double?
    }
    
    func find_place() {
        var getLocationData = locationInfo()
        if let path = Bundle.main.path(forResource: "location", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()

                if let locationData = try? decoder.decode(locationInfo.self, from: data) {
//                    DispatchQueue.main.async{
                        getLocationData = locationData
//                    }
                }
                
              } catch {
                   // handle error
              }
        }
        let userLocation = manager.location
//        let CCL_userLocation = CLLocation(latitude: userLocation?.latitude ?? 0.0, longitude: userLocation?.longitude ?? 0.0)
        let CLL_getLocationData = CLLocation(latitude: getLocationData.data?[0].latitude ?? 0.0, longitude: getLocationData.data?[0].longitude ?? 0.0)
        var distanceInMeters = CLL_getLocationData.distance(from: userLocation ?? CLLocation(latitude: 0, longitude: 0))
        
        for i in getLocationData.data ?? [] {
            let location = CLLocation(latitude: i.latitude ?? 0.0, longitude: i.longitude ?? 0.0)
            let dummy = location.distance(from: userLocation ?? CLLocation(latitude: 0, longitude: 0))
            if dummy < distanceInMeters {
                distanceInMeters = dummy
                ShowLocation = i.place ?? ""
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
