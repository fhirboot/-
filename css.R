style_tag1 <- tags$style(HTML('
  @import url("https://fonts.googleapis.com/css2?family=Poppins:wght@200;300;400;500;600;700;800;900&display=swap");
  @import url("https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@100..900&display=swap");
  
  .myicon::before {
   display: inline-block;
  line-height: 1;
  vertical-align: -.125em;
  content: url(./myicon.svg);
  width: 20px;  /* 아이콘의 너비 설정 */
  height: 20px; /* 아이콘의 높이 설정 */
  }

 #month_bef {
  font-size:1.5em;
  color:rgba(11,108,255,1);
  font-weight:600;
  
  }
  #month_aft {
  font-size:1.5em;
  color:rgba(255,157,11,1);
  font-weight:600;
  
  }  

   #day {
  font-size:1em;
  color:gray;
   }   
   #data_table tbody tr {
        background-color: #FFFFFF !important;
   }
  body { 
  background-color: #F5F5F5; 
  }    
 #outline{
 width:100%;
 }
 
  #outline{
 width:100%;
  }
  
  #data_select2 {
   font-size: 1.1em; !important;
   width: 100%;
   text-align: center !important;
   font-weight:600;
    background-color: #F5F5F5; 
   border-radius: 10px;
   font-family: Noto Sans KR; /* 폰트 패밀리의 백업 추가 권장 */
 }
#data_select2 td {
   border-radius: 10px; /* 셀 모서리를 둥글게 */
   padding: 8px; /* 셀 안의 내용과 모서리 사이의 공간 */
     background-color: #FFFFFF; 
   border: 1px solid #ccc; /* 셀 주위에 경계선 추가 */
   
}

 #data_table {
   font-size: 100% !important;
   width: 100%;
   font-family: Noto Sans KR; /* 폰트 패밀리의 백업 추가 권장 */
}
 #data_select {
   font-size: 1.2em; !important;
   width: 100%;
   text-align: center !important;
   font-weight:600;
    background-color: #F5F5F5; 
   border-radius: 10px;
   font-family: Noto Sans KR; /* 폰트 패밀리의 백업 추가 권장 */
 }
#data_select td {
   border-radius: 10px; /* 셀 모서리를 둥글게 */
   padding: 8px; /* 셀 안의 내용과 모서리 사이의 공간 */
     background-color: #FFFFFF; 
   border: 1px solid #ccc; /* 셀 주위에 경계선 추가 */
   
}


#data_select th, 
#data_select td {
    line-height: 1.0 !important;
    word-wrap: break-word; /* word-wrap은 더 널리 사용되는 overflow-wrap으로 대체될 수 있음 */
    text-overflow: ellipsis;
}

#data_table th, 
#data_table td {
    line-height: 1.1 !important;
    word-wrap: break-word; /* word-wrap은 더 널리 사용되는 overflow-wrap으로 대체될 수 있음 */
    text-overflow: ellipsis;
}



    
  '))
