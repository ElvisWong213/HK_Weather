//
//  WeatherWidget.swift
//  WeatherWidget
//
//  Created by Steve on 5/2/2022.
//

import WidgetKit
import SwiftUI
import CoreLocation

struct Provider: TimelineProvider {
        
    func placeholder(in context: Context) -> WidgetContent {
        WidgetContent.snapshotWeatherEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> ()) {
        let entry = WidgetContent.snapshotWeatherEntry()
        completion(entry)
    }
    
    //location
    var locationManager = WidgetLocationManager()

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
//        var entries: [WidgetContent] = []
                
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
                
        var userLocation = CLLocation(latitude: 0, longitude: 0)
        
        userLocation = locationManager.location ?? CLLocation(latitude: 0, longitude: 0)
        
        var getAllLocationData = locationInfo()
        get_all_location_data { (allLocationData) in
            getAllLocationData = allLocationData
        }
        get_today_weather { (weatherData) in
            let data = WidgetContent(date: currentDate, getTodayWeatherData: weatherData, UserLocation: userLocation, allLocationData: getAllLocationData)
            let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!

            let timeline = Timeline(entries: [data], policy: .after(entryDate))
                completion(timeline)
        }
        
        
    }
    
    func get_today_weather(completion: @escaping(todayWeatherInfo) -> ()) {
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
                            completion(todayWeatherData)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func get_all_location_data(completion: @escaping(locationInfo) -> ()) {
        if let path = Bundle.main.path(forResource: "location", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()

                if let locationData = try? decoder.decode(locationInfo.self, from: data) {
//                    DispatchQueue.main.async{
                    completion(locationData)
//                    }
                }
                
              } catch {
                   // handle error
              }
        }
    }
}

struct WidgetContent: TimelineEntry {
    let date: Date
    var getTodayWeatherData = todayWeatherInfo()
    var UserLocation = CLLocation(latitude: 0, longitude: 0)
    var ShowTemperature = 0
    var allLocationData = locationInfo()
    
    let weatherIcon = ["Cloudy", "Cold", "Hot", "Raining", "Sunny intervals", "Sunny", "Thunder", "Windy"]
    let weatherIconNumber = [[60, 61, 76, 77, 83, 84, 85], [92, 93], [90, 91], [53, 54, 62, 63, 64], [51, 52, 76], [50, 70, 71, 72, 73, 74, 75], [65], [80, 81, 82]]
    
    static func snapshotWeatherEntry() -> WidgetContent {
        return WidgetContent(date: Date(), getTodayWeatherData: todayWeatherInfo(icon: [60], temperature: Temperature(data: [TemperatureData(place: "Hong Kong", value: 0, unit: "℃")])), UserLocation: CLLocation(latitude: 0, longitude: 0), ShowTemperature: 0, allLocationData: locationInfo(data: [locationData(place: "Hong Kong", longitude: 114.177216, latitude: 22.302711)]))
    }
    
}

struct WeatherWidgetEntryView : View {
    var entry: Provider.Entry
    let startColor = Color(red: 238/255, green: 231/255, blue: 203/255)
    let middleColor = Color(red: 57/255, green: 61/255, blue: 93/255, opacity: 0.76)
    let endColor = Color(red: 57/255, green: 61/255, blue: 93/255)

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Image(get_weather_name(weatherNumber: entry.getTodayWeatherData.icon?[0] ?? 60))
                    .resizable()
                    .frame(width: 50, height: 50)
                HStack {
                    Text(String(mach_temp_location(getTodayWeatherData: entry.getTodayWeatherData, ShowLocation: find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData))) + "℃")
                }
                HStack {
                    Text(find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData))
                    Image(systemName: "location.fill")
                }
                Text(entry.date, style: .time)
            }
            .padding(.horizontal)
            Spacer()
        }
        .foregroundColor(Color.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(gradient: Gradient(colors: [startColor, middleColor,endColor]), startPoint: .topTrailing, endPoint: .bottomLeading)
        )
    }
    
    func get_weather_name(weatherNumber: Int) -> String{
        var output = ""
        var out = false
        for i in 0..<entry.weatherIconNumber.count {
            if out {
                break
            }
            for j in 0..<entry.weatherIconNumber[i].count {
                if entry.weatherIconNumber[i][j] == weatherNumber {
                    output = entry.weatherIcon[i]
                    out = true
                    break
                }
            }
        }
        return output
    }
    
    //match temperature with user location
    func mach_temp_location(getTodayWeatherData: todayWeatherInfo, ShowLocation: String) -> Int{
        var returnShowTemperature = 0
        for i in getTodayWeatherData.temperature?.data ?? [] {
            if i.place == ShowLocation {
                returnShowTemperature = i.value ?? 0
            }
        }
        return returnShowTemperature
    }
    
    func find_place(userLocation: CLLocation, getLocationData: locationInfo) -> String{
        var returnShowLocation = "Hong Kong"
        let CLL_getLocationData = CLLocation(latitude: getLocationData.data?[0].latitude ?? 0.0, longitude: getLocationData.data?[0].longitude ?? 0.0)
        var distanceInMeters = CLL_getLocationData.distance(from: userLocation)
        for i in getLocationData.data ?? [] {
            let location = CLLocation(latitude: i.latitude ?? 0.0, longitude: i.longitude ?? 0.0)
            let dummy = location.distance(from: userLocation)
            if dummy < distanceInMeters {
                distanceInMeters = dummy
                returnShowLocation = i.place ?? ""
            }
        }
        return returnShowLocation
    }
}

@main
struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather Widget")
        .description("See the current weather forecast of the location")
    }
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

// user location
struct locationInfo: Codable {
    var data: [locationData]?
}

struct locationData: Codable {
    var place: String?
    var longitude: Double?
    var latitude: Double?
}

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidgetEntryView(entry: WidgetContent(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
