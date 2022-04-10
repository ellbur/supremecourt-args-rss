
let then = Promise.then
let alen = Js.Array.length
let afe = Js.Array2.forEach
let log = Js.Console.log
let x = Belt.Option.getExn

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
@send external getElementsByTagName: (htmlElement, string) => Js.Array.t<htmlElement> = "getElementsByTagName"
@send external getAttribute: (htmlElement, string) => string = "getAttribute"

type arg = {
  caption: string,
  date: Js.Date.t,
  mp3Path: string
}

let tableURL = "https://www.supremecourt.gov/oral_arguments/argument_audio.aspx"

let getMP3URL = argPageURL => {
  ()
}

let listArgs: () => Promise.t<Js.Array.t<arg>> = () => {
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
              log([caption, date->Js.Date.toUTCString, argPageURL])
            }
          }
        }
      }
    })
    
    Promise.resolve(res)
  })
}

//listArgs()->then(args => {
//  log(args)
//  Promise.resolve()
//})->ignore

getMP3URL("https://www.supremecourt.gov/oral_arguments/audio/2021/20-480")->ignore

