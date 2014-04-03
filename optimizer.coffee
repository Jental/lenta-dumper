#!/usr/bin/coffee

IN_DIR = 'lenta_dump_1999.08.31_-_2014.03.30'

fs = require 'fs'
glob = require 'glob'

remove_images = () ->
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

              glob "#{ IN_DIR }/#{category}/#{ year }/#{ month }/**/{tabloid*.jpg,orphus*.gif,top*.jpg}", (er, files) ->
                clearInterval iv

                files.map (path) ->
                  fs.unlink path, (err) ->
                    if err
                      console.log path, err
                    else
                      console.log path, 'deleted'

                inProgress = false
          , 100

remove_images()