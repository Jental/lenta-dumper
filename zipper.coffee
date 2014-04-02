#!/usr/bin/coffee

IN_DIR = 'out'
OUT_DIR = 'zip'

fs = require 'fs'
mkdirp  = require 'mkdirp'
spawn = require('child_process').spawn
readline = require 'readline'

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

    baseDir = process.cwd()
    process.chdir IN_DIR

    inProgress = false

    [maxmin.min .. maxmin.max].map (year) ->
      [1 .. 12].map (m) ->
        month = ('0' + m).slice -2

        paths = files
        .map((file2) -> file2 + '/' + year + '/' + month)
        .filter((file2Name) -> fs.existsSync file2Name)

        if paths.length > 0
          iv = setInterval ->
            if not inProgress
              inProgress = true
              console.log year + '-' + month + ':'

              zipper = spawn '7z', ['a', "#{ baseDir }/#{ OUT_DIR }/#{ year }-#{ month }.zip"].concat(paths),
                cwd: IN_DIR

              zipper.on 'close', (code)->
                console.log "finished with code #{ code }"
                clearInterval iv
                inProgress = false
              readline.createInterface
                input: zipper.stdout
                terminal: false
              .on 'line', (line) ->
                console.log line
              readline.createInterface
                input: zipper.stderr
                terminal: false
              .on 'line', (line) ->
                console.log 'Error: ', line
          , 100

    process.chdir baseDir
