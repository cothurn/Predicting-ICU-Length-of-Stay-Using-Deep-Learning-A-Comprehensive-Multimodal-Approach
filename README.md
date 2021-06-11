# Predicting ICU Length of Stay Using Deep Learning: A Comprehensive Multimodal Approach
Repository storaging the code associated with IJDS submission IJDS-2021-030, Predicting ICU Length of Stay Using Deep Learning: A Comprehensive Multimodal Approach. 

## Required languages & Packages
The project was developed and tested using the following languages and packages:
### R (Version 4.0.3)
fastDummies (Ver 1.6.3)
chron (Ver 2.3-66)
factoextra (Ver 1.0.7)
### Python (3.7.10)
Pandas

NumPy

sklearn

transformers (Ver 4.6.1) 

keras_bert (Ver 0.86.0)

progressbar2 (Ver 3.38.0)

### Tensorflow 2.5.0
CUDA (Version 11.2)

# Content
Following the recommented Code Capsule structure, the repository is comprised of three folders. The Code folder contains the R & Python code written for this project. The Data folder is a placeholder folder, as the DUA associated with the dataset used, MIMIC, forbids the distribution of the data. The BlueBERT folder is a placeholder for a pretrained BERT model available here: https://github.com/ncbi-nlp/bluebert
## Data Acquisition
Individuals interested in replicating this work should apply for access to the MIMIC III dataset at https://physionet.org/content/mimiciii/1.4/
It should be noted that this project was developed using MIMIC III V1.3, and the dataset has since been updated. While the code has been updated to accommodate the updated syntax of the data, please contact TJ Guo at tianjian.guo AT mccombs.utexas.edu for potential issues during replication.

## Replication
### Step 0: Install MIMIC to a SQL database
Please follow the instruction provided in https://mimic.mit.edu/iii/tutorials/ and install MIMIC.
#### Step 0.1 
Run the following scripts from the MIMIC Code Repository, and save the resulting table.
| SQL Script to Run                                                                                      | Location to Save Output  |
|--------------------------------------------------------------------------------------------------------|--------------------------|
| https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iii/concepts/pivot/pivoted_vital.sql             | data/Raw/vitalSign.csv   |
| https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iii/concepts/comorbidity/elixhauser_ahrq_v37.sql | data/Processed/Elixhauser.csv* |
| https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iii/concepts/severityscores/apsiii.sql           | data/Processed/aps3.csv        |
| https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iii/concepts/severityscores/oasis.sql            | data/Processed/oasis.csv       |
| https://github.com/MIT-LCP/mimic-code/blob/main/mimic-iii/concepts/severityscores/sofa.sql             | data/Processed/sofa.csv        |

*: Please follow the instruction provided in the manuscript to compress this table and save as data/Processed/ElixhauserCompressed.csv

### Step 1: Copy MIMIC III data to the data folder
Place the decompressed CSV files in the data/Raw folder.

### Step 2: Run the R/Python scripts for generating the input for the RNN framework
Different types of data used in this project are processed using different tools & methods. Execute the following files in sequential order in order to generate the intermediate outputs that will be used in the next step. (Detailed comments and instructions will be uploaded in the near future)
#### 2.1 Demographic and Misc. 
code/RCode/demographic.R
#### 2.2 Diagnosis
code/RCode/diagnosis.R
#### 2.3 Vital Sign
code/PythonCode/VitalSign.py
#### 2.4 Prescription
code/RCode/prescriptionStep1.R

code/PythonCode/prescriptionStep2.py

code/RCode/prescriptionStep3.R
#### 2.5 Clinical notes
code/RCode/notesStep1.R

code/PythonCode/notesStep2.py*

*This step requires the usage of Tensorflow 2. Please download the pretrained blueBERT model here (https://ftp.ncbi.nlm.nih.gov/pub/lu/Suppl/NCBI-BERT/NCBI_BERT_pubmed_mimic_uncased_L-12_H-768_A-12.zip) and unzip its content to the BlueBERT folder.

### Run the RNN frameworks
The notebook in code/JupyterNoteBook contains the code for the RNN based prediction model. Intermediate data from the previous step will be used to train models based on different types of input, and the average performance will be reported. 
