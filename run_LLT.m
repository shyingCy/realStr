function [ position ] = run_LLT( barData,realBegDate,Length,q )
% Attention:barData为品种2010-04-16到现在的六维数据。
% realBegDate是实盘开始日期，格式如'2010-04-16'
% Length,q 为策略参数

%变量
%K线变量
Date = barData(:,1);
Close = barData(:,6);
barLength = size(Date,1); %K线总量

% 交易变量
my_currentcontracts = 0;  %持仓手数
MarketPosition = 0;
ConOpenTimes = 0;
lots = 1;

%% 计算交易条件
%策略变量
a=2/(Length+1);% α值
LLTvalue = zeros(barLength,1);
for t=1:2
    LLTvalue(t) = Close(t);
end
for t = 3:barLength   %计算LLT趋势线
    LLTvalue(t)=(a-0.25*a^2)*Close(t)+0.5*a^2*Close(t-1)-(a-0.75*a^2)*Close(t-2)+(2-2*a)*LLTvalue(t-1)-(1-a)^2*LLTvalue(t-2);
end
D = zeros(barLength,1);
D(2:end)=diff(LLTvalue); %求差分

%% 实盘交易
% 找出实盘数据起始下标
realBegDate = datenum(realBegDate);
realBegIndex = find(Date>=realBegDate,1);
if isempty(realBegIndex)
    error('realBegDate is not right!');
end

realData = barData(realBegIndex:end,:);
d = D(realBegIndex:end);
barLength = size(realData,1);

for i=3:barLength
    % 买入建仓
    if MarketPosition~=1 && d(i-2)>q
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
    if MarketPosition~=-1 && d(i-2)<q
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

