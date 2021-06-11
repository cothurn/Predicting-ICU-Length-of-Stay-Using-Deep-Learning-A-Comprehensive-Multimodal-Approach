import urllib.request, json
import csv
import time
import pandas as pd
from progressbar import ProgressBar
from datetime import datetime, timedelta

def firstStep(originalNDC):
  rxNormUrl = "https://rxnav.nlm.nih.gov/REST/ndcstatus.json?ndc="+originalNDC+"&history=1"
  #print(rxNormUrl)
  try:
    with urllib.request.urlopen(rxNormUrl) as url:
      data = json.loads(url.read().decode('UTF-8'))
      #print(data)
      return(data["ndcStatus"]["ndcHistory"][0]['originalRxcui'])
  except:
    return("error")

def secondStep(originalRxCui):
  rxNormUrl = "https://rxnav.nlm.nih.gov/REST/rxcui/"+ originalRxCui+"/historystatus.json"
  #print(rxNormUrl)
  if(originalRxCui == "error"):
    return('error')
  try:
    with urllib.request.urlopen(rxNormUrl) as url:
      data = json.loads(url.read().decode('UTF-8'))
      ingredientList = data['rxcuiStatusHistory']['definitionalFeatures']['ingredientAndStrength']
      returnList = []
      for i in ingredientList:
        #print(i)
        returnList.append(i['bossRxcui'])
      return returnList
  except:
    return("error")

def thirdStep(baseRxcui):
  if(baseRxcui == "error"):
    return('error')
  returnList = []
  for i in baseRxcui:
    rxNormUrl = "https://rxnav.nlm.nih.gov/REST/rxcui/"+i+"/property.json?propName=ATC"
    with urllib.request.urlopen(rxNormUrl) as url:
      data = json.loads(url.read().decode('UTF-8'))
      #print(data)
      try:
        for j in data['propConceptGroup']['propConcept']:
          returnList.append(j['propValue'][0:4])
      except:
          return("error")
  return(returnList)

def firstStepKai(originalNDC):
  rxNormUrl = "https://rxnav.nlm.nih.gov/REST/ndcstatus.json?ndc="+originalNDC+"&history=1"
  #print(rxNormUrl)
  try:
    with urllib.request.urlopen(rxNormUrl) as url:
      data = json.loads(url.read().decode('UTF-8'))
      #print(data)
      return(data["ndcStatus"]['rxcui'])
  except:
    return("error")

def secondStepKai(baseRxcui):
  if(baseRxcui == "error"):
    return('error')
  returnList = []
  for i in baseRxcui:
    rxNormUrl = "https://rxnav.nlm.nih.gov/REST/rxcui/"+i+"/historystatus.json"
    #print(rxNormUrl)
    #print(rxNormUrl)
    with urllib.request.urlopen(rxNormUrl) as url:
      data = json.loads(url.read().decode('UTF-8'))
      #print(data['rxcuiStatusHistory']['derivedConcepts']['ingredientConcept'])
      try:
        for j in data['rxcuiStatusHistory']['derivedConcepts']['ingredientConcept']:
          #print(j['ingredientRxcui'])
          returnList.append(j['ingredientRxcui'])
      except:
          return("error")
  return(returnList)

def thirdStepKai(baseRxcui):
  if(baseRxcui == "error"):
    return('error')
  returnList = []
  for i in baseRxcui:
    rxNormUrl = "https://rxnav.nlm.nih.gov/REST/rxcui/"+i+"/property.json?propName=ATC"
    with urllib.request.urlopen(rxNormUrl) as url:
      data = json.loads(url.read().decode('UTF-8'))
      #print(data)
      try:
        for j in data['propConceptGroup']['propConcept']:
          returnList.append(j['propValue'][0:4])
      except:
          try:
            derivedIngredient = secondStepKai([i])
            newVal = thirdStep(derivedIngredient)
            if(newVal != 'error'):
              returnList.extend(newVal)
            else:
              return('error')
          except:
            return('error')
  return(returnList)

with open("../../data/Processed/prescription_11digitNDC.csv", newline='') as f:
    reader = csv.reader(f)
    your_list = list(reader)
pairList = []
for i in your_list:
  i.pop(0)
  pairList.append(i)
pairList.pop(0)

ATCList = []
firstStageErrorList = []
secondStageErrorList = []
thirdStageErrorList = []
count = 0
pbar = ProgressBar()
for i in pbar(pairList):
  tempList = []
  firstOutput = firstStep(i[1])
  secondOutput = secondStep(firstOutput)
  thirdOutput = thirdStep(secondOutput)
  if (firstOutput == "error"):
    tempList.append(i[0])
    tempList.append(i[1])
    firstStageErrorList.append(tempList)
  elif(secondOutput == "error"):
    tempList.append(i[0])
    tempList.extend(firstOutput)
    secondStageErrorList.append(tempList)
  elif(thirdOutput == "error"):
    tempList.append(i[0])
    tempList.extend(secondOutput)
    thirdStageErrorList.append(tempList)
  else:
    tempList.append(i[0])
    tempList.extend(thirdOutput)
    ATCList.append(tempList)
  count = count + 1
  if(count == 10):
    time.sleep(1)
    count = 0 
  
firstPass = ATCList
firstCopy = firstStageErrorList
secondCopy = secondStageErrorList
thirdCopy = thirdStageErrorList

