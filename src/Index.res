
let listArgs = ArgsListing.listArgs
let getMP3URL = ArgsListing.getMP3URL
let generateRSS = RSSGeneration.generateRSS
let log = Js.Console.log
let then = Promise.then
let thenResolve = Promise.thenResolve

type request = {
  "path": string,
  "url": string
}
type response
type httpFunction = (request, response) => ()
@module("@google-cloud/functions-framework") external http: (string, httpFunction) => () = "http"
@send external send: (response, string) => () = "send"
@send external set: (response, string, string) => () = "set"
@send external status: (response, int) => () = "status"

http("supremeCourtArgsRSS", (_req, res) => {
  listArgs()->thenResolve(generateRSS)->thenResolve(rss => {
    res->set("Content-Type", "application/rss+xml")
    res->send(rss)
  })->Promise.catch(e => {
    log(e)
    res->status(500)
    res->send("")
    Promise.resolve()
  })->ignore
})

http("supremeCourtRedirectToMP3", (req, res) => {
  let url = req["url"]
  let tokens = req["url"]->Js.String2.split("/")
  let encodedURL = tokens[tokens->Js.Array2.length - 2]
  let fullURL = NodeJs.Buffer.fromStringWithEncoding(encodedURL, NodeJs.StringEncoding.base64)->NodeJs.Buffer.toString
  getMP3URL(fullURL)->thenResolve(mp3URL => {
    res->status(302)
    res->set("Location", mp3URL)
    res->send("")
  })->Promise.catch(e => {
    log(e)
    res->status(500)
    res->send("")
    Promise.resolve()
  })->ignore
})

