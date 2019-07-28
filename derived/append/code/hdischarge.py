"""
Create cleaned dataset of hospital discharge
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
col_dtypes = {0:'int8'    , 1:'category', 2:'int32'   , 3:'category', 4:'int8'    , 5:'category'
            , 6:'category', 7:'category', 8:'category', 9:'category',10:'category',11:'category'
            ,12:'category',13:'category',14:'int8'    ,15:'category',16:'category',17:'category'}
col_names = { 0:'isapre'  , 1:'month'   , 2:'id_b'    , 3:'gender'  , 4:'age'     , 5:'typben'  
            , 6:'proid'   , 7:'pmnum'   , 8:'icd10_1' , 9:'icd10_2' ,10:'surgery' ,11:'date_in'
            ,12:'date_out',13:'discond' ,14:'dayshos' ,15:'planid'  ,16:'protyp'  ,17:'promun'}
use_cols = [0,1,2,6,7,8,9,10,11,12,13,14,17]
col_str = ['surgery','discond']
dic_date  = [x.strftime('%Y-%m-%d') for x in pd.date_range('2012-01-01', '2017-12-31').tolist()]


def readcsv(a):
    df = pd.read_csv(a, sep='|', header=None, dtype=col_dtypes, usecols=use_cols)
    df.dropna(subset=[0], inplace=True)
    df.dropna(axis=1, how='all', inplace=True) #drop any column with all NA values
    assert len(df.columns) == 13
    df.rename(columns=col_names, inplace=True)    
    df.dropna(how='all', inplace=True)
    clean_single_df(df)
    return df

def clean_single_df(df):
    for c in col_str:
        df[c].replace(to_replace=r'( )+', value=' ', regex=True, inplace=True)
        df[c] = df[c].str.lower().str.strip()
        df[c].replace(to_replace=r'(z\. sin (clasific$|clasificar$)|(no existe|sin) informaci[\Wo]n)', value='no info', regex=True, inplace=True)
        df[c] = df[c].astype('category')
    df['date_in']   = df['date_in'].cat.set_categories(dic_date)
    df['date_out'] = df['date_out'].cat.set_categories(dic_date)
    return df

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_hdischarge.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/hdischarge.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'egresoho' in f]
    
    #file_list2 = file_list[0:36]
    
    print('\n-- Begin pool ')
    start0 = time.time()
    pool = Pool(processes=16) # or whatever your hardware can support
    df_concat = pd.concat(pool.map(readcsv, file_list), axis=0, ignore_index=True)
    print('-- Time pool.map and concat:  ' + str(int(time.time() - start0)) + ' sec.')

    try:
        pool.terminate()
    except WindowsError:
        pass
    
    df_concat['month']    = df_concat['month'].astype('int32')
    df_concat['date_in']  = df_concat['date_in'].cat.set_categories(dic_date)
    df_concat['date_out'] = df_concat['date_out'].cat.set_categories(dic_date)
    for c in ['proid','pmnum','icd10_1','icd10_2','surgery','discond','promun']:
        df_concat[c] = df_concat[c].astype('category')    
    
    print('\n-- Concat dataframe dtypes')
    df_concat.info(memory_usage='deep')

    print('\n-- Descriptive stats')
    for c in col_str:
        print('\n' + str(df_concat[c].value_counts(dropna=False)))    

    print('\n-- Begin pickling ')
    start01 = time.time()
    df_concat.to_pickle(pDerived + 'hdischarge')
    print('-- Time elapsed pickling: ' + str(int(time.time() - start01)) + ' sec.')
    
    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. / ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
    