import JSONAPI
import XCTest

final class CodableResourceTests: XCTestCase {
	func testDecoding() throws {
		// given
		let json = """
			{
			  "data": [
			    {
			      "type": "articles",
			      "id": "1",
			      "attributes": {
			        "title": "JSON:API paints my bikeshed!"
			      },
			      "relationships": {
			        "author": {
			          "data": {
			            "type": "people",
			            "id": "9"
			          }
			        },
			        "comments": {
			          "data": [
			            {
			              "type": "comments",
			              "id": "5"
			            },
			            {
			              "type": "comments",
			              "id": "12"
			            }
			          ]
			        }
			      }
			    }
			  ],
			  "included": [
			    {
			      "type": "people",
			      "id": "9",
			      "attributes": {
			        "firstName": "Dan",
			        "lastName": "Gebhardt",
			        "twitter": "dgeb"
			      }
			    },
			    {
			      "type": "comments",
			      "id": "5",
			      "attributes": {
			        "body": "First!"
			      },
			      "relationships": {
			        "author": {
			          "data": {
			            "type": "people",
			            "id": "2"
			          }
			        }
			      }
			    },
			    {
			      "type": "people",
			      "id": "9",
			      "attributes": {
			        "firstName": "Dan",
			        "lastName": "Gebhardt",
			        "twitter": "dgeb"
			      }
			    },
			    {
			      "type": "comments",
			      "id": "12",
			      "attributes": {
			        "body": "I like XML better"
			      },
			      "relationships": {
			        "author": {
			          "data": {
			            "type": "people",
			            "id": "9"
			          }
			        }
			      }
			    }
			  ]
			}
			""".data(using: .utf8)!

		// when
		let articles = try JSONDecoder().decode([Article].self, from: json)

		// then
		XCTAssertEqual(
			[
				Article(
					id: "1",
					title: "JSON:API paints my bikeshed!",
					author: Person(
						id: "9",
						firstName: "Dan",
						lastName: "Gebhardt",
						twitter: "dgeb"
					),
					comments: [
						Comment(id: "5", body: "First!"),
						Comment(
							id: "12",
							body: "I like XML better",
							author: Person(
								id: "9",
								firstName: "Dan",
								lastName: "Gebhardt",
								twitter: "dgeb"
							)
						),
					]
				)
			],
			articles
		)
	}

	func testDecodeNull() throws {
		// given
		let json = """
			{
			  "data": null
			}
			""".data(using: .utf8)!

		// when
		let articles = try JSONDecoder().decode([Article].self, from: json)

		// then
		XCTAssertEqual([], articles)
	}

	func testDecodeNullRelationshipToMany() throws {
		// given
		let json = """
			{
			  "data": [
			    {
			      "type": "articles",
			      "id": "1",
			      "attributes": {
			        "title": "JSON:API paints my bikeshed!"
			      },
			      "relationships": {
			        "author": {
			          "data": {
			            "type": "people",
			            "id": "9"
			          }
			        },
			        "comments": {
			          "data": null
			        }
			      }
			    }
			  ],
			  "included": [
			    {
			      "type": "people",
			      "id": "9",
			      "attributes": {
			        "firstName": "Dan",
			        "lastName": "Gebhardt",
			        "twitter": "dgeb"
			      }
			    }
			  ]
			}
			""".data(using: .utf8)!

		// when
		let articles = try JSONDecoder().decode([Article].self, from: json)

		// then
		XCTAssertEqual(
			[
				Article(
					id: "1",
					title: "JSON:API paints my bikeshed!",
					author: Person(
						id: "9",
						firstName: "Dan",
						lastName: "Gebhardt",
						twitter: "dgeb"
					),
					comments: []
				)
			],
			articles
		)
	}

	func testNullRelationshipToOne() throws {
		// given
		let json = """
			{
			  "data": {
			    "type": "comments",
			    "id": "12",
			    "attributes": {
			      "body": "I like XML better"
			    },
			    "relationships": {
			      "author": {
			        "data": null
			      }
			    }
			  }
			}
			""".data(using: .utf8)!

		// when
		let comment = try JSONDecoder().decode(Comment.self, from: json)

		// then
		XCTAssertEqual(
			Comment(id: "12", body: "I like XML better"),
			comment
		)
	}

	func testDecodeNullArrayAttribute() throws {
		// given
		let json = """
			{
			  "data": [
			    {
			      "type": "schedules",
			      "id": "1",
			      "attributes": {
			        "name": "Some schedule",
			        "tags": [
			          "some tag"
			        ]
			      }
			    },
			    {
			      "type": "schedules",
			      "id": "2",
			      "attributes": {
			        "name": "Some other schedule",
			        "tags": null
			      }
			    }
			  ]
			}
			""".data(using: .utf8)!

		// when
		let schedules = try JSONDecoder().decode([Schedule].self, from: json)

		// then
		XCTAssertEqual(
			[
				Schedule(id: "1", name: "Some schedule", tags: ["some tag"]),
				Schedule(id: "2", name: "Some other schedule", tags: []),
			],
			schedules
		)
	}

	func testDecodeTypeMismatch() throws {
		// given
		let json = """
			{
			  "data": {
			    "type": "people",
			    "id": "9",
			    "attributes": {
			  	"firstName": "Dan",
			  	"lastName": "Gebhardt",
			  	"twitter": "dgeb"
			    }
			  }
			}
			""".data(using: .utf8)!

		do {
			// when
			_ = try JSONDecoder().decode(Comment.self, from: json)
			XCTFail("Should throw DecodingError.typeMismatch.")
		} catch let DecodingError.typeMismatch(type, context) {
			// then
			XCTAssertEqual(String(describing: type), String(describing: Comment.self))
			XCTAssertEqual(
				context.debugDescription, "Resource type 'people' does not match expected type 'comments'")
		} catch {
			XCTFail("Expected DecodingError.typeMismatch but got \(error).")
		}
	}

	func testEncodingRoundtrip() throws {
		// given
		let articles: [Article] = [
			Article(
				id: "1",
				title: "Assure polite his really and others figure though",
				author: Person(
					id: "10",
					firstName: "Guille",
					lastName: "González"
				),
				comments: [
					Comment(
						id: "20",
						body: "Game of as rest time eyes with of this it.",
						author: Person(
							id: "11",
							firstName: "Yassir",
							lastName: "Ramdani"
						)
					),
					Comment(
						id: "21",
						body: "Add was music merry any truth since going.",
						author: Person(
							id: "12",
							firstName: "Alan",
							lastName: "Fineberg"
						)
					),
				]
			),
			Article(
				id: "2",
				title: "Procuring education on consulted assurance in do",
				author: Person(
					id: "11",
					firstName: "Yassir",
					lastName: "Ramdani"
				),
				comments: [
					Comment(
						id: "22",
						body: "Is sympathize he expression mr no travelling",
						author: Person(
							id: "10",
							firstName: "Guille",
							lastName: "González"
						)
					)
				]
			),
		]

		// when
		let data = try JSONEncoder().encode(articles)
		let decodedArticles = try JSONDecoder().decode([Article].self, from: data)

		// then
		XCTAssertEqual(decodedArticles, articles)
	}
}
