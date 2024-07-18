### 나니아 연대기

---

<img src="https://github.com/user-attachments/assets/2902f545-5416-4f83-9740-f677609ad756" alt="Narnia Chronology" style="width:100%; height:auto;" />

<br>

### 앱 설명

---

**나니아 연대기**는 질병 발생 타임라인에 맞춰 나의 건강상태 추이를 확인할 수 있는 어플리케이션입니다. 이 앱은 2024년 7월 10일부터 12일까지 실시된 FHIR 활용 부트캠프를 통해 설계되었습니다.

#### 사용 프로그램
- **R (4.3.0)** 및 **R shiny**

#### Data Import (입력)
- 데이터 입력은 **Google Sheet**를 통해 간편하게 이루어집니다.
- "나의건강기록" 앱을 통해 **다운로드 받은 나의 투약기록(FHIR JSON)을 Google Sheet 형태로 변경**할 수 있는 앱을 개발하였습니다: **Excel_up**
- **Excel_up 폴더**의 파일을 다운로드 후 필요한 R 라이브러리를 설치한 다음, 자신의 JSON을 업로드하여 변환합니다. 이후 나니아 연대기 앱에 맞는 포맷으로 Google Sheet ("Sheet2")에 생성됩니다.

#### Test Data (최종 테스트 데이터)
- [테스트 데이터 링크](https://docs.google.com/spreadsheets/d/1apgtDqJ9fpKt9HHNi8ZnzcrB0JuVWvZPq-G_C4oMxXg/edit?gid=0#gid=0)

#### 나니아 연대기 앱
- 본 폴더의 **app과 css 파일**을 이용하여 본인의 환경에서도 구동 가능합니다. 자신의 Google Sheet 주소로 변경하고, 데이터 변수명을 맞추면 자신의 데이터로도 사용할 수 있습니다.
- [앱 링크](https://fhir-bootcamp.shinyapps.io/Narnia/)
- FHIR로 데이터를 출력(보내는 경우)하는 경우, 내부 시스템으로 돌아가야 해서 따로 Python 코드로 작동해야 합니다.

#### Data Output (출력)
- 본 앱을 통해 생성된 연대기별 데이터는 **Excel 형태**나 **FHIR 서버로 전송**할 수 있습니다.
- FHIR로 전송은 **Python**으로 작성되어 있으며, 본인의 PC에 설치된 Python이 있어야만 작동합니다. **(bundle_maker.py)**
- FHIR의 destination은 Python 코드를 수정하여 사용해야 합니다.
- FHIR의 IG의 경우, PGHD를 표현하기 위해 step.snu.ac.kr을 참조하여 작성되었습니다.

#### 최종 파일
- **Excel_up 디렉토리**: 나의 건강 기록 나의 투약 기록 FHIR JSON을 입력받아 변경하여 Google Sheet에 뿌려줍니다.
- **app.R**: 나니아 연대기를 실행시키는 파일입니다.

<br>
