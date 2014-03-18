#!/usr/bin/coffee

BASE_URL = 'http://lenta.ru'
OUT_DIR = 'out'
INTERVAL = 200

http    = require 'http'
cheerio = require 'cheerio'
_       = require 'underscore'
fs      = require 'fs'
mkdirp  = require 'mkdirp'

download = (url, callback, encoding) ->
  http
  .get url, (res) ->
    if res.statusCode == 200 # OK
      data = ''
      if encoding?
        res.setEncoding encoding
      res.on 'data', (chunk) ->
        data += chunk
      res.on 'end', ->
        callback data
    else if res.statusCode == 302 # Moved Temporary
      newUrl = BASE_URL + res.headers.location
      download newUrl, callback, encoding
    else
      console.log '' + res.statusCode + ' : ' + url
      callback null
  .on 'error', ->
    callback null


dump_by_date = (date) ->
  url = BASE_URL + '/news/' + date + '/'
  console.log url

  download url, (data) ->
    if data?
      $ = cheerio.load data
      console.log data

      _.each $('section.b-layout_archive .titles a'), (e) ->
        href = e.attribs.href

        if href?
          console.log href

          mkdirp OUT_DIR + '/' + href, (err) ->
            if err?
              console.log err
            else
              href2 = BASE_URL + href

              download href2, (data2) ->
                if data2?
                  $$ = cheerio.load data2

                  _.each $$('img'), (e2) ->
                    src = e2.attribs.src
                    parts = src.split '/'

                    if parts.length > 0
                      name = parts[parts.length - 1]

                      if src? and src != '' and name != ''
                        e2.attribs.src = name

                        setTimeout () ->
                          download src, (data3) ->
                            fs.writeFile OUT_DIR + href + name, data3, 'binary', (err) ->
                              if err?
                                console.log err
                          , 'binary'
                        , INTERVAL

                  fs.writeFile OUT_DIR + href + 'index.html', $$.html(), (err) ->
                    if err?
                      console.log err
                    else
                      console.log 'Saved: ' + href
                else console.log 'Error: ' + href
        else
          console.log 'error'
    else
      console.log 'error'

dump_by_date '2012/03/12'
