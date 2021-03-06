#################################################################
##                                                             ##
##   (c) Adeline Marinho <adelsud6@gmail.com>                  ##
##                                                             ##
##       Image Processing Division                             ##
##       National Institute for Space Research (INPE), Brazil  ##
##                                                             ##
##                                                             ##
##   R script to save raster in GeoTIFF format                 ##
##                                                             ##
##                                             2018-08-28      ##
##                                                             ##
##                                                             ##
#################################################################


#' @title Save a RasterBrick reclassified in Folder
#' @name lucC_save_GeoTIFF
#' @aliases lucC_save_GeoTIFF
#' @author Adeline M. Maciel
#' @docType data
#'
#' @description Save new_raster reclassified in a diretory defined by user.
#' NOTE: Applied only when update a raster with new values, after had applied the
#' function lucC_raster_update.
#'
#' @usage lucC_save_GeoTIFF(raster_obj = NULL, data_mtx = NULL,
#' path_raster_folder = NULL, as_RasterBrick = FALSE)
#'
#' @param raster_obj          Raster. A raster brick with classified images
#' @param data_mtx            Matrix. A matrix with pixel replaced, can be obtined using lucC_update_raster()
#' @param path_raster_folder  Character. Name a path folder to save raster images data. If  doesn't exist, a new directory is created
#' @param as_RasterBrick      Boolean. If FALSE, each layer will be saved in separate file. If TRUE, write a RasterBrick in a file. Default is FALSE.
#'
#' @keywords datasets
#' @return Raster in geotiff format to open using SIG
#' @importFrom ensurer ensure_that
#' @importFrom raster rasterFromXYZ writeRaster crs
#' @export
#'
#' @examples \dontrun{
#' library(lucCalculus)
#'
#' file <- c(system.file("extdata/raster/rasterSample.tif", package = "lucCalculus"))
#' rb_class <- raster::brick(file)
#' my_label <- c("Degradation", "Fallow_Cotton", "Forest", "Pasture", "Soy_Corn", "Soy_Cotton",
#'               "Soy_Fallow", "Soy_Millet", "Soy_Sunflower", "Sugarcane", "Urban_Area", "Water")
#' my_timeline <- c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01",
#'                  "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01",
#'                  "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01",
#'                  "2016-09-01")
#'
#' a <- lucC_pred_recur(raster_obj = rb_class, raster_class = "Forest",
#'                      time_interval1 = c("2001-09-01","2001-09-01"),
#'                      time_interval2 = c("2002-09-01","2016-09-01"),
#'                      label = my_label, timeline = my_timeline)
#'
#' # update original RasterBrick with new class
#' num_label <- length(my_label) + 1
#' rb_class_new <- lucC_raster_update(raster_obj = rb_class,
#'                                    data_mtx = a,
#'                                    timeline = my_timeline,
#'                                    class_to_replace = "Forest",  # the same class previously
#'                                    new_pixel_value = num_label)  # new pixel value
#'
#' lucC_plot_bar_events(data_mtx = rb_class_new, pixel_resolution = 232, custom_palette = FALSE)
#'
#' # save the update matrix as GeoTIFF RasterBrick
#' lucC_save_GeoTIFF(raster_obj = rb_class, data_mtx = rb_class_new,
#'                   path_raster_folder = paste0(getwd(), "/updatedRasterRECUR", sep = ""),
#'                   as_RasterBrick = FALSE )
#'
#'}
#'

