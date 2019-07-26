"""
Create dictionaries for pbonificadas
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
            , 7:'int32'   , 8:'category', 9:'category',10:'category',11:'category',12:'category',13:'category'
            ,14:'category',15:'category',16:'category',17:'category',18:'category',19:'int32'   ,20:'int32'
            ,21:'int32'   ,22:'category',23:'category',24:'category',25:'category',26:'category',27:'float64'
            ,28:'float64' ,29:'category',30:'object',31:'int32'}
   
def readcsv(f):
    df = pd.read_csv(f, sep='|', header=None, dtype=col_dtypes, usecols=[7,11,30])
    return df

def iterate_months(start_ym, end_ym):
    for ym in range(int(start_ym), int(end_ym) + 1):
        if ym % 100 > 12 or ym % 100 == 0:
            continue
        yield str(ym)

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_dictionaries.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/dictionaries.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    
    print('\n-- Begin MONTH dictionary')
    dic_l = list(iterate_months('201201','201712'))
    dic_df = pd.DataFrame(dic_l)
    dic_df.to_csv(pDerived + 'dic_month.csv', index=False, header=False)
    
    print('\n-- Begin pool PROMUN CODE PROID')
    file_list = [os.path.join(path, f) for path, sd, files in os.walk('D:/Personal Directory/Catalina/Data') for f in files if 'Pbonificada' in f]
    start0 = time.time()
    pool = Pool(processes=16) # or whatever your hardware can support
    df_concat = pd.concat(pool.map(readcsv, file_list), axis=0, ignore_index=True)
    
    try:
        pool.terminate()
    except WindowsError:
        pass 

    print('-- Time pool.map and concat:  ' + str(int(time.time() - start0)) + ' sec.')
    
    print('\n-- Create PROMUN dictionary')
    # Get list of unique DPA and codes in data, then save as csv
    dpa = [str(x).lstrip('0') for x in pd.read_csv(pDerived + 'DPA_munici.csv',header=None,dtype={0:'category'})[0]]
    df_unique = df_concat[30].dropna(axis = 0, how ='any').unique().tolist()
    dic_l = list(set(dpa) | set(df_unique))
    dic_df = pd.DataFrame(dic_l)
    dic_df.to_csv(pDerived + 'dic_munic.csv', index=False, header=False)
    del dic_l
    del dic_df
    
    print('\n-- Create CODE dictionary')
    # Get list of unique codes in data, then save as csv
    dic_l = df_concat[11].dropna(axis = 0, how ='any').unique().tolist()
    dic_df = pd.DataFrame(dic_l)       
    dic_df.to_csv(pDerived + 'dic_code.csv', index=False, header=False)
    del dic_l
    del dic_df
    
    print('\n-- Create PROID dictionary')
    # Get list of unique codes in data, then save as csv
    dic_l = df_concat[7].dropna(axis = 0, how ='any').unique().tolist()
    dic_df = pd.DataFrame(dic_l)       
    dic_df.to_csv(pDerived + 'dic_proid.csv', index=False, header=False)
    
    print('\n-- Total time elapsed: ' + str(int((time.time() - start0)/60)) + ' min. | ' + str(int(time.time() - start0)) + ' sec.')
    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()
