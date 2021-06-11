setwd("Z:/Research/MIMIC/code/RCode")


diag = read.csv(file = "../../data/Raw/DIAGNOSES_ICD.csv", stringsAsFactors = FALSE)
diag$icd9_code = substr(diag$icd9_code,1,3)

uniqueID = names(table(diag$hadm_id))
diagDF = data.frame('hadm_id' = uniqueID)

diagDF$infectious=0
diagDF$neoplasms=0
diagDF$endocrine=0
diagDF$blood=0
diagDF$mental=0
diagDF$nerve=0
diagDF$circular=0
diagDF$respiratory=0
diagDF$digestive=0
diagDF$genitourinary=0
diagDF$pregnancy=0
diagDF$skin=0
diagDF$musculoskeletal=0
diagDF$congenital=0
diagDF$perinatal=0
diagDF$symptoms=0
diagDF$injury=0
diagDF$miscellaneous=0



for (i in 1:dim(diag)[1])
{
  if(diag$icd9_code[i] < "140")
  {diagDF$infectious[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "240")
  {diagDF$neoplasms[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "280")
  {diagDF$endocrine[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "290")
  {diagDF$blood[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "320")
  {diagDF$mental[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "390")
  {diagDF$nerve[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "460")
  {diagDF$circular[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "520")
  {diagDF$respiratory[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "580")
  {diagDF$digestive[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "630")
  {diagDF$genitourinary[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "680")
  {diagDF$pregnancy[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "710")
  {diagDF$skin[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "740")
  {diagDF$musculoskeletal[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "760")
  {diagDF$congenital[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "780")
  {diagDF$perinatal[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "800")
  {diagDF$symptoms[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else if(diag$icd9_code[i] < "1000")
  {diagDF$injury[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  else
  {diagDF$miscellaneous[which(diagDF$hadm_id == diag$hadm_id[i])] = 1}
  
  if(i %% 10000 == 0)
  {cat(i)}
}

write.csv(diagDF,file = "../../data/Processed/diagnosis.csv")
