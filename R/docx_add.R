#' @export
#' @title add an image
#' @description add an image into a docx object
#' @param x a docx device
#' @param src image filename
#' @param style paragraph style
#' @param width height in inches
#' @param height height in inches
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
#' @examples
#' doc <- read_docx()
#'
#' img.file <- file.path( Sys.getenv("R_HOME"), "doc", "html", "logo.jpg" )
#' if( file.exists(img.file) ){
#'   doc <- body_add_img(x = doc, src = img.file, height = 1.06, width = 1.39 )
#' }
#' if( require("ionicons") ){
#'   calendar_src = as_png(name = "calendar", fill = "#FFE64D", width = 144, height = 144)
#'   doc <- body_add_img(x = doc, src = calendar_src, height = 2, width = 2 )
#' }
#' if( require("devEMF") ){
#'   emf("bar.emf", height = 5, width = 5)
#'   barplot(1:10, col = 1:10)
#'   dev.off()
#'   doc <- body_add_img(x = doc, src = "bar.emf", height = 5, width = 5)
#' }
#'
#' print(doc, target = "body_add_img.docx" )
#' @importFrom xml2 read_xml xml_find_first write_xml xml_add_sibling as_xml_document
body_add_img <- function( x, src, style = "Normal", width, height, pos = "after" ){

  style_id <- x$doc_obj$get_style_id(style=style, type = "paragraph")

  ext_img <- external_img(src, width = width, height = height)
  xml_elt <- format(ext_img, type = "wml")
  xml_elt <- paste0("<w:p xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\" xmlns:wp=\"http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">",
                    "<w:pPr><w:pStyle w:val=\"", style_id, "\"/></w:pPr>",
                    xml_elt,
                    "</w:p>")

  x <- docx_reference_img(x, src)
  xml_elt <- wml_link_images( x, xml_elt )


  body_add_xml(x = x, str = xml_elt, pos = pos)
}

#' @export
#' @title add a paragraph
#' @description add a paragraph into a docx object
#' @param x a docx device
#' @param value a character
#' @param style paragraph style
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
#' @examples
#' library(magrittr)
#'
#' doc <- read_docx() %>%
#'   body_add_par("A title", style = "heading 1") %>%
#'   body_add_par("Hello world!", style = "Normal") %>%
#'   body_add_par("centered text", style = "centered")
#' print(doc, target = "body_add_par.docx" )
#' @importFrom xml2 read_xml xml_find_first write_xml xml_add_sibling as_xml_document
body_add_par <- function( x, value, style, pos = "after" ){

  style_id <- x$doc_obj$get_style_id(style=style, type = "paragraph")

  xml_elt <- paste0("<w:p xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">",
                    "<w:pPr><w:pStyle w:val=\"", style_id, "\"/></w:pPr><w:r><w:t xml:space=\"preserve\">",
                    value, "</w:t></w:r></w:p>")
  body_add_xml(x = x, str = xml_elt, pos = pos)
}

as_tc <- function(x, collapse = FALSE ){
  str <- paste0("<w:tc><w:trPr/><w:p><w:r><w:t>", gsub("(^[ ]|[ ]$)", "", format(x)), "</w:t></w:r></w:p></w:tc>")
  if( collapse )
    str <- paste(str, collapse = "")
  str
}

#' @export
#' @title add a table
#' @description add a table into a docx object
#' @param x a docx device
#' @param value a data.frame
#' @param style table style
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
#' @param width table width for column width calculation
#' @param first_row,last_row,first_column,last_column,no_hband,no_vband logical for Word table options
#' @examples
#' library(magrittr)
#'
#' doc <- read_docx() %>%
#'   body_add_table(iris, style = "table_template")
#' print(doc, target = "body_add_table.docx" )
#' @importFrom xml2 read_xml xml_find_first write_xml xml_add_sibling as_xml_document
body_add_table <- function( x, value, style, pos = "after", width = 5,
                            first_row = TRUE, first_column = FALSE,
                            last_row = TRUE, last_column = FALSE,
                            no_hband = FALSE, no_vband = TRUE ){

  style_id <- x$doc_obj$get_style_id(style=style, type = "table")

  tbl_look <- "<w:tblLook w:firstRow=\"%.0f\" w:lastRow=\"%.0f\" w:firstColumn=\"%.0f\" w:lastColumn=\"%.0f\" w:noHBand=\"%.0f\" w:noVBand=\"%.0f\" />"
  tbl_look <- sprintf(tbl_look, first_row, last_row, first_column, last_column, no_hband, no_vband)

  dat <- lapply(value, as_tc)
  dat <- do.call(cbind, dat)
  dat <- apply( dat, 1, function(x){
    paste0("<w:tr>", paste(x, collapse = ""), "</w:tr>")
  })
  dat <- paste(dat, collapse = "")
  dat <- paste( paste0("<w:tr><w:trPr><w:tblHeader/></w:trPr>",
                       as_tc(names(value), collapse = TRUE), "</w:tr>"),
                dat )

  width <- width * 72 * 20
  grid_col <- sprintf("<w:gridCol w:w=\"%.0f\"/>", width / ncol(value) )
  grid_col <- rep(grid_col, ncol(value))
  grid_col <- paste(grid_col, collapse = "")
  grid_col <- paste0("<w:tblGrid>", grid_col, "</w:tblGrid>")

  tbpr <- "<w:tblPr><w:tblStyle w:val=\"%s\"/><w:tblW/>%s</w:tblPr>"
  tbpr <- sprintf(tbpr, style_id, tbl_look)

  xml_elt <- paste0( sprintf("<w:tbl %s>", base_ns),
          tbpr, grid_col, dat, "</w:tbl>")

  body_add_xml(x = x, str = xml_elt, pos = pos)
}



