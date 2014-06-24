slices          = []
cachedWallpaper = new Image()

window.addEventListener 'onwallpaperchange', ->
  loadWallpaper (wallpaper) ->
    renderWallpaperSlices(wallpaper)

exports.makeBgSlice = (canvas) ->
  canvas = $(canvas)[0]
  throw new Error('no canvas element provided') unless canvas?.getContext

  slices.push canvas
  getWallpaper (wallpaper) ->
    renderWallpaperSlice wallpaper, canvas

# this should be a promise
getWallpaper = (callback) ->
  return callback(cachedWallpaper) if cachedWallpaper.loaded

  getWallpaper.callbacks ?= []
  getWallpaper.callbacks.push(callback)

  return if cachedWallpaper.loading
  cachedWallpaper.loading = true
  loadWallpaper (wallpaper) ->
    callback(wallpaper) for callback in getWallpaper.callbacks
    getWallpaper.callbacks.length = 0
    cachedWallpaper.loaded = true

loadWallpaper = (callback) ->
  cachedWallpaper.onload = -> callback(cachedWallpaper)
  cachedWallpaper.src = os.wallpaperDataUrl()

renderWallpaperSlices = (wallpaper) ->
  renderWallpaperSlice(wallpaper, canvas) for canvas in slices

renderWallpaperSlice = (wallpaper, canvas) ->
  ctx   = canvas.getContext('2d')
  scale = window.devicePixelRatio / ctx.webkitBackingStorePixelRatio

  rect = canvas.getBoundingClientRect()
  canvas.width  = rect.width  * scale
  canvas.height = rect.height * scale

  left = Math.max(rect.left, 0)       * window.devicePixelRatio
  top  = Math.max((rect.top + 22), 0) * window.devicePixelRatio

  width  = Math.min(canvas.width , wallpaper.width  - left)
  height = Math.min(canvas.height, wallpaper.height - top)

  ctx.drawImage(wallpaper, Math.round(left),
                           Math.round(top),
                           Math.round(width),
                           Math.round(height),
                           0, 0, canvas.width, canvas.height)
