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
