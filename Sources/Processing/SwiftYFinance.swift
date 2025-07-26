//
//  SwiftYFinance.swift
//  SwiftYFinance
//
//  Created by Александр Дремов on 11.08.2020.

import Foundation
import SwiftyJSON

/** Main class of SwiftYFinance. Asynchronous methods' callback always will have format: `Some Data?, Error?`.
 * If error is non-nil, then data is going to be nil. Review Error description to find out what's wrong.
 * Synchronous API is also provided. The only difference is that it blocks the thread and returns data rather than passing it to the callback.
 */
public class SwiftYFinance {
    /**
     For some services,Yahoo requires crumb parameter and cookies.
     The framework fetches it during the first use.
     */
    static var crumb: String = ""
    static var cookies: String = ""

    /**
     The counter of requests. This parameter is added to the urls to change them as, sometimes, caching of content does a bad thing.
     By changing url with this parameter, the app expects uncached response.
     */
    static var cacheCounter: Int = 0

    /**
     The headers to use in all requests
     */
	// I've had problems in the past with other libraries/languages with some headers not being sufficient for Yahoo.
	// With this library broken, I started replacing the header with ones I saw still worked.
	// I think this header comes is one from YahooQuery.
	static var headers: [String: String] = [
		"sec-ch-ua": "\"Google Chrome\";v=\"131\", \"Chromium\";v=\"131\", \"Not_A Brand\";v=\"24\"",
		"sec-ch-ua-mobile": "?0",
		"sec-ch-ua-platform": "\"macOS\"",
		"upgrade-insecure-requests": "1",
		"user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
		"accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
		"sec-fetch-site": "none",
		"sec-fetch-mode": "navigate",
		"sec-fetch-user": "?1",
		"sec-fetch-dest": "document",
		"accept-encoding": "gzip, deflate, br, zstd",
		"accept-language": "en-US,en;q=0.9",
		"priority": "u=0, i"
	]
	
//	static var headers: [String: String] = [
//		"Accept": "*/*",
//		"Pragma": "no-cache",
//		"Origin": "https://finance.yahoo.com",
//		"Cache-Control": "no-cache",
//		"Host": "query1.finance.yahoo.com",
//		"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.2 Safari/605.1.15",
//		"User-Agent": "Mozilla/5.0",
//		"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36",
//		"Accept-Encoding": "gzip, deflate, br"
//	]

    /**
     Session to use in all requests.
     - Note: it is crucial as without httpShouldSetCookies parameter, sometimes, Yahoo sends invalid cookies that are saved. Then, all consequent requests corrupt.
	 Note: Update: This is not working any more with httpShouldSetCookies false. It needs to be turned on.
	 Yahoo is using both the cookies and the crumb together. With this off, I can get the crumb, but requests using the crumb will be 'Unauthorized' do to invalid crumb.
	 If I go to the getcrumb URL at the same time in a web browser, I see a different crumb than the one fetched here (and it persists for awhile hitting refresh),
	 further indicting that the cookie and crumb are linked at the hip.
	 Whatever workaround code was doing manually with cookies no longer works.
	 I don't know enough about the old cookie handling to remove it, so it remains, and could cause other problems.
     */
    static var session: URLSession = {
        let configuration = URLSessionConfiguration.default
//		configuration.httpShouldSetCookies = false
		configuration.httpShouldSetCookies = true
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.httpCookieStorage?.cookieAcceptPolicy = .always
        return URLSession(configuration: configuration)
    }()

    /**
     Fetches crumb and cookies
     - Note: blocks the thread.
     */
    private class func fetchCredentials() {
        let semaphore = DispatchSemaphore(value: 0)

        //        session
        //            .request("https://guce.yahoo.com/copyConsent")
        //            .response(queue: .global(qos: .userInteractive)) { response in
        //                semaphore.signal()
        //            }
        //
        //        semaphore.wait()

		// I've seen multiple libraries, such as yfinance and YahooQuery use this v1/test/getcrumb URL.
		// It is nicer because it only has the crumb and there is no extra data, and nothing to parse.
		let url = URL(string: "https://query2.finance.yahoo.com/v1/test/getcrumb")!
		// Setting a range of 1d is more efficient than otherwise because a lot less data needs to be sent back.
//		let url = URL(string: "https://finance.yahoo.com/quote/SPY/history?range=1d")!
//		let url = URL(string: "https://finance.yahoo.com/quote/SPY/history")!

		var request = URLRequest(url: url)
//		request.setValue("DEMO-API-KEY", forHTTPHeaderField: "x-api-key")
		for (key, value) in Self.headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		
		