# plot maps with events
lucC_save_GeoTIFF <- function(raster_obj = NULL, data_mtx = NULL, path_raster_folder = NULL, as_RasterBrick = FALSE){

  # Ensure if parameters exists
  ensurer::ensure_that(raster_obj, !is.null(raster_obj),
                       err_desc = "raster_obj data, file must be defined!\nA raster brick with classified images.")
  ensurer::ensure_that(data_mtx, !is.null(data_mtx),
                       err_desc = "data_mtx matrix, file must be defined!\nThis data can be obtained using predicates RECUR, HOLDS, EVOLVE and CONVERT and lucC_update_raster().")
  ensurer::ensure_that(path_raster_folder, !is.null(path_raster_folder),
                       err_desc = "path_raster_folder must be defined! Enter a path to SAVE your GeoTIFF images!")

  options(digits = 12)

  # Create directory if doesn't exist
  output_dir <- file.path(path_raster_folder)

  if (!dir.exists(output_dir)){
    message("\nCreated new directory because the path provided doesn't exist! ...\n")
    dir.create(output_dir)
  } else {
    path_raster_folder <- path_raster_folder
  }

  # matrix reclassified to raster format
  new_raster <- raster::rasterFromXYZ(data_mtx)
  names(new_raster) <- gsub("\\..*","", names(new_raster)) # remove dates after point

  # crs from original raster
  raster::crs(new_raster) <- raster_obj@crs

  rm(raster_obj)
  gc()

  message("Saving... \n")

  if(as_RasterBrick == FALSE){
    # write as a geoTIFF file using the raster package by each layer
    raster::writeRaster(new_raster,
                        filename= paste0(path_raster_folder,"/New_", sep = ""),
                        bylayer=TRUE, suffix = names(new_raster), format="GTiff",
                        datatype="INT1U", overwrite=TRUE)
  } else {
    file_name <- basename(path_raster_folder)
    # write as a geoTIFF file using the raster package as a RasterBrick file
    raster::writeRaster(new_raster,
                        filename= paste0(path_raster_folder,"/New_", file_name, sep = ""),
                        bylayer=FALSE, format="GTiff", datatype="INT1U", overwrite=TRUE)
  }

  cat("\nGeoTIFF images saved successfully in directory: '", path_raster_folder, "'\n")

}



#' @title Update a RasterBrick with result from predicates
#' @name lucC_save_raster_result
#' @aliases lucC_save_raster_result
#' @author Adeline M. Maciel
#' @docType data
#'
#' @description Update a RasterBrick with new values of pixel discovered from LUC Calculus formalism to create GeoTIFF files. #' NOTE: Used after had applied some of the functions with predicate.
#'
#' @usage lucC_save_raster_result(raster_obj = NULL, data_mtx = NULL,
#' timeline = NULL, label = NULL, path_raster_folder = NULL, as_RasterBrick = FALSE)
#'
#' @param raster_obj          Raster. A raster brick with classified images
#' @param data_mtx            Matrix. A matrix with values obtained from predicates RECUR, EVOLVE, CONVERT or HOLDS
#' @param timeline            Character. A list of all dates of classified raster, timeline
#' @param label               Character Vector. All labels of each value of pixel from classified raster
#' @param path_raster_folder  Character. Name a path folder to save raster images data. If  doesn't exist, a new directory is created
#' @param as_RasterBrick      Boolean. If FALSE, each layer will be saved in separate file. If TRUE, write a RasterBrick in a file. Default is FALSE.
#'
#' @keywords datasets
#' @return Matrix with raster and pixels to create a RasterBrick with result
#' @importFrom ensurer ensure_that
#' @importFrom lubridate year
#' @importFrom raster rasterToPoints
#' @importFrom dplyr mutate select everything
#' @importFrom tidyr gather spread
#' @importFrom reshape2 dcast
#' @export
#'
#' @examples \dontrun{
#' library(lucCalculus)
#'
#' file <- c(system.file("extdata/raster/rasterSample.tif", package = "lucCalculus"))
#' rb_class <- raster::brick(file)
#' my_label <- c("Degradation", "Fallow_Cotton", "Forest", "Pasture", "Soy_Corn", "Soy_Cotton",
#'               "Soy_Fallow", "Soy_Millet", "Soy_Sunflower", "Sugarcane", "Urban_Area", "Water")
#' my_timeline <- c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01",
#'                  "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01",
#'                  "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01",
#'                  "2016-09-01")
#'
#' a <- lucC_pred_recur(raster_obj = rb_class, raster_class = "Forest",
#'                      time_interval1 = c("2001-09-01","2001-09-01"),
#'                      time_interval2 = c("2002-09-01","2016-09-01"),
#'                      label = my_label, timeline = my_timeline)
#'
#' lucC_plot_raster_result(raster_obj = rb_class, data_mtx = a, timeline = my_timeline,
#'                         label = my_label, custom_palette = FALSE)
#' # save in file
#' lucC_save_raster_result(raster_obj = rb_class, data_mtx = a,
#'                         timeline = my_timeline, label = my_label,
#'                         path_raster_folder = paste0(getwd(), "/onlyRECUR", sep = ""),
#'                         as_RasterBrick = FALSE)
#'
#'}
#'

