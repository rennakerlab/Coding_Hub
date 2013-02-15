AllData=[]

load RRTF_08192004

GD=vertcat(Group(:).Data);

AZCirc=vertcat(Group(:).PSTHZCirc);
ANRRTF=vertcat(Group(:).NormRRTF);
ANStdEr=vertcat(Group(:).StdErr);
ALate=vertcat(Group(:).Latency);
APTime=vertcat(Group(:).PeakTime);
AEndLate=vertcat(Group(:).EndLate);
APeak=vertcat(Group(:).PeakVal);
ARate=vertcat(Group(:).Rate);
APVal=vertcat(Group(:).PValue);
%GD =8 Values, 
AllRatData=horzcat(GD,AZCirc,ANRRTF,ANStdEr,ALate,APTime,AEndLate,APeak,ARate,APVal);
AllData=vertcat(AllData,AllRatData);