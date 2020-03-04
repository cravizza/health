# -*- coding: utf-8 -*-
"""
Created on Tue Sep 24 10:04:14 2019

@author: cravizza
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
code_prg = ['0404002','2004001','2004002','2004003','2004004','2004005','2004006','2004007','2004008'
           ,'2004009','2004010','2004011','2004012','2004013','0101007','2501009','0404122']
code_std = ['0306016','0306023','0306034','0306037','0306038','0306042','0306041','0308044','0306075','0306076','0306078','0306079','0306080'
           ,'0306081','0306082','0306169','0801001']
code_gyp = ['0101308','0101332','0801001','0305070']
code_hiv = ['0306169']
code_pan = ['0302034','0302075','0302076','0309022','0301045','0303024','0303324','0302057','0302023']
code_doc = ['0101001','0101004','0101005','0101006','0101007','0101008','0101009','0101010','0101020','0101101','0101103','0101104','0101105']
code_spe = ['0101002','0101003','0101102','0101106','0101107','0101108','0101109','0101110','0101111','0101112','0101113','0101114','0101201'
           ,'0101202','0101203','0101204','0101205','0101206','0101207','0101208','0101209','0101210','0101211','0101212','0101213','0101300'
           ,'0101301','0101302','0101303','0101304','0101305','0101306','0101307','0101308','0101309','0101310','0101311','0101312','0101313'
           ,'0101314','0101315','0101316','0101317','0101318','0101319','0101320','0101321','0101322','0101323','0101324','0101325','0101326'
           ,'0101327','0101328','0101329','0101330','0101331','0101332','0101333','0101334']
code_hos = ['0202001','0202002','0202003','0202004','0202005','0202006','0202007','0202008','0202009','0202010','0202011','0202101','0202102'
           ,'0202103','0202104','0202105','0202106','0202107','0202108','0202109','0202110','0202111','0202112','0202113','0202114','0202115'
           ,'0202116','0202201','0202202','0202203','0202301','0202302','0202303']
code_pre = ['0108101','0108102','0108103','0108104','0108105','0108106','0108107','0108108','0108111','0108112','0108113','0108114','0108124'
           ,'0302336','0302347','0302367','0302447','0303324','0306301','0306311','0306342','0306369','0306442','0308309','0401310','0401351']
code_psy = ['0901001','0901002','0901003','0901004','0901005','0901006','0901009','0901010','0902001','0902002','0902003','0902010','0902011'
           ,'0902012','0902013','0902014','0902015','0902016','0902017','0902018','0902019','0902020']
code_sur = ['1103001','1103002','1103003','1103004','1103005','1103006','1103007','1103008','1103009','1103010','1103011','1103012','1103013'
           ,'1103014','1103015','1103016','1103017','1103018','1103019','1103020','1103021','1103022','1103023','1103024','1103025','1103026'
           ,'1103027','1103028','1103029','1103030','1103031','1103032','1103033','1103034','1103035','1103036','1103037','1103038','1103039'
           ,'1103040','1103041','1103042','1103043','1103044','1103045','1103046','1103047','1103048','1103049','1103050','1103051','1103052'
           ,'1103053','1103054','1103055','1103056','1103057','1103058','1103059','1103060','1103061','1103062','1103063','1103064','1103065'
           ,'1103066','1103067','1103068','1103069','1202001','1202002','1202003','1202004','1202005','1202006','1202007','1202008','1202009'
           ,'1202010','1202011','1202012','1202013','1202014','1202015','1202016','1202017','1202018','1202019','1202020','1202021','1202022'
           ,'1202023','1202024','1202025','1202026','1202027','1202028','1202029','1202030','1202031','1202032','1202033','1202034','1202035'
           ,'1202036','1202037','1202038','1202039','1202040','1202041','1202042','1202044','1202045','1202046','1202047','1202048','1202049'
           ,'1202050','1202051','1202053','1202054','1202055','1202056','1202057','1202058','1202059','1202060','1202061','1202062','1202063'
           ,'1202064','1202065','1202066','1202067','1202068','1202069','1202070','1202071','1202072','1202073','1202074','1202075','1202076'
           ,'1202077','1202078','1302001','1302002','1302003','1302004','1302005','1302006','1302007','1302008','1302009','1302010','1302011'
           ,'1302012','1302013','1302014','1302015','1302016','1302017','1302018','1302019','1302020','1302021','1302022','1302023','1302024'
           ,'1302025','1302026','1302027','1302028','1302029','1302030','1302031','1302032','1302033','1302034','1302035','1302036','1302037'
           ,'1302038','1302039','1302040','1302041','1302042','1302043','1302044','1302045','1302046','1302047','1302048','1302049','1302050'
           ,'1302051','1302052','1302053','1302054','1302055','1302056','1302057','1302058','1302059','1302060','1302061','1302062','1302063'
           ,'1302064','1302065','1302066','1302067','1302068','1302069','1302070','1302071','1302072','1302073','1402001','1402002','1402003'
           ,'1402004','1402005','1402006','1402007','1402008','1402009','1402010','1402011','1402012','1402013','1402014','1402015','1402016'
           ,'1402017','1402018','1402019','1402020','1402021','1402022','1402023','1402024','1402025','1402026','1402027','1402028','1402029'
           ,'1402030','1402031','1402032','1402033','1402034','1402035','1402036','1402037','1402038','1402039','1402040','1402041','1402042'
           ,'1402043','1402044','1402045','1402046','1402047','1402048','1402050','1402051','1402052','1402053','1402054','1402055','1402056'
           ,'1402057','1402058','1402059','1402060','1502001','1502002','1502003','1502004','1502005','1502006','1502007','1502008','1502009'
           ,'1502010','1502011','1502012','1502013','1502014','1502015','1502016','1502017','1502018','1502019','1502020','1502021','1502022'
           ,'1502023','1502024','1502025','1502026','1502027','1502028','1502029','1502030','1502031','1502032','1502033','1502034','1502035'
           ,'1502036','1502037','1502038','1502039','1502040','1502041','1502042','1502043','1502044','1502045','1502046','1502047','1502048'
           ,'1502049','1502050','1502051','1502052','1502053','1502054','1502055','1502056','1502057','1502058','1502059','1502060','1502061'
           ,'1502062','1502063','1502064','1502065','1502066','1602201','1602202','1602203','1602204','1602205','1602206','1602207','1602211'
           ,'1602212','1602213','1602214','1602215','1602216','1602221','1602222','1602223','1602224','1602225','1602231','1602232','1602233'
           ,'1602240','1602241','1602242','1703001','1703002','1703003','1703004','1703005','1703006','1703007','1703008','1703009','1703010'
           ,'1703011','1703012','1703013','1703014','1703015','1703016','1703017','1703018','1703019','1703020','1703021','1703022','1703023'
           ,'1703024','1703025','1703026','1703027','1703028','1703029','1703030','1703031','1703032','1703033','1703034','1703035','1703036'
           ,'1703037','1703038','1703039','1703040','1703041','1703042','1703043','1703044','1703045','1703046','1703047','1703048','1703049'
           ,'1703050','1703051','1703052','1703053','1703054','1703055','1703056','1703057','1703058','1703059','1703060','1703061','1703062'
           ,'1703063','1704001','1704002','1704003','1704004','1704005','1704006','1704007','1704008','1704009','1704010','1704011','1704012'
           ,'1704013','1704014','1704015','1704016','1704017','1704018','1704019','1704020','1704021','1704022','1704023','1704024','1704025'
           ,'1704026','1704027','1704028','1704029','1704030','1704031','1704032','1704033','1704034','1704035','1704036','1704037','1704038'
           ,'1704039','1704040','1704041','1704042','1704043','1704044','1704045','1704046','1704047','1704048','1704049','1704050','1704051'
           ,'1704052','1704053','1704054','1704055','1704056','1704057','1704058','1704059','1704060','1704061','1704062','1704063','1704064'
           ,'1802001','1802002','1802003','1802004','1802005','1802006','1802007','1802008','1802009','1802010','1802011','1802012','1802013'
           ,'1802014','1802015','1802016','1802017','1802018','1802019','1802020','1802021','1802022','1802023','1802024','1802025','1802026'
           ,'1802027','1802028','1802029','1802030','1802031','1802032','1802033','1802034','1802035','1802036','1802037','1802038','1802039'
           ,'1802040','1802041','1802042','1802043','1802044','1802045','1802046','1802047','1802048','1802049','1802050','1802051','1802052'
           ,'1802053','1802054','1802055','1802056','1802057','1802058','1802059','1802060','1802061','1802062','1802063','1802065','1802066'
           ,'1802067','1802068','1802069','1802070','1802071','1802072','1802073','1802074','1802075','1802076','1802077','1802079','1802080'
           ,'1802081','1802082','1802100','1802148','1803001','1803002','1803003','1803004','1803005','1803006','1803007','1803008','1803009'
           ,'1803010','1803011','1803012','1803013','1803014','1803015','1803016','1803017','1803018','1803019','1803020','1803021','1803022'
           ,'1803023','1803024','1803025','1803026','1803027','1803028','1803029','1803030','1803031','1803032','1803033','1803034','1803035'
           ,'1803036','1803038','1902001','1902002','1902003','1902004','1902005','1902006','1902008','1902009','1902010','1902011','1902012'
           ,'1902013','1902014','1902015','1902016','1902017','1902018','1902019','1902020','1902021','1902022','1902023','1902024','1902025'
           ,'1902027','1902028','1902029','1902030','1902031','1902032','1902033','1902034','1902035','1902036','1902037','1902038','1902040'
           ,'1902041','1902042','1902043','1902044','1902045','1902046','1902047','1902048','1902049','1902050','1902051','1902052','1902053'
           ,'1902054','1902055','1902056','1902057','1902058','1902059','1902060','1902061','1902062','1902063','1902064','1902065','1902066'
           ,'1902067','1902068','1902069','1902070','1902071','1902072','1902073','1902074','1902075','1902076','1902077','1902078','1902079'
           ,'1902080','1902081','1902082','1902083','1902084','1902085','1902090','2002001','2002002','2002003','2002005','2003001','2003002'
           ,'2003003','2003004','2003005','2003006','2003007','2003008','2003009','2003010','2003011','2003012','2003013','2003014','2003015'
           ,'2003016','2003017','2003018','2003019','2003020','2003021','2003022','2003023','2003024','2003025','2003026','2003027','2003028'
           ,'2003029','2003030','2003031','2003040','2003041','2004001','2004002','2004003','2004004','2004005','2004006','2004007','2004008'
           ,'2004009','2004010','2004011','2004012','2004013','2104001','2104002','2104003','2104004','2104005','2104006','2104007','2104008'
           ,'2104009','2104010','2104011','2104012','2104013','2104014','2104015','2104016','2104017','2104018','2104019','2104020','2104021'
           ,'2104022','2104023','2104024','2104025','2104026','2104027','2104028','2104029','2104030','2104031','2104033','2104034','2104035'
           ,'2104036','2104037','2104038','2104039','2104040','2104041','2104042','2104043','2104044','2104045','2104046','2104047','2104048'
           ,'2104049','2104050','2104051','2104052','2104053','2104054','2104055','2104056','2104057','2104058','2104059','2104060','2104061'
           ,'2104062','2104063','2104064','2104065','2104066','2104067','2104068','2104069','2104070','2104071','2104072','2104073','2104074'
           ,'2104075','2104076','2104077','2104078','2104079','2104080','2104081','2104082','2104083','2104084','2104085','2104086','2104087'
           ,'2104088','2104089','2104090','2104091','2104092','2104093','2104094','2104095','2104096','2104097','2104098','2104099','2104100'
           ,'2104101','2104102','2104103','2104104','2104105','2104106','2104107','2104108','2104109','2104110','2104111','2104112','2104113'
           ,'2104114','2104115','2104116','2104117','2104118','2104119','2104120','2104121','2104122','2104123','2104124','2104125','2104126'
           ,'2104127','2104128','2104129','2104130','2104131','2104132','2104133','2104134','2104135','2104136','2104137','2104138','2104139'
           ,'2104140','2104141','2104142','2104143','2104144','2104145','2104146','2104147','2104148','2104149','2104150','2104151','2104152'
           ,'2104153','2104154','2104155','2104156','2104157','2104158','2104159','2104160','2104161','2104162','2104163','2104164','2104165'
           ,'2104166','2104167','2104168','2104169','2104170','2104171','2104172','2104173','2104174','2104175','2104176','2104177','2104178'
           ,'2104179','2104180','2104181','2104182','2104183','2104184','2104185','2104186','2104187','2104188','2104189','2104190','2104191'
           ,'2104192','2104193','2104194','2104195','2104196','2104197','2104198','2104199','2104200','2104201','2104202','2105001','2105002'
           ,'2105003','2105004','2105005','2105006','2105007','2105008','2105009','2105010','2105011','2105012','2105013','2106001','2106002'
           ,'2106003','2107001','2107002','2107003','2107004','2107005','2107006','2107007','2107008','2107009','2107010']

def balanced_df(input_df,max_months):
    output_df = input_df[['id_m','id_b','month']].copy().drop_duplicates()
    output_df['Nmonths'] = output_df.groupby(['id_m','id_b'])['month'].transform('count')
    output_df.drop_duplicates(inplace=True)
    assert output_df.Nmonths.min() == 1
    assert output_df.Nmonths.max() == max_months
    l0 = len(output_df)
    output_df = output_df[output_df.Nmonths == max_months]
    l1 = len(output_df)
    output_df.drop(columns=['Nmonths'], inplace=True)
    print('-- Keep if balanced: ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    return output_df
    
def get_fam_df(df_idm,df_idt,benef,contracts,income):
    i0 = pd.merge(df_idm,contracts, how='inner', on=['month','id_m'],validate='1:1')
    i1 = pd.merge(i0    ,income   , how='inner', on=['month','id_m'],validate='1:1')
    i2 = pd.merge(i1    ,benef    , how='left' , on=['month','id_m'])
    del df_idm
    df_fam = pd.merge(i2, df_idt, how='left', on=['month','id_m','id_b'])
    del i0, i1, i2
    del df_idt
    df_fam['hiv'].fillna(0, inplace=True)
    for c in ['hiv','isapre','indcom','salaried']:
        df_fam[c] = df_fam[c].astype('int8')
    for c in ['id_b','dob','dod_m']:
        df_fam[c] = df_fam[c].astype('int32')
    for c in ['region','munici']:
        df_fam[c] = df_fam[c].astype('string')
    df_fam.reset_index(drop=True,inplace=True)
    df_fam.info(memory_usage='deep')
    return df_fam

def main():
    orig_stdout = sys.stdout
    sys.stdout=open('../output/log_predict.txt','w')
    print('-- Executing: ' + str(os.getcwd())[38:] + '/predict.py')
    print('-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))
    
    start0 = time.time()
    print('\n-- Load pbon')
    df1 = pd.read_pickle(pDerived + 'pboni1')
    df2 = pd.read_pickle(pDerived + 'pboni2')
    df3 = pd.read_pickle(pDerived + 'pboni3')
    dfp = pd.concat([df1, df2, df3], axis=0, ignore_index=True)
    del df1, df2, df3
    dfp.drop(columns=['proid'], inplace=True) #dfp['code2'] = dfp.code.str.zfill(7).str[0:2]
    dfp['date'] = pd.to_numeric(dfp['date'].str.replace("-",""), downcast='integer')
    dfp['temp'] = dfp['code7'].isin(code_prg)
    dfp['pregnant'] = dfp.groupby(by=['id_m','id_b'])['temp'].transform('max')
    l0 = len(dfp)
    dfp = dfp.loc[dfp['pregnant']==0]
    l1 = len(dfp)
    dfp.drop(columns=['temp','pregnant'], inplace=True)
    dfp.reset_index(drop=True,inplace=True)
    print('-- Drop if pregnant: ' + str(l0-l1) + ' rows dropped (' + str(int((l0-l1)/l0*10000)/100) + '%)')
    del l0, l1
    dfp = dfp.loc[dfp['month'].between(201501,201612)]
    dfp.drop(columns=['code','code2','codeid'], inplace=True)
    print('-- Load beneficiaries')
    df1 = pd.read_pickle(pDerived + 'beneficiaries1')
    df2 = pd.read_pickle(pDerived + 'beneficiaries2')
    dfb = pd.concat([df1, df2], axis=0, ignore_index=True)
    dfb = dfb.loc[(dfb['month'].between(201501,201612))].copy() #
    dfb.reset_index(drop=True,inplace=True)
    del df1, df2
    print('-- Load income and contracts')
    dfi = pd.read_pickle(pDerived + 'cotiza_income')
    dfc = pd.read_pickle(pDerived + 'contracts_plantype')
    print('-- Load treatment sample')
    ind_pbon = pd.read_pickle(pDerived + 'ind_pbon')
    ind_pbon = ind_pbon.loc[ind_pbon['control']==0]
    ind_pbon.drop(columns=['control','code','code2','codeid'], inplace=True)
    ind_pbon.rename(columns={'mD':'date_hiv'}, inplace=True)
    ind_pbon = ind_pbon.loc[ind_pbon['date']<ind_pbon['date_hiv']]
    ind_pbon.reset_index(drop=True,inplace=True)
    ind_pbon['predict'] = 1
    ind_idb = ind_pbon[['id_b']].copy().drop_duplicates()
    ind_idb['predict'] = 1
    ind_idb['tester']  = 1
    ind_idb['zeropb']  = 1
    print('-- Load data, time elapsed load and concat: ' + str(int(time.time() - start0)) + ' sec.') #20 min
    
    start1 = time.time()
    print('\n-- Construct subsample: balanced 2015-2016, ages 17-53 on 31Dec2017')
    dfb0    = dfb.loc[(dfb['dob'].between(19640100,20000100))].copy()
    dfb_bal = balanced_df(dfb0,24)
    del dfb0
    dfb_idm = dfb_bal[['id_m']].drop_duplicates().copy()
    dfb_idm['month'] = 201608
    dfb_idt = dfb_bal[['id_m','id_b']].drop_duplicates().copy()
    dfb_idt['month'] = 201608
    dfb_idt['hiv']   = 1
    print('-- Families')
    dfb_fam = get_fam_df(dfb_idm,dfb_idt,dfb,dfc,dfi)
    dfb_fam.to_stata('../output/predict_fam.dta')
    del dfb_fam, dfb_idm, dfb_idt
    dfb_idb = dfb_bal[['id_b']].drop_duplicates().copy()
    dfp_bal = pd.merge(dfb_idb,dfp,how='inner',on=['id_b'])
    dfp_bal.reset_index(drop=True,inplace=True)
    dfp_idb = pd.merge(dfb_idb,dfp['id_b'].drop_duplicates(),how='inner',on=['id_b'])
    print('-- Create sample of testers and not testers')
    hiv_test = dfp.loc[(dfp['code7'] == '0306169')&(dfp['date'].between(20160720,20160910)),['id_b','date']].copy().drop_duplicates()
    hiv_test['date_tester'] = hiv_test.groupby(['id_b'])['date'].transform('min')
    hiv_test = hiv_test[['id_b','date_tester']].drop_duplicates()    
    dates = pd.merge(dfp_idb,hiv_test,how='left',on='id_b',indicator=True,validate='1:1')
    dates['date_rd']  = np.random.choice(hiv_test['date_tester'].drop_duplicates(), size=len(dates))
    del hiv_test
    dates['date_hiv'] = np.where(dates['date_tester'].isnull(), dates['date_rd'], dates['date_tester'])    
    dates['tester']   = np.where(dates['_merge']=='both',1,0)
    dates['date_hiv'] = dates['date_hiv'].astype('int32')
    dates['tester']   = dates['tester'].astype('int8')
    dates['predict'] = 0
    all_idb0 = pd.merge(dfb_idb,dates[['id_b','tester']],on='id_b',how='outer',indicator=True,validate='1:1')
    dates.drop(columns=['_merge','date_rd','date_tester','tester'], inplace=True)
    all_idb0['tester']  = all_idb0['tester'].fillna(0)
    all_idb0['tester']  = all_idb0['tester'].astype('int8')
    all_idb0['zero_pb'] = np.where(all_idb0['_merge']=='left_only',1,0)
    all_idb0['zero_pb'] = all_idb0['zero_pb'].astype('int8')
    assert len(all_idb0.loc[all_idb0['_merge']=='right_only'])==0
    all_idb0.drop(columns=['_merge'], inplace=True)
    all_idb = pd.concat([all_idb0,ind_idb], axis=0, ignore_index=True,sort='True')
    all_idb.to_stata('../output/predict_idb.dta')
    print('-- Sample testers and not testers, time elapsed: ' + str(int(time.time() - start1)) + ' sec.')

    start2 = time.time()
    print('\n-- Construct full sample of past health care use')
    df0 = pd.merge(dfp_bal,dates,how='outer',on='id_b',indicator=True,validate='m:1')
    assert len(df0) == len(df0.loc[df0['_merge']=='both','month'])
    df0.drop(columns=['_merge'], inplace=True)
    df0 = df0.loc[df0['date']<df0['date_hiv']] #only past use
    df0.reset_index(drop=True,inplace=True)
    df = pd.concat([df0,ind_pbon], axis=0, ignore_index=True,sort='True')
    assert len(df)==len(df0)+len(ind_pbon)
    del df0, ind_pbon
    df = df[['id_b','id_m','date','date_hiv','code7','age','predict','gender']].copy().drop_duplicates()
    df['date_ly'] = df['date_hiv']-10000
    df = df.loc[df['date']>=df['date_ly']]
    print('-- Construct dummies for health service use')
    df['I_std'] = df['code7'].isin(code_std).astype('int8')
    df['I_gyp'] = df['code7'].isin(code_gyp).astype('int8')
    df['I_hiv'] = df['code7'].isin(code_hiv).astype('int8')
    df['I_doc'] = df['code7'].isin(code_doc).astype('int8')
    df['I_spe'] = df['code7'].isin(code_spe).astype('int8')
    df['I_hos'] = df['code7'].isin(code_hos).astype('int8')
    df['I_pre'] = df['code7'].isin(code_pre).astype('int8')
    df['I_psy'] = df['code7'].isin(code_psy).astype('int8')
    df['I_sur'] = df['code7'].isin(code_sur).astype('int8')
    df['I_pan'] = df['code7'].isin(code_pan).astype('int8')
    df['I_any'] = ((df['I_std']==1)|(df['I_gyp']==1)|(df['I_hiv']==1)|(df['I_doc']==1)|(df['I_spe']==1)
                  |(df['I_hos']==1)|(df['I_pre']==1)|(df['I_psy']==1)|(df['I_sur']==1)|(df['I_pan']==1)).astype('int8')
    df.drop(columns=['id_m','code7','date','date_hiv','date_ly'], inplace=True)
    print('-- Share of health service use codes included in indicators')
    print(df['I_any'].value_counts(normalize=True))
    print('-- Collapse at individual level')
    aggregations = {'age':'last','gender':'last','I_any':'max','I_pan':'max','I_sur':'max','I_psy':'max'
                 ,'I_pre':'max','I_hos':'max','I_spe':'max','I_doc':'max','I_hiv':'max','I_gyp':'max','I_std':'max'}
    df_ly = df.groupby(['id_b','predict'],as_index=False).agg(aggregations)
    df_ly.to_stata('../output/predict_ly.dta')
    print('-- Health care use, time elapsed: ' + str(int(time.time() - start2)) + ' sec.')

    print('\n-- Timestamp: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'))

    sys.stdout.close()
    sys.stdout=orig_stdout 

if __name__ == '__main__':
    main()