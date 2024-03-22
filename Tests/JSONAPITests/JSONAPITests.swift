import JSONAPI
import XCTest

final class JSONAPITests: XCTestCase {
  func testExample() throws {
    let json = """
      {
        "links": {
          "self": "http://example.com/articles",
          "next": "http://example.com/articles?page[offset]=2",
          "last": "http://example.com/articles?page[offset]=10"
        },
        "data": [{
          "type": "articles",
          "id": "1",
          "attributes": {
            "title": "JSON:API paints my bikeshed!"
          },
          "relationships": {
            "author": {
              "links": {
                "self": "http://example.com/articles/1/relationships/author",
                "related": "http://example.com/articles/1/author"
              },
              "data": { "type": "people", "id": "9" }
            },
            "comments": {
              "links": {
                "self": "http://example.com/articles/1/relationships/comments",
                "related": "http://example.com/articles/1/comments"
              },
              "data": [
                { "type": "comments", "id": "5" },
                { "type": "comments", "id": "12" }
              ]
            }
          },
          "links": {
            "self": "http://example.com/articles/1"
          }
        }],
        "included": [{
          "type": "people",
          "id": "9",
          "attributes": {
            "firstName": "Dan",
            "lastName": "Gebhardt",
            "twitter": "dgeb"
          },
          "links": {
            "self": "http://example.com/people/9"
          }
        }, {
          "type": "comments",
          "id": "5",
          "attributes": {
            "body": "First!"
          },
          "relationships": {
            "author": {
              "data": { "type": "people", "id": "2" }
            }
          },
          "links": {
            "self": "http://example.com/comments/5"
          }
        }, {
          "type": "comments",
          "id": "12",
          "attributes": {
            "body": "I like XML better"
          },
          "relationships": {
            "author": {
              "data": { "type": "people", "id": "9" }
            }
          },
          "links": {
            "self": "http://example.com/comments/12"
          }
        }]
      }
      """.data(using: .utf8)!

    let articles = try JSONDecoder().decode([Article].self, from: json)

    print(articles)

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

    let data = try encoder.encode(articles)

    print(String(decoding: data, as: UTF8.self))

    let articles2 = try JSONDecoder().decode([Article].self, from: data)

    XCTAssertEqual(articles, articles2)
  }
}
