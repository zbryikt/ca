require! <[fs path @plotdb/colors readline ./chat]>

cfgfile = path.join(process.env.HOME, ".ssh/openai/secret.json")

try
  if !fs.exists-sync(cfgfile) => throw new Error "expect #cfgfile with `{apiKey}` object."
  secret = JSON.parse(fs.read-file-sync cfgfile .toString!)
  if !secret.apiKey => throw new Error "expect #cfgfile with `{apiKey}` object."
catch e
  console.error e.toString!red
  process.exit 1

query = (msg) ->
  opt =
    key: secret.apiKey
    max_tokens: 100
    messages: [
      {role: 'system', content: """
      用戶現在正透過終端機指令介面與您對話，請避免輸出不適合的排版文字，但可用跳脫碼上色。
      主要會是程式或指令問題，請用正體中文回覆。
      """}
      {role: 'user', content: msg}
    ]
  chat opt .then (ret) -> return ret.message

lc = {msg: [], write: true, loader: char: <[| / - \]>, idx: 0}

loading = (v = true) ->
  if v and lc.loader.hdr => return
  if !v and !lc.loader.hdr => return
  if !v =>
    readline.moveCursor process.stdout, -1, 0
    clearInterval lc.loader.hdr
    return lc.loader.hdr = 0
  lc.loader.hdr = setInterval (->
    readline.moveCursor process.stdout, -1, 0
    process.stdout.write "#{lc.loader.char[lc.loader.idx]}"
    lc.loader.idx = (lc.loader.idx + 1) % lc.loader.char.length
  ), 100

rl = readline.createInterface do
  input: process.stdin
  output: process.stdout

rl.on \line, (line = "") ->
  line = line.trim!
  if line == '' =>
    lc.write = false
    # write an extra space for loader to spin
    process.stdout.write "[GPT]  ".yellow
    loading true
    msg = lc.msg.join(\\n)
    lc.msg.splice 0
    query msg .then (ret) ->
      loading false
      console.log (ret).brightWhite
      lc.write = true
      process.stdout.write "[You] ".green
  if !lc.write => return
  lc.msg.push line
  process.stdout.write "[You] ".green

rl.input.on 'keypress', (char, key) -> return
rl._writeToOutput = (stw) -> if lc.write => rl.output.write(stw)

console.log "[Cmdline GPT] 'qq' or Ctrl-C to quit, empty line to send.".cyan
process.stdout.write "[You] ".green
