
type axiosRes = {
  responseUrl: string
}
type axiosRequest = {
  res: axiosRes
}
type axiosResponse<'t> = {
  data: 't,
  request: axiosRequest
}

type opts<'a> = {
  headers: 'a
}

module Axios = {
  module Default = {
    type t = {
      "get": 't 'a. (string, opts<'a>) => promise<axiosResponse<'t>>
    }
  }
  
  type t = {
    "default": Default.t
  }
}

@module external axios: Axios.t = "axios"

let get: 't 'a. (string, opts<'a>) => promise<axiosResponse<'t>> = (url, opts) => axios["default"]["get"](url, opts)

