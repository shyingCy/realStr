function [ position ] = run_MESM15( data,instrumentPrefix,M,E,StopLossRate )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   Attention:此策略需要data里面的日期和时间数据，instrumentPrefix是合约名，如IF，此策略无需MinPoint  
%   M,E,StopLossRate为策略参数
lots = 1; %交易手数

%变量
%K线变量
Date = data(:,1);
Time = data(:,2);
Open = data(:,3);
Close = data(:,6);
barLength = size(Close,1); %K线总量

%策略变量
MyEntryPrice = []; %开仓价格，本例是开仓均价，也可根据需要设置为某次入场的价格

MarketPosition = 0;
my_currentcontracts = 0; %持仓手数,多仓为真，空仓为负
ConOpenTimes = 0; %连续建仓次数

%从第二天的起点 寻找开盘点
a=day(Date);
b=diff(a);
index=b>0;
Begin = find(index>0,1)+1;
OpenMoment = Time(Begin);%开盘点
Action = Time(Begin + M);%上午开仓点

for i=1:barLength-1
    %百分比止损
    if MarketPosition~=0 %开始跟踪止损 若MarketPositon=0 说明已经进行过平仓
        if MarketPosition == 1 %当前看多
            LossRate = (EntryPrice - Close(i-1))/EntryPrice;
            % 卖出平仓
            if LossRate > StopLossRate %止损大于阈值
                my_currentcontracts = 0;
                MarketPosition = 0;
                MyEntryPrice = []; %重置开仓价格序列
            end
        else if MarketPosition == -1 %当前看空
                LossRate = (Close(i-1) - EntryPrice)/EntryPrice;
                % 买入平仓
                if LossRate > StopLossRate %止损大于阈值
                    my_currentcontracts = 0;
                    MarketPosition = 0;
                    MyEntryPrice = []; %重置开仓价格序列
                end
            end
        end
    end
    %上午开仓
    if Time(i) == OpenMoment %标记开盘时间
        beg  = i ;
    end
    if Time(i) == Action && beg~=0
        for t = 1:i-beg
            winClose = Close(beg:beg-1+t);
            DT = winClose - Close(beg-1+t);%一个窗口减去当前收盘价Close(i-M-1+t)
            %最大回撤
            if isempty(DT(find(DT>0)))==1
                DDser(t) = 0;
            else
                DDser(t) = max((DT(find(DT>0)))/Close(beg-1+t));
            end
            %反向最大回撤
            if isempty(DT(find(DT<0)))==1
                RDDser(t) = 0;
            else
                RDDser(t) = -min((DT(find(DT<0)))/Close(beg-1+t));
            end
        end
        MDD = sum(DDser)/M;%平均最大回撤
        MRDD = sum(RDDser)/M;%平均反向最大回撤
        Emotion = min(MDD,MRDD);%市场情绪稳定度
        if Emotion < E %市场情绪平稳度小于阈值,说明当日行情趋势明显
            EntryPrice = Open(i);
            % 买入开仓
            if Close(i-1) > Close(beg) %t时刻股指高于开盘价,做多
                if my_currentcontracts < 0 % 判断是否是反手，是则先平仓
                    my_currentcontracts = 0;
                    MarketPosition = 0;
                end
                
                if abs(my_currentcontracts) <= ConOpenTimes % 买入建仓，保证符合连续建仓限制
                    my_currentcontracts = my_currentcontracts + lots;
                    MarketPosition = 1;
                    MyEntryPrice(1) = max(Open(i),highTemp2);
                end
            else % 卖出开仓，t时刻股指低于开盘价,做空
                if my_currentcontracts > 0 % 判断是否是反手，是则先平仓
                    my_currentcontracts = 0;
                    MarketPosition = 0;
                end
                
                if abs(my_currentcontracts) <= ConOpenTimes % 卖出建仓，保证符合连续建仓限制
                    my_currentcontracts = my_currentcontracts - lots;
                    MarketPosition = -1;
                    MyEntryPrice(1) = min(Open(i),lowTemp2);
                end
            end
        end
    end
    %下午收盘时进行平仓
    %股指平仓时间为15:15:00 非股指为15:00:00
    if  ((((abs(0.6146-Time(i))<0.0001))&&(strcmp(instrumentPrefix,'IF')~=1))||((abs(0.6250-Time(i)))<0.0001))
        if MarketPosition == 1;
            exitPrice = Close(i);
            my_currentcontracts = 0;
            MarketPosition = 0;
            MyEntryPrice = []; %重置开仓价格序列
        end
        if MarketPosition == -1;
            exitPrice = Close(i);
            my_currentcontracts = 0;
            MarketPosition = 0;
            MyEntryPrice = []; %重置开仓价格序列
        end
        beg = 0;
    end
end

position = MarketPosition;

end

