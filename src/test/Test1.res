
open ArgsListing

@get external outerHTML: htmlElement => string = "outerHTML"

let (body, _) = await getIndexPage()

Js.Console.log(body->outerHTML)

