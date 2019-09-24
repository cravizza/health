# -*- coding: utf-8 -*-
"""
Created on Sun Aug 11 12:24:17 2019

@author: cravizza

Use hospital discharge, caec, solicitudes ges
Then track pbonificadas of the confirmed patients

ICD-10 (https://www.icd10data.com/ICD10CM/Codes/A00-B99)
A50-A64 | Infections with a predominantly sexual mode of transmission
    A50 | Congenital syphilis
    A51 | Early syphilis
    A52 | Late syphilis
    A53 | Other and unspecified syphilis
    A54 | Gonococcal infection
    A55 | Chlamydial lymphogranuloma (venereum)
    A56 | Other sexually transmitted chlamydial diseases
    A57 | Chancroid
    A58 | Granuloma inguinale
    A59 | Trichomoniasis
    A60 | Anogenital herpesviral [herpes simplex] infections
    A63 | Other predominantly sexually transmitted diseases, not elsewhere classified
    A64 | Unspecified sexually transmitted disease

Z11.3	| Special screening examination for infections with a predominantly sexual mode of transmission
Z20.2   | Contact with and (suspected) exposure to infections with a predominantly sexual mode of transmission
Z22.4	| Carrier of infections with a predominantly sexual mode of transmission
    
B20     | Human immunodeficiency virus [HIV] 
B21		| Human immunodeficiency virus [HIV] disease resulting in malignant neoplasms
B22		| Human immunodeficiency virus [HIV] disease resulting in other specified diseases
B23		| Human immunodeficiency virus [HIV] disease resulting in other conditions
B24		| Unspecified human immunodeficiency virus [HIV] disease
Z11.4	| Special screening examination for human immunodeficiency virus [HIV]
Z20.6   | Contact with and (suspected) exposure to HIV
Z21     | Asymptomatic human immunodeficiency virus [HIV] infection status
R75		| Laboratory evidence of human immunodeficiency virus [HIV]

O00-O9A | Pregnancy, childbirth and the puerperium
"""
from __future__ import division
import os
import pandas as pd
import numpy as np
import time
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'

icd10_hiv_conf = r'^B2[01234]|^Z21|^R75'
code_lin = ['0305090','0305046','0305091']
code_std = ['0306016','0306023','0306034','0306037','0306038','0306042','0306041','0308044','0306075'
           ,'0306076','0306078','0306079','0306080','0306081','0306082','0306169','0801001']
code_gyn = ['0101308','0101332']
code_prg = ['0404002','2004001','2004002','2004003','2004004','2004005','2004006','2004007','2004008'
           ,'2004009','2004010','2004011','2004012','2004013','0101007','2501009','0404122'] #ADD THIS LAS ONE!!!
