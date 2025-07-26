//
//  Quote.swift
//  SwiftYFinance
//
//  Created by Eric Wing on 07.26.2025
//

import Foundation
import SwiftyJSON



// This was originally implemented for the quote field inside the Options structure.
// However, it also seems to be roughly the same structure used for basic latest ticker request.
// So I moved it out to it's own file.
// Note: I discovered Quote will have different/additional fields if you use the contractSymbol instead of the underlying ticker for options, but this data structure is still usable for both cases.

// This looks very similar to struct Price, but it isn't exact.
// I don't know if that is because Yahoo changed fields,
// Price didn't implement all the fields,
// or if they are just different.
// If Price and Quote are supposed to be the same thing, they should be merged.
public struct Quote
{
	
	public var language: String?
	public var region: String?
	public var quoteType: String?
	public var typeDisp: String?
	public var quoteSourceName: String?
	public var triggerable: Bool?
	public var customPriceAlertConfidence: String?
	public var shortName: String?
	public var longName: String?
	public var currency: String?
	// Don't feel like implementing this one right now.
	/*
	public var corporateActions": [
	  {
		"header": "Dividend",
		"message": "MSFT announced a cash dividend of 0.83 with an ex-date of Aug. 21, 2025",
		"meta": {
		  "eventType": "DIVIDEND",
		  "dateEpochMs": 1755748800000,
		  "amount": "0.83"
		}
	  }
	],
	*/
	public var postMarketTime: Date?
	public var regularMarketTime: Date?
	public var averageAnalystRating: String?
	public var tradeable: Bool?
	public var cryptoTradeable: Bool?
	public var marketState: String?
	public var hasPrePostMarketData: Bool?
	public var firstTradeDateMilliseconds: Int?
	public var priceHint: Int?
	public var postMarketChangePercent: Float?
	public var postMarketPrice: Float?
	public var postMarketChange: Float?
	public var regularMarketChange: Float?
	public var regularMarketDayHigh: Float?
	public var regularMarketDayRange: String?
	public var regularMarketDayLow: Float?
	public var regularMarketVolume: Int?
	public var regularMarketPreviousClose: Float?
	public var bid: Float?
	public var ask: Float?
	public var bidSize: Int?
	public var askSize: Int?
	public var fullExchangeName: String?
	public var financialCurrency: String?
	public var regularMarketOpen: Float?
	public var averageDailyVolume3Month: Int?
	public var averageDailyVolume10Day: Int?
	public var fiftyTwoWeekLowChange: Float?
	public var fiftyTwoWeekLowChangePercent: Float?
	public var fiftyTwoWeekRange: String?
	public var fiftyTwoWeekHighChange: Float?
	public var fiftyTwoWeekHighChangePercent: Float?
	public var fiftyTwoWeekLow: Float?
	public var fiftyTwoWeekHigh: Float?
	public var fiftyTwoWeekChangePercent: Float?
	public var dividendDate: Date?
	public var earningsTimestamp: Date?
	public var earningsTimestampStart: Date?
	public var earningsTimestampEnd: Date?
	public var earningsCallTimestampStart: Date?
	public var earningsCallTimestampEnd: Date?
	public var isEarningsDateEstimate: Bool?
	public var trailingAnnualDividendRate: Float?
	public var trailingPE: Float?
	public var dividendRate: Float?
	public var trailingAnnualDividendYield: Float?
	public var dividendYield: Float?
	public var epsTrailingTwelveMonths: Float?
	public var epsForward: Float?
	public var epsCurrentYear: Float?
	public var priceEpsCurrentYear: Float?
	public var sharesOutstanding: Int?
	public var bookValue: Float?
	public var fiftyDayAverage: Float?
	public var fiftyDayAverageChange: Float?
	public var fiftyDayAverageChangePercent: Float?
	public var twoHundredDayAverage: Float?
	public var twoHundredDayAverageChange: Float?
	public var twoHundredDayAverageChangePercent: Float?
	public var marketCap: Int?
	public var forwardPE: Float?
	public var priceToBook: Float?
	public var sourceInterval: Float?
	public var exchangeDataDelayedBy: Int?
	public var exchange: String?
	public var messageBoardId: String?
	public var exchangeTimezoneName: String?
	public var exchangeTimezoneShortName: String?
	public var gmtOffSetMilliseconds: Int?
	public var market: String?
	public var esgPopulated: Bool?
	public var regularMarketChangePercent: Float?
	public var regularMarketPrice: Float?
	public var displayName: String?
	public var symbol: String?
	
