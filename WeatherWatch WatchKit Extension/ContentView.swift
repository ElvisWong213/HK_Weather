//
//  ContentView.swift
//  WeatherWatch WatchKit Extension
//
//  Created by Steve on 10/2/2022.
//

import SwiftUI
import CoreLocation


struct ContentView: View {
    @State var getTodayWeatherData = DataStruct.todayWeatherInfo()
    @State var getMaxAndMinTempData: [String] = ["--", "--"]
    @State var todayMaxTemp = 0
    @State var todayMinTemp = 100
    let weatherIcon = ["Cloudy", "Cold", "Hot", "Raining", "Sunny intervals", "Sunny", "Thunder", "Windy"]
    let weatherIconNumber = [[60, 61, 76, 77, 83, 84, 85], [92, 93], [90, 91], [53, 54, 62, 63, 64], [51, 52, 76], [50, 70, 71, 72, 73, 74, 75], [65], [80, 81, 82]]
    @State var getNineDaysWeatherData = DataStruct.nineDaysWeatherInfo()
    
    @State var manager = CLLocationManager()
    @StateObject var locationManager = LocationManager()
    @State var ShowLocation = ""
    @State var ShowTemperature = "--"
    
    //update timer
    let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        ScrollView {
            HStack{
                VStack(alignment: .leading){
                    HStack {
                        Text(ShowLocation)
                        Image(systemName: "location.fill")
                    }
                    Image(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60))
                        .resizable()
                        .frame(width: 60, height: 60)
                    Text(String(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60)))
                    Text(String(ShowTemperature) + "℃")
                    Text(String(getTodayWeatherData.humidity?.data?[0].value ?? 0) + "%")
                        .font(.footnote)
                        
                }
                Spacer()
            }
            .padding([.leading, .bottom, .trailing])
            VStack {
                if getMaxAndMinTempData.count >= 2 {
                    HStack {
                        Image(String(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60)))
                            .resizable()
                            .frame(width: 50, height: 50)
                        VStack(alignment: .leading) {
                            Text("Today")
                            HStack{
                                Text(String(getMaxAndMinTempData[1]) + "℃")
                                    .foregroundColor(Color.red)
                                Spacer()
                                Text(String(getMaxAndMinTempData[0]) + "℃")
                                    .foregroundColor(Color.blue)
                            }
                        }
                        .padding(.leading)
                        Spacer()
                    }
                    .padding(.vertical)
                }
                if getNineDaysWeatherData.weatherForecast?.count ?? 0 > 0 {
                    ForEach (getNineDaysWeatherData.weatherForecast!, id: \.self) { weatherData in
                        if date_format(weatherDate: weatherData.forecastDate ?? "Today") != "Today" {
                            HStack() {
                                Image(String(get_weather_name(weatherNumber: weatherData.ForecastIcon ?? 60)))
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                VStack(alignment: .leading) {
                                    Text(String(date_format(weatherDate: weatherData.forecastDate ?? "20220101")))
                                    HStack{
                                        Text(String(weatherData.forecastMaxtemp?.value ?? 0) + "℃")
                                            .foregroundColor(Color.red)
                                        Spacer()
                                        Text(String(weatherData.forecastMintemp?.value ?? 0) + "℃")
                                            .foregroundColor(Color.blue)
                                    }
                                }
                                .padding(.leading)
                                Spacer()
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .active {
                print("Active")
                get_today_weather()
                get_max_min_temp()
                get_nine_days_weather()
                find_place()
            } else if newPhase == .background {
                print("Background")
            }
        }
        .onReceive(timer) {_ in
            get_today_weather()
            get_max_min_temp()
            get_nine_days_weather()
            find_place()
        }
        .onAppear(){
            self.manager.delegate = self.locationManager
            get_today_weather()
            get_max_min_temp()
            get_nine_days_weather()
            find_place()
        }
    }
    
    // today weather
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

                    if let todayWeatherData = try? decoder.decode(DataStruct.todayWeatherInfo.self, from: data) {
                        DispatchQueue.main.async{
                            getTodayWeatherData = todayWeatherData
                            mach_temp_location()
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
                ShowTemperature = String(i.value!) ?? "--"
                break
            }
        }
    }
    
    //get max and min temp
    func get_max_min_temp() {
        let address = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=flw&lang=en"
        if let url = URL(string: address) {
            // GET
            URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
                else if let response = response as? HTTPURLResponse, let data = data {
                    print("Status code: \(response.statusCode)")
                    let decoder = JSONDecoder()

                    if let maxAndMinTempData = try? decoder.decode(DataStruct.MaxAndMinTempInfo.self, from: data) {
                        DispatchQueue.main.async{
                            extract_max_min_value(maxAndMinTempData: maxAndMinTempData)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func extract_max_min_value(maxAndMinTempData: DataStruct.MaxAndMinTempInfo) {
        getMaxAndMinTempData.removeAll()
        let dummy: String = maxAndMinTempData.forecastDesc ?? ""
        let dummyArray = dummy.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for i in dummyArray {
            if let temp = Int(i) {
                getMaxAndMinTempData.append(String(temp))
            }
        }
        if getMaxAndMinTempData.count >= 2 {
            if (Int(getMaxAndMinTempData[0]) ?? 0) > (Int(getMaxAndMinTempData[1]) ?? 0) {
                let dummy2 = getMaxAndMinTempData[0]
                getMaxAndMinTempData[0] = getMaxAndMinTempData[1]
                getMaxAndMinTempData[1] = dummy2
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

                    if let nineDaysWeatherData = try? decoder.decode(DataStruct.nineDaysWeatherInfo.self, from: data) {
                        DispatchQueue.main.async{
                            getNineDaysWeatherData = nineDaysWeatherData
                        }
                    }
                }
            }.resume()
        }
    }
    
    func date_format(weatherDate: String) -> String{
        let dummy_m = Calendar.current.component(.month, from: Date())
        let dummy_d = Calendar.current.component(.day, from: Date())
        var today_m = String(dummy_m)
        var today_d = String(dummy_d)

        if dummy_m < 10 {
            today_m = "0" + String(dummy_m)
        }
        if dummy_d < 10 {
            today_d = "0" + String(dummy_d)
        }
        
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
    
    // user location
    func find_place() {
        var getLocationData = DataStruct.locationInfo()
        if let path = Bundle.main.path(forResource: "location", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()

                if let locationData = try? decoder.decode(DataStruct.locationInfo.self, from: data) {
//                    DispatchQueue.main.async{
                        getLocationData = locationData
//                    }
                }
                
              } catch {
                   // handle error
              }
        }
        let userLocation = manager.location
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