        session
			// Changed to use a request because when this broke, I was unsure if the lack of headers was the reason for the breakage.
//			.dataTask(with: URL(string: "https://finance.yahoo.com/quote/AAPL/history")!) { data, response, error in
//			.dataTask(with: URL(string: "https://finance.yahoo.com/quote/SPY/history?range=1d")!) { data, response, error in
//			.dataTask(with: URL(string: "https://query2.finance.yahoo.com/quote/v1/test/getcrumb")!) { data, response, error in
			.dataTask(with: request) { data, response, error in
                defer {
                    semaphore.signal()
                }
                
				// I'm not sure if this is still correct now that I've turned cookies back on for URLSession.
                if let httpResponse = response as? HTTPURLResponse {
                    Self.cookies = httpResponse.allHeaderFields["Set-Cookie"] as? String ?? ""
                }
                
                guard let data = data else {
                    return
                }

                let dataString = String(data: data, encoding: .utf8)
                guard let dataString = dataString else {
                    return
                }
				//	print("dateString: \(dataString)")

				
				// NOTE: This block of code is for parsing for the crumb as of this writing.
				// However, this has broken before due to Yahoo changing things, which is why I'm mucking with this.
				// So rather than using this code, I'm opting for the test/getcrumb URL solution.
				// If Yahoo breaks that, the below code could be re-tried, although consider they may break this too at the same time.
				/*
				// Yahoo has changed what we need to look for.
				// let pattern = #""CrumbStore":\{"crumb":"(?<crumb>[^"]+)"\}"#
				// Need to look for something like this.
				// "crumb":"aetS0Za7Z/8"

				let pattern = #""crumb":\"(.*?)\""# // Captures the text inside the quotes after the colon

				do {
					let regex = try NSRegularExpression(pattern: pattern)
					
					// Find the first match in the string
					if let match = regex.firstMatch(in: dataString, options: [], range: NSRange(location: 0, length: dataString.utf16.count)) {
						
						// Extract the captured group (the string inside the quotes)
						if let range = Range(match.range(at: 1), in: dataString) {
							let extractedString = String(dataString[range])
							print("Extracted string: \(extractedString)") // Output: aetS0Za7Z58
							Self.crumb = extractedString

						}
					}
				} catch {
					print("Error creating regular expression: \(error)")
				}
				 */
				
//				print("dataString:\(dataString).") // Output: aetS0Za7Z/8
				Self.crumb = dataString
            }
            .resume()

        semaphore.wait()
    }

    /**
     Fetches credentials if they were not set.
     */
    private class func prepareCredentials() {
        if Self.crumb == ""{
            Self.fetchCredentials()
        }
    }

