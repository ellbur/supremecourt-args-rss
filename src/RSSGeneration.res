
let log = Js.Console.log

type rss = {
  "rss": {
    "$": {
      "version": string
    },
    "channel": {
      "title": string,
      "description": string,
      "item": array<{
        "title": string,
        "link": string,
        "pubDate": string
      }>
    }
  }
}

type builder
@new @module("xml2js") external newBuilder: () => builder = "Builder"
@send external buildObjectRSS: (builder, rss) => string = "buildObject"

open Model

let generateRSS = args => {
  let builder = newBuilder()
  builder->buildObjectRSS({"rss": {
    "$": {
      "version": "2.0"
    },
    "channel": {
      "title": "Supreme Court Oral Arguments",
      "description": "Oral argument mp3s from the United States Supreme Court",
      "item": args->Js.Array2.map(arg => {
        {
          "title": arg.caption,
          "link": arg.mp3URL,
          "pubDate": arg.date->Js.Date.toUTCString
        }
      })
    }
  } })
}