ATCList = []
firstStageErrorList = []
secondStageErrorList = []
thirdStageErrorList = []
count = 0
pbar = ProgressBar()
for i in pbar(firstCopy):
  tempList = []
  firstOutput = firstStepKai(i[1])
  secondOutput = secondStep(firstOutput)
  thirdOutput = thirdStep(secondOutput)
  if (firstOutput == "error"):
    tempList.append(i[0])
    tempList.append(i[1])
    firstStageErrorList.append(tempList)
  elif (secondOutput == "error"):
    tempList.append(i[0])
    tempList.append(firstOutput)
    secondStageErrorList.append(tempList)
  elif (thirdOutput == "error"):
    tempList.append(i[0])
    tempList.extend(secondOutput)
    thirdStageErrorList.append(tempList)
  else:
    tempList.append(i[0])
    tempList.extend(thirdOutput)
    ATCList.append(tempList)
  count = count + 1
  if(count == 10):
    time.sleep(1)
    count = 0 

firstErrorFixed = ATCList
combinedThirdList = thirdCopy
combinedThirdList.extend(thirdStageErrorList)

ATCList = []
errorList = []
pbar = ProgressBar()
for i in pbar(combinedThirdList):
  input = i[1:]
  output = thirdStepKai(input)
  tempList = []
  tempList.append(i[0])
  tempList.extend(output)
  if(output == 'error'):
    errorList.append(i)
  else:
    ATCList.append(tempList)

thirdErrorFixed = ATCList
ATCList = []
ATCList.extend(firstPass)
ATCList.extend(firstErrorFixed)
ATCList.extend(thirdErrorFixed)

prescription = pd.read_csv("../../data/Processed/prescription_CleanedPresciption.csv")
ICU = pd.read_csv("../../data/Processed/prescription_ICUTime.csv")
prescription = prescription.dropna().reset_index()
ICU = ICU.dropna().reset_index()

with open("../../data/Processed/prescription_NDCtoATC.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerows(ATCList)

onetwoList = []
pbar = ProgressBar()
for i in pbar(range(0,prescription.shape[0])):
  startTime = datetime.strptime( prescription.loc[i,]['startdate'] , '%Y-%m-%d %H:%M:%S')
  endTime = datetime.strptime( prescription.loc[i,]['enddate'] , '%Y-%m-%d %H:%M:%S')
  ICUTime = datetime.strptime(ICU['entryTime'].loc[ICU['icustay_id'] == prescription.loc[i,]["icustay_id"]].values[0], '%Y-%m-%d %H:%M:%S')
  tempList = []
  firstDayICU = ICUTime + timedelta(days = 1)
  secondDayICU = ICUTime + timedelta(days = 2)
  startDiff = startTime - ICUTime
  endDiff = endTime - ICUTime
  #print(startDiff)
  #print(endDiff)
  if startTime < firstDayICU:
    tempList.append(True)
    if endTime >= secondDayICU:
      tempList.append(True)
    else:
      tempList.append(False)
  elif startTime < secondDayICU:
    tempList.append(False)
    tempList.append(True)
  else:
    tempList.append(False)
    tempList.append(False)
  onetwoList.append(tempList)
  #print(onetwoList)
  #break

firstDayList = []
secondDayList = []
for i in onetwoList:
  firstDayList.append(i[0])
  secondDayList.append(i[1])

prescription['firstDay'] = firstDayList
prescription['secondDay'] = secondDayList

firstStageResult = prescription.drop(columns=['index','Unnamed: 0','startdate','enddate','dose_unit_rx'])

df = pd.DataFrame(ATCList)
column_values = df.drop(0, axis = 1).values.ravel()
unique_values =  pd.unique(column_values)

ATCValues = []
for val in unique_values:
    if val != None :
        ATCValues.append(val)
ATCValues.sort()
uniqueATCList = ATCValues

secondStage = pd.DataFrame({'ICUID':[],'firstDay':[],'secondDay':[]})
for i in uniqueATCList:
  secondStage[i] = []
posDic = {}
for i in range(0,len(uniqueATCList)):
  posDic[uniqueATCList[i]] = i+ 3 

secondStage = secondStage.reindex(list(range(1,len(ICU)*2+1)))

reader = csv.reader(open('NDCtoATC.csv',newline=''))

result = {}
for row in reader:
  #print(row)
  key = row[0]
  result[key] = row[1:]
#print(result)
ATCDic = result

uniqueATCCodeslength = len(uniqueATCList)

pbar = ProgressBar()
ICUIDs = ICU['icustay_id'].values
for i in pbar(range(0,len(ICUIDs))):
  firstRow =  [ICUIDs[i],True,False]
  firstRow.extend([0] * uniqueATCCodeslength)
  secondRow = [ICUIDs[i],False,True]
  secondRow.extend([0] * uniqueATCCodeslength)
  secondStage.loc[i*2] = firstRow
  secondStage.loc[1+i*2] = secondRow

ICUIDDic = {}
pbar = ProgressBar()
for i in pbar(range(0,len(ICUIDs))):
  ICUIDDic[ICUIDs[i]] = i * 2

pbar = ProgressBar()
for i in pbar(range(0,firstStageResult.shape[0])):
  NDC = firstStageResult.loc[i]['ndc']
  ICU_ID = firstStageResult.loc[i]['icustay_id']
  dosage = firstStageResult.loc[i]['dose_val_rx']
  try:
    ATCCodes = ATCDic[str(int(NDC))]
  except KeyError:
    continue
  except:
    print("Something else went wrong")
    break
  for j in ATCCodes:
    if firstStageResult.loc[i]['firstDay']:
      secondStage.iloc[ICUIDDic[ICU_ID],posDic[j]] += dosage
    if firstStageResult.loc[i]['secondDay']:
      secondStage.iloc[ICUIDDic[ICU_ID]+1,posDic[j]] += dosage

secondStage.to_csv(r'../../data/Processed/prescription_secondStep.csv',index=False)