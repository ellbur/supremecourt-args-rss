
let then = Promise.then
let alen = Js.Array.length
let afe = Js.Array2.forEach
let log = Js.Console.log
let x = Belt.Option.getExn
type promise<'a> = Promise.t<'a>
open Model

type htmlElement = {
  text: string
}
@module("node-html-parser") external parseHTML: string => htmlElement = "parse"
@send external getElementsByTagName: (htmlElement, string) => array<htmlElement> = "getElementsByTagName"
@send external querySelectorAll: (htmlElement, string) => array<htmlElement> = "querySelectorAll"
@send external getAttribute: (htmlElement, string) => string = "getAttribute"

let tableURL = "https://www.supremecourt.gov/oral_arguments/argument_audio.aspx"
let userAgent = "Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
let headers = {
  "User-Agent": userAgent
}
let axiosOpts: Axios.opts<_> = { headers: headers }

type indexPageEntry = {
  caption: string,
  date: Js.Date.t,
  pageURL: string
}

let getIndexPage: () => promise<(htmlElement, string)> = () => {
  Axios.get(tableURL, axiosOpts)->then(resp => {
    let body = resp.data->parseHTML
    let landingURL = resp.request.res.responseUrl
  
    Promise.resolve((body, landingURL))
  })
}

let parseIndexPage: (htmlElement, string) => array<indexPageEntry> = (body, landingURL) => {
  let res = [ ]

  let trs = body->getElementsByTagName("tr")
  trs->afe(tr => {
    let tds = tr->getElementsByTagName("td")
    if tds->alen == 2 {
      let td1 = tds[0]->x
      let td2 = tds[1]->x
      let links = td1->getElementsByTagName("a")
      if links->alen == 1 {
        let spans = td1->getElementsByTagName("span")
        if spans->alen == 2 {
          let caption = (spans[1]->x).text
          let argPageRelURL = links[0]->x->getAttribute("href")->NodeJs.Url.make
          let argPageURL = NodeJs.Url.fromBaseUrl(~base=argPageRelURL, ~input=landingURL)->NodeJs.Url.format
          let dateString = td2.text

          let dateTokens = dateString->Js.String2.split("/")
          if dateTokens->alen == 3 {
            let monthNumber = dateTokens[0]->x->Belt.Int.fromString->x
            let dayNumber = dateTokens[1]->x->Belt.Int.fromString->x
            let yearNumber2D = dateTokens[2]->x->Belt.Int.fromString->x
            let yearNumber = if yearNumber2D < 100 { yearNumber2D + 2000 } else { yearNumber2D }
            let date = Js.Date.makeWithYMD(
              ~year=yearNumber->Belt.Int.toFloat,
              ~month=(monthNumber-1)->Belt.Int.toFloat,
              ~date=dayNumber->Belt.Int.toFloat,
              ()
            )
            res->Js.Array2.push({
              caption: caption,
              date: date,
              pageURL: argPageURL
            })->ignore
          }
        }
      }
    }
  })

  res
}

let listIndexPage: () => promise<array<indexPageEntry>> = () => {
  getIndexPage()->then(((body, landingURL)) => {
    Promise.resolve(parseIndexPage(body, landingURL))
  })
}

let getMP3URL: string => promise<string> = argPageURL => {
  // User-Agent: Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36
  Axios.get(argPageURL, axiosOpts)->then(resp => {
    let html = resp.data
    let doc = parseHTML(html)
    let links = doc->querySelectorAll("div.datafield > table > tr > td > a")
    
    let found = links->Js.Array2.find(elem => elem->getAttribute("href")->Js.String2.endsWith("mp3"))->x
    Promise.resolve(found->getAttribute("href"))
  })
}

let safeMP3URL = (argPageURL, caption) => {
  let encodedURL = NodeJs.Buffer.fromString(argPageURL)->NodeJs.Buffer.toStringWithEncoding(NodeJs.StringEncoding.base64)
  let encodedCaption = Js.Global.encodeURIComponent(caption)
  `https://us-central1-theservices-346722.cloudfunctions.net/supremeCourtRedirectToMP3/${encodedURL}/${encodedCaption}.mp3`
}

let inSequence = promises => {
  let res = [ ]
  let rec step = i => {
    if i < promises->alen {
      promises[i]->x->then(x => {
        res->Js.Array2.push(x)->ignore
        step(i + 1)
      })
    }
    else {
      Promise.resolve(res)
    }
  }
  step(0)
}

let listArgs: () => promise<Js.Array.t<arg>> = () => {
  listIndexPage()->then(entries => {
    Promise.resolve(entries->Js.Array2.map(entry => {
      let mp3URL = safeMP3URL(entry.pageURL, entry.caption)
      {
        caption: entry.caption,
        date: entry.date,
        mp3URL: mp3URL
      }
    }))
  })
}

