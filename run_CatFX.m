function [ position ] = run_CatFX( barData,MinPoint,realBegDate,Length,Period )
% Attention:barData分别为Date，Open，High，Low，Close五列。
% MinPoint是品种最小变动单位
% realBegDate是实盘开始日期，格式如'2010-04-16'
% Length,Period为策略参数

%变量
%K线变量
Date = barData(:,1);
Open = barData(:,2);
High = barData(:,3);
Low = barData(:,4);
Close = barData(:,5);
barLength = size(Date,1); %K线总量

MarketPosition = 0;
ConOpenTimes = 0;
my_currentcontracts = 0;  %持仓手数
lots = 1;

%% 计算交易条件
%---------以下变量根据需要进行修改--------%
%策略变量
sFcactor = 2/(Length+1);   %计算EMA
Ema=zeros(barLength,1);
Ema(1)=Close(1);
for i=2:barLength
    Ema(i)= Ema(i-1)+sFcactor*(Close(i)-Ema(i-1));
end

sumrange=0;
Kwatr=2;
Last_ma=0;
Last=0;
SmaxMin=zeros(barLength,1);
SmaxMax=zeros(barLength,1);
SminMin=zeros(barLength,1);
SminMax=zeros(barLength,1);
SmaxMid=zeros(barLength,1);
SminMid=zeros(barLength,1);
aSmaxMin=zeros(barLength,1);
aSmaxMax=zeros(barLength,1);
aSminMin=zeros(barLength,1);
aSminMax=zeros(barLength,1);
aSmaxMid=zeros(barLength,1);
aSminMid=zeros(barLength,1);
con1=zeros(barLength,1);
con2=zeros(barLength,1);
diff=zeros(barLength,1);
buyCon1=zeros(barLength,1);
sellCon1=zeros(barLength,1);
buyCon=zeros(barLength,1);
sellCon=zeros(barLength,1);
aStoch1=zeros(barLength,1);
aStoch2=zeros(barLength,1);
watrmax=zeros(barLength,1);
watrmin=zeros(barLength,1);