code_hiv = ['0306169']

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_confirmationsy.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/confirmations.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    start0 = time.time()
    print('\n-- Identify individuals HIV+')
    dfg = pd.read_pickle(pDerived + 'solicitudges')
    dfg['date2'] = np.where(dfg['event']=='tto_or_und',dfg['date'],dfg['evdate'])  
    hiv_dfg = dfg.loc[(dfg['gescod']=='18')&(dfg['gessta']=='Activo'),['id_m','id_b','date2','event']].copy().drop_duplicates()
    hiv_dfg.rename(columns={'date2':'date'}, inplace=True)
    print(hiv_dfg.info(memory_usage='deep'))
    
    dfc = pd.read_pickle(pDerived + 'caec')
    hiv_dfc = dfc.loc[dfc['icd10'].str.contains(icd10_hiv_conf, regex=True)==1,['id_m','id_b','date_app']]
    hiv_dfc.rename(columns={'date_app':'date'}, inplace=True)
    hiv_dfc['date'] = pd.to_numeric(hiv_dfc['date'].str.replace("-",""), downcast='integer')
    hiv_dfc['event'] = 'confirmation'
    print(hiv_dfc.info(memory_usage='deep'))
    
    dfh = pd.read_pickle(pDerived + 'hdischarge')
    hiv_dfh = dfh.loc[(dfh['icd10_2'].str.contains(icd10_hiv_conf, regex=True)==1)|(dfh['icd10_2'].str.contains(icd10_hiv_conf, regex=True)==1),['month','id_b','date_in']]
    hiv_dfh['date_in'] = pd.to_numeric(hiv_dfh['date_in'].str.replace("-",""), downcast='integer')
    hiv_dfh['date'] = np.where(hiv_dfh.date_in.isnull(),hiv_dfh.month*100+1,hiv_dfh.date_in)
    hiv_dfh['date'] = pd.to_numeric(hiv_dfh['date'], downcast='integer')
    hiv_dfh.drop(columns=['date_in','month'], inplace=True)
    hiv_dfh['event'] = 'confirmation'
    hiv_dfh['id_m'] = np.nan
    print(hiv_dfh.info(memory_usage='deep'))
    
    del dfg, dfc, dfh
    hiv_conf_idb  = pd.concat([hiv_dfg[['id_b']].drop_duplicates(),hiv_dfc[['id_b']].drop_duplicates(),hiv_dfh[['id_b']].drop_duplicates()], axis=0, ignore_index=True)
    hiv_conf_idb  = hiv_conf_idb.drop_duplicates()
    hiv_conf_ids  = pd.concat([hiv_dfg,hiv_dfc,hiv_dfh], axis=0, ignore_index=True, sort=True)
    del hiv_dfg, hiv_dfc, hiv_dfh
    hiv_conf_ids['N'] = hiv_conf_ids.groupby(['id_b'])['date'].transform('min')
    hiv_conf_ids      = hiv_conf_ids.loc[hiv_conf_ids['date']==hiv_conf_ids['N']]
    hiv_conf_ids.drop(columns=['N'], inplace=True)
    hiv_conf_ids      = hiv_conf_ids.drop_duplicates()
    hiv_conf_ids['C'] = hiv_conf_ids.groupby(['id_b','date'])['event'].transform('count')
    hiv_conf_ids      = hiv_conf_ids.loc[(hiv_conf_ids['C']==1)|((hiv_conf_ids['C']==2)&(hiv_conf_ids['event']=='confirmation'))]

    hiv_conf_ids.drop(columns=['C','id_m'], inplace=True)
    hiv_conf_ids      = hiv_conf_ids.drop_duplicates()
    hiv_conf_ids.rename(columns={'date':'date_conf'}, inplace=True)

    print('-- HIV+, time elapsed load and clean: ' + str(int(time.time() - start0)) + ' sec.')
    
    start1 = time.time()
    df1 = pd.read_pickle(pDerived + 'pboni1')
    df2 = pd.read_pickle(pDerived + 'pboni2')
    df3 = pd.read_pickle(pDerived + 'pboni3')
    dfp = pd.concat([df1, df2, df3], axis=0, ignore_index=True)
    del df1, df2, df3
    dfp.drop(columns=['proid'], inplace=True) # drop to use in Stata
    print('-- Pbon of hiv confirmed')
    dfp = dfp[['id_m','id_b','code7','date']].copy().drop_duplicates()
    hiv_conf0 = pd.merge(hiv_conf_idb, dfp, how='inner', on=['id_b'])
    hiv_conf  = pd.merge(hiv_conf0, hiv_conf_ids, how='inner', on=['id_b'])
    hiv_conf['date'] = pd.to_numeric(hiv_conf['date'].str.replace("-",""), downcast='integer')
    del dfp, hiv_conf0
    print('\n-- Pbon, time elapsed: ' + str(int(time.time() - start1)) + ' sec.')
    
    start2 = time.time()
    hiv_conf['c_lin'] = hiv_conf['code7'].isin(code_lin)
    hiv_conf['c_std'] = hiv_conf['code7'].isin(code_std)
    hiv_conf['c_prg'] = hiv_conf['code7'].isin(code_prg)
    hiv_conf['c_gyn'] = hiv_conf['code7'].isin(code_gyn)
    hiv_conf['c_hiv'] = hiv_conf['code7'].isin(code_hiv)

    for c in ['c_lin','c_std','c_prg','c_gyn','c_hiv']:
        hiv_conf[c] = hiv_conf[c].astype('int8')
    hiv_conf = hiv_conf.loc[hiv_conf['code7']!='00052t2']
    hiv_conf['code7'] = pd.to_numeric(hiv_conf['code7'], downcast='integer')
    hiv_conf.to_stata('../output/hiv_conf.dta')
    print(hiv_conf.info(memory_usage='deep'))
    print('\n-- New vars, time elapsed: ' + str(int(time.time() - start2)) + ' sec.')

    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
