
let listArgs = ArgsListing.listArgs
let getMP3URL = ArgsListing.getMP3URL
let generateRSS = RSSGeneration.generateRSS
let log = Js.Console.log
let x = Belt.Option.getExn

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
  let main = async () => {
    let args = await listArgs()
    let rss = generateRSS(args)
    rss
  }
  
  main()->Promise.thenResolve(rss => {
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
  let main = async () => {
    let tokens = req["url"]->Js.String2.split("/")
    let encodedURL = tokens[tokens->Js.Array2.length - 2]->x
    let fullURL = NodeJs.Buffer.fromStringWithEncoding(encodedURL, NodeJs.StringEncoding.base64)->NodeJs.Buffer.toString
    await getMP3URL(fullURL)
  }
  
  main()->Promise.thenResolve(mp3URL => {
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

