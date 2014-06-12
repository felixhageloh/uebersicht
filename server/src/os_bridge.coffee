slices    = []
wallpaper = null
callbacks = []

window.addEventListener 'onwallpaperchange', ->
  loadWallpaper -> renderWallpaperSlices()

exports.makeBgSlice = (canvas) ->
  canvas = $(canvas)[0]
  throw new Error('no canvas element provided') unless canvas?.getContext

  slices.push canvas
  getWallpaper -> renderWallpaperSlice canvas

getWallpaper = (callback) ->
  return callback(wallpaper) if wallpaper?
  callbacks.push(callback)

  loadWallpaper (wp) ->
    cb(wp) for cb in callbacks

loadWallpaper = (callback) ->
  wp = new Image()
  wp.onload = ->
    wallpaper = wp
    callback(wp)

  wp.src = os.wallpaperDataUrl()

renderWallpaperSlices = ->
  renderWallpaperSlice(canvas) for canvas in slices

renderWallpaperSlice = (canvas) ->
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
