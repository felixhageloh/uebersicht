cachedWallpaper = new Image()

window.addEventListener 'onlocationchange', (e) ->
  # When new widgets come online (including those available at launch)
  # it's unlikely that an event will be sent soon enough with the
  # current position. We'll watch for position changes here and cache
  # the current value to send to widgets as they are created
  if e.detail && e.detail.position
    console.log 'Caching current position globally'
    console.log e.detail.position
    window._ub_location_position = e.detail.position

window.addEventListener 'onwallpaperchange', ->
  slices = getWallpaperSlices()
  return unless slices.length > 0

  loadWallpaper (wallpaper) ->
    renderWallpaperSlices(wallpaper, slices)

exports.makeBgSlice = (canvas) ->
  canvas = $(canvas)
  throw new Error('no canvas element provided') unless canvas[0]?.getContext

  canvas.attr('data-bg-slice', true)
  getWallpaper (wallpaper) ->
    renderWallpaperSlice wallpaper, canvas[0]

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
  cachedWallpaper.src = os.wallpaperUrl()

getWallpaperSlices = ->
  # slower than storing those, but avoids memory leaks
  $('[data-bg-slice=true]')

renderWallpaperSlices = (wallpaper, slices) ->
  for canvas in slices
    renderWallpaperSlice(wallpaper, canvas)

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
