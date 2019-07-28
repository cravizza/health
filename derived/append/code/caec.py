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
col_dtypes = {0:'int8'    , 1:'category', 2:'category', 3:'int32'   , 4:'category', 5:'int32'   , 6:'category'
            , 7:'int32'   , 8:'category', 9:'category',10:'category',11:'category',12:'category',13:'category'
            ,14:'category',15:'float64' ,16:'float64' ,17:'category',18:'category',19:'category',20:'category'
            ,21:'category',22:'float32' ,23:'float32' ,24:'int32'   ,25:'int32'   ,26:'int32'   ,27:'int32'
            ,28:'int32'   ,29:'category',30:'category'}
col_names = { 0:'isapre'  , 1:'month'   , 2:'gescaec' , 3:'id_b'    , 4:'dv_b'    , 5:'id_m'    , 6:'dv_m'  
            , 7:'proid'   , 8:'prodv'   , 9:'proreg'  ,10:'red'     ,11:'icd10'   ,12:'emerg'   ,13:'pmnum'
            ,14:'pmnumc'  ,15:'numbon'  ,16:'numree'  ,17:'date_app',18:'date_aut',19:'date_pro',20:'date_pb'
            ,21:'date_ded',22:'deduftot',23:'dedufacc',24:'dedclacc',25:'billtot' ,26:'billpro' ,27:'billcaec'
            ,28:'billnotc',29:'dod_b'  ,30:'loan'}
use_cols = [0,1,3,5,7,11,13,14,17,18,19,20,29]
col_cat = ['icd10','pmnum','pmnumc','date_pb','dod_b','date_app','date_aut','date_pro']
col_int = ['month','id_m','id_b','proid']
dic_date  = [x.strftime('%Y-%m-%d') for x in pd.date_range('2014-01-01', '2017-12-31').tolist()]


def readcsv(a):
    df = pd.read_csv(a, sep='|', header=None, dtype=col_dtypes, usecols=use_cols)
    df.dropna(subset=[0], inplace=True)
    df.dropna(axis=1, how='all', inplace=True) #drop any column with all NA values
    assert len(df.columns) == 13
    df.rename(columns=col_names, inplace=True)    
    df.dropna(how='all', inplace=True)
    return df

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_caec.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/caec.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'Caec' in f]
    
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
    
    for c in col_cat:
        df_concat[c] = df_concat[c].astype('category')
    for c in col_int:
        df_concat[c] = df_concat[c].astype('int32')
        
    df_concat['date_pb'] = df_concat['date_pb'].cat.set_categories(dic_date)
    df_concat['dod_b']   = df_concat['dod_b'].cat.set_categories(dic_date)
    
    print('\n-- Concat dataframe dtypes')
    print(df_concat.info(memory_usage='deep'))
    print(df_concat.memory_usage(deep=True))

    print('\n-- Begin pickling ')
    start01 = time.time()
    df_concat.to_pickle(pDerived + 'caec')
    print('-- Time elapsed pickling: ' + str(int(time.time() - start01)) + ' sec.')
    
    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. / ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