	/*
	 I discovered that if you query the contractSymbol directly, you get different values back.
	 See bottom for example.
	 But the most important are the expiration dates, because you need to know the exact dates if you want to query Yahoo for more info on the options chain.
	 For example, I would like to get the implied volatility, but that info is not present in this part of the data.
	 (Although the options price is available in this part,
	 so, if you can get the dividend yield and underlying price through other means,
	 you can calculate the implied volatility.)
	 */
	public var expireDate: Date?
	public var expireIsoDate: Date? // seems redundant
	public var underlyingSymbol: String?
	public var underlyingShortName: String?
	public var optionsType: String?


	
	init(information: JSON) {
		
		self.language = information["language"].string
		self.region = information["region"].string
		self.quoteType = information["quoteType"].string
		self.typeDisp = information["typeDisp"].string
		self.quoteSourceName = information["quoteSourceName"].string
		self.triggerable = information["triggerable"].bool
		self.customPriceAlertConfidence = information["customPriceAlertConfidence"].string
		self.shortName = information["shortName"].string
		self.longName = information["longName"].string
		self.currency = information["currency"].string

		/*
		self.corporateActions = information["corporateActions"].array [
		  {
			"header": "Dividend",
			"message": "MSFT announced a cash dividend of 0.83 with an ex-date of Aug. 21, 2025",
			"meta": {
			  "eventType": "DIVIDEND",
			  "dateEpochMs": 1755748800000,
			  "amount": "0.83"
			}
		  }
		],
		*/
		
		self.postMarketTime = makeDateFromIntTimeIntervalOrNil(information:information["postMarketTime"])
		self.regularMarketTime = makeDateFromIntTimeIntervalOrNil(information:information["regularMarketTime"])
		self.averageAnalystRating = information["averageAnalystRating"].string
		self.tradeable = information["tradeable"].bool
		self.cryptoTradeable = information["cryptoTradeable"].bool
		self.marketState = information["marketState"].string
		self.hasPrePostMarketData = information["hasPrePostMarketData"].bool
		self.firstTradeDateMilliseconds = information["firstTradeDateMilliseconds"].int
		self.priceHint = information["priceHint"].int
		self.postMarketChangePercent = information["postMarketChangePercent"].float
		self.postMarketPrice = information["postMarketPrice"].float
		self.postMarketChange = information["postMarketChange"].float
		self.regularMarketChange = information["regularMarketChange"].float
		self.regularMarketDayHigh = information["regularMarketDayHigh"].float
		self.regularMarketDayRange = information["regularMarketDayRange"].string
		self.regularMarketDayLow = information["regularMarketDayLow"].float
		self.regularMarketVolume = information["regularMarketVolume"].int
		self.regularMarketPreviousClose = information["regularMarketPreviousClose"].float
		self.bid = information["bid"].float
		self.ask = information["ask"].float
		self.bidSize = information["bidSize"].int
		self.askSize = information["askSize"].int
		self.fullExchangeName = information["fullExchangeName"].string
		self.financialCurrency = information["financialCurrency"].string
		self.regularMarketOpen = information["regularMarketOpen"].float
		self.averageDailyVolume3Month = information["averageDailyVolume3Month"].int
		self.averageDailyVolume10Day = information["averageDailyVolume10Day"].int
		self.fiftyTwoWeekLowChange = information["fiftyTwoWeekLowChange"].float
		self.fiftyTwoWeekLowChangePercent = information["fiftyTwoWeekLowChangePercent"].float
		self.fiftyTwoWeekRange = information["fiftyTwoWeekRange"].string
		self.fiftyTwoWeekHighChange = information["fiftyTwoWeekHighChange"].float
		self.fiftyTwoWeekHighChangePercent = information["fiftyTwoWeekHighChangePercent"].float
		self.fiftyTwoWeekLow = information["fiftyTwoWeekLow"].float
		self.fiftyTwoWeekHigh = information["fiftyTwoWeekHigh"].float
		self.fiftyTwoWeekChangePercent = information["fiftyTwoWeekChangePercent"].float
		self.dividendDate = makeDateFromIntTimeIntervalOrNil(information:information["dividendDate"])
		self.earningsTimestamp = makeDateFromIntTimeIntervalOrNil(information:information["earningsTimestamp"])
		self.earningsTimestampStart = makeDateFromIntTimeIntervalOrNil(information:information["earningsTimestampStart"])
		self.earningsTimestampEnd = makeDateFromIntTimeIntervalOrNil(information:information["earningsTimestampEnd"])
		self.earningsCallTimestampStart = makeDateFromIntTimeIntervalOrNil(information:information["earningsCallTimestampStart"])
		self.earningsCallTimestampEnd = makeDateFromIntTimeIntervalOrNil(information:information["earningsCallTimestampEnd"])
		self.isEarningsDateEstimate = information["isEarningsDateEstimate"].bool
		self.trailingAnnualDividendRate = information["trailingAnnualDividendRate"].float
		self.trailingPE = information["trailingPE"].float
		self.dividendRate = information["dividendRate"].float
		self.trailingAnnualDividendYield = information["trailingAnnualDividendYield"].float
		self.dividendYield = information["dividendYield"].float
		self.epsTrailingTwelveMonths = information["epsTrailingTwelveMonths"].float
		self.epsForward = information["epsForward"].float
		self.epsCurrentYear = information["epsCurrentYear"].float
		self.priceEpsCurrentYear = information["priceEpsCurrentYear"].float
		self.sharesOutstanding = information["sharesOutstanding"].int
		self.bookValue = information["bookValue"].float
		self.fiftyDayAverage = information["fiftyDayAverage"].float
		self.fiftyDayAverageChange = information["fiftyDayAverageChange"].float
		self.fiftyDayAverageChangePercent = information["fiftyDayAverageChangePercent"].float
		self.twoHundredDayAverage = information["twoHundredDayAverage"].float
		self.twoHundredDayAverageChange = information["twoHundredDayAverageChange"].float
		self.twoHundredDayAverageChangePercent = information["twoHundredDayAverageChangePercent"].float
		self.marketCap = information["marketCap"].int
		self.forwardPE = information["forwardPE"].float
		self.priceToBook = information["priceToBook"].float
		self.sourceInterval = information["sourceInterval"].float
		self.exchangeDataDelayedBy = information["exchangeDataDelayedBy"].int
		self.exchange = information["exchange"].string
		self.messageBoardId = information["messageBoardId"].string
		self.exchangeTimezoneName = information["exchangeTimezoneName"].string
		self.exchangeTimezoneShortName = information["exchangeTimezoneShortName"].string
		self.gmtOffSetMilliseconds = information["gmtOffSetMilliseconds"].int
		self.market = information["market"].string
		self.esgPopulated = information["esgPopulated"].bool
		self.regularMarketChangePercent = information["regularMarketChangePercent"].float
		self.regularMarketPrice = information["regularMarketPrice"].float
		self.displayName = information["displayName"].string
		self.symbol = information["symbol"].string

		
		
		// For when an options contractSymbol is given as the identifer instead of the underlying ticker, there are some extra fields.
		
		self.expireDate = makeDateFromIntTimeIntervalOrNil(information:information["expireDate"])

		// For when an options contractSymbol is given as the identifer instead of the underlying ticker.
		if let expire_iso_str = information["expireIsoDate"].string
		{
			let dateFormatter = ISO8601DateFormatter()
			let date = dateFormatter.date(from: expire_iso_str)
			self.expireIsoDate = date
		}
		self.underlyingSymbol = information["underlyingSymbol"].string
		self.underlyingShortName = information["underlyingShortName"].string
		self.optionsType = information["optionsType"].string
	}
}