# plot maps for input data
lucC_save_raster_result <- function(raster_obj = NULL, data_mtx = NULL, timeline = NULL, label = NULL, path_raster_folder = NULL, as_RasterBrick = FALSE) {

  # Ensure if parameters exists
  ensurer::ensure_that(raster_obj, !is.null(raster_obj),
                       err_desc = "raster_obj data, file must be defined!\nA raster brick with classified images.")
  ensurer::ensure_that(data_mtx, !is.null(data_mtx),
                       err_desc = "data_mtx matrix, file must be defined!\nThis data can be obtained using predicates RECUR, HOLDS, EVOLVE and CONVERT.")
  ensurer::ensure_that(timeline, !is.null(timeline),
                       err_desc = "timeline must be defined!")
  ensurer::ensure_that(path_raster_folder, !is.null(path_raster_folder),
                       err_desc = "path_raster_folder must be defined! Enter a path to SAVE your GeoTIFF images!")

  options(digits = 12)

  #-------------------- prepare rasterBrick --------------------------------
  df <- raster::rasterToPoints(raster_obj) %>%
    as.data.frame()

  df[,1:2] <- round(df[,1:2], 5) # limit 5 decimal digits after comman

  # replace colnames to timeline
  colnames(df)[c(3:ncol(df))] <- as.character(lubridate::year(timeline))
  #raster_df <- reshape2::melt(as.data.frame(df), id.vars = c("x","y"))
  raster_df <- df %>%
    tidyr::gather(variable, value, -x, -y)

  rm(df)
  gc()

  # remove factor
  raster_df$value <- 0

  #-------------------- prepare matrix with events --------------------------------
  # x and y as factor
  data_mtx$x <- as.numeric(as.character(as.factor(data_mtx$x)))
  data_mtx$y <- as.numeric(as.character(as.factor(data_mtx$y)))

  data_mtx[,1:2] <- round(data_mtx[,1:2], 5) # limit 5 decimal digits after comman

  # replace new clase by new pixel value
  class_name <- unique(data_mtx[3:ncol(data_mtx)][!duplicated(as.vector(data_mtx[3:ncol(data_mtx)])) & !is.na(data_mtx[3:ncol(data_mtx)])] )

  # return index the first match
  class <- match(class_name, label)  # which(label %in% class_name)

  # replace string by values
  temp <- data.frame(A = class_name, B = class)
  data_mtx[c(3:ncol(data_mtx))] <- lapply(data_mtx[c(3:ncol(data_mtx))], function(x) temp[match(x, temp$A), "B"])

  # data matrix to new raster
  colnames(data_mtx)[c(3:ncol(data_mtx))] <- as.character(lubridate::year(colnames(data_mtx)[c(3:ncol(data_mtx))]))

  #point_df <- reshape2::melt(new_df, id.vars = c("x","y"), na.rm = TRUE)
  point_df <- data_mtx %>%
    tidyr::gather(variable, value, -x, -y, na.rm = TRUE)

  rm(data_mtx)
  gc()

  ## remove factors
  #point_df$x = as.numeric(levels(point_df$x))[point_df$x]
  #point_df$y = as.numeric(levels(point_df$y))[point_df$y]

  # ------------------ replace point_df in raster_df ---------------------
  a <- as.matrix(raster_df)
  b <- as.matrix(point_df)

  rm(raster_df, point_df)
  gc()

  # change original by new values - ok
  raster_rows_both <- base::merge(a, b, by = c("x","y","variable")) #, all = TRUE)
  raster_rows_both[,] <- lapply(raster_rows_both, function(x) {as.numeric(as.character(x))}) # remove factor

  raster_rows_both <- raster_rows_both %>%
    dplyr::mutate(value = ifelse(is.na(.$value.y), .$value.x, .$value.y)) %>%
    dplyr::select(-value.x, -value.y) %>%
    .[order(.$variable),]

  rm(a, b)
  gc()

  # remove duplicates
  raster_rows_both <- raster_rows_both[!duplicated(raster_rows_both), ]

  #raster_rows_both <- dplyr::mutate(raster_rows_both, row = 1:nrow(raster_rows_both))
  #raster_df_update <- reshape2::dcast(raster_rows_both, x + y ~ variable, value.var= 'value', fun.aggregate = mean)
  raster_df_update <- reshape2::dcast(raster_rows_both, x + y ~ variable, value.var= 'value')
  #raster_df_update <- tidyr::spread(raster_rows_both, variable, value, -x, -y)
  # raster_df_update <- raster_rows_both %>%
  #   dplyr::mutate(row = 1:nrow(.)) %>%  # because error "Error: Duplicate identifiers for rows..."
  #   tidyr::spread(variable, value) %>%
  #   dplyr::select(-row)

  # check if the raster result does not have all years of timeline
  dates_result <- as.character(colnames(raster_df_update)[c(3:ncol(raster_df_update))])
  dates_timeline <- as.character(lubridate::year(timeline))

  if(length(dates_timeline[!(dates_timeline %in% dates_result)]) > 0){
    years_missing <- as.list(dates_timeline[!(dates_timeline %in% dates_result)])
    df <- do.call(cbind.data.frame, years_missing)    # pass to dataframe
    df[1,] <- NA        # set NA as values of rows
    raster_df_update <- cbind(raster_df_update,df)    # merge columns missing
    raster_df_update <- raster_df_update %>%          # sort columns and put x and y first
      dplyr::select(sort(names(.))) %>%
      dplyr::select(., x, y, dplyr::everything())
    #
    colnames(raster_df_update)[c(3:ncol(raster_df_update))] <- as.character(lubridate::year(timeline))
    raster_df_update <- droplevels(raster_df_update)

  } else {
    raster_df_update <- raster_df_update
  }

  rm(raster_rows_both, years_missing, df, dates_result, dates_timeline)
  gc()

  # pass to complete date, but we prefer leaver only with years
  # colnames(raster_df_update)[c(3:ncol(raster_df_update))] <- as.character(timeline)

  lucC_save_GeoTIFF(raster_obj = raster_obj, data_mtx = raster_df_update, path_raster_folder = path_raster_folder, as_RasterBrick = as_RasterBrick)

  #return(raster_df_update)

}