    /**
     Searches quote in Yahoo finances and returns found results
     - Parameters:
     - searchTerm: String to search
     - quotesCount: Maximum found elements to load
     - queue: queue to use for request asyncgtonous processing
     - callback: callback, two parameters will be passed
     */
    public class func fetchSearchDataBy(searchTerm: String, quotesCount: Int = 20, queue: DispatchQueue = .main, callback: @escaping ([YFQuoteSearchResult]?, Error?) -> Void) {
        /*
         https://query1.finance.yahoo.com/v1/finance/search
         */
        if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            callback([], nil)
            return
        }
        Self.prepareCredentials()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "query1.finance.yahoo.com"
        urlComponents.path = "/v1/finance/search"
        Self.cacheCounter += 1
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: searchTerm),
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "crumb", value: Self.crumb),
            URLQueryItem(name: "quotesCount", value: String(quotesCount)),
            URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
        ]

        var request = URLRequest(url: urlComponents.url!)
        for (key, value) in Self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.cachePolicy = .reloadIgnoringLocalCacheData

        session.dataTask(with: request) { data, response, error in
            // Switch to the requested queue for callback handling
            queue.async {
                if let error = error {
                    callback(nil, error)
                    return
                }

                guard let data = data else {
                    callback(nil, YFinanceResponseError(message: "No data received"))
                    return
                }

                do {
                    let json = try JSON(data: data)

                    if let errorDesc = json["chart"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = json["finance"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = json["search"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }

                    guard let quotesArray = json["quotes"].array else {
                        callback(nil, YFinanceResponseError(message: "Empty response"))
                        return
                    }

                    let result = quotesArray.map { found in
                        YFQuoteSearchResult(
                            symbol: found["symbol"].string,
                            shortname: found["shortname"].string,
                            longname: found["longname"].string,
                            exchange: found["exchange"].string,
                            assetType: found["typeDisp"].string
                        )
                    }
                    callback(result, nil)
                } catch {
                    callback(nil, error)
                }
            }
        }.resume()
    }

    /**
     The same as `SwiftYFinance.fetchSearchDataBy` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncFetchSearchDataBy(searchTerm: String, quotesCount: Int = 20) -> ([YFQuoteSearchResult]?, Error?) {
        var retData: [YFQuoteSearchResult]?, retError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        self.fetchSearchDataBy(searchTerm: searchTerm, quotesCount: quotesCount, queue: DispatchQueue.global(qos: .utility)) {
            data, error in
            defer {
                semaphore.signal()
            }
            retData = data
            retError = error
        }

        semaphore.wait()
        return (retData, retError)
    }

    /**
     The same as `SwiftYFinance.fetchSearchDataBy` except that it searches for news
     */
    public class func fetchSearchDataBy(searchNews: String, newsCount: Int = 20, queue: DispatchQueue = .main, callback: @escaping ([YFNewsSearchResult]?, Error?) -> Void) {
        /*
         https://query1.finance.yahoo.com/v1/finance/search
         */

        if searchNews.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            callback([], nil)
            return
        }

        Self.prepareCredentials()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "query1.finance.yahoo.com"
        urlComponents.path = "/v1/finance/search"
        Self.cacheCounter += 1
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: searchNews),
            URLQueryItem(name: "crumb", value: Self.crumb),
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "newsCount", value: String(newsCount)),
            URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
        ]

        var request = URLRequest(url: urlComponents.url!)
        for (key, value) in Self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        session.dataTask(with: request) { data, response, error in
            queue.async {
                if let error = error {
                    callback(nil, error)
                    return
                }

                guard let data = data else {
                    callback(nil, YFinanceResponseError(message: "No data received"))
                    return
                }

                do {
                    let json = try JSON(data: data)

                    if let errorDesc = json["chart"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = json["finance"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = json["search"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }

                    guard let quotesArray = json["quotes"].array else {
                        callback(nil, YFinanceResponseError(message: "Empty response"))
                        return
                    }

                    let result = quotesArray.map { found in
                        YFNewsSearchResult(
                            type: found["type"].string,
                            uuid: found["uuid"].string,
                            link: found["link"].string,
                            title: found["title"].string,
                            publisher: found["publisher"].string,
                            providerPublishTime: found["providerPublishTime"].string
                        )
                    }
                    callback(result, nil)
                } catch {
                    callback(nil, error)
                }
            }
        }.resume()
    }

    /**
     The same as `SwiftYFinance.fetchSearchDataBy(...)` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncFetchSearchDataBy(searchNews: String, newsCount: Int = 20) -> ([YFNewsSearchResult]?, Error?) {
        var retData: [YFNewsSearchResult]?, retError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        self.fetchSearchDataBy(searchNews: searchNews, newsCount: newsCount, queue: DispatchQueue.global(qos: .utility)) {
            data, error in
            defer {
                semaphore.signal()
            }
            retData = data
            retError = error
        }
        semaphore.wait()
        return (retData, retError)
    }

    /**
     Fetches summary information about identifier.
     - Warning: Identifier must exist or data will be nil and error will be setten
     - Parameters:
     - identifier: Name of identifier
     - selection: Which area of summary to get
     - queue: queue to use for request asyncgtonous processing
     - callback: callback, two parameters will be passed
     */
    public class func summaryDataBy(identifier: String, selection: QuoteSummarySelection = .supported, queue: DispatchQueue = .main, callback: @escaping (IdentifierSummary?, Error?) -> Void) {
        summaryDataBy(identifier: identifier, selection: [selection], queue: queue, callback: callback)
    }

    /**
     The same as `SwiftYFinance.summaryDataBy(...)` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncSummaryDataBy(identifier: String, selection: QuoteSummarySelection = .supported) -> (IdentifierSummary?, Error?) {
        self.syncSummaryDataBy(identifier: identifier, selection: [selection])
    }
	
    /**
     Fetches summary information about identifier.
     - Warning: Identifier must exist or data will be nil and error will be setten
     - Parameters:
     - identifier: Name of identifier
     - selection: Which areas of summary to get
     - queue: queue to use for request asyncgtonous processing
     - callback: callback, two parameters will be passed
     - TODO: return not JSON but custom type
     */
    public class func summaryDataBy(identifier: String, selection: [QuoteSummarySelection], queue: DispatchQueue = .main, callback: @escaping (IdentifierSummary?, Error?) -> Void) {
        if identifier.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            callback(nil, YFinanceResponseError(message: "Empty identifier"))
            return
        }

        Self.prepareCredentials()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "query2.finance.yahoo.com"
        urlComponents.path = "/v10/finance/quoteSummary/\(identifier)"
        Self.cacheCounter += 1
        urlComponents.queryItems = [
            URLQueryItem(name: "modules", value: selection.map({
                data in
                String(data.rawValue)
            }).joined(separator: ",")),
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "region", value: "US"),
            URLQueryItem(name: "crumb", value: Self.crumb),
            URLQueryItem(name: "includePrePost", value: "true"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
            URLQueryItem(name: ".tsrc", value: "finance"),
//            URLQueryItem(name: "symbols", value: identifier),
            URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
        ]

        var request = URLRequest(url: urlComponents.url!)
        for (key, value) in Self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

//		let print_url = request.url
//		print("request URL \(print_url)")
        session.dataTask(with: request) { data, response, error in
            queue.async {
                if let error = error {
                    callback(nil, error)
                    return
                }

                guard let data = data else {
                    callback(nil, YFinanceResponseError(message: "No data received"))
                    return
                }

                do {
                    let jsonRaw = try JSON(data: data)

                    if let errorDesc = jsonRaw["chart"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = jsonRaw["finance"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = jsonRaw["quoteSummary"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }

                    callback(IdentifierSummary(information: jsonRaw["quoteSummary"]["result"][0]), nil)
                } catch {
                    callback(nil, error)
                }
            }
        }.resume()
    }

    /**
     The same as `SwiftYFinance.summaryDataBy(...)` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncSummaryDataBy(identifier: String, selection: [QuoteSummarySelection]) -> (IdentifierSummary?, Error?) {
        var retData: IdentifierSummary?, retError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        self.summaryDataBy(identifier: identifier, selection: selection, queue: DispatchQueue.global(qos: .utility)) {
            data, error in
            defer {
                semaphore.signal()
            }
            retData = data
            retError = error
        }

        semaphore.wait()
        return (retData, retError)
    }

    /**
     Fetches the most recent data about identifier collecting basic information.
     - Warning: Identifier must exist or data will be nil and error will be setten
     - Parameters:
     - identifier: Name of identifier
     - queue: queue to use for request asyncgtonous processing
     - callback: callback, two parameters will be passed
     */
    public class func recentDataBy(identifier: String, queue: DispatchQueue = .main, callback: @escaping (RecentStockData?, Error?) -> Void) {
        if identifier.trimmingCharacters(in: .whitespacesAndNewlines) == ""{
            callback(nil, YFinanceResponseError(message: "Empty identifier"))
            return
        }

        Self.prepareCredentials()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "query1.finance.yahoo.com"
        urlComponents.path = "/v8/finance/chart/\(identifier)"
        Self.cacheCounter += 1
        urlComponents.queryItems = [
 //           URLQueryItem(name: "symbols", value: identifier),
            URLQueryItem(name: "symbol", value: identifier),
            URLQueryItem(name: "region", value: "US"),
            URLQueryItem(name: "lang", value: "en-US"),
            URLQueryItem(name: "includePrePost", value: "false"),
            URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
            URLQueryItem(name: "interval", value: "2m"),
            URLQueryItem(name: "range", value: "1d"),
            URLQueryItem(name: "crumb", value: Self.crumb),
            URLQueryItem(name: ".tsrc", value: "finance"),
            URLQueryItem(name: "period1", value: String(Int(Date().timeIntervalSince1970))),
            URLQueryItem(name: "period2", value: String(Int(Date().timeIntervalSince1970) + 10)),
            URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
        ]

        var request = URLRequest(url: urlComponents.url!)
        for (key, value) in Self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        session.dataTask(with: request) { data, response, error in
            queue.async {
                if let error = error {
                    callback(nil, error)
                    return
                }

                guard let data = data else {
                    callback(nil, YFinanceResponseError(message: "No data received"))
                    return
                }

                do {
                    let json = try JSON(data: data)

                    if let errorDesc = json["chart"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = json["finance"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }

                    guard let metadata = json["chart"]["result"][0]["meta"].dictionary else {
                        callback(nil, YFinanceResponseError(message: "Invalid response format"))
                        return
                    }

                    callback(RecentStockData(
                        currency: metadata["currency"]?.string,
                        symbol: metadata["symbol"]?.string,
                        exchangeName: metadata["exchangeName"]?.string,
                        instrumentType: metadata["instrumentType"]?.string,
                        firstTradeDate: metadata["firstTradeDate"]?.int,
                        regularMarketTime: metadata["regularMarketTime"]?.int,
                        gmtoffset: metadata["gmtoffset"]?.int,
                        timezone: metadata["timezone"]?.string,
                        exchangeTimezoneName: metadata["exchangeTimezoneName"]?.string,
                        regularMarketPrice: metadata["regularMarketPrice"]?.float,
                        chartPreviousClose: metadata["chartPreviousClose"]?.float,
                        previousClose: metadata["previousClose"]?.float,
                        scale: metadata["scale"]?.int,
                        priceHint: metadata["priceHint"]?.int
                    ), nil)
                } catch {
                    callback(nil, error)
                }
            }
        }.resume()
    }

    /**
     The same as `SwiftYFinance.recentDataBy(...)` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncRecentDataBy(identifier: String) -> (RecentStockData?, Error?) {
        var retData: RecentStockData?, retError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        self.recentDataBy(identifier: identifier, queue: DispatchQueue.global(qos: .utility)) {
            data, error in
            defer {
                semaphore.signal()
            }
            retData = data
            retError = error
        }
        semaphore.wait()
        return (retData, retError)
    }

    /**
     Fetches chart data points
     - Warning:
     * Identifier must exist or data will be nil and error will be setten
     * When you select minute – day interval, you can't get historicaly old points. Select oneday interval if you want to fetch maximum available number of points.
     - Parameters:
     - identifier: Name of identifier
     - start: `Date` type start of points retrieve
     - end: `Date` type end of points retrieve
     - interval: interval between points
     - queue: queue to use for request asyncgtonous processing
     - callback: callback, two parameters will be passed
     */
    public class func chartDataBy(identifier: String, start: Date = Date(), end: Date = Date(), interval: ChartTimeInterval = .oneday, queue: DispatchQueue = .main, callback: @escaping ([StockChartData]?, Error?) -> Void) {
        if identifier.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            callback(nil, YFinanceResponseError(message: "Empty identifier"))
            return
        }

        Self.prepareCredentials()
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "query1.finance.yahoo.com"
        urlComponents.path = "/v8/finance/chart/\(identifier)"
        Self.cacheCounter += 1
        urlComponents.queryItems = [
//            URLQueryItem(name: "symbols", value: identifier),
            URLQueryItem(name: "symbol", value: identifier),
            URLQueryItem(name: "crumb", value: Self.crumb),
            URLQueryItem(name: "period1", value: String(Int(start.timeIntervalSince1970))),
            URLQueryItem(name: "period2", value: String(Int(end.timeIntervalSince1970))),
            URLQueryItem(name: "interval", value: interval.rawValue),
            URLQueryItem(name: "includePrePost", value: "true"),
            URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
        ]
        // print(urlComponents.url?.absoluteString ?? "No URL provided")

        var request = URLRequest(url: urlComponents.url!)
        for (key, value) in Self.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        session.dataTask(with: request) { data, response, error in
            queue.async {
                if let error = error {
                    callback(nil, error)
                    return
                }

                guard let data = data else {
                    callback(nil, YFinanceResponseError(message: "No data received"))
                    return
                }

                do {
                    let json = try JSON(data: data)

                    if let errorDesc = json["chart"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }
                    if let errorDesc = json["finance"]["error"]["description"].string {
                        callback(nil, YFinanceResponseError(message: errorDesc))
                        return
                    }

                    guard let fullData = json["chart"]["result"][0].dictionary,
                          let quote = fullData["indicators"]?["quote"][0].dictionary,
                          let timestamps = fullData["timestamp"]?.array else {
                        callback(nil, YFinanceResponseError(message: "Invalid response format"))
                        return
                    }

                    let adjClose = fullData["indicators"]?["adjclose"][0]["adjclose"].array

                    var result: [StockChartData] = []

                    for reading in 0..<timestamps.count {
                        guard let timestamp = timestamps[reading].float else { continue }
                        
                        result.append(StockChartData(
                            date: Date(timeIntervalSince1970: Double(timestamp)),
                            volume: quote["volume"]?[reading].int,
                            open: quote["open"]?[reading].float,
                            close: quote["close"]?[reading].float,
                            adjclose: adjClose?[reading].float,
                            low: quote["low"]?[reading].float,
                            high: quote["high"]?[reading].float)
                        )
                    }
                    callback(result, nil)
                } catch {
                    callback(nil, error)
                }
            }
        }.resume()
    }

    /**
     The same as `SwiftYFinance.chartDataBy(...)` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncChartDataBy(identifier: String, start: Date = Date(), end: Date = Date(), interval: ChartTimeInterval = .oneday) -> ([StockChartData]?, Error?) {
        var retData: [StockChartData]?, retError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        self.chartDataBy(identifier: identifier, start: start, end: end, interval: interval, queue: DispatchQueue.global(qos: .utility)) {
            data, error in
            defer {
                semaphore.signal()
            }
            retData = data
            retError = error
        }
        semaphore.wait()
        return (retData, retError)
    }

    /**
     Fetches chart data at moment or the closest one from the past.
     - Warning: Identifier must exist or data will be nil and error will be setten
     - Parameters:
     - identifier: Name of identifier
     - moment: moment at witch data will be fetched
     - futureMargin: seconds to margin into the future
     - queue: queue to use for request asyncgtonous processing
     - queue: queue to use for request asyncgtonous processing
     - callback: callback, two parameters will be passed
     */
    public class func recentChartDataAtMoment(identifier: String, moment: Date = Date(), futureMargin: TimeInterval = 0, queue: DispatchQueue = .main, callback: @escaping (StockChartData?, Error?) -> Void) {
        let momentWithMargin = Date(timeIntervalSince1970: moment.timeIntervalSince1970 + futureMargin)
        self.chartDataBy(identifier: identifier, start: Date(timeIntervalSince1970: momentWithMargin.timeIntervalSince1970 - 7 * 24 * 60 * 60 + futureMargin), end: momentWithMargin, interval: .oneminute, queue: queue) {
            dataLet, errorLet in

            var data = dataLet
            var error = errorLet

            if data == nil {
                (data, error) = self.syncChartDataBy(identifier: identifier, start: Date(timeIntervalSince1970: momentWithMargin.timeIntervalSince1970 - 7 * 24 * 60 * 60 + futureMargin), end: momentWithMargin, interval: .oneday)
            }

            if data == nil {
                callback(nil, error)
            } else {
                if data!.isEmpty {
                    callback(nil, YFinanceResponseError(message: "No data found at this(\(moment)) moment"))
                    return
                }
                var i = data!.count - 1
                var selectedForReturn: StockChartData = data![data!.count - 1]
                while selectedForReturn.close == nil && selectedForReturn.open == nil && i > 0 {
                    i -= 1
                    selectedForReturn = data![i]
                }
                callback(selectedForReturn, error)
            }
        }
    }

    /**
     The same as `SwiftYFinance.recentChartDataAtMoment(...)` except that it executes synchronously and returns data rather than giving it to the callback.
     */
    public class func syncRecentChartDataAtMoment(identifier: String, moment: Date = Date(), futureMargin: TimeInterval = 0) -> (StockChartData?, Error?) {
        var retData: StockChartData?, retError: Error?
        let semaphore = DispatchSemaphore(value: 0)
        self.recentChartDataAtMoment(identifier: identifier, moment: moment, futureMargin: futureMargin, queue: DispatchQueue.global(qos: .utility)) {
            data, error in
            defer {
                semaphore.signal()
            }
            retData = data
            retError = error
        }

        semaphore.wait()
        return (retData, retError)
    }
	
	
	
	/**
	 Fetches the latest quotes for the provided list of identifiers.
	 This is more efficent than recentDataBy(...) for multiple reasons.
	 1. This API transmits less data back than recentDataBy because the latter uses the Yahoo chart API which seems to send back a lot of additional historical stuff that this library happens to throw away.
	 2. This API is designed for submitting multiple identifiers in one request.
	 Since Yahoo may limit or ban you for too much usage, it is worth considering minimizing your traffic, hence the reason I implemented this API instead of just relying on recentDataBy.
	 - Parameters:
	 - identifiers: An array of tickers. Yahoo also seems to support contractSymbols for identifiers. I did not find information as to if there is a hard limit on the number of tickers in the list, but a general warning that Yahoo looks at your overall traffic usage through the combination off all your different requests.
	 - queue: queue to use for request asyncgtonous processing
	 - callback: callback, two parameters will be passed
	 */
	public class func latestQuotes(identifiers: [String], queue: DispatchQueue = .main, callback: @escaping ([Quote]?, Error?) -> Void) {
		guard !identifiers.isEmpty else { callback(nil, YFinanceResponseError(message: "Empty identifiers")); return; }
		for identifier in identifiers {
			if identifier.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
				callback(nil, YFinanceResponseError(message: "Empty identifier"))
				return
			}
		}
		let comma_separated_tickers:String = identifiers.joined(separator: ",")

		Self.prepareCredentials()
		// https://query2.finance.yahoo.com/v7/finance/quote?symbols=AAPL,MSFT&crumb=4IjOdW3MQPU
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "query2.finance.yahoo.com"
		urlComponents.path = "/v7/finance/quote"
		Self.cacheCounter += 1
		urlComponents.queryItems = [
			URLQueryItem(name: "symbols", value: comma_separated_tickers),
			URLQueryItem(name: "region", value: "US"),
			URLQueryItem(name: "lang", value: "en-US"),
			URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
			URLQueryItem(name: "crumb", value: Self.crumb),
			URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
		]

		var request = URLRequest(url: urlComponents.url!)
		for (key, value) in Self.headers {
			request.setValue(value, forHTTPHeaderField: key)
		}

//		print("request URL \(request.url)")
		session.dataTask(with: request) { data, response, error in
			queue.async {
				if let error = error {
					callback(nil, error)
					return
				}

				guard let data = data else {
					callback(nil, YFinanceResponseError(message: "No data received"))
					return
				}

				do {
					let jsonRaw = try JSON(data: data)

					if let errorDesc = jsonRaw["quoteResponse"]["error"]["description"].string {
						callback(nil, YFinanceResponseError(message: errorDesc))
						return
					}



					// This API only handles one ticker, but it appears the Yahoo API
					// was structured so it could return an array of ticker results.
					// We will ignore any extras here.
					// But make sure there is at least one entry.
					if jsonRaw["quoteResponse"]["result"].array == nil
						|| jsonRaw["quoteResponse"]["result"].array!.isEmpty {
						callback(nil, YFinanceResponseError(message: "No quote data received"))
						return
					}
					
					var quotes_array:[Quote] = []
					for quote_element in jsonRaw["quoteResponse"]["result"].array! {
						let quote = Quote(information: quote_element)
						quotes_array.append(quote)
					}
					
					callback(quotes_array, nil)
				} catch {
					callback(nil, error)
				}
			}
		}.resume()
	}
	
	/**
	 The same as `SwiftYFinance.latestQuotes(...)` except that it executes synchronously and returns data rather than giving it to the callback.
	 */
	public class func latestQuotes(identifiers: [String]) -> ([Quote]?, Error?) {
		var retData: [Quote]?, retError: Error?
		let semaphore = DispatchSemaphore(value: 0)
		self.latestQuotes(identifiers: identifiers, queue: DispatchQueue.global(qos: .utility)) {
			data, error in
			defer {
				semaphore.signal()
			}
			retData = data
			retError = error
		}

		semaphore.wait()
		return (retData, retError)
	}
	
	/**
	 Fetches current options data.
	 - Warning: Identifier must exist or data will be nil and error will be setten
	 - Parameters:
	 - identifier: ticker of underlying identifier or the contractSymbol
	 - expirationDate: Specifying the date will specify the options chain that matches this expiry. It must be an exact match for Yahoo or you will get an empty options chain, but it will still provide the array of expiration dates so you can do a second lookup using those dates. If you pass nil, Yahoo provides you a default options chain which appears to be of the closest expiration. Specifying a date while passing the contractSymbol as the identifer (instead of the underlying) probably doesn't do  anything useful.
	 - queue: queue to use for request asyncgtonous processing
	 - callback: callback, two parameters will be passed
	 */
	public class func optionsChain(identifier: String, expirationDate:Date? = nil, queue: DispatchQueue = .main, callback: @escaping (OptionsChain?, Error?) -> Void) {
		if identifier.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
			callback(nil, YFinanceResponseError(message: "Empty identifier"))
			return
		}

		Self.prepareCredentials()
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "query2.finance.yahoo.com"
		urlComponents.path = "/v7/finance/options/\(identifier)"
		Self.cacheCounter += 1
		urlComponents.queryItems = [
			URLQueryItem(name: "region", value: "US"),
			URLQueryItem(name: "lang", value: "en-US"),
			URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
			URLQueryItem(name: "crumb", value: Self.crumb),
			URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter))
		]
		
		if expirationDate != nil {
			let val = String(Int(expirationDate!.timeIntervalSince1970))
			urlComponents.queryItems?.append(URLQueryItem(name: "date", value: val))
		}

		var request = URLRequest(url: urlComponents.url!)
		for (key, value) in Self.headers {
			request.setValue(value, forHTTPHeaderField: key)
		}

