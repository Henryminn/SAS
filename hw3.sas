/*load data in*/
libname a 'h:\';
data q1; set a.vacation19;run;
proc print data=q1 (obs=20);run;
/*regression model*/
proc reg;
model miles= income age kids/hcc spec;
run;
/*white test*/
proc model data=q1;
parms b0 b1 b2 b3;
miles=b0+b1*income+ b2*age+ b3*kids;
fit miles / white out=resid1 outresid;run;
/*WLS first code: this code does the White's test before applying the weight, so we do not use it*/
proc model data=q1;
parms b0 b1 b2 b3;
income_inv=1/income;
miles=b0+b1*income+ b2*age+ b3*kids;
fit miles / white ;
weight income_inv;
run;

/*WLS: We used this code to do WLS regression and White's test*/
data q1_2;set q1;
kmiles=miles/income;
kage=age/income;
kkids=kids/income;
kincome=1/income;
run;

proc model data=q1_2;
parms b0 b1 b2 b3;
kmiles=b1+b0*kincome+ b2*kage+ b3*kkids ;
fit kmiles / white ;run;
/*test once more using another code*/
proc reg data=q1_2;
model kmiles= kincome kage kkids/hcc spec;
run;

/******************Question 2*********************/
Data q2;
input week Sales;
cards;
1	160
2	390
3	800
4	995
5	1250
6	1630
7	1750
8	2000
9	2250
10	2500
;
run;
proc print;run;
data q2_1;set q2;
cums + Sales;lags =lag(cums);sqrs=lags*lags;
proc reg outest=coeff;model Sales = lags sqrs;run;
proc print data=coeff;run;

data q2_2;set coeff;
M=(-lags-(sqrt(lags*lags-4*intercept*sqrs)))/(2*sqrs);
p=intercept/m;
q=p+lags;
tstar=log(q/p)*1/(p+q);
sstar=M*(p+q)*(p+q)/(4*q);
proc print data = q2_2;run;


data q2_3;set q2_1;
M=26225.01; p=0.020581; q=0.33071;
array nt{10} t1-t10 (0 0 0 0 0 0 0 0 0 0);
do i = 1 to 10;
PSales=p*(M-nt[i])+ q*(nt[i]/M)*(M-nt[i]);
nt[i]=nt[i]+PSales;
end;

proc gplot;plot PSales*week Sales*week/overlay;
title 'Actual sales versus predicted sales';run;

proc print data=q2_3; var week Sales PSales;
title 'Predicted sales in each period ';
run;

/******************Question 3*********************/
data q3;
input brand $	scent $	soft $	oz 	pr	s1	s2	s3	s4	s5;
cards;
complete	fresh	n	48	4.99	1	3	3	2	2
complete	fresh	y	32	2.99	1	3	3	5	5
complete	lemon	n	32	2.99	1	2	7	5	1
complete	lemon	y	64	3.99	1	9	5	8	1
complete	U	n	64	3.99	1	9	7	8	7
complete	U	y	48	4.99	1	3	3	2	3
Smile	fresh	n	64	2.99	1	9	9	9	6
Smile	fresh	y	48	3.99	1	7	7	6	5
Smile	lemon	n	48	3.99	1	7	7	6	1
Smile	lemon	y	32	4.99	1	1	1	1	1
Smile	U	n	32	4.99	1	1	3	1	2
Smile	U	y	64	2.99	1	9	3	9	9
Wave	fresh	n	32	3.99	7	1	7	4	5
Wave	fresh	y	64	4.99	5	5	3	3	2
Wave	lemon	n	64	4.99	5	5	5	3	1
Wave	lemon	y	48	2.99	9	9	5	7	1
Wave	U	n	48	2.99	9	9	5	7	7
Wave	U	y	32	3.99	7	1	5	4	5
Wave	lemon	n	64	2.99	8	9	6	9	3
Smile	lemon	n	32	4.99	2	1	3	2	1
Smile	fresh	y	48	2.99	2	8	4	5	5
complete	U	y	32	2.99	2	4	2	5	6
complete	lemon	y	48	3.99	2	6	6	6	1
;
run;
proc print;run;

/*importance weights and part-worths for each person 1-5*/
proc transreg data = q3 utilities outtest=coeff2;
model identity(s1-s5) = class(brand scent soft oz pr/zero=sum);
run;

/*get utility for each combination*/
data q3_coeff; set coeff2;
keep _DEPVAR_ Variable Coefficient; 
IF Variable = " " then delete; run; 

proc transpose data=q3_coeff out=transpose;
ID Variable;
by _DEPVAR_;
var Coefficient;
run;

data combineU; set transpose;
keep Obs _DEPVAR_ U1 U2 U3 U4 U5;
U1=Class_brandcomplete + Class_scentlemon + Class_softy + Class_oz64+ Class_pr2D99;
U2=Class_brandSmile + Class_scentfresh + Class_softy + Class_oz48 + Class_pr2D99;
U3=Class_brandSmile + Class_scentU + Class_softy + Class_oz48 + Class_pr3D99;
U4=Class_brandWave + Class_scentU + Class_softy + Class_oz48 + Class_pr2D99;
U5=Class_brandSmile + Class_scentU + Class_softn + Class_oz48 + Class_pr2D99;run;

/*combineU table is the Utility for each combination for each person*/
proc print data=combineU; run;


/*Use logit rule to get probability table*/
data a9; set combineU;
DROP U1 U2 U3 U4 U5 total_L1 total_L2 total_L3 total_L4 total_L5;
if _DEPVAR_="Identity(s1)" then 
	total_L1 = exp(U1)+exp(U2)+exp(U3)+exp(U4)+exp(U5);
	s1_C1 = exp(U1)/total_L1;
	s1_C2 = exp(U2)/total_L1;
	s1_C3 = exp(U3)/total_L1;
	s1_C4 = exp(U4)/total_L1;
	s1_C5 = exp(U5)/total_L1;
if _DEPVAR_="Identity(s2)" then 
	total_L2 = exp(U1)+exp(U2)+exp(U3)+exp(U4)+exp(U5);
	s2_C1 = exp(U1)/total_L2;
	s2_C2 = exp(U2)/total_L2;
	s2_C3 = exp(U3)/total_L2;
	s2_C4 = exp(U4)/total_L2;
	s2_C5 = exp(U5)/total_L2;
if _DEPVAR_="Identity(s3)" then 
	total_L3 = exp(U1)+exp(U2)+exp(U3)+exp(U4)+exp(U5);
	s3_C1 = exp(U1)/total_L3;
	s3_C2 = exp(U2)/total_L3;
	s3_C3 = exp(U3)/total_L3;
	s3_C4 = exp(U4)/total_L3;
	s3_C5 = exp(U5)/total_L3;
if _DEPVAR_="Identity(s4)" then 
	total_L4 = exp(U1)+exp(U2)+exp(U3)+exp(U4)+exp(U5);
	s4_C1 = exp(U1)/total_L4;
	s4_C2 = exp(U2)/total_L4;
	s4_C3 = exp(U3)/total_L4;
	s4_C4 = exp(U4)/total_L4;
	s4_C5 = exp(U5)/total_L4;
if _DEPVAR_="Identity(s5)" then 
	total_L5 = exp(U1)+exp(U2)+exp(U3)+exp(U4)+exp(U5);
	s5_C1 = exp(U1)/total_L5;
	s5_C2 = exp(U2)/total_L5;
	s5_C3 = exp(U3)/total_L5;
	s5_C4 = exp(U4)/total_L5;
	s5_C5 = exp(U5)/total_L5;
run;
proc print data=a9; run;

