// Created by Leonid Serebryanyy on 13/09/2019.
// https://github.com/rebbdif
//
// CHCSVParserWrapperExample.swift

import Foundation
import UIKit
import CHCSVParser


struct Item {
	// some fields
	var firstItem: String?
}


class ItemsFromCSVParser {
	
	struct ItemsParserError: Error {
		var title: String
		var message: String
	}
	
	private var filesParser: LineByLineParser<Item>?
	private lazy var filesManager = FileManager.default
	
	public func parse(fileAt url: URL?, completion:@escaping (ItemsParserError?)->()) {
		guard let url = url else {
			return
		}
		
		guard filesManager.fileExists(atPath: url.path) else {
			let error = ItemsParserError(title: "File not found", message: "Please try once more")
			completion(error)
			return
		}
		
		let fileId = url.lastPathComponent
		
		let delimeter = ";".utf16.first!
		let lineHandler = { (lineNumber: UInt, fields: LineByLineParser.Fields) -> Result<Item?, LineByLineParser<Item>.ParserError> in
			if lineNumber == 1 { // table header
				return .success(nil)
			}

			let firstItem = try? fields.safeObject(at: 0)

			// get fields
			
			let result = Item(firstItem: firstItem)
			return .success(result)
		}
		
		self.filesParser = LineByLineParser(url: url, delimeter: delimeter, lineHandler: lineHandler, resultHandler: {[weak self] (result: LineByLineParser<Item>.ParserResult) in
			switch result {
			case .success(let value):
				if let value = value {
					// handle value
				} else {
					let error = ItemsParserError(title: "Error parsing file", message: "No transactions were imported")
					completion(error)
				}
				
			case .failure(let error):
				let error = ItemsParserError(title: "Error parsing file", message: error.message)
				completion(error)
			}
		})
		self.filesParser?.parse()
	}
}