//		print("request URL \(request.url)")
		session.dataTask(with: request) { data, response, error in
			queue.async {
				if let error = error {
					callback(nil, error)
					return
				}

				guard let data = data else {
					callback(nil, YFinanceResponseError(message: "No data received"))
					return
				}

				do {
					let jsonRaw = try JSON(data: data)

					if let errorDesc = jsonRaw["optionChain"]["error"]["description"].string {
						callback(nil, YFinanceResponseError(message: errorDesc))
						return
					}

					// This API only handles one ticker, but it appears the Yahoo API
					// was structured so it could return an array of ticker results.
					// We will ignore any extras here.
					// But make sure there is at least one entry.
					if jsonRaw["optionChain"]["result"].array == nil
						|| jsonRaw["optionChain"]["result"].array!.isEmpty {
						callback(nil, YFinanceResponseError(message: "No options data received"))
						return
					}
					
					callback(OptionsChain(information: jsonRaw["optionChain"]["result"][0]), nil)
				} catch {
					callback(nil, error)
				}
			}
		}.resume()
	}
	/**
	 The same as `SwiftYFinance.optionsChain(...)` except that it executes synchronously and returns data rather than giving it to the callback.
	 */
	public class func optionsChain(identifier: String, expirationDate:Date? = nil) -> (OptionsChain?, Error?) {
		var retData: OptionsChain?, retError: Error?
		let semaphore = DispatchSemaphore(value: 0)
		self.optionsChain(identifier: identifier, expirationDate: expirationDate, queue: DispatchQueue.global(qos: .utility)) {
			data, error in
			defer {
				semaphore.signal()
			}
			retData = data
			retError = error
		}

		semaphore.wait()
		return (retData, retError)
	}
	
	/**
	 Fetches current options data if you know the contractSymbol. This version gives you the most data in a one-shot query, as it gives you information about both the option (e.g. price & implied volatility) and the underlying (e.g. price & dividend yieild).
	 - Warning: Identifier must exist or data will be nil and error will be setten
	 - Parameters:
	 - identifier: ticker of underlying identifier or the contractSymbol, e.g. SPY
	 - contractSymbol: the canonical form of the options symbol, e.g. SPY250728C00565000
	 - queue: queue to use for request asyncgtonous processing
	 - callback: callback, two parameters will be passed
	 */
	public class func optionsChain(underlyingIdentifier: String, contractSymbol:String, queue: DispatchQueue = .main, callback: @escaping (OptionsChain?, Error?) -> Void) {
		if underlyingIdentifier.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
			callback(nil, YFinanceResponseError(message: "Empty identifier"))
			return
		}
		if contractSymbol.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
			callback(nil, YFinanceResponseError(message: "Empty contractSymbol"))
			return
		}
		
		Self.prepareCredentials()
		var urlComponents = URLComponents()
		urlComponents.scheme = "https"
		urlComponents.host = "query2.finance.yahoo.com"
		urlComponents.path = "/v7/finance/options/\(underlyingIdentifier)"
		Self.cacheCounter += 1
		urlComponents.queryItems = [
			URLQueryItem(name: "region", value: "US"),
			URLQueryItem(name: "lang", value: "en-US"),
			URLQueryItem(name: "corsDomain", value: "finance.yahoo.com"),
			URLQueryItem(name: "crumb", value: Self.crumb),
			URLQueryItem(name: "cachecounter", value: String(Self.cacheCounter)),
			URLQueryItem(name: "contractSymbol", value: contractSymbol)
		]
		
		var request = URLRequest(url: urlComponents.url!)
		for (key, value) in Self.headers {
			request.setValue(value, forHTTPHeaderField: key)
		}

