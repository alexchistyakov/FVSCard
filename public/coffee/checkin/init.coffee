#TEMP
fvsCardRootUrl = "http://localhost"
fvsCardXHRRequest = (params, action, callback,url) ->
  xhr = null
  full_url = url
  full_params = ""

  for key,value of params
    unless full_params is ""
      full_params += "&"
    if value?
      full_params += "#{key}=#{encodeURIComponent value}"

  if action is "GET"
    full_url += "?" + full_params

  if XMLHttpRequest?
    xhr = new XMLHttpRequest()
  else
    versions = [
      "MSXML2.XmlHttp.5.0",
      "MSXML2.XmlHttp.4.0",
      "MSXML2.XmlHttp.3.0",
      "MSXML2.XmlHttp.2.0",
      "Microsoft.XmlHttp"
    ]

    for i in [0..versions.length]
      try
        xhr = new ActiveXObject versions[i]
        break
      catch e
        return callback false

  xhr.onreadystatechange = ->
    if xhr.readyState < 4 or xhr.status is not 200
      return callback false
    else if xhr.readyState is 4
      if typeof xhr.response is "string"
        callback JSON.parse xhr.response
      else
        callback xhr.response
    else
      return callback false


  xhr.withCredentials = true;
  xhr.open(action, full_url, true);
  xhr.responseType = "json";

  unless action is "GET"
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

  xhr.send(full_params);

fvsCardUrl = "#{fvsCardRootUrl}/api"
fvsCardRequest = (params, action, callback) =>
  fvsCardXHRRequest params,action,callback,fvsCardUrl

fvsCardRequest
  command: "load-essentials"
, "GET", (response) ->
  unless response is false
    console.log response
    window.FVSCard.init fvsCardRequest, response.data.ui, response.data.data
