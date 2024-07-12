import pandas as pd
import os
import json
from datetime import datetime

import requests
#파일이동으로 인한 경로문제 해결
os.chdir(os.path.dirname(__file__))

file_list=os.listdir('./profile')

data={}
for i in file_list:
    with open('./profile/'+i,'r',encoding='utf-8') as f:
        tmp=json.load(f)
        data[i[:-5]]=tmp
database=pd.read_excel('./check.xlsx')
database=database.fillna('!!!')
database=database.astype(str)
database['날짜']=database['날짜'].apply(lambda x: x[:10])
medi_data=pd.read_excel('./약품.xlsx')
durg_data=medi_data.set_index('약품종류').to_dict(orient='dict')
bundle_list=[]
idx=data
import copy
for i in database.index:
    root=database.loc[i]
    tmp_source=copy.deepcopy(data)
    if root['질병'] !='!!!':
        tmp_source['contion']['code']['text']=root['질병']
        tmp_source['contion']['onsetDateTime']=root['날짜']
        if root['MY']!='!!!':
            tmp_source['contion']['note']=[{'text':root['MY']}]
        bundle_list.append(tmp_source['contion'])
    tmp_source['운동 observation']['component'][0]['valueQuantity']['value']=root['운동시간_분']
    tmp_source['운동 observation']['component'][1]['valueQuantity']['value']=root['소모열량_kcal']
    tmp_source['운동 observation']['component'][2]['valueQuantity']['value']=root['평균심박수_bpm']
    tmp_source['운동 observation']['component'][3]['valueQuantity']['value']=root['걸음수_걸음']
    tmp_source['운동 observation']["effectiveDateTime"]=root['날짜']
    tmp_source['운동 observation']['component'][2]['valueQuantity']['extension'][0]['valueString']=root['최대심박수_bpm']
    tmp_source['운동 observation']['component'][2]['valueQuantity']['extension'][1]['valueString']=root['최저심박수_bpm']
    tmp_source['운동 observation']['component'][2]['valueQuantity']['extension'][2]['valueString']=root['평균심박수_bpm']    
    tmp_source['운동 observation']['component'][2]['valueQuantity']['extension']= [
        item for item in tmp_source['운동 observation']['component'][2]['valueQuantity']['extension']
        if item['valueString'] != '!!!'
    ]
    tmp_source['운동 observation']['component'] = [
        item for item in tmp_source['운동 observation']['component']
        if item['valueQuantity']['value'] != '!!!'
    ]
    if root['MY']!='!!!':
        tmp_source['운동 observation']['note']=[{'text':root['MY']}]
    if (root['소모열량_kcal']!='!!!')or(root['운동시간_분'] !='!!!')or(root['평균심박수_bpm']!='!!!')or(root['걸음수_걸음']!='!!!'):
        bundle_list.append(tmp_source['운동 observation'])
    
    tmp_source['nutrition']["occurrenceDateTime"]=root['날짜']
    tmp_source['nutrition']['component'][0]['valueQuantity']['value']=root['열량_kcal']
    tmp_source['nutrition']['component'][1]['valueQuantity']['value']=root['탄수화물_g']
    tmp_source['nutrition']['component'][2]['valueQuantity']['value']=root['단백질_g']
    tmp_source['nutrition']['component'][3]['valueQuantity']['value']=root['지방_g']
    tmp_source['nutrition']['component'] = [
        item for item in tmp_source['nutrition']['component']
        if item['valueQuantity']['value'] != '!!!'
    ]
    if root['MY']!='!!!':
        tmp_source['nutrition']['note']=[{'text':root['MY']}]
    if (root['열량_kcal']!='!!!')or(['탄수화물_g']!='!!!') or(root['단백질_g']!='!!!'):
        bundle_list.append(tmp_source['nutrition'])
    

    if root['수면_분'] !='!!!':
        tmp_source['수면 observation']['valueQuantity']['value']=root['수면_분']
        if root['MY']!='!!!':
            tmp_source['수면 observation']['note']=[{'text':root['MY']}]
            tmp_source['수면 observation']["effectiveDateTime"]=root['날짜']
        bundle_list.append(tmp_source['수면 observation'])
    
    if root['영양제_알'] !='!!!':
        tmp_source['영양제MedicationRequest']['dosage']['rateQuantity']=root['영양제_알']
        tmp_source['영양제MedicationRequest']["occurrenceDateTime"]=root['날짜']
        if root['MY']!='!!!':
            tmp_source['영양제MedicationRequest']['note']=[{'text':root['MY']}]
        bundle_list.append(tmp_source['영양제MedicationRequest'])
    if root['처방정보']!='!!!':
        medication=json.loads(root['처방정보'])
        for medi in medication:
            print(medi.keys())
            tmp_source['약품 prescription']["authoredOn"]=root['날짜']
            tmp_source['약품 prescription']['medicationCodeableConcept']['text']=medi['medication_name']
            try:
                tmp_source['약품 prescription']['medicationCodeableConcept']['coding'][0]['code']=durg_data['code'][medi['medication_type']]
                tmp_source['약품 prescription']['medicationCodeableConcept']['coding'][0]['display']=durg_data['display'][medi['medication_type']]
            except:
                continue
            tmp_source['약품 prescription']["dosageInstruction"][0]['timing']['repeat']['duraion']=medi['medication_duration']
            tmp_source['약품 prescription']["dosageInstruction"][0]['timing']['repeat']['frequency']=medi['medication_freqeuncy']
            tmp_source['약품 prescription']["dosageInstruction"][0]['timing']['repeat']['period']=medi['medication_period']
            bundle_list.append(tmp_source['약품 prescription'])
    if root['처방정보']=='!!!':
        print('약품정보')

id=0
method='POST'
url='http://step.snu.ac.kr:8089/fhir'
def list_spliter(bundle):
    split_number=len(bundle)//10
    k=0
    split_list=[]
    for i in range(0,split_number):
        if len(bundle)-k>=10:
            split_list.append(bundle[k:k+10])
        else:
            split_list.append(bundle[k:])
    return split_list
split_list=list_spliter(bundle_list)
n_i=0
with open('./profile/patient.json','r',encoding='utf-8-sig') as f:
    patient=json.load(f)
for bun_li in split_list:
    bundle={'resourceType':"Bundle",'type':"transaction"}
    patient_entry={'fullurl':'https://fhir-bootcamp.shinyapps.io/Narnia/patient1','resource':patient, 'request':{'method':method,'request':'Patient'}}
    entry=[patient_entry]
    for i in bun_li:
        tmp={}
        id+=1
        tmp['fullurl']='https://fhir-bootcamp.shinyapps.io/Narnia/'+str(id)
        tmp['resource']=i,
        tmp['request']={'method':method,'request':i['resourceType']}
        entry.append(tmp)
    bundle['entry']=entry
    headers = {'Content-Type': 'application/fhir+json'}
    res=requests.post('	http://hapi.fhir.org/baseR4', headers=headers, json=bundle)
    print(f'그냥 전송 결과는 \n{res}')
    with open('./bundle/fhir_bundle_nanaia'+str(n_i)+'.json','w',encoding='utf-8') as f:
        json.dump(bundle,f, default=str, ensure_ascii=False, indent=4)
    os.chdir(os.path.dirname(__file__))
    with open('./bundle/fhir_bundle_nanaia result'+str(n_i)+'.txt','w',encoding='utf-8') as f:
        f.write(str(res))
    n_i+=1
