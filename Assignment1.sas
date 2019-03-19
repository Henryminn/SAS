
PROC IMPORT DATAFILE="H:\car_insurance_19.csv"
 	OUT=a1
 	DBMS=csv 
 	REPLACE;
 	GETNAMES=Yes;
RUN;
PROC PRINT data=a1 (OBS=20);run;
 /*1*/
PROC freq data=a1; table Gender; run;
PROC freq data=a1; table Vehicle_Size; run;
PROC freq data=a1; table Vehicle_Class; run;

 /*2*/
proc means data=a1; var Customer_Lifetime_Value; class Gender; run; 
proc means data=a1; var Customer_Lifetime_Value; class Vehicle_Size; run; 
proc means data=a1; var Customer_Lifetime_Value; class Vehicle_Class; run;

 /*3*/
DATA a2; SET a1;
KEEP Customer Customer_Lifetime_Value Vehicle_Size Gender; 
IF Vehicle_Size ="Large" or Vehicle_Size = "Medsize"; run;
PROC TTEST DATA = a2; 
VAR Customer_Lifetime_Value; 
CLASS Vehicle_Size;run;

/*4*/
DATA a4; SET a1;
KEEP Customer_Lifetime_Value Gender; 
PROC TTEST DATA = a4; 
VAR Customer_Lifetime_Value; 
CLASS Gender;run;


/*5*/
DATA a5; SET a1;
KEEP Customer_Lifetime_Value Sales_Channel Education Income Marital_Status; run;
PROC anova DATA=a5; class Sales_Channel;
model Customer_Lifetime_Value=Sales_Channel; run;


/*6*/
PROC anova DATA=a1; class Education;
model Customer_Lifetime_Value=Education; run;
PROC corr DATA=a1;var Customer_Lifetime_Value Income ;run;
PROC anova DATA=a1; class Marital_Status;
model Customer_Lifetime_Value=Marital_Status; run;


/*7*/
proc freq data=a1;
 tables Renew_Offer_Type*Response / chisq measures;
run;
DATA a4; SET a1;
KEEP Renew_Offer_Type Response;
IF Renew_Offer_Type ="Offer1" or Renew_Offer_Type = "Offer2"; run;;
PROC freq data=a4;
tables Renew_Offer_Type*Response / chisq measures;
run;

/*8*/
proc anova data = a1;
      class Renew_Offer_Type;
      model Customer_Lifetime_Value=Renew_Offer_Type;
	  means Renew_Offer_Type / tukey plots=none;
   run;


 /*9*/
proc anova data = a1;
     class Renew_Offer_Type State;
     model Customer_Lifetime_Value = Renew_Offer_Type State Renew_Offer_Type*State;
run;

/*10*/
/*insight1*/
proc anova data = a1;
     class Coverage;
     model Customer_Lifetime_Value = Coverage;
run;
proc anova data = a1;
    class Coverage;
    model Customer_Lifetime_Value = Coverage;
    means Coverage / tukey plots=none;
run;

/*insight2*/
proc freq data=a1;
 tables Location_Code*Response / chisq measures;
run;
/*insight3*/
DATA a7; SET a1;
KEEP Customer_Lifetime_Value Education; 
IF Education ="High School or Below" or Education = "Master"; run;
PROC TTEST DATA = a7; 
VAR Customer_Lifetime_Value; 
CLASS Education;run;