%交易
for i=Period:barLength
    sumrange=0;
    for j=0:Period-1
        dK=1+1.0*(Period-j)/Period;
        sumrange=sumrange+dK*(High(i-j)-Low(i-j));
    end
    watr=sumrange/Period;
    if i==Period
        watrmax(i)=watr;
        watrmin(i)=watr;
    else
        watrmax(i)=max(watr,watrmax(i-1));
        watrmin(i)=min(watr,watrmin(i-1));
    end
    StepSizeMin=round(Kwatr*watrmin(i)/MinPoint);
    StepSizeMax=round(Kwatr*watrmax(i)/MinPoint);
    StepSizeMid=round(Kwatr*0.5*(watrmin(i)+watrmax(i))/MinPoint);
    
    if High(i)>Low(i)
        SmaxMin(i)=Low(i)+2*StepSizeMin*MinPoint;
        SminMin(i)=High(i)-2*StepSizeMin*MinPoint;
        SmaxMax(i)=Low(i)+2*StepSizeMax*MinPoint;
        SminMax(i)=High(i)-2*StepSizeMax*MinPoint;
        SmaxMid(i)=Low(i)+2*StepSizeMid*MinPoint;
        SminMid(i)=High(i)-2*StepSizeMid*MinPoint;
        if Close(i)>SmaxMin(i-1)
            TrendMin=1;
        elseif Close(i)<SmaxMin(i-1)
            TrendMin=-1;
        end
        if Close(i)>SmaxMax(i-1)
            TrendMax=1;
        elseif Close(i)<SmaxMax(i-1)
            TrendMax=-1;
        end
        if Close(i)>SmaxMid(i-1)
            TrendMid=1;
        elseif Close(i)<SmaxMin(i-1)
            TrendMid=-1;
        end
    elseif High(i)==Low(i)
        SmaxMin(i)=Close(i)+2*StepSizeMin*MinPoint;
        SminMin(i)=Close(i)-2*StepSizeMin*MinPoint;
        SmaxMax(i)=Close(i)+2*StepSizeMax*MinPoint;
        SminMax(i)=Close(i)-2*StepSizeMax*MinPoint;
        SmaxMid(i)=Close(i)+2*StepSizeMid*MinPoint;
        SminMid(i)=Close(i)-2*StepSizeMid*MinPoint;
        if Close(i)>SmaxMin(i-1)
            TrendMin=1;
        elseif Close(i)<SmaxMin(i-1)
            TrendMin=-1;
        end
        if Close(i)>SmaxMax(i-1)
            TrendMax=1;
        elseif Close(i)<SmaxMax(i-1)
            TrendMax=-1;
        end
        if Close(i)>SmaxMid(i-1)
            TrendMid=1;
        elseif Close(i)<SmaxMin(i-1)
            TrendMid=-1;
        end
    end
    
    if TrendMin>0 && SminMin(i)<SminMin(i-1)
        SminMin(i)=SminMin(i-1);
    elseif TrendMin<0 && SmaxMin(i)>SmaxMin(i-1)
        SmaxMin(i)=SmaxMin(i-1);
    end
    if TrendMax>0 && SminMax(i)<SminMax(i-1)
        SminMax(i)=SminMax(i-1);
    elseif TrendMax<0 && SmaxMax(i)>SmaxMax(i-1)
        SmaxMax(i)=SmaxMax(i-1);
    end
    if TrendMid>0 && SminMid(i)<SminMid(i-1)
        SminMid(i)=SminMid(i-1);
    elseif TrendMid<0 && SmaxMid(i)>SmaxMid(i-1)
        SmaxMid(i)=SmaxMid(i-1);
    end
    if TrendMin>0
        Linemin=SminMin(i)+StepSizeMin*MinPoint;
    elseif TrendMin<0
        Linemin=SmaxMin(i)-StepSizeMin*MinPoint;
    end
    if TrendMax>0
        Linemax=SminMax(i)+StepSizeMax*MinPoint;
    elseif TrendMax<0
        Linemax=SmaxMax(i)-StepSizeMax*MinPoint;
    end
    if TrendMid>0
        Linemid=SminMid(i)+StepSizeMid*MinPoint;
    elseif TrendMid<0
        Linemid=SmaxMid(i)-StepSizeMid*MinPoint;
    end
    
    bsmin=Linemax-StepSizeMax*MinPoint;
    bsmax=Linemax+StepSizeMax*MinPoint;
    
    if bsmax~=bsmin
        Stoch1=(Linemin-bsmin)/(bsmax-bsmin);
        Stoch2=(Linemid-bsmin)/(bsmax-bsmin);
    end
    diff(i)=Stoch1-Stoch2;
     
    if diff(i)>0 && High(i-1)>=Ema(i-1)
        con1(i)=1;
    elseif diff(i)<0 && Low(i-1)<=Ema(i-1)
        con1(i)=-1;
    else
        con1(i)=con1(i-1);
    end
    
    if diff(i-2)>0 && High(i-2)>Ema(i-2) && Open(i-1)<Ema(i-1) && diff(i-1)>0 && Open(i)>Ema(i) && diff(i)>0
        con2(i)=1;
    elseif diff(i-2)<0 && Low(i-2)<Ema(i-2) && Open(i-1)>Ema(i-1) && diff(i-1)<0 && Open(i)<Ema(i) && diff(i)<0
        con2(i)=-1;
    else
        con2(i)=con2(i-1);
    end  
    if (con1(i)==1) || (con2(i)==1)
        sellCon1(i)=-1;
        buyCon1(i)=1;
    elseif (con1(i)==-1) || (con2(i)==-1)
        sellCon1(i)=1;
        buyCon1(i)=-1;
    else
        buyCon1(i)=buyCon1(i-1);
        sellCon1(i)=sellCon1(i-1);
    end
    
    aMin=Kwatr*watrmin(i);
    aMax=Kwatr*watrmax(i);
    aMid=Kwatr*0.5*(watrmax(i)+watrmin(i));
    
    if High(i)>Low(i)
        aSmaxMin(i)=Low(i)+2*aMin;
        aSminMin(i)=High(i)-2*aMin;
        aSmaxMax(i)=Low(i)+2*aMax;
        aSminMax(i)=High(i)-2*aMax;
        aSmaxMid(i)=Low(i)+2*aMid;
        aSminMid(i)=High(i)-2*aMid;
        
        if Close(i)>aSmaxMin(i-1)
            aTrendMin=1;
        elseif Close(i)<aSmaxMin(i-1)
            aTrendMin=-1;
        end
        if Close(i)>aSmaxMax(i-1)
            aTrendMax=1;
        elseif Close(i)<aSmaxMax(i-1)
            aTrendMax=-1;
        end
        if Close(i)>aSmaxMid(i-1)
            aTrendMid=1;
        elseif Close(i)<aSmaxMid(i-1)
            aTrendMid=-1;
        end
    end
    if High(i)==Low(i)
        aSmaxMin(i)=Close(i)+2*aMin;
        aSminMin(i)=Close(i)-2*aMin;
        aSmaxMax(i)=Close(i)+2*aMax;
        aSminMax(i)=Close(i)-2*aMax;
        aSmaxMid(i)=Close(i)+2*aMid;
        aSminMid(i)=Close(i)-2*aMid;
        
        if Close(i)>aSmaxMin(i-1)
            aTrendMin=1;
        elseif Close(i)<aSmaxMin(i-1)
            aTrendMin=-1;
        end
        if Close(i)>aSmaxMax(i-1)
            aTrendMax=1;
        elseif Close(i)<aSmaxMax(i-1)
            aTrendMax=-1;
        end
        if Close(i)>aSmaxMid(i-1)
            aTrendMid=1;
        elseif Close(i)<aSmaxMid(i-1)
            aTrendMid=-1;
        end        
    end
        
    if aTrendMin>0 && aSminMin(i)<aSminMin(i-1)
        aSminMin(i)=aSminMin(i-1);
    elseif aTrendMin<0 && aSmaxMin(i)>aSmaxMin(i-1)
        aSmaxMin(i)=aSmaxMin(i-1);
    end
    if aTrendMax>0 && aSminMax(i)<aSminMax(i-1)
        aSminMax(i)=aSminMax(i-1);
    elseif aTrendMax<0 && aSmaxMax(i)>aSmaxMax(i-1)
        aSmaxMax(i)=aSmaxMax(i-1);
    end
    if aTrendMid>0 && aSminMid(i)<aSminMid(i-1)
        aSminMid(i)=aSminMid(i-1);
    elseif aTrendMid<0 && aSmaxMid(i)>aSmaxMid(i-1)
        aSmaxMid(i)=aSmaxMid(i-1);
    end
    if aTrendMin>0
        aLinemin=aSminMin(i)+aMin;
    elseif aTrendMin<0
        aLinemin=aSmaxMin(i)-aMin;
    end
    if aTrendMax>0
        aLinemax=aSminMax(i)+aMax;
    elseif aTrendMax<0
        aLinemax=aSmaxMax(i)-aMax;
    end
    if aTrendMid>0
        aLinemid=aSminMid(i)+aMid;
    elseif aTrendMid<0
        aLinemid=aSmaxMid(i)-aMid;
    end
    
    asmin=aLinemax-aMax;
    asmax=aLinemax+aMax;
    aStoch1(i)=(aLinemin-asmin)/(asmax-asmin);
    aStoch2(i)=(aLinemid-asmin)/(asmax-asmin);
    
    if (Close(i)-Ema(i))*(Open(i)-Ema(i))<0
        Last_ma=1;
    end
    if (aStoch1(i)-aStoch2(i))*(aStoch1(i-1)-aStoch2(i-1))<0
        Last=0;
        Exit=1;
        if aStoch1(i)>aStoch2(i)
            if Last_ma~=0 && Ema(i)<Open(i)
                buyCon(i)=1;
                sellCon(i)=-1;
                if Last_ma==1 && abs((Ema(i)-Open(i))/MinPoint<20)
                    Exit=1;
                end
            else
                buyCon(i)=buyCon(i-1);
                sellCon(i)=sellCon(i-1);
                Last=1;
            end
        elseif aStoch1(i)<aStoch2(i)
            if Last_ma~=0 && Ema(i)>Open(i)
                sellCon(i)=1;
                buyCon(i)=-1;
                if Last_ma==1 && abs((Ema(i)-Open(i))/MinPoint<20)
                    Exit=1;
                end
            else
                buyCon(i)=buyCon(i-1);
                sellCon(i)=sellCon(i-1);                
                Last=-1;
            end
        end
    else
        Exit=-1;
        if Last>=0 && Open(i)>Ema(i)
            buyCon(i)=1;
            sellCon(i)=-1;
            Last=0;
        elseif Last<=0 && Open(i)<Ema(i)
            sellCon(i)=1;
            buyCon(i)=-1;
            Last=0;
        else
            buyCon(i)=buyCon(i-1);
            sellCon(i)=sellCon(i-1);
        end
    end
    if buyCon1(i-1)==1 && buyCon(i-1)==1
        totalCon(i) = 1;
    elseif sellCon1(i-1)==1 && sellCon(i-1)==1
        totalCon(i) = -1;
    end
