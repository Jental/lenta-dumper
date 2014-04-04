#!/usr/bin/coffee

IN_DIR = 'lenta_dump_1999.08.31_-_2014.03.30'

fs      = require 'fs'
glob    = require 'glob'
cheerio = require 'cheerio'
_       = require 'underscore'

iterate_months = (action) -> 
  fs.readdir IN_DIR, (err, files) ->
    if err
      throw err

    maxmin = files.reduce (prev, file) ->
      files2 = fs.readdirSync IN_DIR + '/' + file
      maxmin2 = files2.reduce (prev, curr) ->
        {
          max: Math.max prev.max, curr
          min: Math.min prev.min, curr
        }
      , {
          max: 0
          min: 9999
        }

      {
        max: Math.max prev.max, maxmin2.max
        min: Math.min prev.min, maxmin2.min
      }
    , {
        max: 0
        min: 9999
      }

    inProgress = false

    files.map (category) ->
      [maxmin.min .. maxmin.max].map (year) ->
        [1 .. 12].map (m) ->
          month = ('0' + m).slice -2

          iv = setInterval ->
            if not inProgress
              inProgress = true
              console.log category + "-" + year + "-" + month

              action category, year, month, ->
                clearInterval iv
                inProgress = false

remove_images = () ->
  iterate_months (category, year, month, callback) ->
    glob "#{ IN_DIR }/#{ category }/#{ year }/#{ month }/**/{tabloid*.jpg,orphus*.gif,top*.jpg}", (er, files) ->
      files.map (path) ->
        fs.unlink path, (err) ->
          if err
            console.log path, err
          else
            console.log path, 'deleted'
      callback()

clear_pages = () ->
  selectorsToRemove = [
    '#root > nav'
    '#root > section'
    '#root_footer'
    '#up'
    '#root > .b-stat'
    '.b-topic-addition'
    '.b-topic > section'
    '.b-topic-layout .row > .span4'
    'footer'
    '#advert-branding'
    '#editor-panel'
    'script'
  ].join ', '

  iterate_months (category, year, month, callback) ->
    glob "#{ IN_DIR }/#{ category }/#{ year }/#{ month }/**/index.html", (er, files) ->
      if files.length == 0
        callback()
      else
        count = 0
        files.map (path) ->
          data = fs.readFileSync path
          $ = cheerio.load data

          _.map $(selectorsToRemove), (e) -> $(e).remove()
          $('.b-topic-layout .row > .span8').css 'width', '100%'

          fs.writeFileSync path, $.html()
          count++
          if count == files.length
            callback()

remove_images()
clear_pages()