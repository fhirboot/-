# rm(list=ls())
# gc()

library(shiny)
library(shinyjs)
library(plotly)
library(htmlwidgets)
library(shinyWidgets)
library(DT)
library(dplyr)
library(stringi);
library(stringr);
library(lubridate)
library(googlesheets4) # google authorization
library(jsonlite);
library(tidyr)
library(openxlsx)
# # library(shinydashboard)

# # library(sortable)

# library(plotly)
# library(htmlwidgets)
# # library(ggplot2)
# # library(xml2);
# # library(rvest);
# # library(readxl);
# library(jsonlite);
# library(httr);
# library(curl);
# library(stringdist)
# library(dplyr)
# # library(tidyr)
# # library(openxlsx)
# library(lubridate)
# library(shinyalert)
gs4_deauth()

# 
Origin_DB <-read_sheet("https://docs.google.com/spreadsheets/d/1apgtDqJ9fpKt9HHNi8ZnzcrB0JuVWvZPq-G_C4oMxXg/edit?gid=0#gid=0","Sheet1",col_types = "c")
# write.xlsx(Origin_DB, file='Origin_DB.xlsx', row.names = FALSE)
# check


# JavaScript to add click event to the divs
js1 <- "
$(document).on('shiny:connected', function() {
  $('#img_button').on('click', function() {
    Shiny.setInputValue('img_button', Math.random());
  });
  $('#img_button2').on('click', function() {
    Shiny.setInputValue('img_button2', Math.random());
  });
});
"

###-------------------------------------
#
# Constant variable definition
#
#------------------------------------------
source("css.R") # web style

#selection table
selecting <- data.frame(x1 = c("질병"), x2= "MY")
selecting2 <- data.frame(x1 = c("1주일"), x2= c("1개월"), x3 =c("6개월"))


#function
convert_minutes_to_hhmm <- function(minutes) {
  hours <- minutes %/% 60
  remaining_minutes <- minutes %% 60
  return(sprintf("%02d:%02d", hours, remaining_minutes))
}
# 천 단위로 콤마를 추가하는 함수
format_with_comma <- function(x) {
  format(x, big.mark = ",", scientific = FALSE)
}

# Custom Plotly 그래프 생성 함수
createCustomPlotly <- function(df, indexColumn, valuesColumn, colorDefault, colorHover) {
  p <- plot_ly(df, x = ~get(indexColumn), y = ~get(valuesColumn), type = 'bar',
               marker = list(color = colorDefault),  # 초기 색상 설정
               hoverinfo = 'y', hovertemplate = " %{y}<extra></extra>") %>%
    layout(
      margin = list(l = 15, r = 10, t = 10, b = 5),
      title = "",
      xaxis = list(title = "", showticklabels = FALSE, zeroline = FALSE, showgrid = FALSE),
      yaxis = list(title = "", showticklabels = FALSE, zeroline = FALSE, showgrid = FALSE),
      plot_bgcolor = 'rgba(0,0,0,0)'  # 배경 색상 투명
    ) %>%
    config(displayModeBar = FALSE)
  
  # JavaScript 코드를 수정하여 색상 값이 정확히 반영되도록 함
  jsCode <- sprintf("function(el, x) {
    el.on('plotly_hover', function(data) {
      var colors = new Array(data.points[0].data.x.length).fill('%s');
      colors[data.points[0].pointNumber] = '%s';
      var update = {marker: {color: colors}};
      Plotly.restyle(el.id, update);
    });
  }", colorDefault, colorHover)
  
  p <- htmlwidgets::onRender(p, jsCode)
  
  return(p)
}

## 
# NA 값을 대체하는 함수 (각 열의 데이터 타입을 유지)
replace_na_with_value <- function(column, value) {
  column[is.na(column)] <- value
  return(column)
}

# 데이터 프레임을 항목별로 변환하는 함수
create_item_df <- function(df, column_name) {
  df[[column_name]] <- replace_na_with_value(df[[column_name]], "0")  # NA 값을 0.1로 대체
  data.frame(
    item = rep(column_name, nrow(df)),
    values = df[[column_name]],
    index = 1:nrow(df),
    stringsAsFactors = FALSE
  )
}


df0_cor = 'rgba(11,108,255,1)' #파랑
df1_cor = 'rgba(239,73,73,0.7)' #red
df2_cor = 'rgba(239,73,73,0.7)' #red
df3_cor = 'rgba(116,79,220,0.7)' #보라
df4_cor = 'rgba(255,157,11,0.7)'
df5_cor = 'rgba(19,202,15,0.7)' #그린
df6_cor =  'rgba(239,73,73,0.7)' #red
df7_cor =  'rgba(255,210,51,1)' #노랑
# 
format_iso8601 <- function(time) {
  iso_time <- format(time, "%Y-%m-%dT%H:%M:%S")   # ISO 8601 형식으로 날짜와 시간을 포맷팅
  paste0(iso_time, "+09:00")  # KST 시간대 정보를 포함하여 문자열 반환
}
DBtime1<-  format(Sys.time(), "%Y")
today_date <- Sys.Date()

