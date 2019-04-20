"""
This file builds a derived table of beneficiaries
"""
from __future__ import division # to use division (instead of integer division) in python 2
from multiprocessing import Pool
import os
import pandas as pd
import time
import datetime
import sys

# Define globals
pDerived = 'D:/Personal Directory/Catalina/Derived/'
col_dtypes = {0:'int8'    , 1:'category', 2:'category', 3:'int32'   , 4:'category', 5:'int8'    , 6:'category'
            , 7:'category', 8:'category', 9:'category',10:'category',11:'category',12:'category',13:'category'
            ,14:'category',15:'category',16:'category',17:'category',18:'category',19:'int32'   ,20:'int32'
            ,21:'int32'   ,22:'category',23:'category',24:'category',25:'category',26:'category',27:'float64'
            ,28:'float64' ,29:'category',30:'category',31:'int32'}
col_names = { 0:'isapre'  , 1:'month'   , 2:'typreg'  , 3:'id_b'    , 4:'gender'  , 5:'age'     , 6:'typben'
            , 7:'proid'   , 8:'proprf'  , 9:'medprp'  ,10:'medprc'  ,11:'code'    ,12:'codeid'  ,13:'codcov'
            ,14:'date'    ,15:'planid'  ,16:'protyp'  ,17:'typatt'  ,18:'freqcd'  ,19:'cost'    ,20:'coverg'
            ,21:'copay'   ,22:'rescop'  ,23:'planty'  ,24:'bushrs'  ,25:'typsur'  ,26:'lawurg'  ,27:'numbon'
            ,28:'numref'  ,29:'proreg'  ,30:'promun'  ,31:'id_m'}
col_dat = ['date']
col_int = ['month','isapre','id_m','id_b','copay','age','proid'] 
col_str = ['typreg','gender','typben','code','codeid','planty']
col_cat = ['month','isapre','proreg','promun','date','code'] 
use_cols = [0,1,2,3,4,5,6,7,11,12,14,21,23,29,30,31]
dic_date  = [x.strftime('%Y-%m-%d') for x in pd.date_range('2012-01-01', '2017-12-31').tolist()]
dic_month = pd.read_csv(pDerived + 'dic_month.csv',header=None,dtype={0:'category'})[0].tolist()
dic_munic = pd.read_csv(pDerived + 'dic_munic.csv',header=None,dtype={0:'category'})[0].tolist()
dic_proid = pd.read_csv(pDerived + 'dic_proid.csv',header=None,dtype={0:'category'})[0].tolist()
dic_code  = pd.read_csv(pDerived + 'dic_code.csv',header=None,dtype={0:'category'})[0].tolist()

def readcsv(f):
    df = pd.read_csv(f, sep='|', header=None, dtype=col_dtypes, usecols=use_cols)
    df.dropna(axis=1, how='all', inplace=True) #drop any column with all NA values
    assert len(df.columns) == 16
    df.rename(columns=col_names, inplace=True)
    df.dropna(how='all', inplace=True)
    clean_single_df(df)
    return df

def clean_single_df(df):
    for c in col_str:
        df[c] = df[c].str.lower().str.strip()
        df[c].replace(to_replace=r'(^z\.$)|(^z\. sin clasific[a-z]*$)', value='no info', regex=True, inplace=True)
    
    df['gender'].replace(to_replace=r'(^no nato)',value='unborn', regex=True, inplace=True)
    df['typreg'].replace(to_replace=r'(^examen medicina preventiva)',value='emp', regex=True, inplace=True)
    df['typreg'].replace(to_replace=r'(^protecci.n a la mujer embarazada)',value='pregnant', regex=True, inplace=True)
    df['typreg'].replace(to_replace=r'(^control del ni.o sano)',value='child', regex=True, inplace=True)
    df['planty'].replace(to_replace=r'(^cobertura general)',value='general', regex=True, inplace=True)
    df['planty'].replace(to_replace=r'(^cobertura reducida)',value='reduced', regex=True, inplace=True)
    df['codeid'].replace(to_replace=r'(^asegurador)',value='isapre', regex=True, inplace=True)
           
    for c in col_str:
        df[c] = df[c].astype('category')
    
    # Set dictionaries
    df['typreg'] = df['typreg'].cat.set_categories(['curativa','emp','pregnant','child'])
    df['gender'] = df['gender'].cat.set_categories(['femenino','masculino','unborn'])
    df['typben'] = df['typben'].cat.set_categories(['cotizante','carga'])
    df['codeid'] = df['codeid'].cat.set_categories(['fonasa','superintendencia','isapre'])
    df['planty'] = df['planty'].cat.set_categories(['general','reduced','no info'])
    df['proreg'] = df['proreg'].cat.set_categories(['0','1','2','3','4','5','6','7','8','9','10','11','12','13','14','15'])
    df['promun'] = df['promun'].cat.set_categories(dic_munic)
    df['proid']  =  df['proid'].cat.set_categories(dic_proid)
    df['month']  =  df['month'].cat.set_categories(dic_month)
    df['date']   =   df['date'].cat.set_categories(dic_date)
    df['code']   =   df['code'].cat.set_categories(dic_code)
    return df

def clean_df_concat(df):
    for c in col_cat:
        df[c] = df[c].astype('category')
    l0 = len(df)
    df_families = pd.read_pickle(pDerived + 'df_families')
    df_families['keep_col'] = 1
    
    final_df = pd.merge(df, df_families, how='left', on=['isapre','id_m','id_b'])
    final_df = final_df.loc[final_df['keep_col']==1]
    final_df.drop(columns=['keep_col'], inplace=True)
    l1 = len(final_df)
    print('-- Drop if not in beneficiaries:  ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    del df_families
    
    final_df.reset_index(drop=True, inplace=True)
    return final_df

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_pbonificadas.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/pbonificadas.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'Pbonificada' in f]
    print('\n-- Begin pool ')
    start0 = time.time()
    pool = Pool(processes=16)
    df_concat = pd.concat(pool.map(readcsv, file_list), axis=0, ignore_index=True)
    print('-- Time pool.map and concat:  ' + str(int(time.time() - start0)) + ' sec.')
    
    try:
        pool.terminate()
    except WindowsError:
        pass 
    
    print('\n-- Concat dataframe dtypes')
    df_concat.info(memory_usage='deep')
    print('\n-- Concat dataframe size')
    print(df_concat.memory_usage(deep=True))

    print('\n-- Cleaning ')    
    start1 = time.time()
    final_df = clean_df_concat(df_concat)
    print('-- Time elapsed cleaning : ' + str(int(time.time() - start1)) + ' sec.')

    print('\n-- Descriptive stats ')
    for c in ['gender','typben','typreg','planty','codeid']:
        print('\n' + str(final_df[c].value_counts(dropna=False)))

    print('\n-- Final dataframe dtypes')
    final_df.info(memory_usage='deep')

    print('\n-- Split final dataframe ') 
    df1 = final_df[0:110000000]
    df2 = final_df[110000000:220000000]
    df3 = final_df[220000000:]
    
    print('\n-- Begin pickling ')
    start01 = time.time()
    df1.to_pickle(pDerived + 'pboni1')
    print('-- Time elapsed first third:  ' + str(int(time.time() - start01)) + ' sec.')
    start02 = time.time()
    df2.to_pickle(pDerived + 'pboni2')
    print('-- Time elapsed second third: ' + str(int(time.time() - start02)) + ' sec.')
    start03 = time.time()
    df3.to_pickle(pDerived + 'pboni3')
    print('-- Time elapsed second third: ' + str(int(time.time() - start03)) + ' sec.')
    
    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. | ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
