library(shiny)
library(jsonlite)
library(dplyr)
library(DT)
library(googlesheets4)

ui <- fluidPage(
  titlePanel("JSON 파일 업로드 및 데이터 처리"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "JSON 파일 선택", accept = ".json"),
      actionButton("upload", "업로드 및 처리"),
      actionButton("writeSheet", "Google Sheets에 저장")
    ),
    mainPanel(
      DTOutput("dataTable")
    )
  )
)

server <- function(input, output) {
  df_out_final <-NULL
  observeEvent(input$upload, {
    req(input$file)
    
    # 파일 읽기
    json_data <- fromJSON(input$file$datapath)
    med_data <- json_data$entry$resource$entry[[1]]$resource
    med_data <-json_data$entry$resource$entry[[1]]$resource
    
    med_data$medication_name <-''
    med_data$medication_duration <- ''
    med_data$medication_frequency <- ''
    med_data$medication_period <-''
    med_data$reference_id<-''
    
    # 데이터 처리
    # 이 부분은 입력 파일 구조에 따라 조정해야 할 수 있습니다.
    med_data <- med_data %>%
      mutate(medication_name = ifelse(!is.null(code$text), code$text, NA),
             medication_frequency = ifelse(!is.null(dosageInstruction[[1]]$timing$`repeat`$frequency), dosageInstruction[[1]]$timing$`repeat`$frequency, NA),
             medication_period = ifelse(!is.null(dosageInstruction[[1]]$timing$`repeat`$period), dosageInstruction[[1]]$timing$`repeat`$period, NA),
             medication_duration = ifelse(!is.null(daysSupply$value), daysSupply$value, NA),
             reference_id = gsub("Medication/", "", medicationReference$reference)
      )
    
    # 데이터프레임 생성
    med_data1 <- med_data %>%
      select(reference_id, whenPrepared, medication_period, medication_frequency, medication_duration, medication_name, resourceType, id)
    
    
    all_grouped_data <- med_data1 %>% 
      group_by(resourceType) %>%
      group_split()
    
    all_grouped_data <- lapply(all_grouped_data, function(df) {
      if ("Medication" %in% df$resourceType) {
        df <- df %>%
          filter(resourceType == "Medication") %>%
          select(medication_name, id)
      } else {
        df <- df %>%
          select(medication_period, medication_frequency, medication_duration, reference_id , whenPrepared) %>% 
          rename(id = reference_id)
      }
      return(df)
    })
    # 첫 번째와 두 번째 데이터 프레임을 id를 기준으로 병합
    merged_data <- full_join(all_grouped_data[[1]], all_grouped_data[[2]], by = "id")
    
    date_group <- unique(merged_data$whenPrepared)
    date_group
    df_out <-''
    df_out <- data.frame(
      date_group = date_group
    )
    df_out$json <-''
    for(j in 1:length(date_group)){
      
      temp <- merged_data[merged_data$whenPrepared == date_group[j],]
      temp <- temp %>%
        mutate(medication_type = "")
      temp <- temp %>% 
        select(medication_name,medication_type,medication_period,medication_frequency ,medication_duration )
      df_out$json[j] <- toJSON(temp)
      
    }

    df_out <<- df_out %>%
      rename(
        날짜 = date_group,
        처방정보 = json
      )
    df_out_final<<-df_out

    output$dataTable <- renderDT({
      datatable(df_out_final)
    })
  })
  
  observeEvent(input$writeSheet, {
    # Google Sheets에 데이터 저장
    req(df_out_final)
    gs4_auth(email = "fhirboot@gmail.com")  # 실제 Google 계정 이메일로 변경 필요
    sheet <- sheet_write(data = df_out_final, ss = "https://docs.google.com/spreadsheets/d/1apgtDqJ9fpKt9HHNi8ZnzcrB0JuVWvZPq-G_C4oMxXg/edit?gid=862145515#gid=862145515", sheet = "Sheet2")  # 스프레드시트 ID와 시트 이름 지정 필요
  })
}

shinyApp(ui, server)
