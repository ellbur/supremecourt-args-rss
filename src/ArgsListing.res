
let then = Promise.then
let alen = Js.Array.length
let afe = Js.Array2.forEach
let log = Js.Console.log
let x = Belt.Option.getExn
type promise<'a> = Promise.t<'a>
open Model

type axiosRes = {
  responseUrl: string
}
type axiosRequest = {
  res: axiosRes
}
type axiosResponse = {
  data: string,
  request: axiosRequest
}
@module("axios") external axiosGet: string => Promise.t<axiosResponse> = "get"

type htmlElement = {
  text: string
}
@module("node-html-parser") external parseHTML: string => htmlElement = "parse"
@send external getElementsByTagName: (htmlElement, string) => array<htmlElement> = "getElementsByTagName"
@send external querySelectorAll: (htmlElement, string) => array<htmlElement> = "querySelectorAll"
@send external getAttribute: (htmlElement, string) => string = "getAttribute"

let tableURL = "https://www.supremecourt.gov/oral_arguments/argument_audio.aspx"

type indexPageEntry = {
  caption: string,
  date: Js.Date.t,
  pageURL: string
}

let listIndexPage: () => promise<array<indexPageEntry>> = () => {
  axiosGet(tableURL)->then(resp => {
    let res = [ ]
    
    let landingURL = resp.request.res.responseUrl
  
    let body = resp.data->parseHTML
    let trs = body->getElementsByTagName("tr")
    trs->afe(tr => {
      let tds = tr->getElementsByTagName("td")
      if tds->alen == 2 {
        let td1 = tds[0]
        let td2 = tds[1]
        let links = td1->getElementsByTagName("a")
        if links->alen == 1 {
          let spans = td1->getElementsByTagName("span")
          if spans->alen == 2 {
            let caption = spans[1].text
            let argPageRelURL = links[0]->getAttribute("href")
            let argPageURL = URL.makeWithBase(argPageRelURL, landingURL)->URL.toString
            let dateString = td2.text
            
            let dateTokens = dateString->Js.String2.split("/")
            if dateTokens->alen == 3 {
              let monthNumber = dateTokens[0]->Belt.Int.fromString->x
              let dayNumber = dateTokens[1]->Belt.Int.fromString->x
              let yearNumber2D = dateTokens[2]->Belt.Int.fromString->x
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
    
    Promise.resolve(res)
  })
}

let getMP3URL: string => promise<string> = argPageURL => {
  axiosGet(argPageURL)->then(resp => {
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
      promises[i]->then(x => {
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