ui <- fluidPage(
  tags$style("#myTabs { display:none; }"),
  useShinyjs(),  # shinyjs 초기화
  tags$head(
    tags$link(rel = "stylesheet", href = "https://unpkg.com/keyboard-css@1.2.2/dist/css/main.min.css")
  ),
  tags$head(style_tag1,
            tags$meta(name="application-name", content="FHIR_bootcamp"),
            tags$meta(name="author", content="나니아"),
            tags$meta(name="creation_date", content="10/07/2024")
  ),
  titlePanel(
    title="",
    windowTitle = "나의연대기"
  ),
  tabsetPanel(id="myTabs", 
              tabPanel(value="DB0", 
                       HTML("<span class='tab-title'>데이터 요소정의 </span>"),
                       fluidRow(
                         column(3,
                                div(style="font-size:100%; background-color:#F5F5F5; font-family:  Noto Sans KR, sans-serif; line-height:1.8; padding: -10px; margin: -10px; border-radius: 4px; word-break: break-all;",
                                    
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 6px; border-radius: 10px; word-break: break-all; height: 80px; border: 1px solid #ccc; ",
                                        
                                        airDatepickerInput(
                                          "input_var_name",
                                          label = "Year",
                                          value = DBtime1,
                                          maxDate = DBtime1,
                                          minDate = "1990",
                                          view = "years",
                                          minView = "years",
                                          dateFormat = "yyyy"
                                        )
                                    ),
                                    div(style="display: flex; flex-direction: column; align-items: center; font-size: 95%; font-family: Noto Sans KR, sans-serif;
            line-height: 1.5;  margin: 10px 0 3px; vertical-align: middle; word-break: break-all; height: 41px;  ",
                                        DTOutput("data_select")
                                    ),
                                    div(style="display: flex;flex-direction: column;font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: -10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 800px; border: 1px solid #ccc; ",
                                        uiOutput('outline'),
                                        DTOutput("data_table")
                                        
                                    )
                                    
                                    
                                )
                         ),
                         column(5,
                                div(style="font-size:100%; background-color:#F5F5F5; font-family:  Noto Sans KR, sans-serif; line-height:1.8; padding: -10px; margin: -10px; border-radius: 4px; word-break: break-all;",
                                    
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 41px; border: 1px solid #ccc; ",
                                        div(style="width: 100 %;", 
                                            uiOutput('timeline')),
                                    ),
                                    
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 81px; border: 1px solid #ccc; ",
                                        div(style="width: 65%;margin-left:14px;", HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df1_cor,'" ><img src="_weight.png" height="18px">&nbsp;&nbsp;체중 </span>')),
                                            uiOutput('df_1_text')
                                        ),
                                        div(style="width: 35%;margin-right:14px;", plotlyOutput("plot1", height = "100%", width = "100%"))
                                    ),
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF; margin: 0 0 3px;border-radius: 10px; word-break: break-all; height: 81px; border: 1px solid #ccc; ",
                                        div(style="width: 65%;margin-left:14px;", HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df4_cor,'" ><img src="_nut.png" height="18px">&nbsp;&nbsp;영양제 </span>')),
                                            uiOutput('df_4_text')
                                        ),
                                        div(style="width: 35%;margin-right:14px;", plotlyOutput("plot4", height = "100%", width = "100%"))
                                    ),
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 81px; border: 1px solid #ccc; ",
                                        div(style="width: 65%;margin-left:14px;", HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df2_cor,'" ><img src="_intake.png" height="18px">&nbsp;&nbsp;섭취열량 </span>')),
                                            uiOutput('df_2_text')),
                                        div(style="width: 35%;margin-right:14px;", plotlyOutput("plot2", height = "100%", width = "100%"))
                                    ),
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 81px; border: 1px solid #ccc; ",
                                        div(style="width: 65%;margin-left:14px;", HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df3_cor,'" ><img src="_sleep.png" height="18px">&nbsp;&nbsp;수면 </span>')),
                                            uiOutput('df_3_text')),
                                        div(style="width: 35%;margin-right:14px;", plotlyOutput("plot3", height = "100%", width = "100%"))
                                    ),
                                    
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 81px; border: 1px solid #ccc; ",
                                        div(style="width: 65%;margin-left:14px;", HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df5_cor,'" ><img src="_walk.png" height="18px">&nbsp;&nbsp;걸음수 </span>')),
                                            uiOutput('df_5_text')),
                                        div(style="width: 35%;margin-right:14px;", plotlyOutput("plot5", height = "100%", width = "100%"))
                                    )
                                    ,
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 81px; border: 1px solid #ccc; ",
                                        div(style="width: 65%;margin-left:14px;", HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df6_cor,'" ><img src="_exer.png" height="18px">&nbsp;&nbsp;운동시간 </span>')),
                                            uiOutput('df_6_text')),
                                        div(style="width: 35%;margin-right:14px;", plotlyOutput("plot6", height = "100%", width = "100%"))
                                    ),
                                    div(style="display: flex; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding: 10px; background-color:#FFFFFF;margin: 0 0 3px; border-radius: 10px; word-break: break-all; height: 380px; border: 1px solid #ccc; ",
                                        div(style="width: 50%;margin-left:14px;", 
                                            HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em;color:',df0_cor,'" ><img src="_medi.png" height="18px">&nbsp;&nbsp;처방정보 </span>')),
                                            span(style="display: inline-block;",  div(style = 'padding:5px;',
                                                                                      HTML(paste0('<span style="font-size:0.9em; ">&nbsp;</span>')
                                                                                      ))  ),
                                            uiOutput('df_7_text')),
                                        div(style="width: 50%;margin-left:14px;", 
                                            HTML(paste0('<span class="entity" style="font-weight:500; font-size:1.1em; color:',df0_cor,';">[이전] </span>')),
                                            span(style="display: inline-block;", uiOutput('df_8_date')),
                                            uiOutput('df_8_text')),
                                    ),
                                    
                                )
                         ),
                         
                         
                         column(4,
                                div(style="font-size:100%; background-color:#F5F5F5; font-family:  Noto Sans KR, sans-serif; line-height:1.8; padding: -10px; margin: -10px;  word-break: break-all;",
                                    
                                    div(style="display: flex; flex-direction: column;padding: -10px; margin: -10px; font-size:95%; font-family:Noto Sans KR, sans-serif;
              line-height:1.5; padding-top: 10px; background-color:#F5F5F5;margin: 0 0 1px; border-radius: 10px; word-break: break-all; ",
                                        div(
                                          style = "width: 100%; height: 41px; background-color:#FFFFFF; margin-top:-10px; border-radius: 10px; word-break: break-all; border: 1px solid #ccc; display: flex; align-items: center; justify-content: space-between;",
                                          div(
                                            uiOutput('timeline2'),
                                            style = "flex-grow: 1; display: inline-block; word-break: break-all;"
                                          ),
                                          downloadButton(
                                            "convert",
                                            label = "DN",  # 텍스트 없이 아이콘만 표시
                                         
                                            style = "background-color: transparent; border: none;" 
                                          ),
                                          
                                          div(
                                            id = "img_button2",
                                            tags$img(src = "_fhir.png", height = "20px"),
                                            style = "cursor: pointer; display: inline-block; margin-right: 10px;"
                                          )
                                        
                                    ),
                                        div(style="width: 100 %;height: 41px; background-color:#FFFFFF;margin-top:3px;", 
                                            DTOutput("data_select2")),
                                        div(style="width: 100 %;height: 200px;background-color:#FFFFFF; margin-top:10px; border-radius: 10px; word-break: break-all; border: 1px solid #ccc;", 
                                            plotlyOutput("plot7", height = "97%", width = "90%")),
                                        div(style="width: 100 %;height: 200px;background-color:#FFFFFF; margin-top:10px; padding-left: -5px; padding-right:-5px;border-radius: 10px; word-break: break-all; border: 1px solid #ccc;", 
                                            plotlyOutput("plot8", height = "97%", width = "90%")),
                                        div(style="width: 100 %;height: 150px; background-color:#FFFFFF;margin-top:10px; padding-left: -5px; padding-right:-5px;border-radius: 10px; word-break: break-all; border: 1px solid #ccc;", 
                                            plotlyOutput("plot9", height = "97%", width = "90%")),
                                        div(style="width: 100 %;height: 150px;background-color:#FFFFFF; margin-top:10px; padding-left: -5px; padding-right:-5px;border-radius: 10px; word-break: break-all; border: 1px solid #ccc;", 
                                            plotlyOutput("plot10", height = "97%", width = "90%"))
                                        
                                          
                                    )
                                    
                                )
                         )
                         
                       )
              )
  )
)