end

%% 实盘交易
% 找出实盘数据起始下标
realBegDate = datenum(realBegDate);
realBegIndex = find(Date>=realBegDate,1);
if isempty(realBegIndex)
    error('realBegDate is not right!');
end

realData = barData(realBegIndex:end,:);
con = totalCon(realBegIndex:end);
barLength = size(realData,1);
for i = 1:barLength
    % 买入建仓
    if MarketPosition~=1 && con(i) == 1
        if my_currentcontracts < 0 % 判断是否是反手，是则先平仓
            my_currentcontracts = 0;
            MarketPosition = 0;
        end
        
        if abs(my_currentcontracts) <= ConOpenTimes % 买入建仓，保证符合连续建仓限制
            my_currentcontracts = my_currentcontracts + lots;
            MarketPosition = 1;
        end
    end
    % 卖出建仓
    if MarketPosition~=-1 && con(i) == -1
        if my_currentcontracts > 0 % 判断是否是反手，是则先平仓
            my_currentcontracts = 0;
            MarketPosition = 0;
        end
        
        if abs(my_currentcontracts) <= ConOpenTimes % 卖出建仓，保证符合连续建仓限制
            my_currentcontracts = my_currentcontracts - lots;
            MarketPosition = -1;
        end
    end
end

position = MarketPosition;

end
