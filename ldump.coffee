#!/usr/bin/coffee

BASE_URL = 'http://lenta.ru'
SECTION = 'news'
OUT_DIR = 'out'
INTERVAL = 200
START_DATE = Date.now()
# START_DATE = new Date 2008, 11, 14 # 11 - December

http    = require 'socks5-http-client'
cheerio = require 'cheerio'
_       = require 'underscore'
fs      = require 'fs'
mkdirp  = require 'mkdirp'

http_options =
  socksPort: 9050
#  port: 80
  hostname: 'lenta.ru'

download2 = (url, callback, encoding, silent) ->
  if not silent? or not silent
    console.log "Downloading: " + url
  http
  .get _.extend(http_options, {path: url}), (res) ->
    if res.statusCode == 200 # OK
      data = ''
      if encoding?
        res.setEncoding encoding
      res.on 'data', (chunk) ->
        data += chunk
      res.on 'end', ->
        if not silent? or not silent
          console.log "Downloaded: " + url
        callback data
        return
    else if res.statusCode == 302 # Moved Temporary
      console.log '' + res.statusCode + ' : ' + url
      newUrl = BASE_URL + res.headers.location
      download newUrl, callback, encoding
      return
#   else if res.statusCode == 416 # Requested Range not satisfiable
#     console.log res
#     callback null
    else
      console.log '' + res.statusCode + ' : ' + url
      callback null
      return
  .on 'error', (e) ->
    console.log e
    callback null
    return
download = (url, callback, encoding, silent) ->
  setTimeout ->
    download2 url, callback, encoding, silent
  , 100
downloadAll = (urls, callback, encoding, silent) ->
  results = []
  downloadAll2 = (urls2) ->
    if urls2.length == 0
      callback results
    else
      url = urls2[0]
      callback2 = (data) ->
        results.push
          url: url
          data: data
        downloadAll2 urls2.splice(1)
      download2 url, callback2, encoding, silent
  downloadAll2 urls, callback, encoding

handle_article = (url, data, basedir, callback) ->
  console.log 'Handling: ' + url
  if fs.existsSync OUT_DIR + basedir + 'index.html'
    console.log 'Already exists: ' + url

  $$ = cheerio.load data

  imagedata = _.map $$('img'), (e) ->
    {
      src: e.attribs.src
      obj: e
    }
  imghrefs = _.map $$('img'), (e) -> e.attribs.src

  downloadAll imghrefs, (results) ->
    _.each results, (res) ->
      if res.data?
        src = res.url
        parts = src.split '/'
        if parts.length > 0
          name = parts[parts.length - 1]
          if name != ''
            e = _.findWhere imagedata,
              src: src
            if e? and e.obj?
              e.obj.attribs.src = name
              fs.writeFileSync OUT_DIR + basedir + name, res.data, 'binary'
    console.log 'Saved resources: ' + url

    fs.writeFileSync OUT_DIR + basedir + 'index.html', $$.html()
    console.log 'Saved: ' + url
    callback()
  , 'binary'
  , true


dump_by_date = (date, callback) ->
  url = BASE_URL + '/' + SECTION + '/' + date + '/'

  download2 url, (data) ->
    if data?
      console.log "Data downloaded: " + url
      $ = cheerio.load data

      hrefs = _.map $('section.b-layout_archive .titles a'), (e) -> e.attribs.href

      hrefs = _.filter hrefs, (h) ->
        nres = fs.existsSync OUT_DIR + h + 'index.html'
        if nres
          console.log "Already downloaded: " + h
        not nres

      if hrefs.length == 0
        callback()
        return

      _.each hrefs, (href) ->
        mkdirp OUT_DIR + '/' + href, (err) ->
          if err?
            console.log err

      setTimeout ->
        downloadAll hrefs, (results) ->
          fcount = 0
          _.each results, (res) ->
            if res.data?
              handle_article res.url, res.data, res.url, ->
                if (fcount == results.length - 1)
                  console.log "All articles handled: " + url
                  callback()
                else
                  fcount++
            else
              fcount++
              console.log 'Error: no article data downloaded'
      , 1000
    else
      console.log 'Error: no data downloaded'
      callback()

loopDate = new Date()
loopDate.setTime START_DATE
inProgress = false

setInterval ->
  if not inProgress
    inProgress = true
    dateString = loopDate.getFullYear() + '/' + ('0' + (loopDate.getMonth()+1)).slice(-2) + '/' + ('0' + loopDate.getDate()).slice(-2)
    console.log "Date: " + dateString
    dump_by_date dateString, ->
      console.log "Next iteration"
      loopDate.setTime loopDate.valueOf() - 1000*60*60*24;
      inProgress = false
, 10000

# download 'http://lenta.ru/news/2012/03/11/dalny/', (data) ->
#   console.log data