#' @export
#' @title add a table of content
#' @description add a table of content into a docx object
#' @param x a docx object
#' @param level max title level of the table
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
#' @param style optional. style in the document that will be used to build entries of the TOC.
#' @param separator optional. Some configurations need "," (i.e. from Canada) separator instead of ";"
#' @examples
#' library(magrittr)
#' doc <- read_docx() %>% body_add_toc()
#' print(doc, target = "body_add_toc.docx" )
body_add_toc <- function( x, level = 3, pos = "after", style = NULL, separator = ";"){

  if( is.null( style )){
    str <- paste0("<w:p xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:pPr/>",
                  "<w:r><w:fldChar w:fldCharType=\"begin\" w:dirty=\"true\"/></w:r>",
                  "<w:r><w:instrText xml:space=\"preserve\" w:dirty=\"true\">TOC \u005Co &quot;1-%.0f&quot; \u005Ch \u005Cz \u005Cu</w:instrText></w:r>",
                  "<w:r><w:fldChar w:fldCharType=\"end\" w:dirty=\"true\"/></w:r>",
                  "</w:p>")
    out <- sprintf(str, level)
  } else {
    str <- paste0("<w:p xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:pPr/>",
                  "<w:r><w:fldChar w:fldCharType=\"begin\" w:dirty=\"true\"/></w:r>",
                  "<w:r><w:instrText xml:space=\"preserve\" w:dirty=\"true\">TOC \u005Ch \u005Cz \u005Ct \"%s%s1\"</w:instrText></w:r>",
                  "<w:r><w:fldChar w:fldCharType=\"end\" w:dirty=\"true\"/></w:r>",
                  "</w:p>")
    out <- sprintf(str, style, separator)
  }

  body_add_xml(x = x, str = out, pos = pos)

}



#' @export
#' @title add a page break
#' @description add a page break into a docx object
#' @param x a docx object
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
#' @examples
#' library(magrittr)
#' doc <- read_docx() %>% body_add_break()
#' print(doc, target = "body_add_break.docx" )
body_add_break <- function( x, pos = "after"){

  str <- paste0("<w:p xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\"><w:pPr/>",
                "<w:r><w:br w:type=\"page\"/></w:r>",
                "</w:p>")
  body_add_xml(x = x, str = str, pos = pos)

}

#' @export
#' @title add a wml string into a Word document
#' @importFrom xml2 as_xml_document xml_replace
#' @description The function add a wml string into
#' the document after, before or on a cursor location.
#' @param x a docx object
#' @param str a wml string
#' @param pos where to add the new element relative to the cursor,
#' one of "after", "before", "on".
body_add_xml <- function(x, str, pos){
  xml_elt <- as_xml_document(str)
  pos_list <- c("after", "before", "on")

  if( !pos %in% pos_list )
    stop("unknown pos ", shQuote(pos, type = "sh"), ", it should be ",
         paste( shQuote(pos_list, type = "sh"), collapse = " or ") )

  if( length(x) == 1 ){
    xml_add_child(x$doc_obj$get(), xml_elt)
    x <- cursor_end(x)
  } else {
    cursor_elt <- x$doc_obj$get_at_cursor()
    if( pos != "on")
      xml_add_sibling(cursor_elt, xml_elt, .where = pos)
    else {
      xml_replace(cursor_elt, xml_elt)
    }
    if(pos == "after")
      x <- cursor_forward(x)
  }


  x
}



#' @export
#' @title remove an element
#' @description remove element pointed by cursor from a Word document
#' @importFrom xml2 xml_remove
#' @param x a docx object
#' @examples
#' library(officer)
#' library(magrittr)
#'
#' str1 <- "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " %>%
#'   rep(20) %>% paste(collapse = "")
#' str2 <- "Drop that text"
#' str3 <- "Aenean venenatis varius elit et fermentum vivamus vehicula. " %>%
#'   rep(20) %>% paste(collapse = "")
#'
#' my_doc <- read_docx()  %>%
#'   body_add_par(value = str1, style = "Normal") %>%
#'   body_add_par(value = str2, style = "centered") %>%
#'   body_add_par(value = str3, style = "Normal")
#' print(my_doc, target = "init_doc.docx")
#'
#' my_doc <- read_docx(path = "init_doc.docx")  %>%
#'   cursor_reach(keyword = "that text") %>%
#'   body_remove()
#' print(my_doc, target = "result_doc.docx")
body_remove <- function(x){
  cursor_elt <- x$doc_obj$get_at_cursor()
  xml_remove(cursor_elt)
  x <- cursor_forward(x)
  x
}


