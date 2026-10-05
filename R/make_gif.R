#' Stitch a list of plots into an animated GIF
#'
#' Each element of `plots` becomes one frame. An element can be a ggplot object (it is
#' printed), a function with no arguments that draws with base graphics (it is called), or
#' a recorded plot from [grDevices::recordPlot()]. Frames are written as PNGs to a
#' temporary folder (or kept, see `keep_frames`) and stitched with the magick package.
#'
#' @param plots A list of frames, in order: ggplot objects, zero-argument functions, or
#'   recorded plots. A single ggplot or function is wrapped into a one-frame list.
#' @param file File name of the GIF (default `"animation.gif"`).
#' @param dir Directory to write into (created if missing; default the working directory).
#' @param width,height Frame size in pixels (default 800 x 600).
#' @param fps Frames per second (default 10). Ignored when `delay` is given.
#' @param delay Optional vector of per-frame delays in seconds (recycled), for pauses:
#'   e.g. `delay = c(rep(0.1, 9), 1)` holds the last frame for one second.
#' @param loop Number of times to loop; `0` (the default) loops forever.
#' @param res Resolution passed to [grDevices::png()] (default 120). Higher = larger text.
#' @param bg Background colour of each frame (default white).
#' @param keep_frames If `TRUE`, the PNG frames are kept next to the GIF in a folder named
#'   `<file>_frames/`; otherwise they are deleted.
#' @param optimize If `TRUE` (default), frames are optimised so the GIF is smaller.
#' @param verbose Print progress (default `TRUE`).
#' @return The path of the GIF, invisibly. Prints a one-line summary.
#' @examples
#' \dontrun{
#' library(ggplot2)
#' frames <- lapply(1:20, function(i) {
#'   ggplot(mtcars[1:(10 + i), ], aes(wt, mpg)) + geom_point() + xlim(1, 6) + ylim(10, 35)
#' })
#' make_gif(frames, "mtcars.gif", width = 600, height = 450, fps = 5)
#'
#' # base graphics: wrap the drawing code in a function
#' frames <- lapply(seq(0, 2 * pi, length.out = 30), function(a) function() {
#'   plot(cos(a), sin(a), xlim = c(-1, 1), ylim = c(-1, 1), pch = 16, cex = 3)
#' })
#' make_gif(frames, "circle.gif", dir = "gifs")
#' }
#' @export
make_gif <- function(plots, file = "animation.gif", dir = ".", width = 800, height = 600,
                     fps = 10, delay = NULL, loop = 0, res = 120, bg = "white",
                     keep_frames = FALSE, optimize = TRUE, verbose = TRUE) {
  if (!requireNamespace("magick", quietly = TRUE))
    stop("plotgif needs the 'magick' package: install.packages(\"magick\")")
  if (!is.list(plots) || inherits(plots, "ggplot")) plots <- list(plots)
  n <- length(plots)
  if (n == 0) stop("'plots' is empty")
  if (!grepl("\\.gif$", file, ignore.case = TRUE)) file <- paste0(file, ".gif")
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  out <- file.path(dir, file)

  frame_dir <- if (keep_frames) file.path(dir, paste0(sub("\\.gif$", "", file, ignore.case = TRUE), "_frames"))
               else tempfile("plotgif_")
  dir.create(frame_dir, showWarnings = FALSE, recursive = TRUE)
  on.exit(if (!keep_frames) unlink(frame_dir, recursive = TRUE), add = TRUE)

  paths <- file.path(frame_dir, sprintf("frame_%04d.png", seq_len(n)))
  for (i in seq_len(n)) {
    if (verbose) cat(sprintf("\rframe %d / %d", i, n))
    grDevices::png(paths[i], width = width, height = height, res = res, bg = bg)
    ok <- try(draw_frame(plots[[i]]), silent = TRUE)
    grDevices::dev.off()
    if (inherits(ok, "try-error")) stop(sprintf("frame %d could not be drawn: %s", i, as.character(ok)))
  }
  if (verbose) cat("\n")

  img <- magick::image_read(paths)
  # magick takes per-frame delays in hundredths of a second (its fps argument only
  # accepts factors of 100, so any fps is turned into a delay here)
  d <- if (is.null(delay)) rep(max(1, round(100 / fps)), n) else round(rep_len(delay, n) * 100)
  anim <- magick::image_animate(img, delay = d, loop = loop, optimize = optimize)
  magick::image_write(anim, out)
  if (verbose) cat(sprintf("wrote %s: %d frames, %d x %d px, %.1f KB\n", out, n, width, height,
                           file.info(out)$size / 1024))
  invisible(out)
}

# draw one frame on the open device
draw_frame <- function(p) {
  if (is.function(p)) {
    p()
  } else if (inherits(p, "recordedplot")) {
    grDevices::replayPlot(p)
  } else if (inherits(p, "ggplot") || inherits(p, "grob") || inherits(p, "patchwork")) {
    print(p)
  } else {
    stop("each frame must be a ggplot object, a function(), or a recorded plot; got ", class(p)[1])
  }
  invisible(NULL)
}
