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
		let articles = try JSONAPIDecoder().decode([Article].self, from: json)

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
		let articles = try JSONAPIDecoder().decode([Article].self, from: json)

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
		let articles = try JSONAPIDecoder().decode([Article].self, from: json)

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
		let comment = try JSONAPIDecoder().decode(Comment.self, from: json)

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
		let schedules = try JSONAPIDecoder().decode([Schedule].self, from: json)

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
			_ = try JSONAPIDecoder().decode(Comment.self, from: json)
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
		let data = try JSONAPIEncoder().encode(articles)
		let decodedArticles = try JSONAPIDecoder().decode([Article].self, from: data)

		// then
		XCTAssertEqual(decodedArticles, articles)
	}

	func testRelationshipToOnePolymorphic() throws {
		// given
		let json = """
			{
				"data": {
					"type": "single_attachment_messages",
					"id": "1",
					"attributes": {
						"text": "Look what I just found!"
					},
					"relationships": {
						"attachment": {
							"data": {
								"type": "images",
								"id": "42"
							}
						}
					}
				},
				"included": [
					{
						"type": "images",
						"id": "42",
						"attributes": {
							"url": "https://via.placeholder.com/640x480",
							"width": 640,
							"height": 480
						}
					}
				]
			}
			""".data(using: .utf8)!

		// when
		let message = try JSONAPIDecoder().decode(SingleAttachmentMessage.self, from: json)

		// then
		XCTAssertEqual(
			SingleAttachmentMessage(
				id: "1",
				text: "Look what I just found!",
				attachment: .image(
					Image(
						id: "42",
						url: URL(string: "https://via.placeholder.com/640x480")!,
						width: 640,
						height: 480
					)
				)
			),
			message
		)
	}

	func testRelationshipToManyPolymorphic() throws {
		// given
		let json = """
			{
				"data": {
					"type": "messages",
					"id": "1",
					"attributes": {
						"text": "Look what I just found!"
					},
					"relationships": {
						"attachments": {
							"data": [
								{
									"type": "images",
									"id": "42"
								},
								{
									"type": "audios",
									"id": "66"
								}
							]
						}
					}
				},
				"included": [
					{
						"type": "images",
						"id": "42",
						"attributes": {
							"url": "https://via.placeholder.com/640x480",
							"width": 640,
							"height": 480
						}
					},
					{
						"type": "audios",
						"id": "66",
						"attributes": {
							"url": "https://audio.com/NeverGonnaGiveYouUp.mp3",
							"title": "Never Gonna Give You Up"
						}
					}
				]
			}
			""".data(using: .utf8)!

		// when
		let message = try JSONAPIDecoder().decode(Message.self, from: json)

		// then
		XCTAssertEqual(
			Message(
				id: "1",
				text: "Look what I just found!",
				attachments: [
					.image(
						Image(
							id: "42",
							url: URL(string: "https://via.placeholder.com/640x480")!,
							width: 640,
							height: 480
						)
					),
					.audio(
						Audio(
							id: "66",
							url: URL(string: "https://audio.com/NeverGonnaGiveYouUp.mp3")!,
							title: "Never Gonna Give You Up"
						)
					),
				]
			),
			message
		)

		// when
		let data = try JSONAPIEncoder().encode(message)
		let decodedMessage = try JSONAPIDecoder().decode(Message.self, from: data)

		// then
		XCTAssertEqual(decodedMessage, message)
	}

	func testUnhandledResourceType() throws {
		// given
		let json = """
			{
				"data": {
					"type": "single_attachment_messages",
					"id": "1",
					"attributes": {
						"text": "Look what I just found!"
					},
					"relationships": {
						"attachment": {
							"data": {
								"type": "videos",
								"id": "42"
							}
						}
					}
				},
				"included": [
					{
						"type": "videos",
						"id": "42",
						"attributes": {
							"url": "https://example.com/video.mp4",
						}
					}
				]
			}
			""".data(using: .utf8)!

		do {
			// when
			_ = try JSONAPIDecoder().decode(SingleAttachmentMessage.self, from: json)
			XCTFail("Should throw JSONAPIDecodingError.unhandledResourceType.")
		} catch let JSONAPIDecodingError.unhandledResourceType(unionType, resourceType) {
			// then
			XCTAssertEqual(String(describing: unionType), String(describing: Attachment.self))
			XCTAssertEqual(resourceType, "videos")
		} catch {
			XCTFail("Expected JSONAPIDecodingError.unhandledResourceType but got \(error).")
		}
	}

	func testIgnoresUnhandledResourceTypeRelationshipToOne() throws {
		// given
		let json = """
			{
				"data": {
					"type": "single_attachment_messages",
					"id": "1",
					"attributes": {
						"text": "Look what I just found!"
					},
					"relationships": {
						"attachment": {
							"data": {
								"type": "videos",
								"id": "42"
							}
						}
					}
				},
				"included": [
					{
						"type": "videos",
						"id": "42",
						"attributes": {
							"url": "https://example.com/video.mp4"
						}
					}
				]
			}
			""".data(using: .utf8)!

		let decoder = JSONAPIDecoder()
		decoder.ignoresUnhandledResourceTypes = true

		// when
		let message = try decoder.decode(SingleAttachmentMessage.self, from: json)

		// then
		XCTAssertEqual(SingleAttachmentMessage(id: "1", text: "Look what I just found!"), message)
	}

	func testIgnoresUnhandledResourceTypeRelationshipToMany() throws {
		// given
		let json = """
			{
				"data": {
					"type": "messages",
					"id": "1",
					"attributes": {
						"text": "Look what I just found!"
					},
					"relationships": {
						"attachments": {
							"data": [
								{
									"type": "videos",
									"id": "42"
								},
								{
									"type": "audios",
									"id": "66"
								}
							]
						}
					}
				},
				"included": [
					{
						"type": "videos",
						"id": "42",
						"attributes": {
							"url": "https://example.com/video.mp4"
						}
					},
					{
						"type": "audios",
						"id": "66",
						"attributes": {
							"url": "https://audio.com/NeverGonnaGiveYouUp.mp3",
							"title": "Never Gonna Give You Up"
						}
					}
				]
			}
			""".data(using: .utf8)!

		let decoder = JSONAPIDecoder()
		decoder.ignoresUnhandledResourceTypes = true

		// when
		let message = try decoder.decode(Message.self, from: json)

		// then
		XCTAssertEqual(
			Message(
				id: "1",
				text: "Look what I just found!",
				attachments: [
					.audio(
						Audio(
							id: "66",
							url: URL(string: "https://audio.com/NeverGonnaGiveYouUp.mp3")!,
							title: "Never Gonna Give You Up"
						)
					)
				]
			),
			message
		)
	}

	func testMissingResource() throws {
		// given
		let json = """
			{
				"data": {
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
								}
							]
						}
					}
				},
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

		do {
			// when
			_ = try JSONAPIDecoder().decode(Article.self, from: json)
			XCTFail("Should throw DecodingError.valueNotFound.")
		} catch let DecodingError.valueNotFound(type, context) {
			// then
			XCTAssertEqual(String(describing: type), String(describing: Comment.self))
			XCTAssertEqual(context.debugDescription, "Could not find resource of type 'comments' with id '5'.")
		} catch {
			XCTFail("Expected DecodingError.valueNotFound but got \(error).")
		}
	}

	func testIgnoresMissingResources() throws {
		// given
		let json = """
			{
				"data": {
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
								}
							]
						}
					}
				},
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

		let decoder = JSONAPIDecoder()
		decoder.ignoresMissingResources = true

		// when
		let article = try decoder.decode(Article.self, from: json)

		// then
		XCTAssertEqual(
			Article(
				id: "1",
				title: "JSON:API paints my bikeshed!",
				author: Person(
					id: .init(rawValue: "9"),
					firstName: "Dan",
					lastName: "Gebhardt",
					twitter: "dgeb"
				),
				comments: []
			),
			article
		)
	}

	func testMetaDecoding() throws {
		// given
		let json = """
			{
				"data": {
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
				},
				"meta": {
					"copyright": "Copyright 2024 Datadog Inc.",
						"authors": [
							"Yassir Ramdani",
							"Nicolas Mulet",
							"Alan Fineberg",
							"Guille González"
						]
				},
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
		let document = try JSONAPIDecoder().decode(Document<Article, CopyrightInfo>.self, from: json)

		// then
		XCTAssertEqual(
			Document(
				data: Article(
					id: "1",
					title: "JSON:API paints my bikeshed!",
					author: Person(
						id: "9",
						firstName: "Dan",
						lastName: "Gebhardt",
						twitter: "dgeb"
					),
					comments: []
				),
				meta: CopyrightInfo(
					copyright: "Copyright 2024 Datadog Inc.",
					authors: ["Yassir Ramdani", "Nicolas Mulet", "Alan Fineberg", "Guille González"]
				)
			),
			document
		)
	}

	func testMetaEncodingRoundtrip() throws {
		// given
		let document = Document(
			data: Article(
				id: "1",
				title: "JSON:API paints my bikeshed!",
				author: Person(
					id: "9",
					firstName: "Dan",
					lastName: "Gebhardt",
					twitter: "dgeb"
				),
				comments: []
			),
			meta: CopyrightInfo(
				copyright: "Copyright 2024 Datadog Inc.",
				authors: ["Yassir Ramdani", "Nicolas Mulet", "Alan Fineberg", "Guille González"]
			)
		)

		// when
		let data = try JSONAPIEncoder().encode(document)
		let decodedDocument = try JSONAPIDecoder().decode(Document<Article, CopyrightInfo>.self, from: data)

		// then
		XCTAssertEqual(decodedDocument, document)
	}
}
