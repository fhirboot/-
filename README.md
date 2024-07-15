<!--타이틀 부분-->
### 나니아 연대기
---
<img src="https://github.com/user-attachments/assets/2902f545-5416-4f83-9740-f677609ad756" />

<br>

### 앱 설명
---

나니아 연대기는 질병 발생 타임라인에 맞춰 나의 건강상태 추이를 확인할 수 있는 어플리케이션입니다.

본 앱은 2024.7.10~2024.7.12 에 실시된 FHIR 활용 부트캠프롤 통해 설계하였습니다.

**사용프로그램**<br>
R (4.3.0) + R shiny<br>
<br>
**data import (입력)** <br>
 : 데이터의 입력은 간편하게 이뤄질 수 있도록 **Google sheet를 통해 입력**을 받을 수 있도록 함 <br>
 : "나의건강기록"앱을 통해 **다운로드받은 나의투약기록(FHIR JSON)을 Google sheet형태로 변경**할 수 있는 앱을 개발함 : Excel_up <br>
 : Excel_up 폴더의 파일을 다운로드후 필요한 R library 설치 -> 이후 자신의 JSON 업로드후 변환 -> 나니아 연대기앱에 포맷과 같은 값이 google sheet에 생성 ("Sheet2")<br>
<br>
**test data (최종 테스트 데이터)** <br>
: https://docs.google.com/spreadsheets/d/1apgtDqJ9fpKt9HHNi8ZnzcrB0JuVWvZPq-G_C4oMxXg/edit?gid=0#gid=0<br>
<br>
**나니아 연대기 앱**<br>
: 본 폴더의** app과 css를 이용하여 본인의 환경에서도 구동가능** ( 자신의 google sheet 주소로 변경하고, 데이터 변수명을 맞추면 자신의 데이터로도 사용)<br>
<br>
**data output (출력)**<br>
: 본 앱을 통해 생성된 연대기별 데이터는 **excel 형태나  FHIR 서버로 전송**할 수 있도록 작업됨<br>
: FHIR로 전송은 **Python으로 작성되여, 본인의 PC에 설치된 python이 있어야만 작동**됨. <br>
: FHIR의 destination은 python 코드를 수정하여 사용해야함<br>
: FHIR의 IG의 경우, PGHD를 표현하기 위해 step.snu.ac.kr을 참조하여 작성함<br>
<br>
**최종 파일**<br>
: Excel_up (디렉토리): 나의건강기록 나의투약기록 FHIR JSON을 입력받아 변경하여 구글 시트에 뿌려줌<br>
: app.R : 나니아 연대기를 실행시키는 파일<br>

<br>
<br>