// helper
func makeDateFromIntTimeIntervalOrNil(information: JSON) -> Date?
{
	if let time_stamp = information.int
	{
		let time_interval = Double(time_stamp)
		return Date(timeIntervalSince1970: time_interval)
	}
	else
	{
		return nil
	}
}

/*
 I'm looking at the API to query multiple symbols in one-shot to see how the data overlaps with the Quote struct.
 Also, this seems to send much less data than the recentChartDataAtMoment API.
 It actually seems to be close in data to quoteSummary, but you don't have to specify a sub-category.
 Given that Yahoo is known to ban too many requests, this probably should either replace the recentChartDataAtMomentAPI or get its own API.

 
 https://query2.finance.yahoo.com/v7/finance/quote?symbols=AAPL,MSFT&crumb=4IjOdW3MQPU
 
 {
	"quoteResponse":{
	   "result":[
		  {
			 "language":"en-US",
			 "region":"US",
			 "quoteType":"EQUITY",
			 "typeDisp":"Equity",
			 "quoteSourceName":"Delayed Quote",
			 "triggerable":true,
			 "customPriceAlertConfidence":"HIGH",
			 "currency":"USD",
			 "corporateActions":[
				
			 ],
			 "postMarketTime":1753487988,
			 "regularMarketTime":1753473601,
			 "exchange":"NMS",
			 "messageBoardId":"finmb_24937",
			 "exchangeTimezoneName":"America/New_York",
			 "exchangeTimezoneShortName":"EDT",
			 "gmtOffSetMilliseconds":-14400000,
			 "market":"us_market",
			 "esgPopulated":false,
			 "regularMarketChangePercent":0.0561426,
			 "regularMarketPrice":213.88,
			 "marketState":"CLOSED",
			 "shortName":"Apple Inc.",
			 "longName":"Apple Inc.",
			 "trailingAnnualDividendRate":1.0,
			 "trailingPE":33.314644,
			 "dividendRate":1.04,
			 "trailingAnnualDividendYield":0.0046781437,
			 "dividendYield":0.49,
			 "epsTrailingTwelveMonths":6.42,
			 "epsForward":8.31,
			 "epsCurrentYear":7.20274,
			 "priceEpsCurrentYear":29.694256,
			 "sharesOutstanding":14935799808,
			 "bookValue":4.471,
			 "fiftyDayAverage":205.4042,
			 "fiftyDayAverageChange":8.4758,
			 "fiftyDayAverageChangePercent":0.041264,
			 "twoHundredDayAverage":222.02605,
			 "twoHundredDayAverageChange":-8.146042,
			 "twoHundredDayAverageChangePercent":-0.036689576,
			 "marketCap":3194468958208,
			 "forwardPE":25.737665,
			 "priceToBook":47.837173,
			 "sourceInterval":15,
			 "exchangeDataDelayedBy":0,
			 "averageAnalystRating":"2.0 - Buy",
			 "tradeable":false,
			 "cryptoTradeable":false,
			 "hasPrePostMarketData":true,
			 "firstTradeDateMilliseconds":345479400000,
			 "priceHint":2,
			 "postMarketChangePercent":0.03272492,
			 "postMarketPrice":213.95,
			 "postMarketChange":0.069992065,
			 "regularMarketChange":0.12001,
			 "regularMarketDayHigh":215.24,
			 "regularMarketDayRange":"213.4 - 215.24",
			 "regularMarketDayLow":213.4,
			 "regularMarketVolume":38585030,
			 "regularMarketPreviousClose":213.76,
			 "bid":213.82,
			 "ask":215.97,
			 "bidSize":5,
			 "askSize":3,
			 "fullExchangeName":"NasdaqGS",
			 "financialCurrency":"USD",
			 "regularMarketOpen":214.7,
			 "averageDailyVolume3Month":53038719,
			 "averageDailyVolume10Day":45668270,
			 "fiftyTwoWeekLowChange":44.67,
			 "fiftyTwoWeekLowChangePercent":0.26399148,
			 "fiftyTwoWeekRange":"169.21 - 260.1",
			 "fiftyTwoWeekHighChange":-46.22,
			 "fiftyTwoWeekHighChangePercent":-0.17770089,
			 "fiftyTwoWeekLow":169.21,
			 "fiftyTwoWeekHigh":260.1,
			 "fiftyTwoWeekChangePercent":-1.9977987,
			 "dividendDate":1747267200,
			 "earningsTimestamp":1753992000,
			 "earningsTimestampStart":1753992000,
			 "earningsTimestampEnd":1753992000,
			 "earningsCallTimestampStart":1753995600,
			 "earningsCallTimestampEnd":1753995600,
			 "isEarningsDateEstimate":false,
			 "displayName":"Apple",
			 "symbol":"AAPL"
		  },
		  {
			 "language":"en-US",
			 "region":"US",
			 "quoteType":"EQUITY",
			 "typeDisp":"Equity",
			 "quoteSourceName":"Nasdaq Real Time Price",
			 "triggerable":true,
			 "customPriceAlertConfidence":"HIGH",
			 "currency":"USD",
			 "corporateActions":[
				{
				   "header":"Dividend",
				   "message":"MSFT announced a cash dividend of 0.83 with an ex-date of Aug. 21, 2025",
				   "meta":{
					  "eventType":"DIVIDEND",
					  "dateEpochMs":1755748800000,
					  "amount":"0.83"
				   }
				}
			 ],
			 "postMarketTime":1753487996,
			 "regularMarketTime":1753473601,
			 "exchange":"NMS",
			 "messageBoardId":"finmb_21835",
			 "exchangeTimezoneName":"America/New_York",
			 "exchangeTimezoneShortName":"EDT",
			 "gmtOffSetMilliseconds":-14400000,
			 "market":"us_market",
			 "esgPopulated":false,
			 "regularMarketChangePercent":0.553949,
			 "regularMarketPrice":513.71,
			 "marketState":"CLOSED",
			 "shortName":"Microsoft Corporation",
			 "longName":"Microsoft Corporation",
			 "trailingAnnualDividendRate":3.24,
			 "trailingPE":39.668728,
			 "dividendRate":3.32,
			 "trailingAnnualDividendYield":0.006341998,
			 "dividendYield":0.65,
			 "epsTrailingTwelveMonths":12.95,
			 "epsForward":14.95,
			 "epsCurrentYear":13.41751,
			 "priceEpsCurrentYear":38.286537,
			 "sharesOutstanding":7432540160,
			 "bookValue":43.3,
			 "fiftyDayAverage":482.194,
			 "fiftyDayAverageChange":31.516022,
			 "fiftyDayAverageChangePercent":0.06535963,
			 "twoHundredDayAverage":430.2201,
			 "twoHundredDayAverageChange":83.48993,
			 "twoHundredDayAverageChangePercent":0.19406329,
			 "marketCap":3818170351616,
			 "forwardPE":34.361874,
			 "priceToBook":11.863973,
			 "sourceInterval":15,
			 "exchangeDataDelayedBy":0,
			 "averageAnalystRating":"1.4 - Strong Buy",
			 "tradeable":false,
			 "cryptoTradeable":false,
			 "hasPrePostMarketData":true,
			 "firstTradeDateMilliseconds":511108200000,
			 "priceHint":2,
			 "postMarketChangePercent":0.0564478,
			 "postMarketPrice":514.0,
			 "postMarketChange":0.289978,
			 "regularMarketChange":2.83002,
			 "regularMarketDayHigh":518.29,
			 "regularMarketDayRange":"510.3592 - 518.29",
			 "regularMarketDayLow":510.3592,
			 "regularMarketVolume":18998701,
			 "regularMarketPreviousClose":510.88,
			 "bid":512.03,
			 "ask":518.0,
			 "bidSize":4,
			 "askSize":2,
			 "fullExchangeName":"NasdaqGS",
			 "financialCurrency":"USD",
			 "regularMarketOpen":512.465,
			 "averageDailyVolume3Month":19908059,
			 "averageDailyVolume10Day":16039860,
			 "fiftyTwoWeekLowChange":168.92001,
			 "fiftyTwoWeekLowChangePercent":0.48992142,
			 "fiftyTwoWeekRange":"344.79 - 518.29",
			 "fiftyTwoWeekHighChange":-4.579956,
			 "fiftyTwoWeekHighChangePercent":-0.008836667,
			 "fiftyTwoWeekLow":344.79,
			 "fiftyTwoWeekHigh":518.29,
			 "fiftyTwoWeekChangePercent":20.382917,
			 "dividendDate":1757548800,
			 "earningsTimestamp":1753905600,
			 "earningsTimestampStart":1753905600,
			 "earningsTimestampEnd":1753905600,
			 "earningsCallTimestampStart":1753911000,
			 "earningsCallTimestampEnd":1753911000,
			 "isEarningsDateEstimate":false,
			 "displayName":"Microsoft",
			 "symbol":"MSFT"
		  }
	   ],
	   "error":null
	}
 }
 */

