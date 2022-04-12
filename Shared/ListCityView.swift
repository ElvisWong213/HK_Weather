//
//  ListCityView.swift
//  weather (iOS)
//
//  Created by Steve on 4/3/2022.
//

import SwiftUI

struct ListCityView: View {
    
    @Binding var getTodayWeatherData: DataStruct.todayWeatherInfo
    @Binding var ShowLocation: String
    let startColor = Color("startColor")
    let middleColor = Color("middleColor")
    let endColor = Color("endColor")
    
    let weatherIcon = ["Cloudy", "Cold", "Hot", "Raining", "Sunny intervals", "Sunny", "Thunder", "Windy"]
    let weatherIconNumber = [[60, 61, 76, 77, 83, 84, 85], [92, 93], [90, 91], [53, 54, 62, 63, 64], [51, 52, 76], [50, 70, 71, 72, 73, 74, 75], [65], [80, 81, 82]]
    
    var body: some View {
        NavigationView {
            List {
                if (getTodayWeatherData.temperature?.data!.count) ?? 0 > 0 {
                    ForEach((getTodayWeatherData.temperature?.data)!, id: \.self) { weatherData in
                        HStack {
                            Image(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60))
                                .padding(.trailing)
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(weatherData.place!)
                                        .font(.title2)
                                    if weatherData.place! == ShowLocation {
                                        Image(systemName: "location.fill")
                                            .font(.subheadline)
                                    }
                                }
                                Text(get_weather_name(weatherNumber: getTodayWeatherData.icon?[0] ?? 60))
                                    .font(.title3)
                                Text(String(weatherData.value!) + "℃")
                                    .font(.title3)
                                .font(.headline)
                            }
                            Spacer()
                        }
                        .padding()
                        .listRowBackground(Color.black.opacity(0))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Stations")
            .background(LinearGradient(gradient: Gradient(colors: [startColor, middleColor,endColor]), startPoint: .topTrailing, endPoint: .bottomLeading).ignoresSafeArea())
        }
        .onAppear() {
            sortWeatherData()
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
    
    func sortWeatherData() {
        while true {
            var sorted = true
            for i in 0..<(getTodayWeatherData.temperature?.data?.count ?? 1) - 1 {
                if (getTodayWeatherData.temperature?.data![i].place?.prefix(1))! > (getTodayWeatherData.temperature?.data![i + 1].place?.prefix(1))! {
                    let dummy = getTodayWeatherData.temperature?.data![i]
                    getTodayWeatherData.temperature?.data![i] = (getTodayWeatherData.temperature?.data![i + 1])!
                    getTodayWeatherData.temperature?.data![i + 1] = dummy!
                    sorted = false
                }
            }
            if sorted {
                break
            }
        }
    }
}

struct ListCityView_Previews: PreviewProvider {
    static var previews: some View {
        ListCityView(getTodayWeatherData: .constant(DataStruct.todayWeatherInfo(icon: [60], temperature: DataStruct.Temperature(data: [DataStruct.TemperatureData(place: "Hong Kong", value: 0, unit: "℃")]), humidity: DataStruct.Humidity(data: [DataStruct.HumidityData(place: "Hong Kong", value: 0, unit: "%")]))),
                     ShowLocation: .constant("Hong Kong")
        )
//        ListCityView()
            
    }
}
