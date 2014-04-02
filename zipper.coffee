#!/usr/bin/coffee

IN_DIR = 'out_test'
OUT_DIR = 'zip'

fs = require 'fs'
mkdirp  = require 'mkdirp'
archiver = require 'archiver'

mkdirp OUT_DIR

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

    [maxmin.min .. maxmin.max].map (year) ->
      [1 .. 12].map (m) ->
        month = ('0' + m).slice -2

        paths = files
        .map((file2) -> file2 + '/' + year + '/' + month)
        .filter((file2Name) -> fs.existsSync IN_DIR + '/' + file2Name)

        if paths.length > 0
          iv = setInterval ->
            if not inProgress
              inProgress = true
              console.log year + '-' + month + ':'
              output = fs.createWriteStream OUT_DIR + '/' + year + '-' + month + '.zip'
              zip = archiver 'zip'

              output.on 'close', ->
                console.log zip.pointer() + ' total bytes'
                clearInterval iv
                inProgress = false
              zip.on 'error', (err) ->
                console.log err
              zip.pipe output

              zip.bulk [{
                expand: true
                cwd: IN_DIR
                src: paths.map((file2Name) -> file2Name + '/**')
              }]
              zip.finalize()
          , 100
