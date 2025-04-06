//
//  FilterCriteria.swift
//  DineHalal
//
//  Created by Chelsea Bhuiyan on 4/5/25.
//


struct FilterCriteria {
    var halalCertified: Bool = false
    var userVerified: Bool = false
    var thirdPartyVerified: Bool = false
    var nearMe: Bool = false
    var cityZip: String = ""
    var middleEastern: Bool = false
    var mediterranean: Bool = false
    var southAsian: Bool = false
    var american: Bool = false
    var rating: Double = 3
    var priceBudget: Bool = false
    var priceModerate: Bool = false
    var priceExpensive: Bool = false
}
