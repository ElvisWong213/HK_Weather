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
        
        var getAllLocationData = DataStruct.locationInfo()
        
        get_all_location_data { (allLocationData) in
            getAllLocationData = allLocationData
        }
        
        get_today_weather { (todayWeatherData) in
            get_nine_days_weather { (nineWeatherData) in
                get_max_min_temp { (maxMinWeatherData) in
                    let data = WidgetContent(date: currentDate, getTodayWeatherData: todayWeatherData, UserLocation: userLocation, allLocationData: getAllLocationData, getNineDaysWeatherData: nineWeatherData, getMaxAndMinTempData: maxMinWeatherData)
                    let entryDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
                    let timeline = Timeline(entries: [data], policy: .after(entryDate))
                    completion(timeline)
                }
            }
        }

        
    }
    
    func get_today_weather(completion: @escaping(DataStruct.todayWeatherInfo) -> ()) {
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
                            completion(todayWeatherData)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func get_max_min_temp(completion: @escaping([Int]) -> ()) {
        let address = "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=flw&lang=en"
        var dummy: [Int] = []
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
                            dummy = extract_max_min_value(maxAndMinTempData: maxAndMinTempData)
                            completion(dummy)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func extract_max_min_value(maxAndMinTempData: DataStruct.MaxAndMinTempInfo) -> [Int] {
        var getMaxAndMinTempData: [Int] = []
        let dummy: String = maxAndMinTempData.forecastDesc ?? ""
        let dummyArray = dummy.components(separatedBy: CharacterSet.decimalDigits.inverted)
        for i in dummyArray {
            if let temp = Int(i) {
                getMaxAndMinTempData.append(temp)
            }
        }
        if getMaxAndMinTempData.count >= 2 {
            if getMaxAndMinTempData[0] > getMaxAndMinTempData[1] {
                let dummy2 = getMaxAndMinTempData[0]
                getMaxAndMinTempData[0] = getMaxAndMinTempData[1]
                getMaxAndMinTempData[1] = dummy2
            }
        }
        return getMaxAndMinTempData
    }
    
    func get_nine_days_weather(completion: @escaping(DataStruct.nineDaysWeatherInfo) -> ()) {
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
                            completion(nineDaysWeatherData)
                        }
                    }
                }
            }.resume()
        }
    }
    
    func get_all_location_data(completion: @escaping(DataStruct.locationInfo) -> ()) {
        if let path = Bundle.main.path(forResource: "location", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let decoder = JSONDecoder()

                if let locationData = try? decoder.decode(DataStruct.locationInfo.self, from: data) {
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
    var getTodayWeatherData = DataStruct.todayWeatherInfo()
    var UserLocation = CLLocation(latitude: 0, longitude: 0)
    var ShowTemperature = 0
    var allLocationData = DataStruct.locationInfo()
    var getNineDaysWeatherData = DataStruct.nineDaysWeatherInfo()
    var getMaxAndMinTempData: [Int] = []
    
    let weatherIcon = ["Cloudy", "Cold", "Hot", "Raining", "Sunny intervals", "Sunny", "Thunder", "Windy"]
    let weatherIconNumber = [[60, 61, 76, 77, 83, 84, 85], [92, 93], [90, 91], [53, 54, 62, 63, 64], [51, 52, 76], [50, 70, 71, 72, 73, 74, 75], [65], [80, 81, 82]]
    
    static func snapshotWeatherEntry() -> WidgetContent {
        return WidgetContent(date: Date(),
                             getTodayWeatherData: DataStruct.todayWeatherInfo(icon: [60], temperature: DataStruct.Temperature(data: [DataStruct.TemperatureData(place: "Hong Kong", value: 0, unit: "℃")]), humidity: DataStruct.Humidity(data: [DataStruct.HumidityData(place: "Hong Kong", value: 0, unit: "%")])),
                             UserLocation: CLLocation(latitude: 0, longitude: 0),
                             ShowTemperature: 0,
                             allLocationData: DataStruct.locationInfo(data: [DataStruct.locationData(place: "Hong Kong", longitude: 114.177216, latitude: 22.302711)]),
                             getNineDaysWeatherData: DataStruct.nineDaysWeatherInfo(weatherForecast: [DataStruct.nineDaysWeatherData(forecastDate: "20220101", forecastMaxtemp: DataStruct.tempData(value: 100, unit: "℃"), forecastMintemp: DataStruct.tempData(value: 0, unit: "℃"), ForecastIcon: 60)]))
    }
    
}

struct WeatherWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    let startColor = Color("startColor")
    let middleColor = Color("middleColor")
    let endColor = Color("endColor")
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            //small widget
            HStack {
                VStack(alignment: .leading) {
                    Image(get_weather_name(weatherNumber: entry.getTodayWeatherData.icon?[0] ?? 60))
                        .resizable()
                        .frame(width: 45, height: 45)
                    Text(mach_temp_location(getTodayWeatherData: entry.getTodayWeatherData, ShowLocation: find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData)) + "℃")
                    Text(String(entry.getTodayWeatherData.humidity?.data?[0].value ?? 0) + "%")
                        .font(.footnote)
                    HStack {
                        Text(find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData))
                        Image(systemName: "location.fill")
                            .font(.footnote)
                    }
    //                Text(entry.date, style: .time)
                }
                .padding(.horizontal)
                Spacer()
            }
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [startColor, middleColor,endColor]), startPoint: .topTrailing, endPoint: .bottomLeading)
            )
        case .systemMedium:
            HStack {
                VStack(alignment: .leading) {
                    Image(get_weather_name(weatherNumber: entry.getTodayWeatherData.icon?[0] ?? 60))
                        .resizable()
                        .frame(width: 45, height: 45)
                    Text(mach_temp_location(getTodayWeatherData: entry.getTodayWeatherData, ShowLocation: find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData)) + "℃")
                    Text(String(entry.getTodayWeatherData.humidity?.data?[0].value ?? 0) + "%")
                        .font(.footnote)
                    HStack {
                        Text(find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData))
                        Image(systemName: "location.fill")
                            .font(.footnote)
                    }
    //                Text(entry.date, style: .time)
                }
                Spacer(minLength: 25)
                VStack {
//                    if entry.getMaxAndMinTempData.count >= 2 {
//                        ExtractedWidget(icon: get_weather_name(weatherNumber: entry.getTodayWeatherData.icon?[0] ?? 60),
//                                      date: "Today",
//                                      maxTemp: entry.getMaxAndMinTempData[1],
//                                      minTemp: entry.getMaxAndMinTempData[0])
//
//                    }
                    if entry.getNineDaysWeatherData.weatherForecast?.count ?? 0 > 0 {
                        ForEach (entry.getNineDaysWeatherData.weatherForecast!, id: \.self) { weatherData in
                            if entry.getNineDaysWeatherData.weatherForecast?.firstIndex(of: weatherData) ?? 10 < 4 {
                                ExtractedWidget(icon: get_weather_name(weatherNumber: weatherData.ForecastIcon ?? 60),
                                              date: date_format(weatherDate: weatherData.forecastDate ?? "20220101"),
                                              maxTemp: weatherData.forecastMaxtemp?.value ?? 100,
                                              minTemp: weatherData.forecastMintemp?.value ?? 0)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [startColor, middleColor,endColor]), startPoint: .topTrailing, endPoint: .bottomLeading)
            )
        case .systemLarge:
            VStack {
                HStack {
                    VStack(alignment: .leading) {
                        Image(get_weather_name(weatherNumber: entry.getTodayWeatherData.icon?[0] ?? 60))
                            .resizable()
                            .frame(width: 45, height: 45)
                        Text(mach_temp_location(getTodayWeatherData: entry.getTodayWeatherData, ShowLocation: find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData)) + "℃")
                        Text(String(entry.getTodayWeatherData.humidity?.data?[0].value ?? 0) + "%")
                            .font(.footnote)
                        HStack {
                            Text(find_place(userLocation: entry.UserLocation, getLocationData: entry.allLocationData))
                            Image(systemName: "location.fill")
                                .font(.footnote)
                        }
        //                Text(entry.date, style: .time)
                    }
                    Spacer()
                }
                HStack(alignment: .top) {
                    VStack {
//                        if entry.getMaxAndMinTempData.count >= 2 {
//                            ExtractedWidget(icon: get_weather_name(weatherNumber: entry.getTodayWeatherData.icon?[0] ?? 60),
//                                          date: "Today",
//                                          maxTemp: entry.getMaxAndMinTempData[1],
//                                          minTemp: entry.getMaxAndMinTempData[0])
//                        }
                        if entry.getNineDaysWeatherData.weatherForecast?.count ?? 0 > 0 {
                            ForEach (entry.getNineDaysWeatherData.weatherForecast!, id: \.self) { weatherData in
                                if entry.getNineDaysWeatherData.weatherForecast?.firstIndex(of: weatherData) ?? 6 < 5 && date_format(weatherDate: weatherData.forecastDate ?? "Today") != "Today"{
                                    ExtractedWidget(icon: get_weather_name(weatherNumber: weatherData.ForecastIcon ?? 60),
                                                  date: date_format(weatherDate: weatherData.forecastDate ?? "20220101"),
                                                  maxTemp: weatherData.forecastMaxtemp?.value ?? 100,
                                                  minTemp: weatherData.forecastMintemp?.value ?? 0)
                                }
                            }
                        }
                    }
                    VStack {
                        if entry.getNineDaysWeatherData.weatherForecast?.count ?? 0 > 0 {
                            ForEach (entry.getNineDaysWeatherData.weatherForecast!, id: \.self) { weatherData in
                                if entry.getNineDaysWeatherData.weatherForecast?.firstIndex(of: weatherData) ?? 0 >= 5 {
                                    ExtractedWidget(icon: get_weather_name(weatherNumber: weatherData.ForecastIcon ?? 60),
                                                  date: date_format(weatherDate: weatherData.forecastDate ?? "20220101"),
                                                  maxTemp: weatherData.forecastMaxtemp?.value ?? 100,
                                                  minTemp: weatherData.forecastMintemp?.value ?? 0)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [startColor, middleColor,endColor]), startPoint: .topTrailing, endPoint: .bottomLeading)
            )
        case .systemExtraLarge:
            Text("extra large")
        @unknown default:
            Text("default")
        }
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
    func mach_temp_location(getTodayWeatherData: DataStruct.todayWeatherInfo, ShowLocation: String) -> String{
        var returnShowTemperature = "--"
        for i in getTodayWeatherData.temperature?.data ?? [] {
            if i.place == ShowLocation {
                returnShowTemperature = String(i.value!) ?? "--"
                break
            }
        }
        return returnShowTemperature
    }
    
    func find_place(userLocation: CLLocation, getLocationData: DataStruct.locationInfo) -> String{
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
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WeatherWidgetEntryView(entry: WidgetContent(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            WeatherWidgetEntryView(entry: WidgetContent(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            WeatherWidgetEntryView(entry: WidgetContent(date: Date()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
}

struct ExtractedWidget: View {
    let icon: String
    let date: String
    let maxTemp: Int
    let minTemp: Int
    
    var body: some View {
        HStack {
            Image(icon)
                .resizable()
                .frame(width: 25, height: 25)
            Spacer()
            Text(date)
                .font(.system(size: 13))
            Spacer()
            Text(String(maxTemp) + "℃")
                .font(.system(size: 13))
                .foregroundColor(Color.red)
            Spacer()
            Text(String(minTemp) + "℃")
                .font(.system(size: 13))
                .foregroundColor(Color.blue)
        }
    }
}
