// Created by Leonid Serebryanyy on 13/09/2019.
// https://github.com/rebbdif
//
// CHCSVParserWrapper.swift


import Foundation
import UIKit
import CHCSVParser


class LineByLineParser<T>: NSObject, CHCSVParserDelegate {
	struct ParserError: Error {
		var message: String
		init(message: String) {
			self.message = message
		}
	}
	
	let url: URL
	let delimeter: unichar
	
	public typealias Fields = [String]
	typealias LineHandler = (UInt, Fields)->(Result<T?, ParserError>)
	let lineHandler: LineHandler
	
	typealias ParserResult =  Result<[T]?, ParserError>
	typealias ResultHandler = (ParserResult)->()
	var resultHandler: ResultHandler
	
	private var parser: CHCSVParser
	private var currentLine = [String]()
	private var results = [T]()
	private var error: ParserError?
	
	init(url: URL, delimeter: unichar, lineHandler: @escaping LineHandler, resultHandler: @escaping ResultHandler) {
		self.url = url
		self.delimeter = delimeter
		self.lineHandler = lineHandler
		self.resultHandler = resultHandler
		
		parser = CHCSVParser(contentsOfDelimitedURL: url, delimiter: delimeter)
		
		super.init()
		
		parser.delegate = self
	}
	
	public func parse() {
		parser.parse()
	}
	
	public func stop() {
		parser.cancelParsing()
	}
	
	// MARK: - CHCSVParserDelegate
	
	func parserDidBeginDocument(_ parser: CHCSVParser!) {
	}
	
	func parser(_ parser: CHCSVParser!, didBeginLine recordNumber: UInt) {
		currentLine = [String]()
	}
	
	func parser(_ parser: CHCSVParser!, didReadField field: String!, at fieldIndex: Int) {
		currentLine.append(field)
	}
	
	func parser(_ parser: CHCSVParser!, didEndLine recordNumber: UInt) {
		let result = lineHandler(recordNumber, currentLine)
		switch result {
		case .success(let value):
			if let value = value {
				results.append(value)
			}
		case .failure(let error):
			self.error = error
			stop()
		}
	}
	
	func parser(_ parser: CHCSVParser!, didFailWithError error: Error!) {
		let parserError = ParserError(message: error.localizedDescription)
		let result = ParserResult.failure(parserError)
		resultHandler(result)
	}
	
	func parserDidEndDocument(_ parser: CHCSVParser!) {
		if let error = error {
			resultHandler(ParserResult.failure(error))
		} else {
			let result = ParserResult.success(results)
			resultHandler(result)
		}
	}
}

extension Array {
	struct MyError: Error {
		init() {}
	}
	
	func safeObject(at index: Int) throws -> Element? {
		if self.count <= index {
			throw MyError()
		}
		return self[index]
	}
}