//		print("request URL \(request.url)")
		session.dataTask(with: request) { data, response, error in
			queue.async {
				if let error = error {
					callback(nil, error)
					return
				}

				guard let data = data else {
					callback(nil, YFinanceResponseError(message: "No data received"))
					return
				}

				do {
					let jsonRaw = try JSON(data: data)

					if let errorDesc = jsonRaw["optionChain"]["error"]["description"].string {
						callback(nil, YFinanceResponseError(message: errorDesc))
						return
					}
					if let errorDesc = jsonRaw["finance"]["error"]["description"].string {
						callback(nil, YFinanceResponseError(message: errorDesc))
						return
					}
					if let errorDesc = jsonRaw["quoteSummary"]["error"]["description"].string {
						callback(nil, YFinanceResponseError(message: errorDesc))
						return
					}


					// This API only handles one ticker, but it appears the Yahoo API
					// was structured so it could return an array of ticker results.
					// We will ignore any extras here.
					// But make sure there is at least one entry.
					if jsonRaw["optionChain"]["result"].array == nil
						|| jsonRaw["optionChain"]["result"].array!.isEmpty {
						callback(nil, YFinanceResponseError(message: "No options data received"))
						return
					}
					
					callback(OptionsChain(information: jsonRaw["optionChain"]["result"][0]), nil)
				} catch {
					callback(nil, error)
				}
			}
		}.resume()
	}
	/**
	 The same as `SwiftYFinance.optionsChain(...)` except that it executes synchronously and returns data rather than giving it to the callback.
	 */
	public class func optionsChain(underlyingIdentifier: String, contractSymbol:String) -> (OptionsChain?, Error?) {
		var retData: OptionsChain?, retError: Error?
		let semaphore = DispatchSemaphore(value: 0)
		self.optionsChain(underlyingIdentifier: underlyingIdentifier, contractSymbol: contractSymbol, queue: DispatchQueue.global(qos: .utility)) {
			data, error in
			defer {
				semaphore.signal()
			}
			retData = data
			retError = error
		}

		semaphore.wait()
		return (retData, retError)
	}
	
}
