#!/usr/bin/coffee

CURRENT_DATE = '2012/03/12'
BASE_URL = 'http://lenta.ru'
OUT_DIR = 'out'

http    = require 'http'
cheerio = require 'cheerio'
_       = require 'underscore'
fs      = require 'fs'
mkdirp  = require 'mkdirp'

download = (url, callback, encoding) ->
  http
  .get url, (res) ->
    data = ''
    if encoding?
      res.setEncoding encoding
    res.on 'data', (chunk) ->
      data += chunk
    res.on 'end', ->
      callback data
  .on 'error', ->
    callback null

date = CURRENT_DATE
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
                    e2.attribs.src = name
                    if src? and src != '' and name != ''
                      download src, (data3) ->
                        fs.writeFile OUT_DIR + href + name, data3, 'binary', (err) ->
                          if err?
                            console.log err
                      , 'binary'
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