#' @export
#' @title add section
#' @description add a section in a Word document. A section is attached to the latest paragraph
#' of the section.
#'
#' @details
#' A section start at the end of the previous section (or the beginning of
#' the document if no preceding section exists), it stops where the section is declared.
#' The function is reflecting that (complicated) Word concept, by adding an ending section
#' attached to the paragraph where cursor is.
#' @importFrom xml2 xml_remove
#' @param x a docx object
#' @param landscape landscape orientation
#' @param colwidths columns widths in percent, if 3 values, 3 columns will be produced.
#' Sum of this argument should be 1.
#' @param space space in percent between columns.
#' @param sep if TRUE a line is sperating columns.
#' @examples
#' library(officer)
#' library(magrittr)
#'
#' str1 <- "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " %>%
#'   rep(20) %>% paste(collapse = "")
#' str2 <- "Sed hendrerit, est eget convallis vestibulum, mauris ligula. " %>%
#'   rep(20) %>% paste(collapse = "")
#' str3 <- "Aenean venenatis varius elit et fermentum vivamus vehicula. " %>%
#'   rep(20) %>% paste(collapse = "")
#'
#' my_doc <- read_docx()  %>%
#'   body_add_par("String 1", style = "heading 1") %>%
#'   body_add_par(value = str1, style = "Normal") %>%
#'   body_add_par("String 2", style = "heading 1") %>%
#'   body_add_par(value = str2, style = "Normal") %>%
#'   body_end_section(landscape = TRUE, colwidths = c(.6, .4), space = .05, sep = FALSE) %>%
#'   body_add_par("String 3", style = "heading 1") %>%
#'   body_add_par(value = str3, style = "Normal")
#' print(my_doc, target = "body_end_section.docx")
#' @importFrom xml2 as_list
body_end_section <- function(x, landscape = FALSE, colwidths = c(1), space = .05, sep = FALSE){

  stopifnot(all.equal( sum(colwidths), 1 ) )


  last_sect <- x$doc_obj$get() %>% xml_find_first("/w:document/w:body/w:sectPr[last()]")
  section_obj <- as_list(last_sect)

  h_ref <- as.integer(attr(section_obj$pgSz, "h"))
  w_ref <- as.integer(attr(section_obj$pgSz, "w"))

  mar_t <- as.integer(attr(section_obj$pgMar, "top"))
  mar_b <- as.integer(attr(section_obj$pgMar, "bottom"))
  mar_r <- as.integer(attr(section_obj$pgMar, "right"))
  mar_l <- as.integer(attr(section_obj$pgMar, "left"))
  mar_h <- as.integer(attr(section_obj$pgMar, "header"))
  mar_f <- as.integer(attr(section_obj$pgMar, "footer"))

  if( !landscape ){
    h <- h_ref
    w <- w_ref
    mar_top <- mar_t
    mar_bottom <- mar_b
    mar_right <- mar_r
    mar_left <- mar_l
  } else {
    h <- w_ref
    w <- h_ref
    mar_top <- mar_r
    mar_bottom <- mar_l
    mar_right <- mar_t
    mar_left <- mar_b
  }
  pgsz_str <- "<w:pgSz %sw:w=\"%.0f\" w:h=\"%.0f\"/>"
  pgsz_str <- sprintf(pgsz_str, ifelse( landscape, "w:orient=\"landscape\" ", ""), w, h )

  mar_str <- "<w:pgMar w:top=\"%.0f\" w:right=\"%.0f\" w:bottom=\"%.0f\" w:left=\"%.0f\" w:header=\"%.0f\" w:footer=\"%.0f\" w:gutter=\"0\"/>"
  mar_str <- sprintf(mar_str, mar_top, mar_right, mar_bottom, mar_left, mar_h, mar_f )

  width_ <- w - mar_right - mar_left
  column_values <- colwidths - space
  columns_str_all_but_last <- sprintf("<w:col w:w=\"%.0f\" w:space=\"%.0f\"/>",
                                      column_values[-length(column_values)] * width_,
                                      space * width_)
  columns_str_last <- sprintf("<w:col w:w=\"%.0f\"/>",
                              column_values[length(column_values)] * width_)
  columns_str <- c(columns_str_all_but_last, columns_str_last)
  columns_str <- sprintf("<w:cols w:num=\"%.0f\" w:sep=\"%.0f\" w:space=\"%.0f\" w:equalWidth=\"0\">%s</w:cols>",
          length(colwidths), as.integer(sep), space * w, paste0(columns_str, collapse = "") )



  str <- paste0("<w:sectPr xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">",
                pgsz_str, columns_str, mar_str, "</w:sectPr>")
  xml_elt <- as_xml_document(str)

  cursor_elt <- x$doc_obj$get_at_cursor()
  xml_add_child(.x = xml_child(cursor_elt, "w:pPr"), .value = xml_elt )
  x
}