/*
 Interesting: This API even accepts option contract symbols.
 
 
 https://query2.finance.yahoo.com/v7/finance/quote?symbols=AAPL,MSFT,SPY250728C00565000&crumb=4IjOdW3MQPU
 
 {
	"quoteResponse":{
	   "result":[
		  {
			 "language":"en-US",
			 "region":"US",
			 "quoteType":"EQUITY",
			 "typeDisp":"Equity",
			 "quoteSourceName":"Delayed Quote",
			 "triggerable":true,
			 "customPriceAlertConfidence":"HIGH",
			 "currency":"USD",
			 "corporateActions":[
				
			 ],
			 "postMarketTime":1753487988,
			 "regularMarketTime":1753473601,
			 "exchange":"NMS",
			 "messageBoardId":"finmb_24937",
			 "sharesOutstanding":14935799808,
			 "bookValue":4.471,
			 "fiftyDayAverage":205.4042,
			 "fiftyDayAverageChange":8.4758,
			 "fiftyDayAverageChangePercent":0.041264,
			 "twoHundredDayAverage":222.02605,
			 "twoHundredDayAverageChange":-8.146042,
			 "twoHundredDayAverageChangePercent":-0.036689576,
			 "marketCap":3194468958208,
			 "forwardPE":25.737665,
			 "priceToBook":47.837173,
			 "sourceInterval":15,
			 "exchangeDataDelayedBy":0,
			 "averageAnalystRating":"2.0 - Buy",
			 "tradeable":false,
			 "cryptoTradeable":false,
			 "shortName":"Apple Inc.",
			 "longName":"Apple Inc.",
			 "marketState":"CLOSED",
			 "exchangeTimezoneName":"America/New_York",
			 "exchangeTimezoneShortName":"EDT",
			 "gmtOffSetMilliseconds":-14400000,
			 "market":"us_market",
			 "esgPopulated":false,
			 "regularMarketChangePercent":0.0561426,
			 "regularMarketPrice":213.88,
			 "hasPrePostMarketData":true,
			 "firstTradeDateMilliseconds":345479400000,
			 "priceHint":2,
			 "postMarketChangePercent":0.03272492,
			 "postMarketPrice":213.95,
			 "postMarketChange":0.069992065,
			 "regularMarketChange":0.12001,
			 "regularMarketDayHigh":215.24,
			 "regularMarketDayRange":"213.4 - 215.24",
			 "regularMarketDayLow":213.4,
			 "regularMarketVolume":38585030,
			 "regularMarketPreviousClose":213.76,
			 "bid":213.82,
			 "ask":215.97,
			 "bidSize":5,
			 "askSize":3,
			 "fullExchangeName":"NasdaqGS",
			 "financialCurrency":"USD",
			 "regularMarketOpen":214.7,
			 "averageDailyVolume3Month":53038719,
			 "averageDailyVolume10Day":45668270,
			 "fiftyTwoWeekLowChange":44.67,
			 "fiftyTwoWeekLowChangePercent":0.26399148,
			 "fiftyTwoWeekRange":"169.21 - 260.1",
			 "fiftyTwoWeekHighChange":-46.22,
			 "fiftyTwoWeekHighChangePercent":-0.17770089,
			 "fiftyTwoWeekLow":169.21,
			 "fiftyTwoWeekHigh":260.1,
			 "fiftyTwoWeekChangePercent":-1.9977987,
			 "dividendDate":1747267200,
			 "earningsTimestamp":1753992000,
			 "earningsTimestampStart":1753992000,
			 "earningsTimestampEnd":1753992000,
			 "earningsCallTimestampStart":1753995600,
			 "earningsCallTimestampEnd":1753995600,
			 "isEarningsDateEstimate":false,
			 "trailingAnnualDividendRate":1.0,
			 "trailingPE":33.314644,
			 "dividendRate":1.04,
			 "trailingAnnualDividendYield":0.0046781437,
			 "dividendYield":0.49,
			 "epsTrailingTwelveMonths":6.42,
			 "epsForward":8.31,
			 "epsCurrentYear":7.20274,
			 "priceEpsCurrentYear":29.694256,
			 "displayName":"Apple",
			 "symbol":"AAPL"
		  },
		  {
			 "language":"en-US",
			 "region":"US",
			 "quoteType":"EQUITY",
			 "typeDisp":"Equity",
			 "quoteSourceName":"Nasdaq Real Time Price",
			 "triggerable":true,
			 "customPriceAlertConfidence":"HIGH",
			 "currency":"USD",
			 "corporateActions":[
				{
				   "header":"Dividend",
				   "message":"MSFT announced a cash dividend of 0.83 with an ex-date of Aug. 21, 2025",
				   "meta":{
					  "eventType":"DIVIDEND",
					  "dateEpochMs":1755748800000,
					  "amount":"0.83"
				   }
				}
			 ],
			 "postMarketTime":1753487996,
			 "regularMarketTime":1753473601,
			 "exchange":"NMS",
			 "messageBoardId":"finmb_21835",
			 "sharesOutstanding":7432540160,
			 "bookValue":43.3,
			 "fiftyDayAverage":482.194,
			 "fiftyDayAverageChange":31.516022,
			 "fiftyDayAverageChangePercent":0.06535963,
			 "twoHundredDayAverage":430.2201,
			 "twoHundredDayAverageChange":83.48993,
			 "twoHundredDayAverageChangePercent":0.19406329,
			 "marketCap":3818170351616,
			 "forwardPE":34.361874,
			 "priceToBook":11.863973,
			 "sourceInterval":15,
			 "exchangeDataDelayedBy":0,
			 "averageAnalystRating":"1.4 - Strong Buy",
			 "tradeable":false,
			 "cryptoTradeable":false,
			 "shortName":"Microsoft Corporation",
			 "longName":"Microsoft Corporation",
			 "marketState":"CLOSED",
			 "exchangeTimezoneName":"America/New_York",
			 "exchangeTimezoneShortName":"EDT",
			 "gmtOffSetMilliseconds":-14400000,
			 "market":"us_market",
			 "esgPopulated":false,
			 "regularMarketChangePercent":0.553949,
			 "regularMarketPrice":513.71,
			 "hasPrePostMarketData":true,
			 "firstTradeDateMilliseconds":511108200000,
			 "priceHint":2,
			 "postMarketChangePercent":0.0564478,
			 "postMarketPrice":514.0,
			 "postMarketChange":0.289978,
			 "regularMarketChange":2.83002,
			 "regularMarketDayHigh":518.29,
			 "regularMarketDayRange":"510.3592 - 518.29",
			 "regularMarketDayLow":510.3592,
			 "regularMarketVolume":18998701,
			 "regularMarketPreviousClose":510.88,
			 "bid":512.03,
			 "ask":518.0,
			 "bidSize":4,
			 "askSize":2,
			 "fullExchangeName":"NasdaqGS",
			 "financialCurrency":"USD",
			 "regularMarketOpen":512.465,
			 "averageDailyVolume3Month":19908059,
			 "averageDailyVolume10Day":16039860,
			 "fiftyTwoWeekLowChange":168.92001,
			 "fiftyTwoWeekLowChangePercent":0.48992142,
			 "fiftyTwoWeekRange":"344.79 - 518.29",
			 "fiftyTwoWeekHighChange":-4.579956,
			 "fiftyTwoWeekHighChangePercent":-0.008836667,
			 "fiftyTwoWeekLow":344.79,
			 "fiftyTwoWeekHigh":518.29,
			 "fiftyTwoWeekChangePercent":20.382917,
			 "dividendDate":1757548800,
			 "earningsTimestamp":1753905600,
			 "earningsTimestampStart":1753905600,
			 "earningsTimestampEnd":1753905600,
			 "earningsCallTimestampStart":1753911000,
			 "earningsCallTimestampEnd":1753911000,
			 "isEarningsDateEstimate":false,
			 "trailingAnnualDividendRate":3.24,
			 "trailingPE":39.668728,
			 "dividendRate":3.32,
			 "trailingAnnualDividendYield":0.006341998,
			 "dividendYield":0.65,
			 "epsTrailingTwelveMonths":12.95,
			 "epsForward":14.95,
			 "epsCurrentYear":13.41751,
			 "priceEpsCurrentYear":38.286537,
			 "displayName":"Microsoft",
			 "symbol":"MSFT"
		  },
		  {
			 "language":"en-US",
			 "region":"US",
			 "quoteType":"OPTION",
			 "typeDisp":"Option",
			 "quoteSourceName":"Delayed Quote",
			 "triggerable":false,
			 "customPriceAlertConfidence":"NONE",
			 "currency":"USD",
			 "corporateActions":[
				
			 ],
			 "regularMarketTime":1753457622,
			 "underlyingSymbol":"SPY",
			 "exchange":"OPR",
			 "sourceInterval":15,
			 "exchangeDataDelayedBy":20,
			 "tradeable":false,
			 "cryptoTradeable":false,
			 "marketState":"CLOSED",
			 "exchangeTimezoneName":"America/New_York",
			 "exchangeTimezoneShortName":"EDT",
			 "gmtOffSetMilliseconds":-14400000,
			 "market":"us24_market",
			 "esgPopulated":false,
			 "regularMarketChangePercent":10.346976,
			 "regularMarketPrice":70.92,
			 "hasPrePostMarketData":false,
			 "firstTradeDateMilliseconds":1753070400000,
			 "priceHint":2,
			 "regularMarketChange":6.6500015,
			 "regularMarketDayHigh":71.16,
			 "regularMarketDayRange":"70.84 - 71.16",
			 "regularMarketDayLow":70.84,
			 "regularMarketVolume":100,
			 "regularMarketPreviousClose":64.27,
			 "bid":70.73,
			 "ask":73.38,
			 "fullExchangeName":"OPR",
			 "regularMarketOpen":70.95,
			 "fiftyTwoWeekLowChange":0.08000183,
			 "fiftyTwoWeekLowChangePercent":0.0011293314,
			 "fiftyTwoWeekRange":"70.84 - 71.16",
			 "fiftyTwoWeekHighChange":-0.2400055,
			 "fiftyTwoWeekHighChangePercent":-0.0033727584,
			 "fiftyTwoWeekLow":70.84,
			 "fiftyTwoWeekHigh":71.16,
			 "openInterest":2,
			 "optionsType":"Call",
			 "underlyingShortName":"SPDR S&P 500",
			 "expireDate":1753660800,
			 "expireIsoDate":"2025-07-28T00:00:00Z",
			 "symbol":"SPY250728C00565000"
		  }
	   ],
	   "error":null
	}
 }
 */