ui <- tagList(
  ui,
  tags$script(HTML(js1))
)





server <- function(input, output, session) {
  selected_year <- reactiveVal(NULL)
  DB_selected <-reactiveVal(NULL)
  DB_selected2 <- reactiveVal(NULL)
  initial <- reactiveVal(TRUE)
  target_me_date <- NULL
  out_DB <- NULL
  
  out_target_DB <- NULL
  out_target_DB_date<- NULL
  target_date <-NULL
  df_1_out<-NULL 
  df_2_out<-NULL
  df_3_out<-NULL
  df_4_out<-NULL
  df_5_out<-NULL
  df_6_out<-NULL
  
  output$convert <- downloadHandler(
    filename = function() {
      req(out_DB)
      temp <- out_DB
      count_out <- nrow(temp)
      date_out <- temp[count_out, ]$날짜
      file_name <- paste0("Narnia_", date_out, "_before_", count_out, ".xlsx")
      print(file_name)  # 파일명을 콘솔에 출력
      
      return(file_name)
    },
    content = function(file) {
      req(out_DB)
      write.xlsx(out_DB, file)
    }
  )
  
  observeEvent(input$img_button2, {
    showModal(modalDialog("Converting FHIR and Sending...", footer = NULL))
    invalidateLater(3000, session)  # 2초 딜레이 후 작업 수행
    req(out_DB)
    temp <- out_DB
    write.xlsx(out_DB, file="check.xlsx")
    # Python 스크립트 실행
    system("python hello.py")
    
    # Python 스크립트 실행 후 결과 처리
    if (file.exists("output.txt")) {
      result <- readLines("output.txt")
      print(result)
    } else {
      print("Python script did not generate output.")
    }
    
    removeModal()
  })
  
  
  output$data_select <- renderDT({
    datatable(selecting, 
              class = list(stripe = FALSE),
              options = list(
                headerCallback = JS(
                  "function(thead, data, start, end, display){",
                  "  $(thead).remove();",
                  "  $('table.dataTable.no-footer').css('border-bottom', 'none');",
                  "}"),
                dom = 't',
                paging = FALSE,
                info = FALSE,
                autoWidth = FALSE,
                columnDefs = list(
                  list(width = '50%', targets = 0),  # 첫 번째 컬럼 너비 50%
                  list(width = '50%', targets = 1)   # 두 번째 컬럼 너비 50%
                )
              )
              ,
              selection = list(target = "cell", mode = "single", selected = matrix(c(1, 0), ncol = 2)),
              
              rownames=FALSE)
    
  })
  
  
  output$data_select2 <- renderDT({
    datatable(selecting2, 
              class = list(stripe = FALSE),
              options = list(
                headerCallback = JS(
                  "function(thead, data, start, end, display){",
                  "  $(thead).remove();",
                  "  $('table.dataTable.no-footer').css('border-bottom', 'none');",
                  "}"),
                dom = 't',
                paging = FALSE,
                info = FALSE
             
              )
              ,
              selection = list(target = "cell", mode = "single", selected = matrix(c(1, 0), ncol = 2)),
              
              rownames=FALSE)
    
  })
  
  observeEvent(input$data_select2_cells_selected, {
    req(target_me_date)
    # print(target_me_date)
    selected2 <- input$data_select2_cells_selected
    # print(selected2)
    if (!is.null(selected2) && nrow(selected2) > 0) {
      row_index <- selected2[1, 1]   # R 인덱스는 1부터 시작하므로 +1
      column_index <- selected2[1, 2]   # R 인덱스는 1부터 시작하므로 +1
      selected_value2 <- selecting2[row_index, column_index+1]  # 인덱스 조정
      DB_selected2(selected_value2)
    }  else {
      # 선택된 셀이 없을 때 첫 번째 셀을 선택하도록 강제
      proxy2<- dataTableProxy("data_select2")
      selectCells(proxy2, list(c(1, 0)))
    }
    # print(DB_selected2())
  
    if(DB_selected2() == "1주일"){
      before_date <- target_me_date - 6
    }else if(DB_selected2() == "1개월"){
      before_date <- target_me_date - 30
    }else{
      before_date <- target_me_date - 180
    }
    
    output$timeline2 <- renderUI({
      div(style = 'margin-top:-5px; padding:10px;',
          HTML(paste0('<span class="entity" style="font-weight:600; font-size:1.0em;" >',
                      str_replace_all(before_date,"-",'/'), " - ", str_replace_all(target_me_date,"-",'/'),'</span>')))
    })
    temp_graph_DB <-  Origin_DB %>%
      filter(날짜 >= before_date & 날짜 <= target_me_date) 
    
    out_DB <<- temp_graph_DB
   
    
    graph_DB1 <- temp_graph_DB %>%
      select(소모열량_kcal, 열량_kcal) %>%
      mutate(소모열량_kcal = as.numeric(소모열량_kcal),
             열량_kcal = as.numeric(열량_kcal)) %>%
      replace_na(list(소모열량_kcal = 0, 열량_kcal = 0))
    
  
    output$plot7 <- renderPlotly({
      color1 <- 'rgba(217, 83, 79, 0.7)'  # 첫 번째 선의 색상
      color2 <- 'rgba(66, 139, 202, 0.7)'  # 두 번째 선의 색상
      fillColor1 <- 'rgba(217, 83, 79, 0.2)'  # 빨간색 음영
      fillColor2 <- 'rgba(66, 139, 202, 0.2)'  # 파란색 음영
      
      p <- plot_ly() %>%
        add_polygons(data = graph_DB1,
                     x = c(1:nrow(graph_DB1), rev(1:nrow(graph_DB1))),
                     y = c(graph_DB1$소모열량_kcal, rep(0, nrow(graph_DB1))),
                     fillcolor = fillColor1, line = list(color = 'transparent'), showlegend = FALSE,
                     hoverinfo = 'skip') %>%
        add_polygons(data = graph_DB1,
                     x = c(1:nrow(graph_DB1), rev(1:nrow(graph_DB1))),
                     y = c(graph_DB1$열량_kcal, rep(0, nrow(graph_DB1))),
                     fillcolor = fillColor2, line = list(color = 'transparent'), showlegend = FALSE,
                     hoverinfo = 'skip') %>%
        add_lines(data = graph_DB1, x = ~1:nrow(graph_DB1), y = ~소모열량_kcal, line = list(color = color1), name = '소모열량',
                  hoverinfo = 'y', hovertemplate = "<b>소모열량: %{y}</b><extra></extra>") %>%
        add_lines(data = graph_DB1, x = ~1:nrow(graph_DB1), y = ~열량_kcal, line = list(color = color2), name = '섭취열량',
                  hoverinfo = 'y', hovertemplate = "<b>섭취열량: %{y}</b><extra></extra>")
      
      p <- p %>%
        layout(
          margin = list(l = 5, r = 5, t = 8, b = 5),
          title = "",
          xaxis = list(title = "", showticklabels = TRUE, zeroline = FALSE, showgrid = FALSE,
                       tickfont = list(size = 12, family = 'Arial', weight = 'bold')),
          yaxis = list(title = "", showticklabels = TRUE, zeroline = FALSE, showgrid = FALSE,
                       tickfont = list(size = 12, family = 'Arial', weight = 'bold')),
          plot_bgcolor = 'rgba(0,0,0,0)',  # 배경 색상 투명
          legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.1, font = list(size = 10))  # 범례를 아래로 이동하고 폰트 크기 줄임
        ) %>%
        config(displayModeBar = FALSE)
      
      return(p)
    })

    # print(temp_graph_DB)
    max_weight<-max(as.numeric(Origin_DB$체중),na.rm = TRUE) +3
    min_weight<-min(as.numeric(Origin_DB$체중),na.rm = TRUE) -3
    graph_DB2<- temp_graph_DB %>%
      select(탄수화물_g , 단백질_g, 지방_g,체중) %>%
      mutate(탄수화물_g = as.numeric(탄수화물_g),
             단백질_g = as.numeric(단백질_g),
             지방_g = as.numeric(지방_g),
             체중 = as.numeric(체중)
             ) %>%
      replace_na(list(탄수화물_g = 0, 단백질_g = 0,
                      지방_g =0))
    
    
    output$plot8 <-  renderPlotly({
      p <- plot_ly(graph_DB2, x = ~seq_along(탄수화물_g)) %>%
        add_bars(y = ~탄수화물_g, name = "탄수화물", marker = list(color = df1_cor),
                 hovertemplate = "<b>탄수화물: %{y}</b><extra></extra>") %>%
        add_bars(y = ~단백질_g, name = "단백질", marker = list(color = df4_cor),
                 hovertemplate = "<b>단백질: %{y}</b><extra></extra>") %>%
        add_bars(y = ~지방_g, name = "지방", marker = list(color = df7_cor),
                 hovertemplate = "<b>지방: %{y}</b><extra></extra>") %>%
        add_lines(y = ~체중, name = "체중", yaxis = "y2", line = list(color = 'gray'), 
                  marker = list(color = 'gray'), connectgaps = TRUE,
                  hovertemplate = "<b>체중: %{y}</b><extra></extra>") %>%
        layout(
          barmode = 'stack',
          yaxis = list(title = "", showgrid = FALSE, tickfont = list(size = 12, family = 'Arial', weight = 'bold')),
          yaxis2 = list(overlaying = "y", side = "right", title = "", showgrid = FALSE, tickfont = list(size = 12, family = 'Arial', weight = 'bold'), range = c(min_weight, max_weight)),
          xaxis = list(title = "", showgrid = FALSE, showticklabels = FALSE, tickfont = list(size = 12, family = 'Arial', weight = 'bold')),
          plot_bgcolor = 'rgba(0,0,0,0)',  # 배경 색상 투명
          legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.3, font = list(size = 10)),  # 범례를 아래로 이동하고 폰트 크기 줄임
          margin = list(l = 5, r = 20, t = 8, b = 5)  # 오른쪽 여백을 40으로 설정하여 y축 레이블이 잘리지 않도록 함
        ) %>%
        config(displayModeBar = FALSE)  # 모드바 숨김
      
      return(p)
    })
    # head(temp_graph_DB)
    
    graph_DB3 <- temp_graph_DB %>%
      select(최저심박수_bpm, 최대심박수_bpm,평균심박수_bpm, 운동시간_분) %>%
      mutate(최저심박수_bpm = as.numeric(최저심박수_bpm),
             최대심박수_bpm = as.numeric(최대심박수_bpm),
             평균심박수_bpm = as.numeric(평균심박수_bpm),
             운동시간_분 = as.numeric(운동시간_분)
             ) %>%
      replace_na(list(운동시간_분 = 0))
    
    # print(graph_DB3)
    # rgba(255, 0, 102, 1)
    
    output$plot9 <-  renderPlotly({
      plot_ly(graph_DB3) %>%
        # 최저-최대 범위 바 추가
        add_bars(
          x = ~seq_along(최저심박수_bpm),
          y = ~최대심박수_bpm - 최저심박수_bpm,
          base = ~최저심박수_bpm,
          name = '심박수 범위',
          marker = list(color = 'rgba(255, 99, 132, 0.6)'),
          hovertemplate = "<b>최저: %{base}<br>최대: %{customdata}</b><extra></extra>",
          customdata = ~최대심박수_bpm,
          showlegend = FALSE
        ) %>%
        # 평균 심박수 포인트 추가
        add_markers(
          x = ~seq_along(평균심박수_bpm),
          y = ~평균심박수_bpm,
          name = '평균심박수',
          marker = list(symbol = 'heart', color = 'rgba(255, 255, 255, 1)', size = 10),
          hovertemplate = "<b>평균: %{y}</b><extra></extra>",
          showlegend = FALSE
        ) %>%
        layout(
          barmode = 'overlay',
          yaxis = list(title = "", showgrid = FALSE),
          xaxis = list(title = "", showgrid = FALSE, showticklabels = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',  # 배경 색상 투명
          margin = list(l = 5, r = 5, t = 8, b = 5)  # 여백 설정
        ) %>%
        config(displayModeBar = FALSE)  # 모드바 숨김
    })
    
    
    output$plot10 <-  renderPlotly({
      plot_ly(graph_DB3) %>%
        add_lines(
          x = ~seq_along(운동시간_분),
          y = ~운동시간_분,
          name = '운동시간',
          line = list(color = 'rgba(0, 128, 0, 0.8)'),  # 선을 일반 선으로 설정
          marker = list(color = 'rgba(0, 128, 0, 1)'),
          hovertemplate = "<b>운동시간: %{y}분</b><extra></extra>",
          showlegend = TRUE
        ) %>%
        layout(
          yaxis = list(title = "", showgrid = FALSE, range = c(0, max(graph_DB3$운동시간_분, na.rm = TRUE) * 1.1)),
          xaxis = list(title = "", showgrid = FALSE, showticklabels = FALSE),
          plot_bgcolor = 'rgba(0,0,0,0)',  # 배경 색상 투명
          legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.1, font = list(size = 10)),
          margin = list(l = 5, r = 5, t = 8, b = 40)  # 여백 설정
        ) %>%
        config(displayModeBar = FALSE)  # 모드바 숨김
    })
    
  })
  
  
  observeEvent(input$data_select_cells_selected, {
 
    selected <- input$data_select_cells_selected
    if (!is.null(selected) && nrow(selected) > 0) {
      row_index <- selected[1, 1]   # R 인덱스는 1부터 시작하므로 +1
      column_index <- selected[1, 2]   # R 인덱스는 1부터 시작하므로 +1
      selected_value <- selecting[row_index, column_index+1]  # 인덱스 조정
      DB_selected(selected_value)
    }  else {
      # 선택된 셀이 없을 때 첫 번째 셀을 선택하도록 강제
      proxy <- dataTableProxy("data_select")
      selectCells(proxy, list(c(1, 0)))
    }
    
    observeEvent(selected_year(), {
      if (DB_selected() == "질병") {
        temp1 <- Origin_DB %>%
          select(날짜, 질병)
      } else if (DB_selected() == "MY") {
        temp1 <- Origin_DB %>%
          select(날짜, MY)
      }
      output$df_7_text <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0(""
            ))) })
      output$df_8_text <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0(""
            ))) })
      output$df_8_date <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0(""
            ))) })
      # print(temp1)
      temp1 <- Origin_DB %>%
        select(날짜, 선택된_열 = all_of(DB_selected())) %>%
        rename(headme = 선택된_열)
      # print(temp1)
      
      target_DB <- temp1 %>% 
        filter(grepl(as.character(selected_year()), 날짜))
      
      if (nrow(target_DB) == 0) {
        output$data_table <- renderDT({
          NULL
        })
        output$outline <- renderUI({
          div(style = 'padding:10px;',
              HTML("No Data"))
        })
      } else {
        target_DB <- target_DB %>% 
          filter(!is.na(headme)) %>% 
          select(날짜, headme)
        
        target_DB$new_date <- str_remove_all(target_DB$날짜, paste0(selected_year(), "-"))
        target_DB$new_date <- paste0('<span id="month_bef">', target_DB$new_date)
        target_DB$new_date <- str_replace_all(target_DB$new_date, "-", '</span><br><span id="day">')
        target_DB$new_date <- paste0(target_DB$new_date ,'</span>')
        
        target_DB <- target_DB %>% 
          select(new_date, headme,날짜)
        
        out_target_DB <<- target_DB
        
        output$data_table <- renderDT({
          datatable(out_target_DB, 
                    class = list(stripe = FALSE),
                    options = list(
                      headerCallback = JS(
                        "function(thead, data, start, end, display){",
                        "  $(thead).remove();",
                        "  $('table.dataTable.no-footer').css('border-bottom', 'none');",
                        "}"),
                      dom = 't',
                      paging = FALSE,
                      info = FALSE,
                      columnDefs = list(
                        list(className = 'dt-center', targets = 0),
                        list(className = 'dt-left', targets = 1),
                        list(visible = FALSE, targets = 2))
                    ),
                    selection = 'single',
                    rownames = FALSE,
                    escape = FALSE  
          ) 
        })
        
        output$outline <- renderUI({
          div(style = 'padding:10px;',
              HTML(""))
        })
      }
    })
  })
  
  
  
  
  observeEvent(input$input_var_name, {
    # Update the reactive value when a new year is selected
    new_year <- format(as.Date(input$input_var_name), "%Y")
    selected_year(new_year)
    print(selected_year()) 
  })
  
  proxy <- dataTableProxy('data_table')
  
  observe({
    # 초기 로드시 오늘 날짜를 기준으로 데이터 설정
    if (initial()) {
      week_before_date <- today_date - 6
      target_DB2 <- Origin_DB %>%
        filter(날짜 >= week_before_date & 날짜 <= today_date)
      # print(target_DB2)

       output$timeline <- renderUI({
            div(style = 'margin-top:-15px; padding:10px;',
                HTML(paste0('<span class="entity" style="font-weight:800; font-size:1.2em;" >',
                            str_replace_all(week_before_date,"-",'/'), " - ", str_replace_all(today_date,"-",'/'),'</span>')))
          })
        target_me_date<<- today_date
       
          df_1<- create_item_df(target_DB2, "체중")
          df_1$values<-as.numeric(df_1$values)
          filtered_values1 <- df_1$values[df_1$values != 0]
          last_value1 <- tail(filtered_values1, 1)
          df_1_out <<- last_value1

          output$df_1_text <- renderUI({
            div(style = 'padding:5px;',
                HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',df_1_out,'</span> <span style="font-size:0.9em;">kg</span>')))
          })
          df_2<- create_item_df(target_DB2, "열량_kcal")
          df_2$values<-as.numeric(df_2$values)

          filtered_values2 <- df_2$values[df_2$values != 0]
          df_2_out <<- round(mean(filtered_values2),0)
          formatted_df_2_out <- format_with_comma(df_2_out)

          output$df_2_text <- renderUI({
            div(style = 'padding:5px;',
                HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',formatted_df_2_out,'</span> <span style="font-size:0.9em;">kcal</span>')))
          })

          df_3<- create_item_df(target_DB2, "수면_분")
          df_3$values<-as.numeric(df_3$values)
          filtered_values3 <- df_3$values[df_3$values != 0]
          df_3_out <<- round(mean(filtered_values3),0)
          # print(df_3_out)
          hhmm_format3 <- convert_minutes_to_hhmm(df_3_out)
          time_parts3 <- strsplit(hhmm_format3, ":")[[1]]
          hours3 <- as.numeric(time_parts3[1])
          minutes3 <- as.numeric(time_parts3[2])

          output$df_3_text <- renderUI({
            div(style = 'padding:5px;',
                HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',hours3,
                            '</span><span style="font-size:0.9em;">시간</span>&nbsp;',
                            '<span style="font-size:1.6em; font-weight:800;">',minutes3,
                            '</span><span style="font-size:0.9em;">분</span>'
                )))
          })

          df_4<- create_item_df(target_DB2, "영양제_알")
          df_4$values<-as.numeric(df_4$values)
          filtered_values4 <- df_4$values[df_4$values != 0]
          last_value4 <- tail(filtered_values4, 1)
          df_4_out <<- last_value4

          output$df_4_text <- renderUI({
            div(style = 'padding:5px;',
                HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',df_4_out,'</span> <span style="font-size:0.9em;">알</span>')))
          })

          df_5<- create_item_df(target_DB2, "걸음수_걸음")
          df_5$values<-as.numeric(df_5$values)

          filtered_values5 <- df_5$values[df_5$values != 0]
          df_5_out <<- round(mean(filtered_values5),0)
          formatted_df_5_out <- format_with_comma(df_5_out)

          output$df_5_text <- renderUI({
            div(style = 'padding:5px;',
                HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',formatted_df_5_out,'</span> <span style="font-size:0.9em;">걸음</span>')))
          })

          df_6<- create_item_df(target_DB2, "운동시간_분")
          df_6$values<-as.numeric(df_6$values)

          filtered_values6 <- df_6$values[df_6$values != 0]
          df_6_out <<- round(mean(filtered_values6),0)
          # print(df_3_out)
          hhmm_format6 <- convert_minutes_to_hhmm(df_6_out)
          time_parts6 <- strsplit(hhmm_format6, ":")[[1]]
          hours6 <- as.numeric(time_parts6[1])
          minutes6 <- as.numeric(time_parts6[2])

          output$df_6_text <- renderUI({
            div(style = 'padding:5px;',
                HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',hours6,
                            '</span><span style="font-size:0.9em;">시간</span>&nbsp;',
                            '<span style="font-size:1.6em; font-weight:800;">',minutes6,
                            '</span><span style="font-size:0.9em;">분</span>'
                )))
          })

          # print(target_DB2[target_DB2$날짜 == today_date,]$처방정보)
          if(is.na(target_DB2[target_DB2$날짜 == today_date,]$처방정보)){
            output$df_7_text <- renderUI({
              div(style = 'padding:5px;',
                  HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.1em; ">
                                No data </span>
                              '
                  )))
            })
          }
          output$plot1 <- renderPlotly({
            createCustomPlotly(df_1, "index", "values", 'rgba(217,217,217,0.8)', df1_cor)
          })
          output$plot2 <- renderPlotly({
            createCustomPlotly(df_2, "index", "values", 'rgba(217,217,217,0.8)', df2_cor)
          })
          output$plot3 <- renderPlotly({
            createCustomPlotly(df_3, "index", "values", 'rgba(217,217,217,0.8)', df3_cor)
          })
          output$plot4 <- renderPlotly({
            createCustomPlotly(df_4, "index", "values", 'rgba(217,217,217,0.8)', df4_cor)
          })
          output$plot5 <- renderPlotly({
            createCustomPlotly(df_5, "index", "values", 'rgba(217,217,217,0.8)', df5_cor)
          })
          output$plot6 <- renderPlotly({
            createCustomPlotly(df_6, "index", "values", 'rgba(217,217,217,0.8)', df6_cor)
          })
          
          initial(FALSE)
          }

        })
  
  
  
  
  observeEvent(input$data_table_rows_selected, {
    proxy2 <- dataTableProxy("data_select2")
    selectCells(proxy2, list(c(1, 1)))
    selectCells(proxy2, list(c(1, 0)))
    
    selected_row <- input$data_table_rows_selected

    if (length(selected_row) > 0) {
      out_target_DB[selected_row, ]$new_date <- str_replace_all(out_target_DB[selected_row, ]$new_date, "month_bef", "month_aft")
      target_date <<- as.Date(out_target_DB[selected_row, ]$날짜)
    } else {
      out_target_DB <- out_target_DB %>%
        mutate(new_date = str_replace_all(new_date, "month_aft", "month_bef"))
      target_date <<- as.Date(DBtime1)
    }
    # print(ㄲtarget_date)
    replaceData(proxy, out_target_DB, resetPaging = FALSE, rownames = FALSE)


    out_target_DB_date <<- Origin_DB %>%
                  mutate(날짜 = as_date(날짜))
    week_before_date <- target_date - 6
    target_me_date<<- target_date
    
    # 일주일 전 날짜가 out_target_DB_date의 날짜 열에 존재하는 행을 target_DB2로 선택
    target_DB2 <- out_target_DB_date %>%
      filter(날짜 >= week_before_date & 날짜 <= target_date)


    output$timeline <- renderUI({
      div(style = 'margin-top:-15px; padding:10px;',
          HTML(paste0('<span class="entity" style="font-weight:800; font-size:1.2em;" >',
                      str_replace_all(week_before_date,"-",'/'), " - ", str_replace_all(target_date,"-",'/'),'</span>')))
    })

    df_1<- create_item_df(target_DB2, "체중")
    df_1$values<-as.numeric(df_1$values)
    filtered_values1 <- df_1$values[df_1$values != 0]
    last_value1 <- tail(filtered_values1, 1)
    df_1_out <<- last_value1

    output$df_1_text <- renderUI({
      div(style = 'padding:5px;',
          HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',df_1_out,'</span> <span style="font-size:0.9em;">kg</span>')))
    })
    df_2<- create_item_df(target_DB2, "열량_kcal")
    df_2$values<-as.numeric(df_2$values)

    filtered_values2 <- df_2$values[df_2$values != 0]
    df_2_out <<- round(mean(filtered_values2),0)
    formatted_df_2_out <- format_with_comma(df_2_out)

    output$df_2_text <- renderUI({
      div(style = 'padding:5px;',
          HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',formatted_df_2_out,'</span> <span style="font-size:0.9em;">kcal</span>')))
    })

    df_3<- create_item_df(target_DB2, "수면_분")
    df_3$values<-as.numeric(df_3$values)
    filtered_values3 <- df_3$values[df_3$values != 0]
    df_3_out <<- round(mean(filtered_values3),0)
    # print(df_3_out)
    hhmm_format3 <- convert_minutes_to_hhmm(df_3_out)
    time_parts3 <- strsplit(hhmm_format3, ":")[[1]]
    hours3 <- as.numeric(time_parts3[1])
    minutes3 <- as.numeric(time_parts3[2])

    output$df_3_text <- renderUI({
      div(style = 'padding:5px;',
          HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',hours3,
          '</span><span style="font-size:0.9em;">시간</span>&nbsp;',
          '<span style="font-size:1.6em; font-weight:800;">',minutes3,
          '</span><span style="font-size:0.9em;">분</span>'
          )))
    })

    df_4<- create_item_df(target_DB2, "영양제_알")
    df_4$values<-as.numeric(df_4$values)
    filtered_values4 <- df_4$values[df_4$values != 0]
    last_value4 <- tail(filtered_values4, 1)
    df_4_out <<- last_value4

    output$df_4_text <- renderUI({
      div(style = 'padding:5px;',
          HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',df_4_out,'</span> <span style="font-size:0.9em;">알</span>')))
    })

    df_5<- create_item_df(target_DB2, "걸음수_걸음")
    df_5$values<-as.numeric(df_5$values)

    filtered_values5 <- df_5$values[df_5$values != 0]
    df_5_out <<- round(mean(filtered_values5),0)
    formatted_df_5_out <- format_with_comma(df_5_out)

    output$df_5_text <- renderUI({
      div(style = 'padding:5px;',
          HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',formatted_df_5_out,'</span> <span style="font-size:0.9em;">걸음</span>')))
    })

    df_6<- create_item_df(target_DB2, "운동시간_분")
    df_6$values<-as.numeric(df_6$values)

    filtered_values6 <- df_6$values[df_6$values != 0]
    df_6_out <<- round(mean(filtered_values6),0)
    # print(df_3_out)
    hhmm_format6 <- convert_minutes_to_hhmm(df_6_out)
    time_parts6 <- strsplit(hhmm_format6, ":")[[1]]
    hours6 <- as.numeric(time_parts6[1])
    minutes6 <- as.numeric(time_parts6[2])

    output$df_6_text <- renderUI({
      div(style = 'padding:5px;',
          HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.6em; font-weight:800;">',hours6,
                      '</span><span style="font-size:0.9em;">시간</span>&nbsp;',
                      '<span style="font-size:1.6em; font-weight:800;">',minutes6,
                      '</span><span style="font-size:0.9em;">분</span>'
          )))
    })

    # print(target_DB2[target_DB2$날짜 == target_date,]$처방정보)
    if(is.na(target_DB2[target_DB2$날짜 == target_date,]$처방정보)){
      output$df_7_text <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.1em; ">
                                No data </span>
                              '
            )))
      })
      sick_name <- target_DB2[target_DB2$날짜 == target_date,]$질병
      previous_db <-Origin_DB[which(grepl(sick_name,Origin_DB$질병)),]
      previous_db <-previous_db[order(previous_db$날짜),]
      previous_db <- previous_db[previous_db$날짜 < target_date,]
      previous_db <- previous_db[previous_db$날짜 != target_date,]
      last_row <- tail(previous_db, 1)
      # print(last_row)
      if (nrow(last_row) > 0) {
        parsed_data2<- fromJSON(last_row$처방정보)
        parsed_data2 <- parsed_data2[order(parsed_data2$medication_type),]
        # print(parsed_data2) 
        
        # 
        for(j in 1:length(parsed_data2$medication_name)){
          if (j ==1){
            temp_out2 <- paste0('<div style="line-height:1.2 !important"><span style="font-size:1.1em;font-weight:800; ">',parsed_data2$medication_name[j],'</span><br>
                          <span style="font-size:0.9em; ">',parsed_data2$medication_type[j],'</span><br>
                          <span style="font-size:0.9em; ">  총 ',parsed_data2$medication_duration[j] ,'일</span>
                           <span style="font-size:0.9em; ">  ',parsed_data2$medication_period[j] ,'일에</span>
                               <span style="font-size:0.9em; ">  ',parsed_data2$medication_freqeuncy[j]  ,'번</span><br><br>')
          }else{
            temp_in2 <- paste0('<span style="font-size:1.1em;font-weight:800; ">',parsed_data2$medication_name[j],'</span><br>
                          <span style="font-size:0.9em; ">',parsed_data2$medication_type[j],'</span><br>
                          <span style="font-size:0.9em; ">  총 ',parsed_data2$medication_duration[j] ,'일</span>
                           <span style="font-size:0.9em; ">  ',parsed_data2$medication_period[j] ,'일에</span>
                               <span style="font-size:0.9em; ">  ',parsed_data2$medication_freqeuncy[j]  ,'번</span><br><br>')
            temp_out2 <- paste0(temp_out2,temp_in2)
          }
        }
        temp_out2 <- paste0(temp_out2, "</div>")
        
        
        output$df_8_text <- renderUI({
          div(style = 'padding:5px;',
              HTML(paste0(temp_out2
              )))
        })
        
        output$df_8_date <- renderUI({
          div(style = 'padding:5px;',
              HTML(paste0('<span style="font-size:0.9em; ">',last_row$날짜,'</span>')
              )) })
      }else{
      output$df_8_text <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0('<span style="font-size:0.9em;"></span><span style="font-size:1.1em; ">
                                </span>
                              '
            )))
      })
      }
    }else{
      sick_name <- target_DB2[target_DB2$날짜 == target_date,]$질병
      previous_db <-Origin_DB[which(grepl(sick_name,Origin_DB$질병)),]
      previous_db <-previous_db[order(previous_db$날짜),]
      previous_db <- previous_db[previous_db$날짜 < target_date,]
      previous_db <- previous_db[previous_db$날짜 != target_date,]
     
      last_row <- tail(previous_db, 1)
      # print(last_row)
      if (nrow(last_row) > 0) {
          parsed_data2<- fromJSON(last_row$처방정보)
          parsed_data2 <- parsed_data2[order(parsed_data2$medication_type),]
          # print(parsed_data2) 
          
      # 
      for(j in 1:length(parsed_data2$medication_name)){
        if (j ==1){
          temp_out2 <- paste0('<div style="line-height:1.2 !important"><span style="font-size:1.1em;font-weight:800; ">',parsed_data2$medication_name[j],'</span><br>
                          <span style="font-size:0.9em; ">',parsed_data2$medication_type[j],'</span><br>
                          <span style="font-size:0.9em; ">  총 ',parsed_data2$medication_duration[j] ,'일</span>
                           <span style="font-size:0.9em; ">  ',parsed_data2$medication_period[j] ,'일에</span>
                               <span style="font-size:0.9em; ">  ',parsed_data2$medication_freqeuncy[j]  ,'번</span><br><br>')
        }else{
          temp_in2 <- paste0('<span style="font-size:1.1em;font-weight:800; ">',parsed_data2$medication_name[j],'</span><br>
                          <span style="font-size:0.9em; ">',parsed_data2$medication_type[j],'</span><br>
                          <span style="font-size:0.9em; ">  총 ',parsed_data2$medication_duration[j] ,'일</span>
                           <span style="font-size:0.9em; ">  ',parsed_data2$medication_period[j] ,'일에</span>
                               <span style="font-size:0.9em; ">  ',parsed_data2$medication_freqeuncy[j]  ,'번</span><br><br>')
          temp_out2 <- paste0(temp_out2,temp_in2)
        }
      }
          temp_out2 <- paste0(temp_out2, "</div>")
      
      
      output$df_8_text <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0(temp_out2
            )))
      })
      
      output$df_8_date <- renderUI({
        div(style = 'padding:5px;',
            HTML(paste0('<span style="font-size:0.9em; ">',last_row$날짜,'</span>')
            )) })
      
      }else{
        output$df_8_text <- renderUI({
          div(style = 'padding:5px;',
              HTML(paste0(""
              ))) })
      }
  
        parsed_data <- fromJSON(target_DB2[target_DB2$날짜 == target_date,]$처방정보)
        parsed_data <- parsed_data[order(parsed_data$medication_type),]
   
        
        for(j in 1:length(parsed_data$medication_name)){
          if (j ==1){
          temp_out <- paste0('<div style="line-height:1.2 !important"><span style="font-size:1.1em;font-weight:800; ">',parsed_data$medication_name[j],'</span><br>
                            <span style="font-size:0.9em; ">',parsed_data$medication_type[j],'</span><br>
                            <span style="font-size:0.9em; ">  총 ',parsed_data$medication_duration[j] ,'일</span>
                             <span style="font-size:0.9em; ">  ',parsed_data$medication_period[j] ,'일에</span>
                                 <span style="font-size:0.9em; ">  ',parsed_data$medication_freqeuncy[j]  ,'번</span><br><br>')
          }else{
            temp_in <- paste0('<span style="font-size:1.1em;font-weight:800; ">',parsed_data$medication_name[j],'</span><br>
                            <span style="font-size:0.9em; ">',parsed_data$medication_type[j],'</span><br>
                            <span style="font-size:0.9em; ">  총 ',parsed_data$medication_duration[j] ,'일</span>
                             <span style="font-size:0.9em; ">  ',parsed_data$medication_period[j] ,'일에</span>
                                 <span style="font-size:0.9em; ">  ',parsed_data$medication_freqeuncy[j]  ,'번</span><br><br>')
            temp_out <- paste0(temp_out,temp_in)
          }
        }
        temp_out <- paste0(temp_out, "</div>")
     
          
        output$df_7_text <- renderUI({
          div(style = 'padding:5px;',
              HTML(paste0(temp_out
              )))
        })
     
      
    }
    
    # print(df_1)
    output$plot1 <- renderPlotly({
      createCustomPlotly(df_1, "index", "values", 'rgba(217,217,217,0.8)', df1_cor)
    })
    output$plot2 <- renderPlotly({
      createCustomPlotly(df_2, "index", "values", 'rgba(217,217,217,0.8)', df2_cor)
    })
    output$plot3 <- renderPlotly({
      createCustomPlotly(df_3, "index", "values", 'rgba(217,217,217,0.8)', df3_cor)
    })
    output$plot4 <- renderPlotly({
      createCustomPlotly(df_4, "index", "values", 'rgba(217,217,217,0.8)', df4_cor)
    })
    output$plot5 <- renderPlotly({
      createCustomPlotly(df_5, "index", "values", 'rgba(217,217,217,0.8)', df5_cor)
    })
    output$plot6 <- renderPlotly({
      createCustomPlotly(df_6, "index", "values", 'rgba(217,217,217,0.8)', df6_cor)
    })
    
  })
  
  
  
  
  
}


shinyApp(ui, server)

