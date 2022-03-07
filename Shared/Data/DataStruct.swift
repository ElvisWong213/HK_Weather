//
//  DataStruct.swift
//  weather
//
//  Created by Steve on 7/3/2022.
//

import Foundation

struct DataStruct {
    // today weather
    struct todayWeatherInfo: Codable {
        var icon: [Int]?
        var temperature: Temperature?
        var humidity: Humidity?
    }

    struct Temperature: Codable, Hashable {
        var data: [TemperatureData]?
    }

    struct TemperatureData: Codable, Hashable {
        var place: String?
        var value: Int?
        var unit: String?
    }

    struct Humidity: Codable {
        var data: [HumidityData]?
    }

    struct HumidityData: Codable {
        var place: String?
        var value: Int?
        var unit: String?
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
    
    //get max and min temp
    struct MaxAndMinTempInfo: Codable {
        var forecastDesc: String?
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
}
