#!/usr/bin/coffee

IN_DIR = 'out'
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

    [maxmin.min .. maxmin.max].map (year) ->
      console.log year + ':'
      paths = files
      .map((file2) -> file2 + '/' + year)
      .filter((file2Name) -> fs.existsSync IN_DIR + '/' + file2Name)

      output = fs.createWriteStream OUT_DIR + '/' + year + '.zip'
      zip = archiver 'zip'

      output.on 'close', ->
        console.log zip.pointer() + ' total bytes';
      zip.on 'error', (err) ->
        console.log err
      zip.pipe output

      zip.bulk [{
        expand: true
        cwd: IN_DIR
        src: paths.map((file2Name) -> file2Name + '/**')
        # src: ['culture/2000/11/03/antique/**']
      }]
      zip.finalize()
