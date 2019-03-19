/*import data*/
data GROC;
infile'/folders/myfolders/files/fzpizza_groc_1114_1165.dat' firstobs=2 missover;
input IRI_KEY WEEK SY z2. GE z2. VEND z5. ITEM z5. UNITS DOLLARS F $ D PR;
run;
proc print data=GROC(obs=10);run;

data stores;
infile'/folders/myfolders/files/Delivery_Stores.dat' firstobs=2 missover;
input IRI_KEY OU $ EST_ACV Market_Name $20. Open Clsd MskdName $10;
run;
PROC CONTENTS DATA=WORK.stores; RUN;

PROC IMPORT DATAFILE= '/folders/myfolders/files/prod_fpizza.xls'
	DBMS=XLS
	OUT=WORK.prod;
	GETNAMES=YES;
RUN;


/*done loading datasets in, start merging*/
/*create UPC*/
data groc2; set GROC;
UPC = cats(put(SY,z2.),'-',put(GE,z2.),'-',put(VEND,z5.),'-',put(ITEM,z5.));
run;
/*sort data*/
proc sort data=groc2; by UPC; run;
proc sort data=prod; by UPC; run;

/*merge prod with groc-> m1*/
data m1; merge prod groc2; by UPC;
if DOLLARS = "." then delete; run;
proc print data=m1 (obs=10); run;

/*merge with delivery file-> alldata*/
proc SQL;
create table alldata as
select *
from m1 as a, stores as b
where a.IRI_KEY = b.IRI_KEY;
QUIT;

/*prepare the data, drop some unimportant variables*/

data dat1; set alldata;
DROP SY GE VEND ITEM OU EST_ACV Open Clsd L1 L2 Level _STUBSPEC_1664RC PRODUCT_TYPE;
If F="NONE" then FEATURE = 0; else FEATURE = 1;
If D = 0 then DISPLAY = 0; else DISPLAY = 1;
PRICE = DOLLARS/UNITS;
PRICE_PER_UNIT = DOLLARS/(UNITS*VOL_EQ*16);
run;

/*...................Q1.....................*/
proc sql outobs=6;
    create table q1_1 as
    select L5,sum(DOLLARS) as total_sales
    from dat1
    group by L5
    order by total_sales DESC;
quit;

proc sql;
create table q1_2 as
select L5, total_sales/SUM(total_sales)
from Q1_1;
QUIT;
proc print data=q1_2;
run;

/*....................Q2..................*/

proc summary data=dat1;
  var DOLLARS;
  class L4;
  output out=q2_1
           sum=DOLLARS;
run;
proc sort data=q2_1; by descending DOLLARS; run;
proc print data=q2_1 ; run;
/*top 10  brands*/
PROC SQL outobs=5;
CREATE TABLE q2_2 as
SELECT L4 as COMPANY, SUM(DOLLARS) as SALES
FROM dat1
GROUP BY L4
ORDER BY SALES descending;
QUIT;
proc print data=q2_2; run;

proc sql;
create table q2_3 as
	select distinct b.COMPANY, a.L5 from dat1 as a, q2_2 as b
	where a.L4 = b.COMPANY;
quit;
proc print data=q2_3; run;

/*....................Q3..................*/
data dat2;
set dat1;
if L5 = 'DI GIORNO' then brand = 1;
else if L5 = 'TOMBSTONE' then brand = 2;
else if L5 = 'RED BARON' then brand = 3;
else if L5 = 'FRESCHETTA' then brand = 4;
else if L5 = 'PRIVATE LABEL' then brand = 5;
else if L5 = 'TONYS' then brand = 6;
else brand = 7;
run;

/*....................Q4..................*/
proc sql;
create table q4 as
select sum(DOLLARS)/sum(UNITS*VOL_EQ*16) as avg_P_per_unit, sum(DISPLAY*UNITS)/sum(UNITS) as avg_d, sum(Feature*UNITS)/sum(UNITS)  as avg_F,brand
from dat2
group by brand;
quit;

/*....................Q5..................*/

PROC SQL outobs=5;
CREATE TABLE q5 as
SELECT Market_Name as Region, SUM(DOLLARS) as SALES
FROM dat2
GROUP BY Market_Name
ORDER BY SALES descending;
QUIT;
proc print data=q5; run;


/*....................Q6..................*/

PROC SQL outobs=10;
CREATE TABLE q6 as
SELECT MskdName as Store_Chain, SUM(DOLLARS) as SALES
FROM dat2
GROUP BY MskdName
ORDER BY SALES descending;
QUIT;
proc print data=q6; run;

/*....................Q7..................*/
proc sql;
create table q7 as
select sum(DOLLARS)/sum(UNITS*VOL_EQ*16) as avg_price,week,brand
from dat2
group by week, brand;
quit;

proc gplot data=Q7;
   plot avg_price*week = brand / vref=1000 to 75000 by 1000
                             lvref=2;
