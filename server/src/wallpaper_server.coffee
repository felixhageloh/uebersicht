exports.makeBgSlice = (canvas) ->
  canvas = $(canvas)[0]

  throw

  canvas.width  = $(canvas).width()
  canvas.height = $(canvas).height()

  ctx  = canvas.getContext('2d')
  rect = canvas.getBoundingClientRect()


  left = Math.max(rect.left, 0)
  top  = Math.max((rect.top + 22), 0)

  width  = Math.min(canvas.width , wallpaper.width  - left)
  height = Math.min(canvas.height, wallpaper.height - top)

  ctx.drawImage(wallpaper, Math.round(left),
                           Math.round(top),
                           Math.round(width),
                           Math.round(height),
                           0, 0, canvas.width, canvas.height)
