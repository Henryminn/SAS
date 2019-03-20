data q1;
infile 'H:\hw4\WAGE.dat' firstobs=2 missover;
input edu hr wage famearn self sal mar numkid age unemp; 
logwage = LOG(wage);
age2 = age*age;
hr2 = hr*hr;
hr3 = hr*hr*hr;
edu2 = edu*edu;
numkid2 = numkid*numkid;
run;

proc iml;
ID = repeat( T(1:334), 1, 3);
CS_ID = colvec(ID);
TS_ID = repeat(T(1984:1986),334,1);
create CSTS var {CS_ID TS_ID}; /* create data set */
append;       /* write data in vectors */
close CSTS; /* close the data set */

data q1panel;
merge csts q1;
run;
/*done preparing*/
/**********OLS with White-Pagan test**********/
proc model data=q1panel;
parms b0 b1 b2 b3 b4 b5 b6 b7 b8 b9;
logwage = b0+b1*age+b2*edu+b3*numkid+b4*hr+b5*mar+b6*sal+b7*self+b8*unemp;
fit logwage/white pagan=(1 hr);
run;
/***********OLS with hetero-skedasticity corrected se, VIF and COLLIN ***************/
proc reg data = q1panel;
model logwage = age edu numkid hr mar sal self unemp / VIF COLLIN hcc;
run;

/*test to see if there's nonlinear effect*/
proc reg data = q1 plots=none;
model logwage =age edu numkid hr mar sal self unemp age2 hr2 hr3 numkid2 edu2/ hcc;
run;

/*panel reg ran2 */
proc panel data = q1panel plots=none;
id CS_ID TS_ID;
model logwage = age numkid hr mar sal self edu unemp/rantwo;
run;
/*panel reg ran1 */
proc panel data = q1panel plots=none;
id CS_ID TS_ID;
model logwage = age numkid hr mar sal self edu unemp/ranone;
run;
/*fixone model*/
proc panel data = q1panel plots=none;
id CS_ID TS_ID;
model logwage = age edu numkid hr mar sal self unemp/fixone;
run;
/*fixtwo model*/
proc panel data = q1panel plots=none;
id CS_ID TS_ID;
model logwage = age edu numkid hr mar sal self unemp/fixtwo;
run;

/*********q2**********/
proc import datafile= 'H:\hw4\pims.xls' out=q2 dbms=xls replace;
getnames = YES, run;
proc print data=q2 (obs=10); run;
PROC SYSLIN 2SLS data=q2 SIMPLE plots=none first;
ENDOGENOUS ms qual plb price dc;
INSTRUMENTS ef pion phpf plpf psc papc penew pnp custsize custtyp ncust ncomp mktexp tyrp cap rbvi emprody union;
MODEL ms = qual plb price pion ef phpf plpf psc papc ncomp mktexp;
MODEL qual=price dc pion ef tyrp mktexp pnp;
MODEL plb=dc pion tyrp ef pnp custtyp ncust custsize; 
MODEL price=ms qual dc pion ef tyrp mktexp pnp;
MODEL dc=ms qual pion ef tyrp penew cap rbvi emprody union;
RUN;

PROC REG data = q2 plot=none;
model MS=qual plb price pion ef phpf plpf psc papc ncomp mktexp;
Run;

