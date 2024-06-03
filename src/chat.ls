require! <[node-fetch]>

chat = (o = {}) ->
  model = o.model or \gpt-4o
  messages = o.messages or [{role: \user, content: 'hello there'}]
  temperature = o.temperature or 0.8
  opt =
    method: \POST
    headers:
      "Content-Type": "application/json"
      "Authorization": "Bearer #{o.key}"
    body: JSON.stringify({
      model, messages, temperature
      seed: o.seed, user: o.user, response_format: o.response_format
      max_tokens: o.max_tokens
    })
  node-fetch \https://api.openai.com/v1/chat/completions, opt
    .then (ret) ->
      if ret.ok => return ret.json!
      (msg) <- ret.text!then _
      Promise.reject((new Error(msg)) <<< {status: ret.status})
    .then (ret) ->
      # stablize and normalize returned result
      {raw: ret, message: (ret.[]choices.0 or {}).message.content}

module.exports = chat
