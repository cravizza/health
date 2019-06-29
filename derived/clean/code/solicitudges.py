"""
Create cleaned datasets of ges
"""
from __future__ import division # to use division (instead of integer division) in python 2
import os
import pandas as pd 
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_solicitudges.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/solicitudges.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    dfg = pd.read_pickle(pDerived + 'solicitudges')
    dfg_hiv = dfg.loc[(dfg['gescod']=='18')].copy()
    icd10_hiv = r'(^B2[01234])|(^Z21)|(^Z11\.4)|(^D84\.[89])'
    dfg_hiv['icd10hiv'] = dfg_hiv['icd10'].str.contains(icd10_hiv, regex=True)
    dfg_hiv.drop(columns=['pronam'], inplace=True)
    dfg_hiv.to_pickle(pDerived + 'hiv_ges')
    dfg_hiv.to_stata('../output/hiv_ges.dta')
    
    print('\n-- Dataframe dtypes')
    print(dfg_hiv.info(memory_usage='deep'))
    print('\n-- Dataframe size')
    print(dfg_hiv.memory_usage(deep=True))
    
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    sys.stdout.close()
    sys.stdout=orig_stdout 
        
if __name__ == '__main__':
    main()