#' @title Save a RasterBrick by layers
#' @name lucC_save_rasterBrick_by_layers
#' @aliases lucC_save_rasterBrick_by_layers
#' @author Adeline M. Maciel
#' @docType data
#'
#' @description Save a RasterBrick into individual layers files GeoTIFFs
#'
#' @usage lucC_save_rasterBrick_by_layers(path_name_GeoTIFF_Brick = NULL)
#'
#' @param path_name_GeoTIFF_Brick  Character. Name file and path folder to SPLIT rasterBrick by layers
#'
#' @keywords datasets
#' @return A set of GeoTIFF separate images
#' @importFrom ensurer ensure_that
#' @importFrom raster raster writeRaster brick
#' @importFrom tools file_path_sans_ext
#' @export
#'
#' @examples \dontrun{
#' library(lucCalculus)
#'
#' file <- c(system.file("extdata/raster/rasterItanhanga.tif", package = "lucCalculus"))
#' rb_class <- raster::brick(file)
#'
#' # blocks saved in folder
#' lucC_blocks_raster_create(raster_obj = rb_class, number_blocks_xy = 2, save_images = TRUE)
#'
#' lucC_blocks_raster_merge(path_open_GeoTIFFs = paste0(getwd(), "/Blocks_RasterBrick", sep = ""),
#'                          number_raster = 4, pattern_name = "Raster_Block_", is.rasterBrick = TRUE)
#'
#' lucC_save_rasterBrick_by_layers(
#' path_name_GeoTIFF_Brick = paste0(getwd(),"/Blocks_RasterBrick/Mosaic_Raster_Block_.tif", sep = ""))
#'
#'
#'
#'}
#'

# plot maps for input data
lucC_save_rasterBrick_by_layers <- function(path_name_GeoTIFF_Brick = NULL) {

  # Ensure if parameters exists
  ensurer::ensure_that(path_name_GeoTIFF_Brick, !is.null(path_name_GeoTIFF_Brick),
                       err_desc = "path_name_GeoTIFF_Brick file, must be defined! Enter a path to OPEN your GeoTIFF image RasterBrick.")

  message("Verifying if GeoTIFF image exist ...")

  # chack file exists
  if(file.exists(path_name_GeoTIFF_Brick)){
     cat(path_name_GeoTIFF_Brick, sep = "\n")
     raster <- raster::brick(path_name_GeoTIFF_Brick)
  } else
    stop("There is no path or file with this name!\n")

  path_save <- basename(tools::file_path_sans_ext(path_name_GeoTIFF_Brick))

  # Create directory if doesn't exist
  output_dir <- file.path(paste0(dirname(path_name_GeoTIFF_Brick), "/", path_save, sep = ""))

  if (!dir.exists(output_dir)){
    message("\nCreated new directory because the path provided doesn't exist! ...\n")
    dir.create(output_dir)
    path_raster_folder <- output_dir
  } else {
    path_raster_folder <- path_raster_folder
  }

  message("Saving... \n")

  # write as a geoTIFF file using the raster package by layer
  raster::writeRaster(raster, filename= paste0(path_raster_folder,"/New_", sep = ""),
                      bylayer=TRUE, suffix = names(raster), format="GTiff",
                      datatype="INT1U", overwrite=TRUE)

}