TITLE 'average price by week' ;
Run;

/*....................Q9..................*/
/*rank stores by sales*/
proc sql;
create table q9 as
select sum(DOLLARS) as totalsales, sum(DOLLARS)/sum(UNITS*VOL_EQ*16) as avg_P_per_unit, IRI_KEY
from dat2 where brand=1
group by IRI_KEY;
quit;
proc sort data=q9;
by descending totalsales;
run;
proc print data=q9 (obs=10); run;
/*create table with needed variables*/

proc sql;
create table q9_1 as
select sum(DOLLARS)/sum(UNITS*VOL_EQ*16) as weekly_price, IRI_KEY,WEEK
from dat2
group by IRI_KEY, WEEK;
quit;
proc print data=q9_1 (obs=10);
run;
data q9_2; set q9_1;
if IRI_KEY = '259495' or IRI_KEY = '276392' or IRI_KEY = '225023' then storetype ='large';
else if IRI_KEY = '649405' or IRI_KEY = '243941' or IRI_KEY = '646857' then storetype = 'small';
else delete;
run;

proc sql;
create table q9_3 as
select sum(weekly_price)/3 as avg_weekly_price, storetype, week
from q9_2
group by storetype, week;
quit;

proc ttest;
var avg_weekly_price; class storetype; run;


/*....................Q10..................*/

/*insight1*/
proc freq data=dat2; table Size;run;
data q10_1; set dat2;
keep DOLLARS UNITS VOL_EQ SIZE WEEK;
if SIZE="LARGE" or SIZE="MINI";
run;

proc sql;
create table q10_2 as
select sum(DOLLARS) as SALES, SIZE,WEEK
from q10_1
group by SIZE, WEEK;
quit;

proc ttest data=q10_2;
var  SALES;
class SIZE;
run;

/*insight 2*/
data Q10_3; set dat2;
keep DOLLARS UNITS VOL_EQ FLAVOR_SCENT WEEK;
if FLAVOR_SCENT='VEGGIE ULTIMATE' or FLAVOR_SCENT='VEGETABLE PRIMAVERA' or FLAVOR_SCENT='VEGETABLE';
run;

proc sql;
create table q10_4 as
select sum(DOLLARS) as SALES, FLAVOR_SCENT,WEEK
from q10_3
group by FLAVOR_SCENT, WEEK;
quit;

proc anova data=Q10_4;
class FLAVOR_SCENT;
model SALES=FLAVOR_SCENT ;
means FLAVOR_SCENT / tukey plots=none;
run;

/*insight3*/

proc freq data=dat1;table MICROWAVEABILITY;run;

data Q10_5;set dat1;
keep DOLLARS UNITS VOL_EQ MICROWAVEABILITY WEEK;
if MICROWAVEABILITY="MISSING" then delete;run;

proc sql;
create table q10_6 as
select sum(DOLLARS) as SALES, MICROWAVEABILITY, WEEK
from q10_5
group by MICROWAVEABILITY, WEEK;
quit;

proc anova data=q10_6;
class MICROWAVEABILITY;
model SALES=MICROWAVEABILITY;
run;

/*....................Q11..................*/
/*prepare data*/
proc sql;
create table q11 as
select sum(DOLLARS) as SALES,sum(DOLLARS)/sum(UNITS*VOL_EQ*16) as avg_P_per_unit,sum(D*UNITS)/sum(UNITS) as avg_d,sum(FEATURE*UNITS)/sum(UNITS) as avg_F,week
From dat2
where brand = 1
group by week;
quit;
/*a,b,c,d,e,h*/
proc reg data=q11;                                                                                                                      
model SALES = avg_P_per_unit avg_f avg_d/STB VIF COLLIN;                                                                     
run; 
proc glm data=q11;                                                                                                                      
model SALES = avg_P_per_unit | avg_d | avg_f; run;
                                                                                                                                   
proc corr data=m12; var avg_P_per_unit avg_feature avg_display; run;     
/*g*/
data Q11g;
set Q11;
avg_p_sq = avg_P_per_unit**2;
avg_p_3 = avg_P_per_unit**3;
run;
proc reg data = Q11g;
model SALES=avg_P_per_unit avg_d avg_F avg_p_sq avg_p_3;
run;

/*d - elasticity*/
data q11_2; set q11;                                                                                                                    
Y = log(sales);                                                                                                                  
X = log(avg_P_per_unit); run;                                                                                                                   
proc print data=q11_2 (obs=10); run;                                                                                                    
                                                                                                                                        
                                                                                                                                        
proc reg data=q11_2;                                                                                                                    
model Y = X; run;
/*i*/
proc model data=q11;                                                                                                                    
parms b0 b1 b2 b3;                                                                                                                      
SALES = b0 + b1*avg_P_per_unit + b2*avg_f + b3*avg_d;                                                                        
fit SALES / white; run;              



