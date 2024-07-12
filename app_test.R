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
library(purrr)

gs4_deauth()

gs4_auth()
# 접근할 구글 시트의 URL 또는 ID
sheet_url <- "https://docs.google.com/spreadsheets/d/1dJJVFNhmyjFkOV-zT4XlYARPNpYpL651fgHekI1Uac0/edit?gid=0#gid=0"

# 기존 구글 시트에 접근
google_me <- gs4_get(sheet_url)

json_data <- fromJSON("나의건강기록-투약이력.json")

med_data <-json_data$entry$resource$entry[[1]]$resource

med_data$medication_name <-''
med_data$medication_duration <- ''
med_data$medication_freqeuncy <- ''
med_data$medication_period <-''
med_data$reference_id<-''

for (k in 1:length(med_data$identifier)) {
  med_data$medication_name[k] <- if (!is.null(med_data$code$text[k])) {
    med_data$code$text[k]
  } else {
    NA
  }
  med_data$medication_freqeuncy[k] <- if (!is.null(med_data$dosageInstruction[[k]]$timing$`repeat`$frequency)) {
    med_data$dosageInstruction[[k]]$timing$`repeat`$frequency
  } else {
    NA
  }
  med_data$medication_period[k] <- if (!is.null(med_data$dosageInstruction[[k]]$timing$`repeat`$period)) {
    med_data$dosageInstruction[[k]]$timing$`repeat`$period
  } else {
    NA
  }
  med_data$medication_duration[k] <- if (!is.null(med_data$daysSupply$value[k])) {
    med_data$daysSupply$value[k]
  } else {
    NA
  }
}

for(m in 1:length(med_data$medication_duration)){
med_data$referece_id[m]<-str_remove_all(med_data$medicationReference$reference[m],"Medication/")
}

med_data1<-med_data %>% 
  select(referece_id,whenPrepared,medication_period,medication_freqeuncy, medication_duration,medication_name,resourceType,id )

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
      select(medication_period, medication_freqeuncy, medication_duration, referece_id , whenPrepared) %>% 
      rename(id = referece_id)
  }
  return(df)
})
# 첫 번째와 두 번째 데이터 프레임을 id를 기준으로 병합
merged_data <- full_join(all_grouped_data[[1]], all_grouped_data[[2]], by = "id")

date_group <- unique(merged_data$whenPrepared)
date_group

df_out <- data.frame(
  date_group = date_group
)
df_out$json <-''
for(j in 1:length(date_group)){
    
    temp <- merged_data[merged_data$whenPrepared == date_group[j],]
    temp <- temp %>%
      mutate(medication_type = "")
    df_out$json[j] <- toJSON(temp)
   
}
df_out
df_out <- df_out %>%
  rename(
    '날짜' = date_group,
    '처방정보' = json
  )

sheet_write(data = df_out, ss = google_me, sheet = "Sheet1")


